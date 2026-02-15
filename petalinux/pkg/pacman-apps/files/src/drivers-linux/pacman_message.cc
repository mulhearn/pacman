#include <cstdio>
#include "pacman_message.hh"
#include <inttypes.h>

// -----------------------------
// Allowed sets
// -----------------------------
static const char valid_msg_types[] = {
  MSG_TYPE_REQ, MSG_TYPE_REP, MSG_TYPE_DATA, MSG_TYPE_STRING
};

static const char valid_word_types[] = {
  WORD_TYPE_PING, WORD_TYPE_READ, WORD_TYPE_WRITE, WORD_TYPE_DATA,
  WORD_TYPE_SYNC, WORD_TYPE_TRIG, WORD_TYPE_ERR
};

static bool is_valid_msg_type(char mt) {
    for (char c : valid_msg_types) {
        if (c == mt) return true;
    }
    return false;
}

static bool is_valid_word_type(char wt) {
    for (char c : valid_word_types) {
        if (c == wt) return true;
    }
    return false;
}

// check_msg: validate a message
bool check_msg(const pacman_msg_t* msg) {
    if (!msg) {
        printf("ERROR: msg pointer is NULL\n");
        return false;
    }

    uint16_t n_bytes = msg->header.n_bytes;

    // --- validate header msg_type ---
    char mt = msg->header.msg_type;
    if (not is_valid_msg_type(mt)){
      printf("ERROR: Unknown msg_type '%c' in header\n", mt);
      return false;
    }

    if (mt == MSG_TYPE_STRING) {
      // For strings, no per-word check is needed
      if (n_bytes > MAX_WORDS * WORD_BYTES) {
	printf("ERROR: string length %u exceeds maximum\n", n_bytes);
	return false;
      }
      return true;
    }


    uint16_t n_words = msg->header.n_bytes / WORD_BYTES;
    // Sanity check number of words
    if (n_words > MAX_WORDS) {
        printf("ERROR: n_bytes=%u exceeds MAX_WORDS=%u\n", n_bytes, MAX_WORDS);
        return false;
    }

    // Validate each word
    for (uint16_t i = 0; i < n_words; ++i) {
        const pacman_word_t* word = &msg->words[i];

        char wt = word->raw[0];  // first byte is word_type
        if (!is_valid_word_type(wt)) {
            printf("ERROR: Unknown word_type '%c' at index %u\n", wt, i);
            return false;
        }

        // Optional: add range checks per field if desired
        // e.g., pacman <= 255, addresses within 32-bit range, etc.
    }

    return true;
}

void print_header(const pacman_header_t* header, const char * prefix = "") {
  printf("version %d.%d n_bytes: %d ",header->version_major, header->version_minor, header->n_bytes);
  printf("timestamp:  0x%08x%08x \n", header->timestamp_hi, header->timestamp_lo);
}

void print_word(const pacman_word_t* word, const char * prefix = "") {
  char wt = word->raw[0];  // first byte is word_type

  switch (wt) {
  case WORD_TYPE_PING:
    printf("type: ping  ");
    break;
  case WORD_TYPE_READ:
    printf("type: read  pacman: %03d addr: 0x%04X value: 0x%08X", word->read.pacman, word->read.addr, word->read.value);
    break;
  case WORD_TYPE_WRITE:
    printf("type: write  pacman: %03d addr: 0x%04X value: 0x%08X", word->write.pacman, word->write.addr, word->write.value);
    break;
  case WORD_TYPE_DATA:
    printf("type: data  pacman: %03d chan: %5d payload:  0x%08x%08x timestamp: 0x%08x%08x", word->data.pacman,  word->data.chan,
	   word->data.payload_hi, word->data.payload_lo, word->data.timestamp_hi, word->data.timestamp_lo);
    break;
  case WORD_TYPE_SYNC:
    printf("type: sync  pacman %03d type: %u src: %d timestamp: 0x%08x%08x status: 0x%08x", word->sync.pacman, word->sync.sync_type,
	   word->sync.clk_src, word->sync.timestamp_hi, word->sync.timestamp_lo, word->sync.status);
    break;
  case WORD_TYPE_TRIG:
    printf("type: trig  pacman %03d type: %d src: %d timestamp: 0x%08x%08x", word->trig.pacman, word->trig.trig_type, word->trig.trig_src,
	    word->trig.timestamp_hi, word->trig.timestamp_lo);
    break;
  case WORD_TYPE_ERR:
    printf("type: err   pacman %03d timestamp: 0x%08x%08x error_code: 0x%08x", word->err.pacman,
	   word->err.timestamp_hi, word->err.timestamp_lo, word->err.error_code);
    break;
  default:
    printf("unknown ");
  }
  printf("\n");
}


void print_msg(const pacman_msg_t* msg, const char * prefix) {
  printf("%sheader:  ",prefix);
  print_header(&msg->header);

  if (msg->header.msg_type == MSG_TYPE_STRING) {
    printf("%sstring payload (%u bytes): ", prefix, msg->header.n_bytes);
    fwrite(msg->raw, 1, msg->header.n_bytes, stdout);
    putchar('\n');
    return;
  }

  uint32_t n_words = msg->header.n_bytes / WORD_BYTES;
  for (uint32_t i = 0; i < n_words; ++i) {
    printf("%sword %3u: ", prefix, i);
    print_word(&msg->words[i], prefix);
  }
}
