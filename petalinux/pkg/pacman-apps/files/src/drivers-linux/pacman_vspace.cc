#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>

#include "pacman_vspace.hh"
#include "addr_conf.hh"
#include "pacman.hh"
#include "pacman_i2c.hh"

#define PACMAN_SERVER_I2C_START     0x00024000

int pacman_vspace_write(uint32_t addr, uint32_t value){

  if (addr >= PACMAN_SERVER_I2C_START) {
    unsigned off = addr - PACMAN_AXIL_ADDR;
    return i2c_write(off, value);
  }

  return pacman_write(addr, value);

  return EXIT_FAILURE;
}

uint32_t pacman_vspace_read(uint32_t addr, int * status){
  if (status)
    *status = EXIT_SUCCESS;

  if (addr >= PACMAN_SERVER_I2C_START) {
    unsigned off = addr - PACMAN_AXIL_ADDR;
    return i2c_read(off);
  }

  return pacman_read(addr, status);

}
