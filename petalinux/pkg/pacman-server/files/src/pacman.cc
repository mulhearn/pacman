#ifndef pacman_cc
#define pacman_cc

#include <cstdint>

#include "pacman.hh"

uint32_t pacman_set(uint32_t* pl_addr, uint32_t &offset, uint32_t &value) {
  pl_addr[offset >> 2] = value;
}

uint32_t pacman_get(uint32_t* pl_addr, uint32_t &offset) {
  return pl_addr[offset >> 2];
}

#endif
