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

#define INA220_REG_I       0x1        // Shunt Voltage Register
#define INA220_REG_V       0x2        // BUS Voltage Register


hw_val_t ina220_v_adc_dn(hw_u8_t addr){
  hw_u8_t buf[2];

  iic_read(addr, INA220_REG_V, buf, 2, false);  // TODO:  try repeated read = true, which should be default...

  hw_val_t reg = (((hw_val_t) buf[0]) << 8) | buf[1];
  hw_val_t dn = (reg >> 3); // D0 is at bit 3

  return dn;
}

hw_val_t ina220_i_adc_dn(hw_u8_t addr){
  hw_u8_t buf[2];

  iic_read(addr, INA220_REG_I, buf, 2, false);  // TODO:  try repeated read = true, which should be default...

  hw_val_t reg = (((hw_val_t) buf[0]) << 8) | buf[1];
  hw_val_t dn  = reg;

  return dn;
}


#define ADS1219_REG_RESET      0x06
#define ADS1219_REG_CFG        0x40
#define ADS1219_REG_START      0x08
#define ADS1219_REG_READY      0x24
#define ADS1219_REG_RDATA      0x10
#define ADS1219_MASK_READY     0x80
#define ADS1219_SHIFT_MUX      5

hw_val_t ads1219_adc_dn(hw_u8_t addr, hw_u8_t mux){
  hw_val_t timeout = 100;
  hw_u8_t buf[4];

  if (mux > 0x7)
    return 0;
  hw_u8_t cfg = (mux << ADS1219_SHIFT_MUX);

  //printf("INFO:  ads1219_adc_dn:  addr: 0x%x cfg: 0x%x \r\n", addr, cfg);
  iic_write(addr, ADS1219_REG_RESET, NULL, 0);
  buf[0] = cfg;
  iic_write(addr, ADS1219_REG_CFG, buf, 1);
  iic_write(addr, ADS1219_REG_START, NULL, 0);
  while(timeout--){
    iic_read(addr, ADS1219_REG_READY, buf, 1, true);
    if (buf[0] & ADS1219_MASK_READY)
      break;
    usleep(1000);
  }
  if (!timeout) {
    printf("ERROR: timeout waiting on ADS1219 ready bit");
    return 0;
  }

  iic_read(addr, ADS1219_REG_RDATA, buf, 3, true);

  uint32_t val = (buf[0] << 16) | (buf[1] << 8) | buf[2];
  return val;
}



