#pragma once
#include <stdint.h>
#include <assert.h>
#include <cstring>

#define MSG_VERSION_MAJOR 1
#define MSG_VERSION_MINOR 0

#define WORD_LEN 24
#define HEADER_LEN 24
#define MAX_WORDS 16000  // configurable, matches dataserver/publisher max

// -----------------------------
// Header struct (24 bytes)
// -----------------------------
#define MSG_TYPE_REQ  '?'
#define MSG_TYPE_REP  '!'
#define MSG_TYPE_DATA 'D'

typedef struct {
    uint8_t  msg_type;      // 0
    uint8_t  version_minor; // 1
    uint16_t version_major; // 2–3
    uint32_t n_words;       // 4–7
    uint64_t timestamp;     // 8–15
    uint8_t  _pad[4];       // 16–19 padding to reach 24 bytes
} pacman_header_t;

static_assert(sizeof(pacman_header_t) == HEADER_LEN, "Header must be 24 bytes");

// -----------------------------
// Word structs
// -----------------------------
#define WORD_TYPE_PING   'P'
#define WORD_TYPE_READ   'R'
#define WORD_TYPE_WRITE  'W'
#define WORD_TYPE_DATA   'D'
#define WORD_TYPE_SYNC   'S'
#define WORD_TYPE_TRIG   'T'
#define WORD_TYPE_ERR    'E'

typedef struct { uint8_t word_type; uint8_t _pad[23]; } pacman_word_ping_t;
typedef struct { uint8_t word_type; uint8_t pacman; uint8_t _pad[6]; uint32_t addr; uint32_t value; uint8_t _pad2[8]; } pacman_word_read_t;
typedef struct { uint8_t word_type; uint8_t pacman; uint8_t _pad[6]; uint32_t addr; uint32_t value; uint8_t _pad2[8]; } pacman_word_write_t;
typedef struct { uint8_t word_type; uint8_t chan;   uint8_t upper; uint8_t pacman;  uint8_t _pad[4]; uint64_t timestamp; uint64_t payload; } pacman_word_data_t;
typedef struct { uint8_t word_type; uint8_t pacman; uint8_t sync_type; uint8_t clk_src; uint8_t _pad[4]; uint64_t timestamp; uint32_t status; uint8_t _pad2[4]; } pacman_word_sync_t;
typedef struct { uint8_t word_type; uint8_t pacman; uint8_t trig_type; uint8_t trig_src; uint8_t _pad[4]; uint64_t timestamp; uint8_t _pad2[8]; } pacman_word_trig_t;
typedef struct { uint8_t word_type; uint8_t pacman; uint8_t _pad[6]; uint64_t timestamp; uint32_t error_code; uint8_t _pad2[4]; } pacman_word_err_t;

static_assert(sizeof(pacman_word_ping_t)  == WORD_LEN, "PING word must be 24 bytes");
static_assert(sizeof(pacman_word_read_t)  == WORD_LEN, "READ word must be 24 bytes");
static_assert(sizeof(pacman_word_write_t) == WORD_LEN, "WRITE word must be 24 bytes");
static_assert(sizeof(pacman_word_data_t)  == WORD_LEN, "DATA word must be 24 bytes");
static_assert(sizeof(pacman_word_sync_t)  == WORD_LEN, "SYNC word must be 24 bytes");
static_assert(sizeof(pacman_word_trig_t)  == WORD_LEN, "TRIG word must be 24 bytes");
static_assert(sizeof(pacman_word_err_t)   == WORD_LEN, "ERR word must be 24 bytes");

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
  uint8_t raw[WORD_LEN]; // raw byte access
} pacman_word_t;

static_assert(sizeof(pacman_word_t) == WORD_LEN, "PACMAN word must be 24 bytes");

// -----------------------------
// Full message struct with preallocated buffer
// -----------------------------
typedef struct {
    pacman_header_t header;
    pacman_word_t   words[MAX_WORDS]; // zero-copy, in-place field access
} pacman_msg_t;

static_assert(sizeof(pacman_msg_t) == HEADER_LEN + MAX_WORDS * WORD_LEN, "PACMAN message total size");


// helpers to populate words in-place

inline void write_header_req(pacman_header_t* h, uint16_t n_words = 0, uint64_t timestamp = 0) {
    memset(h, 0, sizeof(*h));
    h->msg_type      = MSG_TYPE_REQ;
    h->version_major = MSG_VERSION_MAJOR;
    h->version_minor = MSG_VERSION_MINOR;
    h->n_words       = n_words;
    h->timestamp     = timestamp;
}

inline void write_header_rep(pacman_header_t* h, uint16_t n_words = 0, uint64_t timestamp = 0) {
    memset(h, 0, sizeof(*h));
    h->msg_type      = MSG_TYPE_REP;
    h->version_major = MSG_VERSION_MAJOR;
    h->version_minor = MSG_VERSION_MINOR;
    h->n_words       = n_words;
    h->timestamp     = timestamp;
}

inline void write_header_data(pacman_header_t* h, uint16_t n_words = 0, uint64_t timestamp = 0) {
    memset(h, 0, sizeof(*h));
    h->msg_type      = MSG_TYPE_DATA;
    h->version_major = MSG_VERSION_MAJOR;
    h->version_minor = MSG_VERSION_MINOR;
    h->n_words       = n_words;
    h->timestamp     = timestamp;
}

// helpers to populate words in-place

inline void write_word_ping(pacman_word_t* w) {
    memset(w, 0, sizeof(*w));
    w->ping.word_type = WORD_TYPE_PING;
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

inline void write_word_data(pacman_word_t* w, uint8_t pacman, uint8_t chan, uint64_t timestamp, uint64_t payload) {
    memset(w, 0, sizeof(*w));
    w->data.word_type = 'D';
    w->data.pacman    = pacman;
    w->data.chan      = chan;
    w->data.timestamp = timestamp;
    w->data.payload   = payload;
}

inline void write_word_sync(pacman_word_t* w, uint8_t pacman, uint8_t sync_type, uint8_t clk_src, uint64_t timestamp, uint8_t status) {
    memset(w, 0, sizeof(*w));
    w->sync.word_type = 'S';
    w->sync.pacman    = pacman;
    w->sync.sync_type = sync_type;
    w->sync.clk_src   = clk_src;
    w->sync.timestamp = timestamp;
    w->sync.status    = status;
}

inline void write_word_trig(pacman_word_t* w, uint8_t pacman, uint8_t trig_type, uint8_t trig_src, uint64_t timestamp) {
    memset(w, 0, sizeof(*w));
    w->trig.word_type = 'T';
    w->trig.pacman    = pacman;
    w->trig.trig_type = trig_type;
    w->trig.trig_src  = trig_src;
    w->trig.timestamp = timestamp;
}

inline void write_word_err(pacman_word_t* w, uint8_t pacman, uint64_t timestamp, uint32_t error_code) {
    memset(w, 0, sizeof(*w));
    w->err.word_type  = 'E';
    w->err.pacman     = pacman;
    w->err.timestamp  = timestamp;
    w->err.error_code = error_code;
}

bool check_msg(const pacman_msg_t* msg);

void print_msg(const pacman_msg_t* msg, const char * prefix = "");

// -----------------------------
// Helper macros to access words
// -----------------------------
//#define PACMAN_WORD(msg, idx) ((msg)->words[(idx)])

