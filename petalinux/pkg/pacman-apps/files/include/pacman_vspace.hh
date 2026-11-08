#ifndef pacman_vspace_hh
#define pacman_vspace_hh

#include <linux/types.h>
#include <cstdint>

#define PACMAN_VSPACE_REG_START 0x00100000
#define PACMAN_VSPACE_I2C_START 0x00200000

int pacman_vspace_write(uint32_t addr, uint32_t value);

uint32_t pacman_vspace_read(uint32_t addr, int * status = NULL);


#endif
