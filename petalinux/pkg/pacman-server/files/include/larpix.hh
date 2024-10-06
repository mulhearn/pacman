#ifndef larpix_hh
#define larpix_hh

// This is the size of the LARPIX data word (64 bits):
#define LARPIX_DATA_LEN 8  // bytes  (= 64 bits)
// Each word in a message is twice the size of the LARPIX data word,
// so that it can contain a data word plus additional information (data type, channel, timestampe)
#define LARPIX_WIDE_LEN 16 // bytes   (=128 bits)

#define WORD_TYPE_OFFSET 0 // bytes
#define IO_CHANNEL_OFFSET 1 // bytes
#define TS_PACMAN_OFFSET 4 // bytes
#define LARPIX_DATA_OFFSET 8 // bytes

#endif
