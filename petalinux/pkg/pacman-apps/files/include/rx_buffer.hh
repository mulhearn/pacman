#ifndef RX_BUFFER_HH
#define RX_BUFFER_HH

#include <stdint.h>

//#define RX_BUFFER_DEPTH     1024
// TODO:  This is likely much bigger than needed with latest firmware, but leaving for now:
#define RX_BUFFER_DEPTH     1048576
// number of bytes in each rx buffer  input/output word
#define RX_BUFFER_BYTES   24

void rx_buffer_init(int verbose=0);

void rx_buffer_status();

unsigned rx_buffer_in(uint32_t * src);

unsigned rx_buffer_out(uint32_t * dst);

void rx_buffer_print_output(uint32_t * src);

unsigned rx_buffer_count();

unsigned rx_buffer_lost();

unsigned rx_buffer_max();

#endif
