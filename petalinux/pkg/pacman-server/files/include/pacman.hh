#ifndef pacman_hh
#define pacman_hh

#include <cstdint>

uint32_t pacman_set(uint32_t* pl_addr, uint32_t &offset, uint32_t &val);
uint32_t pacman_get(uint32_t* pl_addr, uint32_t &offset);

#endif
