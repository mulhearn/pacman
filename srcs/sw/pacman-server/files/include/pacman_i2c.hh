#ifndef pacman_i2c_hh
#define pacman_i2c_hh

#include <cstdint>

#include "addr_conf.hh"

// I2C peripherals:
// I2C-1
#define ADDR_VDDA_TILE1 0x40
#define ADDR_VDDD_TILE1 0x41
#define ADDR_VDDA_TILE2 0x42
#define ADDR_VDDD_TILE2 0x43
#define ADDR_VDDA_TILE3 0x44
#define ADDR_VDDD_TILE3 0x45
#define ADDR_VDDA_TILE4 0x46
#define ADDR_VDDD_TILE4 0x47
#define ADDR_VDDA_TILE5 0x48
#define ADDR_VDDD_TILE5 0x49
#define ADDR_VDDA_TILE6 0x4a
#define ADDR_VDDD_TILE6 0x4b
#define ADDR_VDDA_TILE7 0x4c
#define ADDR_VDDD_TILE7 0x4d
#define ADDR_VDDA_TILE8 0x4e
#define ADDR_VDDD_TILE8 0x4f
#define ADDR_V_DAC      0x0C
// I2C-2
#define ADDR_TEST_MUX   0x4C

//MAX14661: (for reference)
#define DIR0 0x00
#define DIR1 0x01
#define DIR2 0x02
#define DIR3 0x03
#define SHDW0 0x10
#define SHDW1 0x11
#define SHDW2 0x12
#define SHDW3 0x13
#define CMD_A 0x14 // 0x11 copy from shdw
#define CMD_B 0x15 // 0x11 copy from shdw
/*
For 1-hot enable analog monitor / adc test:
Write channel mask to wrapped 32-bit register 0x10, loads channel mask into shadow register
Write 0x1111 to wrapped 32-bit register 0x14, updates
*/

//ADS5677R: (for reference)
/*
To update a DAC:
write to register: addr 0x30 + (DAC #) with the 16-bit value
read back: addr 0x90 + (DAC #)
 */

//INA219: (for reference)
#define CONFIG      0x00
#define ADC_V_SHUNT 0x01
#define ADC_V_BUS   0x02
#define ADC_POW     0x03
#define ADC_I       0x04
#define ADC_CAL     0x05

// I2C server-level access:
#define I2C_1_BASE_ADDR PACMAN_LEN // i2c registers immediately follow pacman-fw registers
#define I2C_1_BASE_LEN  0x1000
#define I2C_2_BASE_ADDR I2C_1_BASE_ADDR + I2C_1_BASE_LEN
#define I2C_2_BASE_LEN  0x1000

// I2C-1 register space
#define OFFSET_ADC_VDDA_1 0x000
#define OFFSET_ADC_VDDD_1 0x010
#define OFFSET_ADC_VDDA_2 0x020
#define OFFSET_ADC_VDDD_2 0x030
#define OFFSET_ADC_VDDA_3 0x040
#define OFFSET_ADC_VDDD_3 0x050
#define OFFSET_ADC_VDDA_4 0x060
#define OFFSET_ADC_VDDD_4 0x070
#define OFFSET_ADC_VDDA_5 0x080
#define OFFSET_ADC_VDDD_5 0x090
#define OFFSET_ADC_VDDA_6 0x0A0
#define OFFSET_ADC_VDDD_6 0x0B0
#define OFFSET_ADC_VDDA_7 0x0C0
#define OFFSET_ADC_VDDD_7 0x0D0
#define OFFSET_ADC_VDDA_8 0x0E0
#define OFFSET_ADC_VDDD_8 0x0F0
#define OFFSET_V_DAC      0x100

// I2C-2 register space
#define OFFSET_TEST_MUX   0x000

#define I2C_1_DEV "/dev/i2c-0"
#define I2C_2_DEV "/dev/i2c-1"

// low-level access to i2c
int i2c_open(char* dev);

int i2c_ping(int fh, uint8_t addr);
int i2c_set(int fh, uint8_t addr, uint8_t val);
int i2c_set(int fh, uint8_t addr, uint8_t reg, uint32_t val, uint8_t bytes);
int i2c_recv(int fh, uint8_t addr, uint8_t* buf, uint32_t nbytes);
int i2c_recv(int fh, uint8_t addr, uint8_t reg, uint8_t* buf, uint32_t nbytes);

// high-level access to i2c (wraps address + reg access)
uint32_t i2c_read(int fh, uint32_t reg);
uint32_t i2c_write(int fh, uint32_t reg, uint32_t val);

#endif
