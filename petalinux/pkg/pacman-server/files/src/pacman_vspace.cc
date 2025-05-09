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

  unsigned tmp = 0;
  switch(addr){
  case 0x0010:
    tmp = pacman_read(0xFF20);
    tmp &= 0xFFFF0000;
    tmp |= (value & 0x03FF);
    return pacman_write(0xFF20, tmp);
  case 0x0014:
    tmp = pacman_read(0xFF20);
    tmp &= 0xFFF0FFFF;
    if (value&0x1)
      tmp |= 0x00010000;
    return pacman_write(0xFF20, tmp);
  case 0x0018:
    // ignoring... already configured correctly.
    return EXIT_SUCCESS;
  case 0x001C:
    // ignoring... already configured correctly.
    return EXIT_SUCCESS;    
  case 0x1010:
    // this is a request to send a sync pulse:
    if ((value&0x4)!=0){
      return pacman_write(0xFE24, 0x00FF03FF);
    }    
    return EXIT_SUCCESS;
  case 0x1014:
    // ignoring... already configured correctly.
    return EXIT_SUCCESS;
  case 0x1018:
    // ignoring... already configured correctly.
    return EXIT_SUCCESS;
  case 0x101C:
    // ignoring... already configured correctly.
    return EXIT_SUCCESS;
  case 0x2014:
    // ignoring... 
    return EXIT_SUCCESS;
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

  unsigned tmp = 0;
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
    tmp = pacman_read(0xFF20, status);
    tmp &= 0x000003FF;
    return tmp;
  case 0x0014:
    tmp = pacman_read(0xFF20);
    return ((tmp & 0x00010000) != 0);
  case 0x1000:
    return 0;    
  case 0x1010:
    return 0;
  }

  // assume pass through if we didn't catch it earlier:
  //return pacman_read(addr, status);

  if (status)
    *status = EXIT_FAILURE;
  return 0;
}


