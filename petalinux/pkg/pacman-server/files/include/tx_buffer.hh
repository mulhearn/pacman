#ifndef TX_BUFFER_HH
#define TX_BUFFER_HH

#include <stdint.h>

#define TX_BUFFER_BROADCAST 255
#define TX_BUFFER_CHAN      40
#define TX_BUFFER_DEPTH     1024
// number of 32 bit words in tx buffer output
#define TX_BUFFER_BYTES     336

void tx_buffer_init(int verbose=0);

void tx_buffer_status();

unsigned tx_buffer_in(unsigned char chan, uint32_t * tx_data);

unsigned tx_buffer_out(uint32_t * dst);

void tx_buffer_print_output(uint32_t * src);

unsigned tx_buffer_count(unsigned char chan);

#endif
