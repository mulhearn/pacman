#ifndef IIC_H
#define IIC_H

#include "hw_access.h"

#ifdef __cplusplus
extern "C" {
#endif

// AD5677 DAC (16 channel)
// addr: I2C address of device
// chan[3,0]: DAC channel
// val: digital value to write
void ad5677_set_voltage(hw_u8_t addr, hw_u8_t chan, hw_val_t val);

// PAC1944 ADC
// addr: I2C address of device
// reg: register to read (see datasheet)
hw_val_t pac1944_adc_dn(hw_u8_t addr, hw_u8_t reg);

// MAX14661 MUX
// addr: I2C address of device
// code[3:0]: setting for COMA/COMB (see datasheet)
void max14661_set_coma(hw_u8_t addr, hw_val_t code);
void max14661_set_comb(hw_u8_t addr, hw_val_t code);

// Legacy devices (not present in latest HW version, but still supported in legacy HW)

// ADS1219 ADC
// addr: I2C address of device
// mux: mux[2:0] selection (see datasheet)
hw_val_t ads1219_adc_dn(hw_u8_t addr, hw_u8_t mux);

// INA220 ADC
// addr: I2C address of device
hw_val_t ina220_v_adc_dn(hw_u8_t addr);
hw_val_t ina220_i_adc_dn(hw_u8_t addr);

#ifdef __cplusplus
}
#endif


#endif // IIC_DEVICES_H
