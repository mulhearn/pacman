#include <stdio.h>
#include "tx_buffer.hh"
#include "chan_map.hh"

uint32_t G_TX_BUFFER_DATA[TX_BUFFER_CHAN][2*TX_BUFFER_DEPTH];
unsigned G_TX_BUFFER_HEAD[TX_BUFFER_CHAN];
unsigned G_TX_BUFFER_TAIL[TX_BUFFER_CHAN];

void tx_buffer_init(int verbose){
  for (int i=0; i<TX_BUFFER_CHAN; i++){
    G_TX_BUFFER_HEAD[i] = 0;
    G_TX_BUFFER_TAIL[i] = 0;
    for (int j=0; j<TX_BUFFER_DEPTH; j++){
      G_TX_BUFFER_DATA[i][2*j+0] = 0;
      G_TX_BUFFER_DATA[i][2*j+1] = 0;
    }
  }
  if (verbose) {
    printf("INFO:  tx_buffer_init:\n");
    printf("INFO:  channels:      %d\n", TX_BUFFER_CHAN);
    printf("INFO:  depth:         %d\n", TX_BUFFER_DEPTH);
    printf("INFO:  output bytes:  %d\n", TX_BUFFER_BYTES);
  }
}

void tx_buffer_status(){
  for (int i=0; i<TX_BUFFER_CHAN; i++){
    unsigned count = tx_buffer_count(i);
    unsigned head  = G_TX_BUFFER_HEAD[i];
    unsigned tail  = G_TX_BUFFER_TAIL[i];
    if ((count==0)&&(head==0)&&(tail==0))
      continue;
    printf("chan %3d %d  --- %d %d\n", i, count, head, tail);
  }
}

void tx_buffer_print_output(uint32_t * src){
  printf("channel mask:  0x%08x %08x\n", src[1], src[0]);
  printf("always zero:   0x%08x %08x\n", src[3], src[2]);
  for (int i=0; i<TX_BUFFER_CHAN; i++){
    if (((src[i/32]>>(i%32))&1)==1) {
      printf("chan: %3d tx_data: 0x%08x %08x\n", i, src[4+2*i+1], src[4+2*i+0]);
    }
  }
}

unsigned tx_buffer_count(unsigned char chan){
  if (chan > TX_BUFFER_CHAN)
    return 0;
  unsigned head = G_TX_BUFFER_HEAD[chan];
  unsigned tail = G_TX_BUFFER_TAIL[chan];

  return (TX_BUFFER_DEPTH + head - tail) % TX_BUFFER_DEPTH;  
}

unsigned tx_buffer_in(unsigned char chan, uint32_t * tx_data){
  // apply channel mapping:
  chan = chan_map_tx(chan);
  if (chan < 0)
    return 0;
  
  // ignoring broadcast for now
  if (chan > TX_BUFFER_CHAN)
    return 0;
  unsigned head = G_TX_BUFFER_HEAD[chan];

  if (((head+1) % TX_BUFFER_DEPTH) == G_TX_BUFFER_TAIL[chan])
    return 0;
  G_TX_BUFFER_DATA[chan][2*head+0] = tx_data[0];
  G_TX_BUFFER_DATA[chan][2*head+1] = tx_data[1];
  G_TX_BUFFER_HEAD[chan] = (head + 1) % TX_BUFFER_DEPTH; 
  return 1;
}

unsigned tx_buffer_out(uint32_t * out){
  uint32_t mask[2] = {0,0};
  uint32_t one     = 1;

  //printf("DEBUG:  mask before loop:  %lx\n", mask);
  for (unsigned i=0; i<TX_BUFFER_CHAN; i++){
    if (tx_buffer_count(i) > 0)
      mask[i/32] |= (one << i%32);
  }
  //printf("DEBUG:  mask after:  %lx\n", mask);  
  if ((mask[0]==0) && (mask[1]==0))
    return 0;
  
  out[0] = mask[0];
  out[1] = mask[1];
  out[2] = 0;
  out[3] = 0;
  
  for (int i=0; i<TX_BUFFER_CHAN; i++){
    if ((mask[i/32]>>(i%32))&1==1) {
      unsigned tail = G_TX_BUFFER_TAIL[i];
      out[4+2*i+0] = G_TX_BUFFER_DATA[i][2*tail+0];
      out[4+2*i+1] = G_TX_BUFFER_DATA[i][2*tail+1];
      G_TX_BUFFER_TAIL[i] = (tail+1) % TX_BUFFER_DEPTH;
    } else {
      out[4+2*i+0] = 0;
      out[4+2*i+1] = 0;
    }
  }
  return 1;
}
