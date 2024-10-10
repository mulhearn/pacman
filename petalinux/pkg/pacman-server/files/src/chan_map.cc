#include <stdio.h>

#include "chan_map.hh"
#include "message_format.hh"

#define MAX_CHAN 40

void print_chan_map(){
  unsigned rows = MAX_CHAN/4;
  
  for (int i=0; i<rows; i++){
    for (int j=0; j<4; j++){
      unsigned chan = j*rows+i;
      int mchan = chan_map_tx(chan);
      if (mchan>=0){
	printf("%3d --> %3d ", chan+1, chan_map_tx(chan)+1);
      } else {
	printf("%3d -->  -- ", chan+1);
      }
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
  if ( buf[0]&0xFF != WORD_TYPE_DATA)
    return;

  unsigned chan = (buf[0]>>8)&0xFF;
  // legacy firmware starts at "1":
  chan = chan - 1;

  if ((chan<8) || (chan >= MAX_CHAN)){
    return;
  }
  
  unsigned nchan = chan;
  unsigned toff = (chan-8)/3;
  unsigned uart = (chan-8)%3;
  nchan = 8 + 4*toff + uart;

  // legacy firmware starts at "1":
  nchan = nchan + 1;
  
  buf[0] &= 0xFFFF00FF;
  buf[0] |= ((nchan&0xFF)<<8);
}

