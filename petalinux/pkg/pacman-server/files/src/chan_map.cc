#include <stdio.h>

#include "chan_map.hh"

#define MAX_CHAN 40

void print_chan_map(){
  unsigned rows = MAX_CHAN/4;
  
  for (int i=0; i<rows; i++){
    for (int j=0; j<4; j++){
      unsigned chan = j*rows+i;
      printf("%3d --> %d  ", chan, chan_map_tx(chan));
    }
    printf("\n");
  }
}

int chan_map_tx(int chan){
  if ((chan < 8) || (chan >= MAX_CHAN))
    return chan;

  unsigned tile = chan / 4;
  unsigned uart = chan % 4;
  
  if (uart==3)
    return -1;

  int new_chan = 8+3*(tile-2)+uart;
  return new_chan;
  
  
  return chan;  
}

void chan_map_rx(uint32_t * buf){
  unsigned chan = (buf[0]>>8)&0xFF;
  unsigned nchan = chan;
  if (chan>8){
    unsigned toff = (chan-8)/3;
    unsigned uart = (chan-8)%3;
    nchan = 8 + 4*toff + uart;
  }
  buf[0] &= 0xFFFF00FF;
  buf[0] |= ((nchan&0xFF)<<8);
}

