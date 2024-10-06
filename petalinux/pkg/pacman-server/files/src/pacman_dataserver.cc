#ifndef pacman_dataserver_cc
#define pacman_dataserver_cc


#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <zmq.h>
#include <assert.h>

#include "message_format.hh"
#include "larpix.hh"
#include "rx_buffer.hh"
#include "pacman.hh"


//#include <thread>
//#include <chrono>
//#include <algorithm>
//#include <fcntl.h>
//#include <stdio.h>
//#include <sys/types.h>
//#include <sys/stat.h>
//#include <sys/mman.h>

//#include <zmq.h>
//#include <ctime>

#define MAX_WORDS_MSG 1024 // The max number of LARPIX_PACKET_LEN (16-byte) words in a single message
#define PUB_SOCKET_BINDING "tcp://*:5556"

volatile bool msg_ready = true;

void clear_msg(void*, void*) {
    msg_ready = true;
}

int main(int argc, char* argv[]){
  int success;
  uint32_t words;
  uint32_t rx_data[4];
  char msg_buffer[HEADER_LEN + MAX_WORDS_MSG*WORD_LEN]; // message buffer of maximum length
  // stats:
  uint64_t total_words = 0;
  uint64_t sent_msgs = 0;

  // ensure that buffer is consistent with larpix:
  assert((WORD_LEN) == (RX_BUFFER_BYTES));
  assert((WORD_LEN) == (LARPIX_WIDE_LEN));
  assert((MAX_WORDS_MSG) == (RX_BUFFER_DEPTH));

  printf("INFO:  Starting pacman_dataserver...\n");
  printf("INFO:  Initializing RX buffer.\n");
  rx_buffer_init();
  printf("INFO:  Initializing ZMQ sockets.\n");

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
    printf("ERROR:  Failed to bind socket (%s)!\n", PUB_SOCKET_BINDING);
    printf("ERROR:  (Perhaps pacman_dataserver is already running?)\n");
    return 1;
  }
  printf("INFO:  ZMQ socket created successfully.\n");
  printf("INFO:  Initializing PACMAN hardware drivers\n");
  if (pacman_init_rx(1) == EXIT_FAILURE){
    printf("ERROR:  Failed to initialize PACMAN RX driver\n");
    return 1;
  }
  printf("INFO:  PACMAN HW driver initialization was successful.\n");

  zmq_msg_t* pub_msg = new zmq_msg_t();
  printf("Begin loop\n");
  while(1) {
    usleep(2000000);
    pacman_poll_rx();

    words = rx_buffer_count();

    if (words == 0){
      printf("INFO: no new data received...\n");
      continue;
    }
    printf("INFO: Received new data, words = %d\n", words);

    // create new message
    init_msg(msg_buffer, words, MSG_TYPE_DATA);
    zmq_msg_init_data(pub_msg, msg_buffer, get_msg_bytes(words), clear_msg, NULL);

    // copy available data into message
    success=1;
    for(int word_idx=0; word_idx<words; word_idx++){
      success &= (rx_buffer_out(rx_data)==1);
      char* word = get_word(msg_buffer, word_idx);
      memcpy(word, rx_data, WORD_LEN);
    }
    assert(success);

    msg_ready = false;
    if (zmq_msg_send(pub_msg, pub_socket, 0) < 0)
        printf("Error sending message!\n");
    else
        sent_msgs++;
    zmq_msg_close(pub_msg);

    printf("Data messages sent: %d\n", sent_msgs);
    total_words += words;
  }
  return 0;
}

#endif
