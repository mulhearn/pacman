#ifndef pacman_dataserver_cc
#define pacman_dataserver_cc

#include <thread>
#include <chrono>

#include <algorithm>
#include <fcntl.h>
#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/mman.h>
#include <string.h>
#include <zmq.h>
#include <ctime>

#include "addr_conf.hh"
#include "dma.hh"
#include "larpix.hh"
#include "message_format.hh"

#define MAX_MSG_LEN 65535 // words
#define PUB_SOCKET_BINDING "tcp://*:5556"

volatile bool msg_ready = true;

void clear_msg(void*, void*) {
    msg_ready = true;
}

void* restart_dma(uint32_t* dma, uint32_t curr) {
  printf("Restarting DMA...\n");
  dma_set(dma, DMA_S2MM_CTRL_REG, DMA_RST); // reset
  dma_set(dma, DMA_S2MM_CTRL_REG, 0); // halt
  dma_set(dma, DMA_S2MM_CURR_REG, curr); // set curr
  dma_set(dma, DMA_S2MM_CTRL_REG, DMA_RUN); // run
  dma_s2mm_status(dma);
}

int main(int argc, char* argv[]){
  printf("Start pacman-dataserver\n");
  // create zmq connection
  void* ctx = zmq_ctx_new();
  void* pub_socket = zmq_socket(ctx, ZMQ_PUB);
  int hwm = 100;
  zmq_setsockopt(pub_socket, ZMQ_SNDHWM, &hwm, sizeof(hwm));
  int linger = 0;
  zmq_setsockopt(pub_socket, ZMQ_LINGER, &linger, sizeof(linger));
  int timeo = 1000;
  zmq_setsockopt(pub_socket, ZMQ_SNDTIMEO, &timeo, sizeof(timeo));
  if (zmq_bind(pub_socket, PUB_SOCKET_BINDING) !=0 ) {
    printf("Failed to bind socket!\n");
    return 1;
  }
  printf("ZMQ socket created\n");
  
  // initialize dma
  int dh = open("/dev/mem", O_RDWR|O_SYNC);
  uint32_t* dma = (uint32_t*)mmap(NULL, DMA_LEN, PROT_READ|PROT_WRITE, MAP_SHARED, dh, DMA_ADDR);
  uint32_t* dma_rx = (uint32_t*)mmap(NULL, DMA_RX_MAXLEN, PROT_READ|PROT_WRITE, MAP_SHARED, dh, DMA_RX_ADDR);
  dma_desc* buffer_start = init_circular_buffer(dma_rx, DMA_RX_ADDR, DMA_RX_MAXLEN, LARPIX_PACKET_LEN);
  dma_desc* buffer_end = buffer_start->prev;
  uint32_t  buffer_desc_size = sizeof(*buffer_start);
  dma_desc* curr = buffer_start;
  dma_desc* prev = buffer_start;
  restart_dma(dma, curr->addr);
  dma_set(dma, DMA_S2MM_TAIL_REG, buffer_end->addr);
  uint32_t dma_status = dma_get(dma, DMA_S2MM_STAT_REG);
  if ( dma_status & DMA_HALTED ) {
    printf("Error starting DMA\n");
    return 2;
  }
  printf("DMA started\n");

  auto start_time = std::chrono::high_resolution_clock::now().time_since_epoch();
  auto last_time  = start_time;
  auto now = start_time;
  auto last_sent_msg = now;  
  uint64_t total_words = 0;
  uint32_t words = 0;
  uint32_t msg_bytes;
  uint32_t sent_msgs = 0;
  uint32_t word_idx;
  char word_type;
  char* word;
  char msg_buffer[HEADER_LEN + MAX_MSG_LEN*WORD_LEN]; // pre-allocate message buffer
  zmq_msg_t* pub_msg = new zmq_msg_t();  
  bool err = false;
  printf("Begin loop\n");
  while(1) {
    //std::this_thread::sleep_for(std::chrono::milliseconds(100));

    // collect all complete transfers (up to max message size)
    while(dma_desc_cmplt(curr->desc)) {
      curr = curr->next;
      words++;
      if (curr == prev->prev) break; // reached end of buffer
      if (words == MAX_MSG_LEN) break; // reached max message size
    }
    if (curr == prev) continue; // no new words
    total_words += words;
    now = std::chrono::high_resolution_clock::now().time_since_epoch();
    //printf("DMA_CURR: %p, DMA_TAIL: %p\n",dma_get(dma,DMA_S2MM_CURR_REG), dma_get(dma,DMA_S2MM_TAIL_REG));
    printf("\n");
    printf("New data available\n");
    printf("Words: %d, total: %d, rate: %.02fMb/s (%.02fMb/s)\n",
           words,
           total_words,
           (std::chrono::duration<double>)words/(now-last_time) * LARPIX_PACKET_LEN * 8 / 1e6,
           (std::chrono::duration<double>)total_words/(now-start_time) * LARPIX_PACKET_LEN * 8 / 1e6
           );
    // wait for last message transfer to complete (up to some timeout)
    last_time = now;
    while (!msg_ready && (std::chrono::high_resolution_clock::now().time_since_epoch() < last_sent_msg + std::chrono::milliseconds(timeo))) { ; }

    // create new message
    init_msg(msg_buffer, words, MSG_TYPE_DATA);
    msg_bytes = get_msg_bytes(words);      

    zmq_msg_init_data(pub_msg, msg_buffer, msg_bytes, clear_msg, NULL);

    word_idx = 0;
    // copy data into message
    while(word_idx < words) {
	word = get_word(msg_buffer, word_idx);
        memcpy(word, prev->word, 16);
      
	// reset word
	if (dma_get(prev->desc, DESC_STAT) & (DESC_INTERR | DESC_SLVERR | DESC_DECERR)) {
            printf("Descriptor error!\n");
            err = true;
            dma_desc_print(prev->desc);
            // reset
            dma_set(prev->desc, DESC_ADDR, prev->word_addr);
            dma_set(prev->desc, DESC_NEXT, (prev->next)->addr);
            dma_desc_print(prev->desc);
	}
	dma_set(prev->desc, DESC_STAT, 0);

	// get next word
	word_idx++;
	prev = prev->next;
    }
    // update dma
    dma_set(dma, DMA_S2MM_TAIL_REG, (prev->prev)->addr);
    
    // send message
    //print_msg(msg_buffer);
    msg_ready = false;    
    if (zmq_msg_send(pub_msg, pub_socket, 0) < 0)
        printf("Error sending message!\n");
    else
        sent_msgs++;
    last_sent_msg = std::chrono::high_resolution_clock::now().time_since_epoch();
    zmq_msg_close(pub_msg);

    printf("Data messages sent: %d\n", sent_msgs);
    sent_msgs = 0;
    words = 0;

    prev = curr;
    if (err || dma_get(dma, DMA_S2MM_STAT_REG) & DMA_ERR_IRQ) {
      // try reset if errors occurred
      printf("An error occurred!\n");
      dma_s2mm_status(dma);
      restart_dma(dma, curr->addr);
      dma_set(dma, DMA_S2MM_TAIL_REG, (prev->prev)->addr);
      err = false;
    }
  }
  return 0;
}

#endif
