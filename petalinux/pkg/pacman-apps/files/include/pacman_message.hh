#pragma once
#include <stdint.h>
#include <assert.h>
#include <cstring>

#define MSG_VERSION_MAJOR 1
#define MSG_VERSION_MINOR 0

#define WORD_BYTES 24
#define HEADER_BYTES 24
#define MAX_WORDS 16000  // configurable, matches dataserver/publisher max

// -----------------------------
// Header struct (24 bytes)
// -----------------------------
#define MSG_TYPE_REQ  '?'
#define MSG_TYPE_REP  '!'
#define MSG_TYPE_DATA 'D'
#define MSG_TYPE_STRING 'S'

typedef struct {
  uint8_t  msg_type;      // 0
  uint8_t  pacman;        // 1
  uint8_t  version_major; // 2
  uint8_t  version_minor; // 3
  uint32_t n_bytes;       // 4–7
  uint32_t timestamp_lo;  // 8–11
  uint32_t timestamp_hi;  // 12–15
  uint32_t _pad[2];       // 16–23
} pacman_header_t;

static_assert(sizeof(pacman_header_t) == HEADER_BYTES, "Header must be 24 bytes");

// -----------------------------
// Word structs
// -----------------------------
#define WORD_TYPE_PING   'P'
#define WORD_TYPE_READ   'R'
#define WORD_TYPE_WRITE  'W'
#define WORD_TYPE_DATA   'D'
#define WORD_TYPE_CFG    'C'
#define WORD_TYPE_SYNC   'S'
#define WORD_TYPE_TRIG   'T'
#define WORD_TYPE_ERR    'E'

typedef struct { uint8_t word_type; uint8_t pacman; uint8_t _pad[22]; } pacman_word_ping_t;
typedef struct { uint8_t word_type; uint8_t pacman; uint8_t _pad[6]; uint32_t addr; uint32_t value; uint8_t _pad2[8]; } pacman_word_read_t;
typedef struct { uint8_t word_type; uint8_t pacman; uint8_t _pad[6]; uint32_t addr; uint32_t value; uint8_t _pad2[8]; } pacman_word_write_t;
typedef struct { uint8_t word_type; uint8_t pacman; uint16_t chan; uint8_t _pad[4];
  uint32_t timestamp_lo; uint32_t timestamp_hi; uint32_t payload_lo; uint32_t payload_hi;} pacman_word_data_t;
typedef struct { uint8_t word_type; uint8_t pacman; uint8_t sync_type; uint8_t clk_src; uint8_t _pad[4];
  uint32_t timestamp_lo; uint32_t timestamp_hi; uint32_t status; uint8_t _pad2[4]; } pacman_word_sync_t;
typedef struct { uint8_t word_type; uint8_t pacman; uint8_t trig_type; uint8_t trig_src; uint8_t _pad[4];
  uint32_t timestamp_lo; uint32_t timestamp_hi; uint8_t _pad2[8]; } pacman_word_trig_t;
typedef struct { uint8_t word_type; uint8_t pacman; uint8_t _pad[6];
  uint32_t timestamp_lo; uint32_t timestamp_hi; uint32_t error_code; uint8_t _pad2[4]; } pacman_word_err_t;

static_assert(sizeof(pacman_word_ping_t)  == WORD_BYTES, "PING word must be 24 bytes");
static_assert(sizeof(pacman_word_read_t)  == WORD_BYTES, "READ word must be 24 bytes");
static_assert(sizeof(pacman_word_write_t) == WORD_BYTES, "WRITE word must be 24 bytes");
static_assert(sizeof(pacman_word_data_t)  == WORD_BYTES, "DATA word must be 24 bytes");
static_assert(sizeof(pacman_word_sync_t)  == WORD_BYTES, "SYNC word must be 24 bytes");
static_assert(sizeof(pacman_word_trig_t)  == WORD_BYTES, "TRIG word must be 24 bytes");
static_assert(sizeof(pacman_word_err_t)   == WORD_BYTES, "ERR word must be 24 bytes");

// -----------------------------
// Word union for in-place access
// -----------------------------
typedef union {
  pacman_word_ping_t  ping;
  pacman_word_read_t  read;
  pacman_word_write_t write;
  pacman_word_data_t  data;
  pacman_word_sync_t  sync;
  pacman_word_trig_t  trig;
  pacman_word_err_t   err;
  uint8_t raw[WORD_BYTES]; // raw byte access
} pacman_word_t;

static_assert(sizeof(pacman_word_t) == WORD_BYTES, "PACMAN word must be 24 bytes");


// -----------------------------
// 64-bit -> two 32-bit helpers:
// -----------------------------

static inline uint32_t upper_32(uint64_t word){
  return (uint32_t) (word>>32);
}

static inline uint32_t lower_32(uint64_t word){
  return (uint32_t) (word);
}

// -----------------------------
// Full message struct with preallocated buffer
// -----------------------------
typedef struct {
    pacman_header_t header;
    union {
      pacman_word_t words[MAX_WORDS];          // word access
      uint8_t       raw[MAX_WORDS * WORD_BYTES]; // alternate raw byte access
    };
} pacman_msg_t;

static_assert(sizeof(pacman_msg_t) == HEADER_BYTES + MAX_WORDS * WORD_BYTES, "PACMAN message total size");

static inline uint32_t total_message_size(const pacman_msg_t * msg){
  return HEADER_BYTES + msg->header.n_bytes;
}

// helpers to populate words in-place



inline void write_header_req(pacman_header_t* h, uint16_t n_bytes = 0, uint32_t timestamp_hi = 0, uint32_t timestamp_lo = 0, uint8_t pacman = 0) {
    memset(h, 0, sizeof(*h));
    h->msg_type      = MSG_TYPE_REQ;
    h->pacman        = pacman;
    h->version_major = MSG_VERSION_MAJOR;
    h->version_minor = MSG_VERSION_MINOR;
    h->n_bytes       = n_bytes;
    h->timestamp_lo  = timestamp_lo;
    h->timestamp_hi  = timestamp_hi;
}

inline void write_header_rep(pacman_header_t* h, uint16_t n_bytes = 0, uint32_t timestamp_hi = 0, uint32_t timestamp_lo = 0, uint8_t pacman = 0) {
    memset(h, 0, sizeof(*h));
    h->msg_type      = MSG_TYPE_REP;
    h->pacman        = pacman;
    h->version_major = MSG_VERSION_MAJOR;
    h->version_minor = MSG_VERSION_MINOR;
    h->n_bytes       = n_bytes;
    h->timestamp_lo  = timestamp_lo;
    h->timestamp_hi  = timestamp_hi;
}

inline void write_header_data(pacman_header_t* h, uint16_t n_bytes = 0, uint32_t timestamp_hi = 0, uint32_t timestamp_lo = 0, uint8_t pacman = 0) {
    memset(h, 0, sizeof(*h));
    h->msg_type      = MSG_TYPE_DATA;
    h->pacman        = pacman;
    h->version_major = MSG_VERSION_MAJOR;
    h->version_minor = MSG_VERSION_MINOR;
    h->n_bytes       = n_bytes;
    h->timestamp_lo  = timestamp_lo;
    h->timestamp_hi  = timestamp_hi;

}

// helpers to populate words in-place

inline void write_word_ping(pacman_word_t* w,  uint8_t pacman=0) {
    memset(w, 0, sizeof(*w));
    w->ping.word_type = WORD_TYPE_PING;
    w->ping.pacman    = pacman;
}

inline void write_word_read(pacman_word_t* w, uint8_t pacman, uint32_t addr, uint32_t value=0) {
    memset(w, 0, sizeof(*w));
    w->read.word_type = 'R';
    w->read.pacman    = pacman;
    w->read.addr      = addr;
    w->read.value     = value;
}

inline void write_word_write(pacman_word_t* w, uint8_t pacman, uint32_t addr, uint32_t value) {
    memset(w, 0, sizeof(*w));
    w->write.word_type = 'W';
    w->write.pacman    = pacman;
    w->write.addr      = addr;
    w->write.value     = value;
}

inline void write_word_data(pacman_word_t* w, uint8_t pacman, uint16_t chan,
			    uint32_t timestamp_hi, uint32_t timestamp_lo, uint32_t payload_hi, uint32_t payload_lo) {
    memset(w, 0, sizeof(*w));
    w->data.word_type = 'D';
    w->data.pacman    = pacman;
    w->data.chan      = chan;
    w->data.timestamp_lo = timestamp_lo;
    w->data.timestamp_hi = timestamp_hi;
    w->data.payload_lo   = payload_lo;
    w->data.payload_hi   = payload_hi;
}

inline void write_word_sync(pacman_word_t* w, uint8_t pacman, uint8_t sync_type, uint8_t clk_src, uint32_t timestamp_hi, uint32_t timestamp_lo, uint8_t status) {
    memset(w, 0, sizeof(*w));
    w->sync.word_type = 'S';
    w->sync.pacman    = pacman;
    w->sync.sync_type = sync_type;
    w->sync.clk_src   = clk_src;
    w->sync.timestamp_lo = timestamp_lo;
    w->sync.timestamp_hi = timestamp_hi;
    w->sync.status    = status;
}

inline void write_word_trig(pacman_word_t* w, uint8_t pacman, uint8_t trig_type, uint8_t trig_src, uint32_t timestamp_hi, uint32_t timestamp_lo) {
    memset(w, 0, sizeof(*w));
    w->trig.word_type = 'T';
    w->trig.pacman    = pacman;
    w->trig.trig_type = trig_type;
    w->trig.trig_src  = trig_src;
    w->trig.timestamp_lo = timestamp_lo;
    w->trig.timestamp_hi = timestamp_hi;

}

inline void write_word_err(pacman_word_t* w, uint8_t pacman, uint32_t timestamp_hi, uint32_t timestamp_lo, uint32_t error_code) {
    memset(w, 0, sizeof(*w));
    w->err.word_type  = 'E';
    w->err.pacman     = pacman;
    w->err.timestamp_lo = timestamp_lo;
    w->err.timestamp_hi = timestamp_hi;
    w->err.error_code = error_code;
}

bool check_msg(const pacman_msg_t* msg);

void print_msg(const pacman_msg_t* msg, const char * prefix = "");

// -----------------------------
// Helper macros to access words
// -----------------------------
//#define PACMAN_WORD(msg, idx) ((msg)->words[(idx)])


// check if a message is a string
inline bool is_string_msg(const pacman_msg_t* msg) {
    return msg->header.msg_type == MSG_TYPE_STRING;
}


// pack a variable-length string
inline void pack_string_msg(pacman_msg_t* msg, const char* str, uint32_t len, uint32_t timestamp_hi=0, uint32_t timestamp_lo=0, uint8_t pacman=0) {
    memset(&msg->header, 0, sizeof(msg->header));
    msg->header.msg_type      = MSG_TYPE_STRING;
    msg->header.pacman        = pacman;
    msg->header.version_major = MSG_VERSION_MAJOR;
    msg->header.version_minor = MSG_VERSION_MINOR;
    msg->header.n_bytes       = len;
    msg->header.timestamp_lo  = timestamp_lo;
    msg->header.timestamp_hi  = timestamp_hi;
    memcpy(msg->raw, str, len);  // raw access aligns with Python
}

// unpack a string from a message
inline void unpack_string_msg(const pacman_msg_t* msg, char* out, uint32_t max_len) {
    uint32_t n = msg->header.n_bytes;
    if (n > max_len) n = max_len;
    memcpy(out, msg->raw, n);
    out[n] = '\0';
}


