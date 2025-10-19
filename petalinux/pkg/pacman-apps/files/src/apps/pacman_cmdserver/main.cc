#include <stdlib.h>
#include <stdio.h>
#include <zmq.h>

#include "tx_buffer.hh"
#include "pacman.hh"
#include "pacman_vspace.hh"
#include "pacman_message.hh"

#define REP_SOCKET_BINDING "tcp://*:5555"
#define ECHO_SOCKET_BINDING "tcp://*:5554"

void handle_ping(pacman_word_t * req_word, pacman_word_t * rep_word){
  printf("INFO:  handling ping request\n");
  write_word_ping(rep_word);
}

void handle_read(pacman_word_t * req_word, pacman_word_t * rep_word){
  uint32_t addr = req_word->read.addr;
  printf("INFO:  handling read request for address 0x%08x\n", addr);
  uint32_t value = pacman_vspace_read(addr);
  uint8_t pacman_id = pacman_vspace_get_pacman_id();
  write_word_read(rep_word, pacman_id, addr, value);
}

void handle_write(pacman_word_t * req_word, pacman_word_t * rep_word){
  uint32_t addr  = req_word->read.addr;
  uint32_t value = req_word->read.value;
  printf("INFO:  handling write request for address 0x%08x and value 0x%08x\n", addr, value);
  pacman_vspace_write(addr, value);
  uint8_t pacman_id = pacman_vspace_get_pacman_id();
  write_word_write(rep_word, pacman_id, addr, value);
}

void handle_data(pacman_word_t * req_word, pacman_word_t * rep_word){
  uint8_t  chan    = req_word->data.chan;
  uint64_t payload = req_word->data.payload;
  printf("INFO:  handling TX request for chan %5d payload 0%016lx\n", chan, payload);
  uint8_t pacman_id = pacman_vspace_get_pacman_id();
  if (chan > 0) {
    tx_buffer_in(chan-1, reinterpret_cast<uint32_t *>(&payload));
  }
  write_word_data(rep_word, pacman_id, chan, 0, payload);
}

void handle_unknown(pacman_word_t * req_word, pacman_word_t * rep_word){
  printf("ERROR:  invalid request received, replying with error \n");
  write_word_err(rep_word, 0, 0, 0xEEEE);
}

int main(int argc, char* argv[]){
    printf("INFO:  Starting pacman_cmdserver...\n");

    printf("INFO:  Initializing TX buffer.\n");
    tx_buffer_init();

    printf("INFO:  Initializing ZMQ sockets.\n");
    void* ctx = zmq_ctx_new();
    void* rep_socket = zmq_socket(ctx, ZMQ_REP);

    int timeo = 7000;
    zmq_setsockopt(rep_socket, ZMQ_SNDTIMEO, &timeo, sizeof(timeo));

    if (zmq_bind(rep_socket, REP_SOCKET_BINDING) != 0) {
        printf("ERROR:  Failed to bind socket (%s)!\n", REP_SOCKET_BINDING);
        return 1;
    }
    printf("INFO:  ZMQ REP socket created successfully.\n");

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

    // request messages:
    zmq_msg_t req_msg;
    // reply messages:
    pacman_msg_t rep_msg;

    while (1) {
      pacman_poll_tx();

      //printf("INFO:  Waiting for new message...\n");
      zmq_msg_init(&req_msg);
      int nbytes = zmq_msg_recv(&req_msg, rep_socket, 0);
      //printf("INFO:  Message received with %d bytes\n", nbytes);
      if (nbytes < 0) {
        zmq_msg_close(&req_msg);
        return 0;  // exit on error
      }

      // Cast to pacman_msg_t and print
      pacman_msg_t* msg = reinterpret_cast<pacman_msg_t*>(zmq_msg_data(&req_msg));
      print_msg(msg, "INFO:  ");

      // Start a reply message with the same number of words as the request:
      uint16_t n_words = msg->header.n_words;
      write_header_rep(&rep_msg.header, n_words, msg->header.timestamp);

      // Handle each word in the request one at a time:
      for (int i=0; i<n_words; i++){
	char wt = msg->words[i].raw[0];
	switch (wt) {
	case WORD_TYPE_PING:
	  handle_ping(&msg->words[i], &rep_msg.words[i]);
	  break;
	case WORD_TYPE_READ:
	  handle_read(&msg->words[i], &rep_msg.words[i]);
	  break;
	case WORD_TYPE_WRITE:
	  handle_write(&msg->words[i], &rep_msg.words[i]);
	  break;
	case WORD_TYPE_DATA:
	  handle_data(&msg->words[i], &rep_msg.words[i]);
	  break;
	default:
	  handle_unknown(&msg->words[i], &rep_msg.words[i]);
	}
      }

      // close the request message once we have finished handling the requests
      zmq_msg_close(&req_msg);

      // Send reply using preallocated buffer (zero-copy)
      zmq_msg_t zmq_rep;
      zmq_msg_init_data(
			&zmq_rep,
			&rep_msg,                      // pointer to preallocated buffer
			HEADER_LEN + n_words*WORD_LEN, // header + 1 word
			[](void* /*data*/, void* /*hint*/) { /* do nothing */ },
			nullptr
			);
      zmq_msg_send(&zmq_rep, rep_socket, 0);
      zmq_msg_close(&zmq_rep);
    }

    return 0;
}
