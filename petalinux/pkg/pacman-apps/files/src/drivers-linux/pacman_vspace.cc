#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>

#include "pacman_vspace.hh"
#include "addr_conf.hh"
#include "pacman.hh"
#include "pacman_i2c.hh"


int pacman_vspace_write(uint32_t addr, uint32_t value){
  printf("DEBUG: vspace_write: addr 0x%x value 0x%x \r\n", addr, value);

  if (addr >= PACMAN_VSPACE_I2C_START) {
    unsigned off = addr - PACMAN_VSPACE_I2C_START;
    printf("DEBUG: vspace_write: virtual I2C write at offset 0x%x value 0x%x \r\n", off, value);
    return i2c_write(off, value);
  }

  if (addr >= PACMAN_VSPACE_REG_START){
    unsigned tmp = 0;
    unsigned off = addr - PACMAN_VSPACE_REG_START;
    printf("DEBUG: vspace_write: virtual reg write at offset 0x%x value 0x%x \r\n", off, value);

    switch(off){
    case 0x0010:
      tmp = pacman_read(0xF010);
      tmp &= 0xFFFF0000;
      tmp |= (value & 0x03FF);
      return pacman_write(0xF010, tmp);
    case 0x0014:
      tmp = pacman_read(0xF010);
      tmp &= 0xFFF0FFFF;
      if (value&0x1)
	tmp |= 0x00010000;
      return pacman_write(0xF010, tmp);
    case 0x0018:
      // ignoring... already configured correctly.
      return EXIT_SUCCESS;
    case 0x001C:
      // ignoring... already configured correctly.
      return EXIT_SUCCESS;
    case 0x1010:
      // this is a request to send a sync pulse:
      if ((value&0x4)!=0){
	// use Poke C register (mapped to SYNC pulse in config)
	return pacman_write(0xE0C0, 0x0);
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

    // non-virtual addesses: silently ignore:
    return EXIT_SUCCESS;
  }

  // non-virtual address:
  printf("DEBUG: vspace_write: non-virtual reg write at offset 0x%x value 0x%x \r\n", addr, value);
  return pacman_write(addr, value);

}

uint32_t pacman_vspace_read(uint32_t addr, int * status){
  if (status)
    *status = EXIT_SUCCESS;

  printf("DEBUG: vspace_read addr 0x%x\r\n",addr);

  if (addr >= PACMAN_VSPACE_I2C_START) {
    unsigned off = addr - PACMAN_VSPACE_I2C_START;
    printf("DEBUG: vspace_read:  I2C read at offset 0x%x\r\n", off);
    return i2c_read(off);
  }

  if (addr >= PACMAN_VSPACE_REG_START){
    unsigned tmp = 0;
    unsigned off = addr - PACMAN_VSPACE_REG_START;
    printf("DEBUG: vspace_read: virtual reg write at offset 0x%x \r\n", off);

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
      tmp = pacman_read(0xF010, status);
      tmp &= 0x000003FF;
      return tmp;
    case 0x0014:
      tmp = pacman_read(0xF010);
      return ((tmp & 0x00010000) != 0);
    case 0x1000:
      return 0;
    case 0x1010:
      return 0;
    }
    return 0;
  }

  // non-virtual address:
  printf("DEBUG: vspace_read: non-virtual reg write at address 0x%x \r\n", addr);
  return pacman_read(addr, status);

}
