#ifndef CHAN_MAP_HH
#define CHAN_MAP_HH

#include <stdint.h>

void  print_chan_map();

int  chan_map_tx(int chan);

void chan_map_rx(uint32_t * buf);

#endif
