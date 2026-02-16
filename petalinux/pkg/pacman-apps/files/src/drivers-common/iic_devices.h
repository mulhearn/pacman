#ifndef IIC_H
#define IIC_H

#include "hw_access.h"

#ifdef __cplusplus
extern "C" {
#endif

// === AD5677 DAC ===
// addr: I2C address of the DAC
// chan: 0..15 channel number
// val: digital value to write
void ad5677_set_voltage(hw_u8_t addr, hw_u8_t chan, hw_val_t val);

// === PAC1944 ADC ===
// addr: I2C address of PAC1944
// reg: register to read
// returns raw DN
hw_val_t pac1944_adc_dn(hw_u8_t addr, hw_u8_t reg);

// === MAX14661 MUX ===
// addr: I2C address of MAX14661
// code: code to write to the MUX (0..15)
void max14661_set_coma(hw_u8_t addr, hw_val_t code);
void max14661_set_comb(hw_u8_t addr, hw_val_t code);

#ifdef __cplusplus
}
#endif


#endif // IIC_DEVICES_H
