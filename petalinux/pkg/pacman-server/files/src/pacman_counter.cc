#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <zmq.h>
#include <cstring>
#include <cassert>
#include <sys/time.h>

#define SOCKET_B_BINDING_SUB "tcp://localhost:5556"

static void * ctx = NULL;
static void * sub = NULL;

#define MAX_CHANNEL 40

//#define MAX_BUFFER_SIZE 1024
//#define MAX_BUFFER_SIZE 16384

// BUFFER SIZE:  8 + N * 16
#define MAX_BUFFER_SIZE 10248
uint32_t rx_buffer[MAX_BUFFER_SIZE/4];

int main(int argc, char* argv[]){
  uint32_t packets[MAX_CHANNEL];
  for (int i=0; i<MAX_CHANNEL; i++){
    packets[i]=0;
  }

  struct timeval start, end;
  double elapsed_time;
  int rc, iparam;
  printf("INFO:  Starting ZMQ loopback demo.\n");
  printf("INFO:  RAND_MAX: 0x%x\n", RAND_MAX);
  printf("INFO:  Creating new ZMQ context...\n");
  void* ctx = zmq_ctx_new();

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

  //printf("INFO: benchmarking %d TX/RX\n", N);
  gettimeofday(&start, NULL);

  while(1){
    zmq_msg_t msg;
    zmq_msg_init(&msg);
    rc = zmq_msg_recv(&msg, sub, 0);
    int size = zmq_msg_size(&msg);
    if (size <= 0){
      zmq_msg_close(&msg);
      //printf("DEBUG:  no message received \n");
      continue;
    }
    if (size > MAX_BUFFER_SIZE){
      printf("ERROR:  unexpectedly large message... discarding\n");
      continue;
    }
    memcpy(rx_buffer,zmq_msg_data(&msg), size);
    zmq_msg_close(&msg);

    //printf("DEBUG:  received message of size %d bytes \n", size);
    //printf("DEBUG:  header:  0x%x 0x%x\n", rx_buffer[0], rx_buffer[1]);
    uint32_t mtype = rx_buffer[0]&0xFF;
    uint32_t npkts = (rx_buffer[1]>>16)&0xFFFF;
    //printf("DEBUG:  type:  0x%x pkts:  0x%x (%d)\n", mtype, npkts, npkts);
    if (mtype != 0x44){
      printf("ERROR:  message type is not 0x44 (0x%x)... discarding\n", mtype);
      continue;
    }
    if (size != (npkts*16+8)){
      printf("ERROR:  message size (%d) does not match packets in header (%d)\n", size, npkts);
      continue;      
    }
    //printf("DEBUG:  received valid message\n");
    for (int i=0; i<npkts; i++){
      uint32_t wtype =  rx_buffer[2+4*i]&0xFF;
      uint32_t chan  = (rx_buffer[2+4*i]>>8)&0xFF;      
      //printf("DEBUG:  packet %d wtype:  0x%x  chan:  %d \n", i, wtype, chan);

      if (wtype == 0x44){      
	if ((chan == 0) || (chan > 40)){
	  printf("ERROR:  invalid channel detected:  %d\n", chan);
	  continue;
	}
	packets[chan-1]++;
      } else {
	printf("INFO:  packet: 0x %08x %08x %08x %08x\n",
	       rx_buffer[2+4*i+3], rx_buffer[2+4*i+2],
	       rx_buffer[2+4*i+1], rx_buffer[2+4*i+0]);
      }
    }
    printf("INFO:  received packet counts per channel:\n");
    for (int i=0; i<MAX_CHANNEL; i++){
      printf("%8d ", packets[i]);
      if (((i+1)%8)==0)
	printf("\n");
    }
  }
  //gettimeofday(&end, NULL);
  //elapsed_time = 1000.0*(end.tv_sec - start.tv_sec) + (end.tv_usec - start.tv_usec) / 1000.0;
  //printf("INFO: rx_count: %d\n", rx_count);
  //printf("INFO: time (ms): %lf\n", elapsed_time);
  //printf("INFO: total words: %d  errors: %d\n", tot_words, err_words);
  //uint64_t data = rx_count * MAX_BUFFER_SIZE;
  //double mbts = data*1000/(elapsed_time*1024*1024);
  //printf("INFO: bytes:     %lu\n", data);  
  //printf("INFO: mbts:      %lf\n", mbts);
  return 0;
}
