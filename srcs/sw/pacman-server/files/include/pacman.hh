#ifndef pacman_hh
#define pacman_hh

#include <cstdint>

#define PACMAN_CTRL_REG   0x0000
#define PACMAN_CYCLES_REG 0x0004

uint32_t pacman_set(uint32_t* pl_addr, uint32_t &offset, uint32_t &val);
uint32_t pacman_get(uint32_t* pl_addr, uint32_t &offset);

#endif
