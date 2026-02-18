#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>

#include "pacman_vspace.hh"
#include "addr_conf.hh"
#include "pacman.hh"
#include "pacman_i2c.hh"


#include "rxtx.h"


int pacman_vspace_write(uint32_t addr, uint32_t value){
  unsigned tmp, off;
  printf("DEBUG: vspace_write: addr 0x%x value 0x%x \r\n", addr, value);

  if (addr >= PACMAN_VSPACE_I2C_START) {
    off = addr - PACMAN_VSPACE_I2C_START;
    printf("DEBUG: vspace_write: virtual I2C write at offset 0x%x value 0x%x \r\n", off, value);
    return i2c_write(off, value);
  }

  // for debugging legacy DAQ with new driver, we are treating all non-I2C registers as vitual:
  if (addr >= PACMAN_VSPACE_REG_START){
    off = addr - PACMAN_VSPACE_REG_START;
    printf("DEBUG: vspace_write: virtual reg write at offset 0x%x value 0x%x \r\n", off, value);
  } else {
    off = addr;
    printf("DEBUG: vspace_write: treating HW reg as virtual reg write at offset 0x%x value 0x%x \r\n", off, value);
  }

  switch(off){
  case 0x0010: // 0x00XX
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
    // unused
    return EXIT_SUCCESS;
  case 0x001C:
    // unused
    return EXIT_SUCCESS;
  case 0x1010: // 0x10XX
    // this is a request to send a sync pulse:
    if ((value&0x4)!=0){
      // use Poke C register (mapped to G output) and enable all tiles
      return pacman_write(0xE0C0, 0x3FF);
    }
    return EXIT_SUCCESS;
  case 0x1014:
    // this is a request to set the pulse length of the reset signal
    // Configure POKE C stimulus for G output, all ten tiles enabled, provided (12-bit) pulse length
    tmp = 0x03FF0001 | ((value & 0xFFF)<<4);
    return pacman_write(0xE118, tmp);
  case 0x1018:
    //ignoring...
    return EXIT_SUCCESS;
  case 0x101C:
    // clock rate = 50 MHz / (1 + X)
    // ignoring... already configured correctly (X=4)
    return EXIT_SUCCESS;
  case 0x2010: // 0x20XX
    return EXIT_SUCCESS;
  case 0x2014:
    return EXIT_SUCCESS;
  case 0x2018:
    return EXIT_SUCCESS;
  case 0x201C:
    // RX enables for UARTS 1-32
    for (uint32_t i = 0; i < 32; ++i) {
      if (value & (1u << i))
	rx_enable_uart(i);
      else
	rx_disable_uart(i);
    }
    return EXIT_SUCCESS;
  case 0x2020:
    // RX enables for UARTS 33-40
    for (uint32_t i = 0; i < 8; ++i) {
      if (value & (1u << i))
	rx_enable_uart(32+i);
      else
	rx_disable_uart(32+i);
    }
    return EXIT_SUCCESS;
  }

  // silently ignore anything not explicitly handled:
  return EXIT_SUCCESS;

  // non-virtual address:
  //printf("DEBUG: vspace_write: non-virtual reg write at offset 0x%x value 0x%x \r\n", addr, value);
  //return pacman_write(addr, value);

}

uint32_t pacman_vspace_read(uint32_t addr, int * status){
  unsigned off, tmp;

  if (status)
    *status = EXIT_SUCCESS;

  printf("DEBUG: vspace_read addr 0x%x\r\n",addr);

  if (addr >= PACMAN_VSPACE_I2C_START) {
    off = addr - PACMAN_VSPACE_I2C_START;
    printf("DEBUG: vspace_read:  I2C read at offset 0x%x\r\n", off);
    return i2c_read(off);
  }

  // for debugging legacy DAQ with new driver, we are treating all non-I2C registers as vitual:
  if (addr >= PACMAN_VSPACE_REG_START){
    off = addr - PACMAN_VSPACE_REG_START;
    printf("DEBUG: vspace_read: virtual reg read at offset 0x%x \r\n", off);
  } else {
    off = addr;
    printf("DEBUG: vspace_read: treating HW reg as virtual reg read at offset 0x%x \r\n", off);
  }

  tmp = 0;
  switch(addr){
  case 0x0000:
    tmp = pacman_read(0xFF10, status);
    tmp = (tmp << 16);
    tmp |= ((pacman_read(0xFF14, status)) & 0xFFFF);
    return tmp;
  case 0x0010:
    tmp = pacman_read(0xF010, status);
    tmp &= 0x000003FF;
    return tmp;
  case 0x0014:
    tmp = pacman_read(0xF010);
    return ((tmp & 0x00010000) != 0);
  case 0x201C:
    tmp = 0;
    for (uint32_t i = 0; i < 32; ++i) {
      if (rx_uart_is_enabled(i))
	tmp |= (1u << i);
    }
    return tmp;
  case 0x2020:
    tmp = 0;
    for (uint32_t i = 0; i < 8; ++i) {
      if (rx_uart_is_enabled(32+i))
	tmp |= (1u << i);
    }
    return tmp;
  }
  // return 0 for registers not explicitly handled.
  return 0;

  // non-virtual address:
  //printf("DEBUG: vspace_read: non-virtual reg read at address 0x%x \r\n", addr);
  //return pacman_read(addr, status);

}
