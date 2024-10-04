#ifndef MESSAGE_FORMAT_HH
#define MESSAGE_FORMAT_HH

#include <cstdint>

/* ~~~ ZMQ messaging format ~~~ */
#define VERSION 0x00

#define HEADER_LEN 8 // bytes
#define WORD_LEN   16 // bytes

#define MSG_TYPE_DATA 0x44 // D
#define MSG_TYPE_REQ  0x3F // ?
#define MSG_TYPE_REP  0x21 // !
/* data words*/
#define WORD_TYPE_DATA 0x44 // D
#define WORD_TYPE_TRIG 0x54 // T
#define WORD_TYPE_SYNC 0x53 // S
/* cmd words */
#define WORD_TYPE_PING  0x50 // P
#define WORD_TYPE_WRITE 0x57 // W
#define WORD_TYPE_READ  0x52 // R
#define WORD_TYPE_TX    WORD_TYPE_DATA
/* response words */
#define WORD_TYPE_PONG_REP  WORD_TYPE_PING
#define	WORD_TYPE_WRITE_REP WORD_TYPE_WRITE
#define	WORD_TYPE_READ_REP  WORD_TYPE_READ
#define	WORD_TYPE_TX_REP    WORD_TYPE_TX
#define WORD_TYPE_ERR       0x45 // E

void      print_msg(char* msg);
uint32_t  get_msg_bytes(const uint16_t &msg_words);
uint32_t  init_msg(char* msg, const uint16_t &msg_words, const char &msg_type);
char*     get_msg_type(char* msg);
uint16_t* get_msg_words(char* msg);
uint32_t  get_msg_bytes(char* msg);
char*     get_word(char* msg, const uint16_t &offset);
char*     get_word_type(char* word);

const uint32_t set_data_word_data(char* word, char* io_channel, uint32_t* ts_pacman, uint64_t* data);
const uint32_t set_data_word_trig(char* word, uint32_t* trig_type,  uint32_t* ts_pacman);
const uint32_t set_data_word_sync(char* word, char* sync_type, char* sync_src, uint32_t* ts_pacman);

uint32_t* get_req_word_write_reg(char* word);
uint32_t* get_req_word_write_val(char* word);
uint32_t* get_req_word_read_reg(char* word);
char*     get_req_word_tx_channel(char* word);
uint64_t* get_req_word_tx_data(char* word);

const uint32_t set_rep_word_pong(char* word);
const uint32_t set_rep_word_write(char* word, uint32_t* reg, uint32_t* val);
const uint32_t set_rep_word_read(char* word, uint32_t* reg, uint32_t* val);
const uint32_t set_rep_word_tx(char* word, char* io_channel, uint64_t* data);
const uint32_t set_rep_word_err(char* word, char* err_type, char* err_desc);

#endif
