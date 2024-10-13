#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>

#include "pacman_vspace.hh"
#include "addr_conf.hh"
#include "pacman.hh"
#include "pacman_i2c.hh"

#define PACMAN_SERVER_I2C_START     0x00024000

int pacman_vspace_write(uint32_t addr, uint32_t value){
  if (addr >= PACMAN_AXIL_ADDR){
    unsigned off = addr - PACMAN_AXIL_ADDR;
    return pacman_write(off, value);
  }
  if (addr >= PACMAN_SERVER_I2C_START) {  
    unsigned off = addr - PACMAN_AXIL_ADDR;
    return i2c_write(off, value);
  }

  unsigned enables = 0;
  switch(addr){
  case 0x0010:
    enables = pacman_read(0xFF20);
    enables &= 0xFFFF0000;
    enables |= (value & 0x03FF);
    return pacman_write(0xFF20, enables);
  case 0x0014:
    enables = pacman_read(0xFF20);
    enables &= 0xFFF0FFFF;
    if (value&0x1)
      enables |= 0x00010000;
    return pacman_write(0xFF20, enables);
  }
  // assume pass through if we didn't catch it earlier:
  //pacman_write(addr, value);
  //return EXIT_SUCCESS;

  return EXIT_FAILURE; 
}

uint32_t pacman_vspace_read(uint32_t addr, int * status){
  if (status)
    *status = EXIT_SUCCESS;
  if (addr >= PACMAN_AXIL_ADDR){
    unsigned off = addr - PACMAN_AXIL_ADDR;
    return pacman_read(off, status);
  }
  if (addr >= PACMAN_SERVER_I2C_START) {  
    unsigned off = addr - PACMAN_AXIL_ADDR;
    return i2c_read(off);
  }

  unsigned enables = 0;
  switch(addr){
  case 0x0000:
    return pacman_read(0xFF10, status);
  case 0x0004:
    return pacman_read(0xFF14, status);
  case 0x0008:
    return pacman_read(0xFF18, status);
  case 0x000C:
    return pacman_read(0xFF1C, status);
  case 0x0010:
    enables = pacman_read(0xFF20, status);
    enables &= 0x000003FF;
    return enables;
  case 0x0014:
    enables = pacman_read(0xFF20);
    return ((enables & 0x00010000) != 0);
  }

  // assume pass through if we didn't catch it earlier:
  //return pacman_read(addr, status);

  if (status)
    *status = EXIT_FAILURE;
  return 0;
}


