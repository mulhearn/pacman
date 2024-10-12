#ifndef pacman_i2c_hh
#define pacman_i2c_hh

#include <linux/types.h>
#include <cstdint>

#include "addr_conf.hh"

#define I2C_MAJOR_VERSION 5
#define I2C_MINOR_VERSION 2

#define I2C_DEV "/dev/i2c-0"

// The I2C device is used to access the PACMAN I2C peripherals:
//#define I2C_DEV "/dev/i2c-0"

// The PACMAN driver code uses a virtual register (VREG) space to abstract
// the specific hardware implementation.  This utility allows access
// to the PACMAN I2C devices via the vitual register space.
//
// Expert uses may access the I2C bus directly via the virtual resitser I2C_DIRECT
//

// I2C server-level access:
#define I2C_VREG_BASE_ADDR PACMAN_LEN // i2c registers immediately follow pacman-fw registers
#define I2C_VREG_LEN       0x1000

// I2C-1 virtual register space as offsets:
// for example SET_VDDA register for tile 3 is located at I2C_BASE_ADDR + 0x010 + (3-1).
#define I2C_VREG_OFFSET_SET_VDDA   0x010  // set VDDA level (one register per tile + test(0xA) )
#define I2C_VREG_OFFSET_SET_VDDD   0x020  // set VDDD level (one register per tile + test(0xA) )
#define I2C_VREG_OFFSET_MON_VDDA   0x030  // ADC for VDDA voltage (one register per tile, plus two board-level) 
#define I2C_VREG_OFFSET_MON_VDDD   0x040  // ADC for VDDD voltage (one register per tile, plus two board-level) 
#define I2C_VREG_OFFSET_MON_IDDA   0x050  // ADC for VDDA current (one register per tile, plus two board-level) 
#define I2C_VREG_OFFSET_MON_IDDD   0x060  // ADC for VDDA current (one register per tile, plus two board-level) 
#define I2C_VREG_OFFSET_SET_MUXA   0x070  // MUX setting Contact A (Front Panel)  (0=off, 1-10=TILE, 11=DAC)
#define I2C_VREG_OFFSET_SET_MUXB   0x080  // MUX setting Contact B (ADC)          (0=off, 1-10=TILE, 11=DAC)
#define I2C_VREG_OFFSET_MUX_EXPERT 0x090  // MUX expert settings  // NOT IMPLEMENTED

#define I2C_VREG_OFFSET_SCRATCH    0x100  // Scratch registers (16 registers:  0x100 to 0x10F)
#define I2C_VREG_OFFSET_EXPERT     0x110  // Expert registers (16 registers: 0x110 to 0x11F)
#define I2C_VREG_OFFSET_DIRECT     0x120  // Direct access to I2C HW as configured using expert registers.

#define I2C_VREG_OFFSET_MON_VBRD   0x200  // ADC for board voltage (one register for 3V6,3V3,3V0,Probe) // NOT YET IMPLEMENTED
#define I2C_VREG_OFFSET_MON_IBRD   0x210  // ADC for board current (one register for 3V6,3V3,3V0,Probe) // NOT YET IMPLEMENTED
#define I2C_VREG_OFFSET_I2C_VER    0x220  // PACMAN I2C Version (Read Only) (0=major, 1=minor, 2=debug)

#define I2C_VREG_OFFSET_DEVEL      0x300  // Run development code on write

// PACMAN-specific high-level I2C access:  initialize, read, write virtual I2C register space.

// open the I2C device:
int i2c_open(const char* dev);
// read the virtual register with offset vreg_offset and return its value
uint32_t i2c_read(uint32_t vreg_offset);
// write the value val to the virtual register with offset vreg_offset and return the associated value
uint32_t i2c_write(uint32_t vreg_offset, uint32_t val);

#endif
