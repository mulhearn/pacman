#ifndef pacman_cmdserver_cc
#define pacman_cmdserver_cc

#include <stdlib.h>
#include <stdio.h>
#include <zmq.h>

#include "message_format.hh"
#include "tx_buffer.hh"
#include "pacman.hh"
#include "pacman_vspace.hh"

#define REP_SOCKET_BINDING "tcp://*:5555"
#define ECHO_SOCKET_BINDING "tcp://*:5554"

void send_messages(zmq_msg_t* req_msg, zmq_msg_t* rep_msg, zmq_msg_t* echo_msg, void* rep_socket, void* echo_socket) {
  zmq_msg_init(echo_msg);
  zmq_msg_copy(echo_msg, req_msg);
  zmq_msg_send(echo_msg, echo_socket, 0);

  zmq_msg_init(echo_msg);
  zmq_msg_copy(echo_msg, rep_msg);
  zmq_msg_send(echo_msg, echo_socket, 0);

  zmq_msg_send(rep_msg, rep_socket, 0);

  zmq_msg_close(req_msg);
  zmq_msg_close(echo_msg);
  zmq_msg_close(rep_msg);
}
  
int main(int argc, char* argv[]){
  printf("INFO:  Starting pacman_cmdserver...\n");
  printf("INFO:  Initializing TX buffer.\n");
  tx_buffer_init();
  printf("INFO:  Initializing ZMQ sockets.\n");
  // create zmq connection
  void* ctx = zmq_ctx_new();
  void* rep_socket = zmq_socket(ctx, ZMQ_REP);
  void* echo_socket = zmq_socket(ctx, ZMQ_PUB);
  int hwm = 100;
  int timeo = 7000;
  zmq_setsockopt(rep_socket, ZMQ_SNDTIMEO, &timeo, sizeof(timeo));
  zmq_setsockopt(echo_socket, ZMQ_SNDTIMEO, &timeo, sizeof(timeo));  
  if (zmq_bind(rep_socket, REP_SOCKET_BINDING) != 0) {
    printf("ERROR:  Failed to bind socket (%s)!\n", REP_SOCKET_BINDING);
    printf("ERROR:  (Perhaps pacman_cmdserver is already running?)\n");
    return 1;
  }
  if (zmq_bind(echo_socket, ECHO_SOCKET_BINDING) != 0) {
    printf("ERROR:  Failed to bind socket (%s)!\n", ECHO_SOCKET_BINDING);
    return 1;
  }
  printf("INFO:  ZMQ sockets created successfully.\n");

  printf("INFO:  Initializing PACMAN hardware drivers\n");
  if (pacman_init(1) == EXIT_FAILURE){
    printf("ERROR:  Failed to initialize PACMAN hardware drivers\n");
    return 1;
  }
  if (pacman_init_tx(1) == EXIT_FAILURE){
    printf("ERROR:  Failed to initialize PACMAN TX driver\n");
    return 1;
  }
  
  printf("INFO:  PACMAN HW driver initialization was successful.\n");
  
  // initialize zmq msg
  int req_msg_nbytes;
  uint32_t tx_words = 0;
  zmq_msg_t* req_msg = new zmq_msg_t();
  zmq_msg_t* rep_msg = new zmq_msg_t();
  zmq_msg_t* echo_msg = new zmq_msg_t();  
  printf("Begin loop\n");
  while (1) {
    printf("\n");
    pacman_poll_tx();
    
    // wait for msg
    printf("INFO:  Waiting for new message...\n");
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
        uint32_t* val = get_req_word_write_val(word);
	pacman_vspace_write(*reg, *val);
	set_rep_word_write(reply_word, reg, val);
        break;
      }
      
      case WORD_TYPE_READ: {
        // read pacman reg
        uint32_t* reg = get_req_word_read_reg(word);	
        uint32_t val = pacman_vspace_read(*reg);
	set_rep_word_read(reply_word, reg, &val);	
        break;
      }

      case WORD_TYPE_TX: {
	// transmit data
	char* io_channel = get_req_word_tx_channel(word);	
	// UGLY... FIXME INTERFACE TX_BUFFER / PACMAN-SERVER:
	uint64_t* pdata = get_req_word_tx_data(word);
	uint64_t data = *pdata;

	printf("DEBUG:  DATA REQUEST:  0x%lx\n", data);
	
	uint32_t dat[2] = {0,0};
	dat[0] = (data & 0x00000000FFFFFFFF);
	dat[1] = ((data>>32) & 0x00000000FFFFFFFF);
	printf("DEBUG:  TX: %d 0x%08x %08x\n",*io_channel,dat[1],dat[0]);
	tx_buffer_in((*io_channel)-1, dat);
	set_rep_word_tx(reply_word, io_channel, pdata);
	break;
      }
      default: 
	// unknown command
        printf("UNKNOWN COMMAND\n");
	set_rep_word_err(reply_word, NULL, NULL);
      }
    }

    // send reply
    printf("Sending messages...\n");
    //print_msg(reply);
    send_messages(req_msg, rep_msg, echo_msg, rep_socket, echo_socket);
    printf("Messages sent!\n");
      

  }
  return 0;
}
#endif
