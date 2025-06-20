//#define SIMULATED_PACMAN
#ifdef SIMULATED_PACMAN

#include <stdlib.h>
#include <stdio.h>
#include <cstring>
#include <unistd.h>
#include <zmq.h>
#include <cassert>

#include "pacman.hh"
#include "tx_buffer.hh"
#include "rx_buffer.hh"

#define PUB_SOCKET_BINDING "tcp://*:5557"
#define SUB_SOCKET_BINDING "tcp://localhost:5557"

static void * pub = NULL;
static void * sub = NULL;

#define MAX_PACKETS 10000
#define BYTES_PER_PACKET 16

static uint32_t buffer[MAX_PACKETS*BYTES_PER_PACKET/4];
static volatile bool msg_done = true;

static void clear_msg(void*, void*) {
  msg_done = true;
}

static void send_msg(int count) {
  //printf("DEBUG:  sending message with count %d\n", count);
  zmq_msg_t msg;
  zmq_msg_init_data(&msg, buffer, BYTES_PER_PACKET*count, clear_msg, NULL);
  zmq_msg_send(&msg, pub, 0);
  zmq_msg_close(&msg);
  //printf("DEBUG:  done sending message\n");
}

int pacman_init(int verbose){
  printf("WARNING:  *** Using simulated hardware driver.  ***\n");
  return EXIT_SUCCESS;
}

int pacman_init_rx(int verbose, int skip_reset){
  printf("WARNING:  *** Using simulated hardware driver.  ***\n");

  printf("INFO: opening a loopback ZMQ socket:  \n");
  void* ctx = zmq_ctx_new();
  sub = zmq_socket(ctx, ZMQ_SUB);
  int linger = 0;
  zmq_setsockopt(sub, ZMQ_LINGER, &linger, sizeof(linger));
  int timeo = 0;
  zmq_setsockopt(sub, ZMQ_RCVTIMEO, &timeo, sizeof(timeo));
  timeo = 1000;
  zmq_setsockopt(sub, ZMQ_SNDTIMEO, &timeo, sizeof(timeo));
  zmq_setsockopt(sub, ZMQ_SUBSCRIBE, "", 0);

  if (zmq_connect(sub, SUB_SOCKET_BINDING) !=0 ) {
    printf("ERROR:  Failed to connect socket (%s)!\n", SUB_SOCKET_BINDING);
    return 1;
  }
  printf("INFO:  ZMQ socket created successfully.\n");

  return EXIT_SUCCESS;
}

int pacman_init_tx(int verbose, int skip_reset){
  printf("WARNING:  *** Using simulated hardware driver.  ***\n");

  printf("INFO: opening a loopback ZMQ socket:  \n");
  void* ctx = zmq_ctx_new();
  pub = zmq_socket(ctx, ZMQ_PUB);
  int hwm = 100;
  zmq_setsockopt(pub, ZMQ_SNDHWM, &hwm, sizeof(hwm));
  int linger = 0;
  zmq_setsockopt(pub, ZMQ_LINGER, &linger, sizeof(linger));
  int timeo = 0;
  zmq_setsockopt(pub, ZMQ_SNDTIMEO, &timeo, sizeof(timeo));
  if (zmq_bind(pub, PUB_SOCKET_BINDING) !=0 ) {
    printf("ERROR:  Failed to bind socket (%s)!\n", PUB_SOCKET_BINDING);
    return 1;
  }
  printf("INFO:  ZMQ socket created successfully.\n");


  return EXIT_SUCCESS;
}

int pacman_poll_rx(){
  static uint32_t buffer[4*MAX_PACKETS];
  int rc;

  // keep reading messages until we timeout waiting:
  while(1){
    zmq_msg_t msg;
    rc = zmq_msg_init(&msg);
    assert(rc==0);
    rc = zmq_msg_recv(&msg, sub, 0);
    int size = zmq_msg_size(&msg);

    if (size <= 0){
      zmq_msg_close(&msg);
      return EXIT_SUCCESS;
    }

    if (size % 16) {
      printf("ERROR:  received message of size %d\n", size);
      return EXIT_FAILURE;
    }


    int count = size / 16;
    //printf("DEBUG:  received %d words in buffer of size %d \n", count, size);
    memcpy(buffer,zmq_msg_data(&msg), size);
    zmq_msg_close(&msg);

    for (int i=0; i<count; i++){
      rx_buffer_in(&buffer[4*i]);
    }


    return EXIT_SUCCESS;
  }
}


int pacman_poll_tx(){
  uint32_t src[TX_BUFFER_BYTES/4];
  int count = 0;

  while (tx_buffer_out(src)){
    //printf("DEBUG:  Filling loopback buffer...\n");
    for (int i=0; i<TX_BUFFER_CHAN; i++){
      if (((src[i/32]>>(i%32))&1)==1) {
	if (count == 0){
	  // start of new message, wait for previous message to complete:
	  while (! msg_done){ usleep(100); }
	  msg_done = false;
	}
	//printf("DEBUG:  count: %d chan: %3d tx_data: 0x%08x %08x\n", count, i, src[4+2*i+1], src[4+2*i+0]);
	buffer[4*count + 0]=0x0044+((i+1)<<8);
	buffer[4*count + 1]=0;
	buffer[4*count + 2]=src[4+2*i+0];
	buffer[4*count + 3]=src[4+2*i+1];
	count++;
	if (count == MAX_PACKETS){
	  // send message:
	  send_msg(count);
	  count = 0;
	}
      }
    }
  }
  if (count > 0){
    // send message:
    send_msg(count);
    count = 0;
  }

  //printf("DEBUG:  sending message with count %d\n", count);
  //zmq_msg_t msg;
  //zmq_msg_init_data(&msg, buffer, 16*count, clear_msg, NULL);
  //zmq_msg_send(&msg, pub, 0);
  //zmq_msg_close(&msg);
  //printf("DEBUG:  done sending message\n");
  return EXIT_SUCCESS;
}

uint32_t G_PACMAN_SCRA = 0x0;
uint32_t G_PACMAN_SCRB = 0x0;

int pacman_write(uint32_t addr, uint32_t value){
  if (addr == 0x0)
    G_PACMAN_SCRA = value;
  else if (addr == 0x4)
    G_PACMAN_SCRB = value;

  return EXIT_SUCCESS;
}

uint32_t pacman_read(uint32_t addr, int * status){
  if (status)
    *status = EXIT_SUCCESS;
  if (addr == 0x0)
    return G_PACMAN_SCRA;
  else if (addr == 0x4)
    return G_PACMAN_SCRB;
  return 0x0;
}

#endif
