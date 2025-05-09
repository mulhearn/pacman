#ifndef pacman_vspace_hh
#define pacman_vspace_hh

#include <linux/types.h>
#include <cstdint>

#define PACMAN_VSPACE_MAJOR_VERSION 3
#define PACMAN_VSPACE_MINOR_VERSION 0

int pacman_vspace_write(uint32_t addr, uint32_t value);

uint32_t pacman_vspace_read(uint32_t addr, int * status = NULL);

#endif
