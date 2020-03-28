#ifndef message_format_cc
#define message_format_cc

#include <ctime>
#include <cstring>
#include <cstdint>

#include "message_format.hh"

char* init_msg(uint16_t* msg_words, char &msg_type) {
  // Allocates and clears memory for message and sets header n words
  uint32_t msg_bytes = HEADER_LEN + (*msg_words) * WORD_LEN;
  char* msg = new char[msg_bytes];
  memset(msg, 0, msg_bytes);
  memset(msg, msg_type, 1);
  memset(msg+1, time(NULL), 4);
  memcpy(msg+6, msg_words, 2);
  return msg;
}

void* free_msg(char* msg) {
  // Deallocates memory held for message
  delete[] msg;
  return NULL;
}

char* get_msg_type(char* msg) {
  // Returns ptr to msg type
  return msg;
}

uint16_t* get_msg_words(char* msg) {
  // Returns ptr to msg words
  return (uint16_t*)(msg+6); 
}

char* get_word(char* msg, uint16_t &offset) {
  // Returns ptr to word start
  return msg + HEADER_LEN + offset * WORD_LEN;
}

char* get_word_type(char* word) {
  // Returns ptr to word type
  return word + 0;
}

const uint32_t set_data_word_data(char* word, char* io_channel, uint32_t* ts_pacman, uint64_t* data_larpix) {
  // Write data into specified word position as a larpix data word
  // io_channel : io channel packet arrived on
  // ts_pacman : 32-bit timestamp of packet arrival from pacman PL
  // data_larpix : 64-bit larpix data word
  // returns : word length
  memset(word, WORD_TYPE_DATA, 1);
  memcpy(word, io_channel, 1);
  memcpy(word+4, ts_pacman, 4);
  memcpy(word+8, data_larpix, 8);
  return WORD_LEN;
}

const uint32_t set_data_word_trig(char* word, uint32_t* trig_type,  uint32_t* ts_pacman) {
  // Write data into specified word position as a trigger word
  // trig_type : trigger bits to associate with trigger
  // ts_pacman : 32-bit timestamp of trigger from pacman PL
  // returns : word length
  memset(word, WORD_TYPE_TRIG, 1);
  memcpy(word+1, trig_type, 3);
  memcpy(word+4, ts_pacman, 4);
  return WORD_LEN;
}

const uint32_t set_data_word_sync(char* word, char* sync_type, char* sync_src, uint32_t* ts_pacman) {
  // Write data into specified word position as a sync word
  // sync_type : sync packet type
  // sync_src : internal / external source
  // ts_pacman : 32-bit timestamp of sync from pacman PL
  // returns : word length
  memset(word, WORD_TYPE_SYNC, 1);
  memcpy(word+1, sync_type, 1);
  memcpy(word+2, sync_src, 1);
  memcpy(word+4, (char*)ts_pacman, 4);
  return WORD_LEN;
}

uint32_t* get_req_word_write_reg(char* word) {
  // Parse write request word for register address
  return (uint32_t*)(word+4);
}

uint64_t* get_req_word_write_val(char* word) {
  // Parse write request word for register value
  return (uint64_t*)(word+8);
}

uint32_t* get_req_word_read_reg(char* word) {
  // Parse read request word for register address
  return (uint32_t*)(word+4);
}

char* get_req_word_tx_channel(char* word) {
  // Parse transmit request word for io channel
  return word+1;
}

uint64_t* get_req_word_tx_data(char* word) {
  // Parse transmit request word for data
  return (uint64_t*)(word+8);
}

const uint32_t set_rep_word_write(char* word, uint32_t* reg, uint64_t* val) {
  // Write data in specified word position as successful write
  // reg : register address
  // val : register value
  // returns : word length
  memcpy(word+4, reg, 4);
  memcpy(word+8, val, 8);
  return WORD_LEN;
}

const uint32_t set_rep_word_read(char* word, uint32_t* reg, uint64_t* val) {
  // Write data in specified word position as successful read
  // reg : register address
  // val : register value
  // returns : word length
  memcpy(word+4, reg, 4);
  memcpy(word+8, val, 8);
  return WORD_LEN;
}

const uint32_t set_rep_word_tx(char* word, char* io_channel, uint64_t* data) {
  // Write data in specified word position as successful transmit
  // io_channel : io channel to send data on
  // data : 64-bit larpix packet to send
  // returns : word length
  memcpy(word+1, io_channel, 1);
  memcpy(word+8, data, 8);
  return WORD_LEN;
}

const uint32_t set_rep_word_err(char* word, char* err_type, char* err_desc) {
  // Write data in specified word position as an error
  // err_type : type of error
  // err_desc : info to associate with error
  // return : word length
  memcpy(word+1, err_type, 1);
  memcpy(word+2, err_desc, 14);
  return WORD_LEN;
}

#endif
