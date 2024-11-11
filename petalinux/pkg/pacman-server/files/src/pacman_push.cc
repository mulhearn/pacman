#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <zmq.h>
#include <cstring>
#include <cassert>
#include <sys/time.h>

#define SOCKET_A_BINDING_REQ "tcp://localhost:5555"

static void * ctx = NULL;
static void * req = NULL;

//#define MAX_BUFFER_SIZE 1024
//#define MAX_BUFFER_SIZE 16384

// BUFFER SIZE:  8 + N * 16
//#define MAX_BUFFER_SIZE 648
#define MAX_BUFFER_SIZE 2568
//#define MAX_BUFFER_SIZE 10248
//#define MAX_BUFFER_SIZE 20488
uint32_t tx_buffer[MAX_BUFFER_SIZE/4];

static volatile bool msg_done = true;

static void clear_msg(void*, void*) {
  msg_done = true;
}

int main(int argc, char* argv[]){

  // empirically determined:
  struct timeval delay = {1, 0};  
  //struct timeval tau   = {0, 132};
  struct timeval tau   = {0, 264};
  //struct timeval tau   = {0, 2000};
  struct timeval cur, target, start, end;
  double elapsed_time;
  int rc, iparam;
  printf("INFO:  Starting ZMQ loopback demo.\n");
  printf("INFO:  RAND_MAX: 0x%x\n", RAND_MAX);
  printf("INFO:  Creating new ZMQ context...\n");
  void* ctx = zmq_ctx_new();

  printf("INFO:  Initializing REQ socket (A) ...\n");
  req = zmq_socket(ctx, ZMQ_REQ);
  iparam = 100;
  zmq_setsockopt(req, ZMQ_SNDHWM, &iparam, sizeof(iparam));
  iparam = 1000;
  zmq_setsockopt(req, ZMQ_LINGER, &iparam, sizeof(iparam));
  iparam = 1000;
  zmq_setsockopt(req, ZMQ_SNDTIMEO, &iparam, sizeof(iparam));
  zmq_setsockopt(req, ZMQ_RCVTIMEO, &iparam, sizeof(iparam));
  if (zmq_connect(req, SOCKET_A_BINDING_REQ) !=0 ) {
    printf("ERROR:  Failed to bind socket (%s)!\n", SOCKET_A_BINDING_REQ);
    return 1;
  }
  gettimeofday(&cur, NULL);
  timeradd(&cur, &delay, &start);
  timeradd(&start, &tau, &target);

  printf("INFO:  ZQM REQ socket (A) connected successfully...\n");

  int tx_count   = 0;
  int err_words  = 0;
  int tot_words  = 0;
  int N = 10000;

  printf("INFO: benchmarking %d TX/RX\n", N);

  while(tx_count < N){
    zmq_msg_t msg;
    unsigned nreq = (MAX_BUFFER_SIZE-8)/16;

    gettimeofday(&cur, NULL);
    if (timercmp(&cur, &target, <)){
      usleep(10);
      continue;
    }
    cur = target;
    timeradd(&cur, &tau, &target);
    
    //printf("DEBUG: preparing a message with %d requests.\n", nreq);
    tx_buffer[0]=0x3F;
    tx_buffer[1]=((nreq)&0xFFFF)<<16;
    for (int i=0; i<nreq; i++){
      tx_buffer[2+4*i+0]=0x0044 + (((i%40)+1)<<8);
      tx_buffer[2+4*i+1]=0x00;
      tx_buffer[2+4*i+2]=rand();
      tx_buffer[2+4*i+3]=rand();
    }
    
    //printf("DEBUG:  sending a message \n");
    rc = zmq_msg_init_data(&msg, tx_buffer, MAX_BUFFER_SIZE, 0, 0);
    assert(rc==0);
    rc = zmq_msg_send(&msg, req, 0);
    assert(rc!=-1);
    rc = zmq_msg_close(&msg);
    assert(rc==0);

    zmq_msg_t reply;
    zmq_msg_init (&reply);
    rc = zmq_msg_recv (&reply, req, 0);
    //printf("DEBUG: rc:  %d\n", rc);
    //printf("DEBUG:  done sending message \n");
    tx_count = tx_count+1;
  }
  gettimeofday(&end, NULL);
  elapsed_time = 1000.0*(end.tv_sec - start.tv_sec) + (end.tv_usec - start.tv_usec) / 1000.0;
  printf("INFO: tx_count: %d\n", tx_count);
  uint64_t data    = tx_count * (MAX_BUFFER_SIZE-8);
  uint64_t packets = data / 16;
  double mbps = data*1000/(elapsed_time*1024*1024);
  double ppms = packets/elapsed_time;  
  printf("INFO: total bytes:        %lu\n", data);
  printf("INFO: total packets:      %lu\n", packets);
  printf("INFO: elapsed time (ms):  %lf\n", elapsed_time);
  printf("INFO: Mbps:               %lf\n", mbps);
  printf("INFO: packets per ms:     %lf\n", ppms);
  printf("INFO: uart rate (kHz):    %lf\n", ppms/40.);
  return 0;
}
