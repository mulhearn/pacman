#include <stdio.h>
#include "rx_buffer.hh"

#define RX_BUFFER_WORDS RX_BUFFER_BYTES/4

static uint32_t G_DATA[RX_BUFFER_DEPTH][RX_BUFFER_WORDS];
static unsigned G_HEAD;
static unsigned G_TAIL;
static unsigned G_LOST;
static unsigned G_MAX;

void rx_buffer_init(int verbose){
  G_HEAD = 0;
  G_TAIL = 0;
  G_LOST = 0;
  G_MAX = 0;
  if (verbose) {
    printf("INFO:  rx_buffer_init:\n");
    printf("INFO:  depth:         %d\n", RX_BUFFER_DEPTH);
    printf("INFO:  output bytes:  %d\n", RX_BUFFER_BYTES);
  }
}

void rx_buffer_status(){
  unsigned count = rx_buffer_count();
  unsigned head  = G_HEAD;
  unsigned tail  = G_TAIL;
  unsigned lost  = rx_buffer_lost();
  unsigned max   = rx_buffer_max();
  printf("rx_buffer count: %u  head %u tail %u lost %u max %u \n", count, head, tail, lost, max);
}

void rx_buffer_print_output(uint32_t * src){
  printf("rx:  0x");
  for (int i=0; i<RX_BUFFER_WORDS; i++){
    printf("%08x", src[RX_BUFFER_WORDS-i-1]);
  }
  printf("\n");
}

unsigned rx_buffer_count(){
  unsigned head = G_HEAD;
  unsigned tail = G_TAIL;
  return (RX_BUFFER_DEPTH + head - tail) % RX_BUFFER_DEPTH;
}

unsigned rx_buffer_lost(){
  return G_LOST;
}

unsigned rx_buffer_max(){
  return G_MAX;
}

unsigned rx_buffer_in(uint32_t * src){
  unsigned head = G_HEAD;

  if (((head+1) % RX_BUFFER_DEPTH) == G_TAIL){
    G_LOST++;
    return 0;
  }

  for (int i=0; i<RX_BUFFER_WORDS; i++){
    G_DATA[head][i] = src[i];
  }

  G_HEAD = (head + 1) % RX_BUFFER_DEPTH;

  unsigned count = rx_buffer_count();
  if (count > G_MAX)
    G_MAX = count;

  return 1;
}

unsigned rx_buffer_out(uint32_t * dst){
  if (rx_buffer_count() == 0)
    return 0;

  unsigned tail = G_TAIL;

  for (int i=0; i<RX_BUFFER_WORDS; i++){
    dst[i] = G_DATA[tail][i];
  }
  G_TAIL = (tail+1) % RX_BUFFER_DEPTH;
  return 1;
}
