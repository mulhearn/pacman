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


  if (addr < PACMAN_VSPACE_REG_START){
    // non-virtual address:
    printf("DEBUG: vspace_write: non-virtual reg write at offset 0x%x value 0x%x \r\n", addr, value);
    return pacman_write(addr, value);
  }

  if (addr >= PACMAN_VSPACE_I2C_START) {
    off = addr - PACMAN_VSPACE_I2C_START;
    printf("DEBUG: vspace_write: virtual I2C write at offset 0x%x value 0x%x \r\n", off, value);
    return i2c_write(off, value);
  }

  // we are in the virtual register space:
  off = addr - PACMAN_VSPACE_REG_START;
  printf("DEBUG: vspace_write: virtual reg write at offset 0x%x value 0x%x \r\n", off, value);

  // ALL CHANNELS ARE ZERO REFERENCED.

  // 0x00100100:  READ_GLOBAL_TILE_POWER      (RO)

  // 0x00100110:  DISABLE_GLOBAL_TILE_POWER    (WO)
  // 0x00100114:  ENABLE_GLOBAL_TILE_POWER   (WO)

  // 0x00100200:  READ_TILE_ENABLES           (RO)

  // 0x00100210:  DISABLE_SINGLE_TILE   <TILE> (WO)
  // 0x00100214:  ENABLE_SINGLE_TILE  <TILE> (WO)

  // 0x001002F0:  DISABLE_ALL_TILE     DC/0     (WO)
  // 0x001002F4:  ENABLE_ALL_TILE     DC/0     (WO)

  // 0x00100300:  READ_RX_ENABLES_LOWER    (RO)
  // 0x00100304:  READ_RX_ENABLES_UPPER    (RO)

  // 0x00100310:  DISABLE_SINGLE_UART_RX  <UART>   (WO)
  // 0x00100314:  ENABLE_SINGLE_UART_RX   <UART>   (WO)  (UNTESTED)

  // 0x001003F0:  DISABLE_ALL_UART_RX     DC/0     (WO)
  // 0x001003F4:  ENABLE_ALL_UART_RX      DC/0     (WO)

  // 0x00100410:  SEND_FULL_RESET      <MASK>
  // 0x00100420:  SEND_INTERNAL_RESET  <MASK>

  switch(off){

  case 0x0110:
    // DISABLE_GLOBAL_TILE_POWER
    tmp  = pacman_read(0xF010);
    tmp &= ~0x00010000;
    return pacman_write(0xF010, tmp);
  case 0x0114:
    // ENABLE_GLOBAL_TILE_POWER
    tmp = pacman_read(0xF010);
    tmp |= 0x00010000;
    return pacman_write(0xF010, tmp);

  case 0x0210:
    // DISABLE_SINGLE_TILE
    if (value >= 10)
      return EXIT_SUCCESS;
    tmp = pacman_read(0xF010);
    tmp &= ~(1<<value);
    return pacman_write(0xF010, tmp);
  case 0x0214:
    // ENABLE_SINGLE_TILE
    if (value >= 10)
      return EXIT_SUCCESS;
    tmp = pacman_read(0xF010);
    tmp |= (1<<value);
    return pacman_write(0xF010, tmp);
  case 0x02F0:
    // DISABLE_ALL_TILE
    tmp = pacman_read(0xF010);
    tmp &= ~0x3FF;
    return pacman_write(0xF010, tmp);
  case 0x02F4:
    // ENABLE_ALL_TILE
    tmp = pacman_read(0xF010);
    tmp |= 0x3FF;
    return pacman_write(0xF010, tmp);
  case 0x0310:
    // Disable single UART channel
    if (value >= 40)
      return EXIT_SUCCESS;
    rx_disable_uart(value);
    return EXIT_SUCCESS;
  case 0x0314:
    // Enable single UART channels
    if (value >= 40)
      return EXIT_SUCCESS;
    rx_enable_uart(value);
    return EXIT_SUCCESS;
  case 0x03F0:
    // Disable all UART channels
    for (uint32_t i = 0; i < 40; ++i) {
      rx_disable_uart(i);
    }
    return EXIT_SUCCESS;
  case 0x03F4:
    // Enable all UART channels
    for (uint32_t i = 0; i < 40; ++i) {
      rx_enable_uart(i);
    }
    return EXIT_SUCCESS;
  case 0x0410:
    // this is a request to send a internal reset to tiles in mask:
    // poke C is configured for internal reset
    return pacman_write(0xE0C0, value);
  case 0x0420:
    // this is a request to send a full reset to tiles in mask:
    // poke D is configured for full reset
    return pacman_write(0xE0D0, value);

  //Legacy interface:
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
  case 0x1010: // 0x10XX
    // this is a request to send a reset pulse:
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

  case 0x201C:
    // RX enables for UARTS 1-32
    for (uint32_t i = 0; i < 32; ++i) {
      if (value & (1u << i))
	rx_disable_uart(i);
      else
	rx_enable_uart(i);
    }
    return EXIT_SUCCESS;
  case 0x2020:
    // RX enables for UARTS 33-40
    for (uint32_t i = 0; i < 8; ++i) {
      if (value & (1u << i))
	rx_disable_uart(32+i);
      else
	rx_enable_uart(32+i);
    }
    return EXIT_SUCCESS;
  }

  // silently ignore anything not explicitly handled:
  return EXIT_SUCCESS;

}

uint32_t pacman_vspace_read(uint32_t addr, int * status){
  unsigned off;

  if (status)
    *status = EXIT_SUCCESS;

  printf("DEBUG: vspace_read addr 0x%x\r\n",addr);

  if (addr < PACMAN_VSPACE_REG_START){
    // non-virtual address:
    printf("DEBUG: vspace_read: non-virtual reg read at address 0x%x \r\n", addr);
    return pacman_read(addr, status);
  }

  if (addr >= PACMAN_VSPACE_I2C_START) {
    off = addr - PACMAN_VSPACE_I2C_START;
    printf("DEBUG: vspace_read:  I2C read at offset 0x%x\r\n", off);
    return i2c_read(off);
  }

  // we are in the virtual address space:
  off = addr - PACMAN_VSPACE_REG_START;
  printf("DEBUG: vspace_read: virtual reg read at offset 0x%x \r\n", off);

  // read virtual registers not yet supported.  Use pacman_menu interface to check registers.
  return 0;

}
