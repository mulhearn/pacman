#ifndef pacman_dataserver_cc
#define pacman_dataserver_cc

#include <chrono>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <zmq.h>
#include <unistd.h>

#include "message_format.hh"
#include "rx_buffer.hh"
#include "pacman.hh"

#define MAX_MSG_LEN  16000 // words
#define MIN_MSG_LEN   4000 // words
#define PUB_SOCKET_BINDING "tcp://*:5556"

volatile bool msg_ready = true;

void clear_msg(void*, void*) {
    msg_ready = true;
}

int main(int argc, char* argv[]){
  printf("INFO:  Starting pacman-dataserver...\n");
  printf("INFO:  Initializing RX buffer.\n");
  rx_buffer_init();
  printf("INFO:  Initializing ZMQ socket.\n");
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
    printf("ERROR:  Failed to bind socket!\n");
    printf("ERROR:  (Perhaps pacman_dataserver is already running?)\n");
    return 1;
  }
  printf("INFO:  ZMQ socket created successfully.\n");
  printf("INFO:  Initializing PACMAN RX driver.\n");
  if (pacman_init_rx(1,1) == EXIT_FAILURE){
    printf("ERROR:  Failed to initialize PACMAN RX driver\n");
    return 1;
  }
  printf("INFO:  PACMAN RX driver initialization was successful.\n");

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
  printf("INFO:  Entering RX loop.\n");
  while(1) {
    pacman_poll_rx();
    words = rx_buffer_count();

    unsigned timeout = 10000;
    while((words < MIN_MSG_LEN) && (timeout > 0)){
      timeout--;
      pacman_poll_rx();
      words = rx_buffer_count();
    }
    if (words > 0){
      printf("DEBUG:  words: %u timeout %u\n", words, timeout);
    }
    if ((words==0) || (!msg_ready)){
      continue;
    }

    if (words > MAX_MSG_LEN)
      words = MAX_MSG_LEN;

    total_words += words;
    now = std::chrono::high_resolution_clock::now().time_since_epoch();

    // create new message
    init_msg(msg_buffer, words, MSG_TYPE_DATA);
    msg_bytes = get_msg_bytes(words);

    zmq_msg_init_data(pub_msg, msg_buffer, msg_bytes, clear_msg, NULL);

    word_idx = 0;
    // copy data into message
    while(word_idx < words) {
	word = get_word(msg_buffer, word_idx);
	if (rx_buffer_out((uint32_t *) word) == 0){
	  printf("ERROR:  There is a bug in rx_buffer, because output failed despite checking size.\n");
	}
	word_idx++;
    }
    msg_ready = false;
    if (zmq_msg_send(pub_msg, pub_socket, 0) < 0)
        printf("Error sending message!\n");
    else
        sent_msgs++;
    last_sent_msg = std::chrono::high_resolution_clock::now().time_since_epoch();
    zmq_msg_close(pub_msg);

    printf("INFO:  message of %u words sent.  Total sent message:  %d\n", words, sent_msgs);
  }
  return 0;
}

#endif
