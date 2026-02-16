// iic_hw1v5.c
//
// I2C implementation specific to PACMAN 1V5
//

#include <assert.h>
#include "hw_access.h"
#include "iic_devices.h"

#define AD5677_BASE_REG   0x30
#define AD5677_NUM_CHAN   16

#define PAC1944_SINGLE_SHOT_CFG 0x85

void ad5677_set_voltage(hw_u8_t addr, hw_u8_t chan, hw_val_t val) {
  assert(chan <= AD5677_NUM_CHAN); // 16-channel DAC

  hw_u8_t reg = AD5677_BASE_REG + chan;
  hw_u8_t buf[2];
  buf[0] = (val >> 8) & 0xFF;
  buf[1] = val & 0xFF;

  iic_write(addr, reg, buf, 2);
}

hw_val_t pac1944_adc_dn(hw_u8_t addr, hw_u8_t reg){
  hw_u8_t buf[2];

  // Configure single-shot mode
  hw_u8_t cfg[2] = { PAC1944_SINGLE_SHOT_CFG, 0x00 };
  iic_write(addr, 1, cfg, 2);

  // Refresh twice
  iic_write(addr, 0, NULL, 0);
  usleep(5000);
  iic_write(addr, 0, NULL, 0);
  usleep(5000);

  // Read the output register
  iic_write(addr, reg, NULL, 0);
  iic_read(addr, reg, buf, 2, false);

  uint32_t val = (buf[0] << 8) | buf[1];
  return val;
}

void max14661_set_coma(hw_u8_t addr, hw_val_t code) {
  const hw_u8_t reg = 0x14;
  const hw_u8_t nbytes = 1;

  hw_u8_t buf[1] = { (hw_u8_t) code };
  iic_write(addr, reg, buf, nbytes);
}

void max14661_set_comb(hw_u8_t addr, hw_val_t code) {
  const hw_u8_t reg = 0x15;
  const hw_u8_t nbytes = 1;

  hw_u8_t buf[1] = { (hw_u8_t) code };
  iic_write(addr, reg, buf, nbytes);
}
