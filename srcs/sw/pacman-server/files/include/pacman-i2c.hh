#ifndef pacman_i2c_hh
#define pacman_i2c_hh

#include <cstdint>

//I2C peripherals:
#define ADDR_ADC_VPLUS    0b1001000
#define ADDR_DAC_VDDD     0b0011100  // ADDR -> GND
#define ADDR_DAC_VDDA     0b0011101  // ADDR -> NC
#define ADDR_ADC_VDDD     0b1001100  // A1-> SCL. A0-> GND
#define ADDR_ADC_VDDA     0b1000000  // A1-> GND, A0-> GND

//MAX5215-5217:
#define CODE_LOAD 0x01
#define NO_OP 0x00
#define CODE 0x02
#define LOAD 0x03
#define USER_CONFIG 0x08
#define SW_RESET 0x09
#define SW_CLEAR 0x0A

//INA219:
#define CONFIG 0x00
#define ADC_V_SHUNT 0x01
#define ADC_V_BUS 0x02
#define ADC_POW 0x03
#define ADC_I 0x04
#define ADC_CAL 0x05

//I2C server-level access:
#define I2C_BASE_ADDR 0x00023000
#define I2C_BASE_LEN 0x100
#define OFFSET_DAC_VDDD 0x000
#define OFFSET_DAC_VDDA 0x010
#define OFFSET_ADC_VPLUS 0x020
#define OFFSET_ADC_VDDD 0x030
#define OFFSET_ADC_VDDA 0x040
#define I2C_DEV "/dev/i2c-0"

// low-level access to i2c
int i2c_open(char* dev);

int i2c_ping(int fh, uint32_t addr);
int i2c_send(int fh, uint8_t addr, uint8_t reg);
int i2c_set(int fh, uint32_t addr, uint8_t reg, uint16_t val);
int i2c_recv(int fh, uint32_t addr, uint8_t reg, uint8_t* buf, uint32_t nbytes);

// high-level access to i2c (wraps address + reg access)
uint32_t i2c_read(int fh, uint32_t reg);
uint32_t i2c_write(int fh, uint32_t reg, uint32_t val);

#endif