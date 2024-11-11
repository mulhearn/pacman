#include <stdio.h>
#include "rx_buffer.hh"

#define RX_BUFFER_WORDS RX_BUFFER_BYTES/4

uint32_t G_RX_BUFFER_DATA[RX_BUFFER_DEPTH][RX_BUFFER_WORDS];
unsigned G_RX_BUFFER_HEAD;
unsigned G_RX_BUFFER_TAIL;
unsigned G_RX_LOST;

void rx_buffer_init(int verbose){
  G_RX_BUFFER_HEAD = 0;
  G_RX_BUFFER_TAIL = 0;
  G_RX_LOST = 0;
  if (verbose) {
    printf("INFO:  rx_buffer_init:\n");
    printf("INFO:  depth:         %d\n", RX_BUFFER_DEPTH);
    printf("INFO:  output bytes:  %d\n", RX_BUFFER_BYTES);
  }
}

void rx_buffer_status(){
  unsigned count = rx_buffer_count();
  unsigned head  = G_RX_BUFFER_HEAD;
  unsigned tail  = G_RX_BUFFER_TAIL;
  unsigned lost  = rx_buffer_lost();
  printf("rx_buffer count: %d  head %d tail %d lost %d \n", count, head, lost);
}

void rx_buffer_print_output(uint32_t * src){
  printf("rx:  0x");
  for (int i=0; i<RX_BUFFER_WORDS; i++){
    printf("%08x", src[RX_BUFFER_WORDS-i-1]);
  }
  printf("\n");
}

unsigned rx_buffer_count(){
  unsigned head = G_RX_BUFFER_HEAD;
  unsigned tail = G_RX_BUFFER_TAIL;
  return (RX_BUFFER_DEPTH + head - tail) % RX_BUFFER_DEPTH;
}

unsigned rx_buffer_lost(){
  return G_RX_LOST;
}

unsigned rx_buffer_in(uint32_t * src){
  unsigned head = G_RX_BUFFER_HEAD;
  if (((head+1) % RX_BUFFER_DEPTH) == G_RX_BUFFER_TAIL){
    G_RX_LOST++;
    return 0;
  }

  for (int i=0; i<RX_BUFFER_WORDS; i++){
    G_RX_BUFFER_DATA[head][i] = src[i];
  }

  G_RX_BUFFER_HEAD = (head + 1) % RX_BUFFER_DEPTH;
  return 1;
}

unsigned rx_buffer_out(uint32_t * dst){
  if (rx_buffer_count() == 0)
    return 0;

  unsigned tail = G_RX_BUFFER_TAIL;

  for (int i=0; i<RX_BUFFER_WORDS; i++){
    dst[i] = G_RX_BUFFER_DATA[tail][i];
  }
  G_RX_BUFFER_TAIL = (tail+1) % RX_BUFFER_DEPTH;
  return 1;
}
