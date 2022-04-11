#ifndef pacman_cmdserver_cc
#define pacman_cmdserver_cc

#include <chrono>
#include <thread>

#include <stdio.h>
#include <fcntl.h>
#include <cstring>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/mman.h>
#include <zmq.h>
#include <cerrno>

#include "addr_conf.hh"
#include "dma.hh"
#include "message_format.hh"
#include "larpix.hh"
#include "pacman.hh"
#include "pacman_i2c.hh"

#define REP_SOCKET_BINDING "tcp://*:5555"
#define ECHO_SOCKET_BINDING "tcp://*:5554"

void dma_restart(uint32_t* virtual_address, dma_desc* start) {
  printf("Restarting DMA...\n");
  dma_set(virtual_address, DMA_MM2S_CTRL_REG, DMA_RST); // reset
  dma_set(virtual_address, DMA_MM2S_CTRL_REG, 0); // halt
  dma_set(virtual_address, DMA_MM2S_CURR_REG, start->addr);
  dma_set(virtual_address, DMA_MM2S_CTRL_REG, DMA_RUN); // run
  dma_mm2s_status(virtual_address);
}


void transmit_data(uint32_t* virtual_address, dma_desc* start, uint32_t nwords) {
  if (nwords == 0) return;
  dma_desc* tail = start;
  while (nwords > 1) {
    tail = tail->next;
    nwords--;
  }
  dma_set(virtual_address, DMA_MM2S_TAIL_REG, tail->addr);
  while (!dma_desc_cmplt(tail->desc)){
    //std::this_thread::sleep_for(std::chrono::milliseconds(100));
    NULL;
  }
}

void send_reply(zmq_msg_t* rep_msg, zmq_msg_t* echo_msg, void* rep_socket, void* echo_socket) {
  zmq_msg_init(echo_msg);
  zmq_msg_copy(echo_msg, rep_msg);

  zmq_msg_send(echo_msg, echo_socket, 0);
  zmq_msg_send(rep_msg, rep_socket, 0);

  zmq_msg_close(echo_msg);
  zmq_msg_close(rep_msg);
}
  

int main(int argc, char* argv[]){
  printf("Start pacman-cmdserver\n");
  // create zmq connection
  void* ctx = zmq_ctx_new();
  void* rep_socket = zmq_socket(ctx, ZMQ_REP);
  void* echo_socket = zmq_socket(ctx, ZMQ_PUB);
  int hwm = 100;
  int timeo = 7000;
  zmq_setsockopt(rep_socket, ZMQ_SNDTIMEO, &timeo, sizeof(timeo));
  zmq_setsockopt(echo_socket, ZMQ_SNDTIMEO, &timeo, sizeof(timeo));  
  if (zmq_bind(rep_socket, REP_SOCKET_BINDING) != 0) {
    printf("Failed to bind socket (%s)!\n", REP_SOCKET_BINDING);
    return 1;
  }
  if (zmq_bind(echo_socket, ECHO_SOCKET_BINDING) != 0) {
    printf("Failed to bind socket (%s)!\n", ECHO_SOCKET_BINDING);
    return 1;
  }
  printf("ZMQ socket(s) created\n");
  
  // initialize dma
  int dh = open("/dev/mem", O_RDWR|O_SYNC);
  uint32_t* dma = (uint32_t*)mmap(NULL, DMA_LEN, PROT_READ|PROT_WRITE, MAP_SHARED, dh, DMA_ADDR);
  uint32_t* dma_tx = (uint32_t*)mmap(NULL, DMA_TX_MAXLEN, PROT_READ|PROT_WRITE, MAP_SHARED, dh, DMA_TX_ADDR);
  dma_desc* curr = init_circular_buffer(dma_tx, DMA_TX_ADDR, DMA_TX_MAXLEN, LARPIX_PACKET_LEN);
  dma_desc* prev = curr;
  dma_restart(dma, curr);
  uint32_t dma_status = dma_get(dma, DMA_MM2S_STAT_REG);
  if ( dma_status & DMA_HALTED ) {
    printf("Error starting DMA\n");
    return 2;
  }
  printf("DMA started\n");

  // initialize pacman-pl
  uint32_t* pacman_pl = (uint32_t*)mmap(NULL, PACMAN_LEN, PROT_READ|PROT_WRITE, MAP_SHARED, dh, PACMAN_ADDR);

  // initialize i2c-1
  int i2c_1_dh = i2c_open(I2C_1_DEV);
  if (i2c_1_dh < 0) {
      printf("Error initializing I2C-1\n");
      return 3;
  }
  // initialize i2c-2
  //int i2c_2_dh = i2c_open(I2C_2_DEV);
  //if (i2c_2_dh < 0) {
  //    printf("Error initializing I2C-2\n");
  //    return 3;
  //}
  printf("I2C initialized\n");

  // initialize zmq msg
  int req_msg_nbytes;
  uint32_t tx_words = 0;
  zmq_msg_t* req_msg = new zmq_msg_t();
  zmq_msg_t* rep_msg = new zmq_msg_t();
  zmq_msg_t* echo_msg = new zmq_msg_t();  
  printf("Begin loop\n");
  while (1) {
    printf("\n");
    //std::this_thread::sleep_for(std::chrono::milliseconds(100));
    
    // wait for msg
    printf("Waiting for new message...\n");
    zmq_msg_init(req_msg);
    req_msg_nbytes = zmq_msg_recv(req_msg, rep_socket, 0);
    if (req_msg_nbytes<0) {
      continue;
    }
    printf("Receiving message...\n");
    char* msg = (char*)zmq_msg_data(req_msg);
    char* msg_type = get_msg_type(msg);
    //print_msg(msg);
    printf("Request received!\n");    
    
    // respond to each word in message
    uint16_t* msg_words = get_msg_words(msg);
    printf("Requested %d actions\n",*msg_words);
    uint32_t reply_bytes = get_msg_bytes(*msg_words);

    zmq_msg_init_size(rep_msg, reply_bytes);
    char* reply = (char*)zmq_msg_data(rep_msg);
    init_msg(reply, *msg_words, MSG_TYPE_REP);    

    for (uint32_t word_idx = 0; word_idx < *msg_words; word_idx++) {
      char* word = get_word(msg, word_idx);
      char* word_type = get_word_type(word);
      char* reply_word = get_word(reply, word_idx);
      
      switch (*word_type) {
      case WORD_TYPE_PING: {
	// ping-pong
	set_rep_word_pong(reply_word);
        //printf("PING\n");        
	break;
      }
      
      case WORD_TYPE_WRITE: {
        // set pacman reg
        uint32_t* reg = get_req_word_write_reg(word);
        uint32_t* val;
        if (*reg < PACMAN_LEN) {
          val = get_req_word_write_val(word);
          pacman_set(pacman_pl, *reg, *val);
          set_rep_word_write(reply_word, reg, val);
        } else if (*reg >= I2C_1_BASE_ADDR && *reg < I2C_1_BASE_ADDR + I2C_1_BASE_LEN) {
          val = get_req_word_write_val(word);
          i2c_write(i2c_1_dh, *reg, *val);
          set_rep_word_write(reply_word, reg, val);
        } else if (*reg >= I2C_2_BASE_ADDR && *reg < I2C_2_BASE_ADDR + I2C_2_BASE_LEN) {
          val = get_req_word_write_val(word);
          i2c_write(i2c_1_dh, *reg, *val);
          set_rep_word_write(reply_word, reg, val);
        } else {
          set_rep_word_err(reply_word, NULL, NULL);
        }
        //printf("WRITE: 0x%08x 0x%08x\n",*reg,*val);
        break;
      }
      
      case WORD_TYPE_READ: {
        // read pacman reg
        uint32_t* reg = get_req_word_read_reg(word);
        uint32_t val;
        if (*reg < PACMAN_LEN) {
          val = pacman_get(pacman_pl, *reg);
          set_rep_word_read(reply_word, reg, &val);
        } else if (*reg >= I2C_1_BASE_ADDR && *reg < I2C_1_BASE_ADDR + I2C_1_BASE_LEN) {
          val = i2c_read(i2c_1_dh, *reg);
          set_rep_word_read(reply_word, reg, &val);
        } else if (*reg >= I2C_2_BASE_ADDR && *reg < I2C_2_BASE_ADDR + I2C_2_BASE_LEN) {
          val = i2c_read(i2c_1_dh, *reg);
          set_rep_word_read(reply_word, reg, &val);
        } else {
          set_rep_word_err(reply_word, NULL, NULL);
        }
        //printf("READ: 0x%08x 0x%08x\n",*reg,val);
        break;
      }

      case WORD_TYPE_TX: {
	// transmit data
	char* io_channel = get_req_word_tx_channel(word);
	uint64_t* data = get_req_word_tx_data(word);
	tx_words++;

	memcpy(&curr->word[WORD_TYPE_OFFSET], word_type, 1);
	memcpy(&curr->word[IO_CHANNEL_OFFSET], io_channel, 1);
	memcpy(&curr->word[LARPIX_DATA_OFFSET], (char*)data, sizeof(*data));
	dma_set(curr->desc, DESC_STAT, 0);
	curr = curr->next;

	set_rep_word_tx(reply_word, io_channel, data);
        //printf("TX: %d 0x%016x\n",*io_channel,*data);
	break;
      }

      default: 
	// unknown command
        printf("UNKNOWN COMMAND\n");
	set_rep_word_err(reply_word, NULL, NULL);
      }
    }

    // transmit
    transmit_data(dma, prev, tx_words);
    prev = curr;
    tx_words = 0;

    // send reply
    printf("Sending reply...\n");
    //print_msg(reply);
    send_reply(rep_msg, echo_msg, rep_socket, echo_socket);
    printf("Reply sent!\n");
      
    zmq_msg_close(req_msg);
  }
  return 0;
}
#endif
