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

#include "fw-addr-conf.hh"
#include "dma.hh"
#include "larpix.hh"
#include "message-format.hh"

#define MAX_MSG_LEN 1024 // words

void* restart_dma(uint32_t* dma) {
  printf("Restarting DMA...\n");
  dma_set(dma, DMA_S2MM_CTRL_REG, 0); // halt
  dma_set(dma, DMA_S2MM_CTRL_REG, DMA_RST); // reset
  dma_set(dma, DMA_S2MM_CTRL_REG, DMA_RUN); // run
  dma_s2mm_status(dma);
}

int main(int argc, char* argv[]){
  printf("Start pacman-dataserver\n");
  // create zmq connection
  void* ctx = zmq_ctx_new();
  void* pub_socket = zmq_socket(ctx, ZMQ_PUB);
  if (zmq_bind(pub_socket, "tcp://*:5556") !=0 ) {
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
  dma_set(dma, DMA_S2MM_CURR_REG, curr->addr);
  restart_dma(dma);
  dma_set(dma, DMA_S2MM_TAIL_REG, prev->addr);
  uint32_t dma_status = dma_get(dma, DMA_S2MM_STAT_REG);
  if ( dma_status & DMA_HALTED ) {
    printf("Error starting DMA\n");
    return 2;
  }
  printf("DMA started\n");

  uint32_t words = 0;
  uint32_t msg_words;
  uint32_t msg_bytes;
  uint32_t word_idx;
  char word_type;
  char* word;
  bool err = false;
  while(1) {
    // std::this_thread::sleep_for(std::chrono::milliseconds(100));
    
    // collect all complete transfers
    while(dma_desc_cmplt(curr->desc)) {
      curr = curr->next;
      words++;
    }
    if (curr == prev) continue;
    printf("Words: %d\n", words);

    // create message(s)
    while (words > 0) {
      char* msg;
      msg_words = words >= MAX_MSG_LEN ? MAX_MSG_LEN : words % MAX_MSG_LEN;
      msg_bytes = init_msg(msg, msg_words, MSG_TYPE_DATA);
      word_idx = 0;
      printf("Message bytes: %d\n", msg_bytes);
    
      zmq_msg_t* pub_msg = new zmq_msg_t();
      zmq_msg_init_data(pub_msg, msg, msg_bytes, (void (*)(void*,void*))free_msg, NULL);
    
      // copy data into message
      while(word_idx < msg_words) {
	word_type = *((char*)prev->word + WORD_TYPE_OFFSET);
	
	word = get_word(msg, word_idx);
	switch (word_type) {
	default : {
	  // for now, don't worry about the word type, make all larpix data
	  set_data_word_data(word,
			     (char*)prev->word + IO_CHANNEL_OFFSET,
			     (uint32_t*)((char*)prev->word + TS_PACMAN_OFFSET),
			     (uint64_t*)((char*)prev->word + LARPIX_DATA_OFFSET)
			     );
	}}
      
	// reset word
	if (dma_get(prev->desc, DESC_STAT) & (DESC_INTERR | DESC_SLVERR | DESC_DECERR)) {
	  err = true;
	  dma_desc_print(prev->desc);
	}
	memset(prev->word, 0, LARPIX_PACKET_LEN);
	dma_set(prev->desc, DESC_STAT, 0);

	// get next word
	words--;
	word_idx++;
	prev = prev->next;
      }
      // update dma
      if (err || dma_get(dma, DMA_S2MM_STAT_REG) & DMA_HALTED) {
	// reset if errors occurred
	dma_s2mm_status(dma);
	restart_dma(dma);
	curr = buffer_start;
	prev = buffer_end;
	err = false;
      }
      dma_set(dma, DMA_S2MM_TAIL_REG, (prev->prev)->addr);

      // send message
      // print_msg(msg);
      if (zmq_msg_send(pub_msg, pub_socket, NULL) < 0)
	printf("Error sending message!\n");
      else
	printf("Message sent!\n");
    }
  }
  return 0;
}

#endif
