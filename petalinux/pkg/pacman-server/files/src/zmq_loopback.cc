#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <zmq.h>
#include <cstring>
#include <cassert>

#define SOCKET_A_BINDING_SUB "tcp://localhost:5567"
#define SOCKET_B_BINDING_PUB "tcp://*:5568"

static void * ctx = NULL;
static void * pub = NULL;
static void * sub = NULL;

#define MAX_BUFFER_SIZE 16384

static volatile bool msg_done = true;

static void clear_msg(void*, void*) {
  msg_done = true;
}

int main(int argc, char* argv[]){
  uint32_t buffer[MAX_BUFFER_SIZE];
  int rc, iparam; 
  printf("INFO:  Starting ZMQ loopback demo.\n");
  printf("INFO:  Creating new ZMQ context...\n");
  void* ctx = zmq_ctx_new();
  printf("INFO:  Initializing SUB socket (A) ...\n");
  sub = zmq_socket(ctx, ZMQ_SUB);
  iparam = 1000;
  zmq_setsockopt(sub, ZMQ_RCVTIMEO, &iparam, sizeof(iparam));
  zmq_setsockopt(sub, ZMQ_SUBSCRIBE, "", 0);

  if (zmq_connect(sub, SOCKET_A_BINDING_SUB) !=0 ) {
    printf("ERROR:  Failed to connect socket (%s)!\n", SOCKET_A_BINDING_SUB);
    return 1;
  }
  printf("INFO:  ZQM SUB socket (A) connected successfully...\n");
  
  printf("INFO:  Initializing PUB socket (B) ...\n");  
  pub = zmq_socket(ctx, ZMQ_PUB);
  iparam = 100;
  zmq_setsockopt(pub, ZMQ_SNDHWM, &iparam, sizeof(iparam));
  iparam = 1000;
  zmq_setsockopt(pub, ZMQ_LINGER, &iparam, sizeof(iparam));
  iparam = 1000;
  zmq_setsockopt(pub, ZMQ_SNDTIMEO, &iparam, sizeof(iparam));
  if (zmq_bind(pub, SOCKET_B_BINDING_PUB) !=0 ) {
    printf("ERROR:  Failed to bind socket (%s)!\n", SOCKET_B_BINDING_PUB);
    return 1;
  }
  printf("INFO:  ZQM PUB socket (A) connected successfully...\n");

  printf("INFO:  Entering loop:\n");
  while(1){
    zmq_msg_t msg;
    rc = zmq_msg_init(&msg);
    assert(rc==0);
    rc = zmq_msg_recv(&msg, sub, 0);
    int size = zmq_msg_size(&msg);
    if (size <= 0){
      zmq_msg_close(&msg);
      continue;
    }
    if (size > MAX_BUFFER_SIZE){
      printf("ERROR:  message too large... truncating.\n");
      size = MAX_BUFFER_SIZE;
    }
    
    printf("DEBUG:  received message of size %d bytes \n", size);
    memcpy(buffer,zmq_msg_data(&msg), size);
    zmq_msg_close(&msg);

    printf("DEBUG:  forwarding message \n");
    zmq_msg_init_data(&msg, buffer, size, 0, 0);
    zmq_msg_send(&msg, pub, 0);
    zmq_msg_close(&msg);
    printf("DEBUG:  done forwarding message \n");
  }
  return 0;
}
