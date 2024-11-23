#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <zmq.h>
#include <cstring>
#include <cassert>
#include <sys/time.h>

#define SOCKET_A_BINDING_PUB "tcp://*:5567"
#define SOCKET_B_BINDING_SUB "tcp://localhost:5568"

static void * ctx = NULL;
static void * pub = NULL;
static void * sub = NULL;

//#define MAX_BUFFER_SIZE 1024
#define MAX_BUFFER_SIZE 16384
uint32_t tx_buffer[MAX_BUFFER_SIZE/4];
uint32_t rx_buffer[MAX_BUFFER_SIZE/4];

static volatile bool msg_done = true;

static void clear_msg(void*, void*) {
  msg_done = true;
}

int main(int argc, char* argv[]){
  struct timeval start, end;
  double elapsed_time;
  int rc, iparam; 
  printf("INFO:  Starting ZMQ loopback demo.\n");
  printf("INFO:  RAND_MAX: 0x%x\n", RAND_MAX);
  printf("INFO:  Creating new ZMQ context...\n");
  void* ctx = zmq_ctx_new();

  printf("INFO:  Initializing PUB socket (A) ...\n");  
  pub = zmq_socket(ctx, ZMQ_PUB);
  iparam = 100;
  zmq_setsockopt(pub, ZMQ_SNDHWM, &iparam, sizeof(iparam));
  iparam = 1000;
  zmq_setsockopt(pub, ZMQ_LINGER, &iparam, sizeof(iparam));
  iparam = 1000;
  zmq_setsockopt(pub, ZMQ_SNDTIMEO, &iparam, sizeof(iparam));
  if (zmq_bind(pub, SOCKET_A_BINDING_PUB) !=0 ) {
    printf("ERROR:  Failed to bind socket (%s)!\n", SOCKET_A_BINDING_PUB);
    return 1;
  }
  printf("INFO:  ZQM PUB socket (A) connected successfully...\n");
  
  printf("INFO:  Initializing SUB socket (B) ...\n");
  sub = zmq_socket(ctx, ZMQ_SUB);
  iparam = 1000;
  zmq_setsockopt(sub, ZMQ_RCVTIMEO, &iparam, sizeof(iparam));
  zmq_setsockopt(sub, ZMQ_SUBSCRIBE, "", 0);

  if (zmq_connect(sub, SOCKET_B_BINDING_SUB) !=0 ) {
    printf("ERROR:  Failed to connect socket (%s)!\n", SOCKET_B_BINDING_SUB);
    return 1;
  }
  printf("INFO:  ZQM SUB socket (B) connected successfully...\n");
  
  int tx_count   = 0;
  int rx_count   = 0;
  int err_words  = 0;
  int tot_words  = 0;
  int N = 100;

  //I miss the first message unless I have this not-understood pause...
  usleep(1000000);
  
  printf("INFO: benchmarking %d TX/RX\n", N);
  gettimeofday(&start, NULL);

  while(rx_count < N){
    zmq_msg_t msg;

    for (int i=0; i<(MAX_BUFFER_SIZE/4); i++){
      tx_buffer[i] = rand();
      rx_buffer[i] = 0;
    }
    
    if (tx_count < N){
      //printf("DEBUG:  sending a message \n");
      rc = zmq_msg_init_data(&msg, tx_buffer, MAX_BUFFER_SIZE, 0, 0);
      assert(rc==0);
      rc = zmq_msg_send(&msg, pub, 0);
      assert(rc!=-1);
      rc = zmq_msg_close(&msg);
      assert(rc==0);
      //printf("DEBUG:  done sending message \n");
      tx_count = tx_count+1;
    }

    zmq_msg_init(&msg);
    rc = zmq_msg_recv(&msg, sub, 0);
    int size = zmq_msg_size(&msg);
    if (size <= 0){
      zmq_msg_close(&msg);
      printf("DEBUG:  no message received \n");
      continue;
    }
    if (size != MAX_BUFFER_SIZE){
      printf("ERROR:  unexpected size message\n");
      continue;
    }    
    memcpy(rx_buffer,zmq_msg_data(&msg), size);
    zmq_msg_close(&msg);

    for (int i=0; i<(MAX_BUFFER_SIZE/4); i++){
      tot_words++;
      if (tx_buffer[i] != rx_buffer[i]){
	err_words++;
      }
    }
    
    //printf("DEBUG:  received message of size %d bytes \n", size);
    rx_count = rx_count+1;
  }
  gettimeofday(&end, NULL);
  elapsed_time = 1000.0*(end.tv_sec - start.tv_sec) + (end.tv_usec - start.tv_usec) / 1000.0;
  printf("INFO: tx_count: %d\n", tx_count);
  printf("INFO: rx_count: %d\n", rx_count);
  printf("INFO: total words: %d  errors: %d\n", tot_words, err_words);
  uint64_t data = tx_count * MAX_BUFFER_SIZE;
  double mbts = data*1000/(elapsed_time*1024*1024);
  printf("INFO: bytes:     %lu\n", data);
  printf("INFO: time (ms): %lf\n", elapsed_time);
  printf("INFO: mbts:      %lf\n", mbts);
  return 0;
}