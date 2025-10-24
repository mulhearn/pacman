#ifndef pacman_highlevel_interface_hh
#define pacman_highlevel_interface_hh


// Handler for high-level commands:
// - req_str / req_len: the incoming string
// - rep_buf: pointer to buffer to write reply into (preallocated by caller)
// - max_len: maximum number of bytes that can be safely written into rep_buf
// Returns: number of bytes written into rep_buf
size_t pacman_highlevel_command(const char* req_str, size_t req_len, char* rep_buf, size_t max_len);

uint8_t get_pacman_id();

#endif
