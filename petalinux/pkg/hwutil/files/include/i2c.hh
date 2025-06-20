#ifndef i2c_hh
#define i2c_hh

//#include <linux/types.h>
//#include <cstdint>

#define I2C_MAJOR_VERSION 5
#define I2C_MINOR_VERSION 2

#define I2C_DEV "/dev/i2c-0"

// initialize the I2C driver:
void init_i2c();
void close_i2c();

// retrieve and clear the I2C status
uint32_t get_i2c_status();
void clear_i2c_status();

// set VDDA and VDDD of channel <chan> to value <val>
void i2c_set_vdda(uint32_t chan, uint32_t val);
void i2c_set_vddd(uint32_t chan, uint32_t val);
// Get monitored value of VDDA and VDDD of channel <chan> in mV
uint32_t i2c_mon_vdda(uint32_t chan);
uint32_t i2c_mon_vddd(uint32_t chan);
// Get monitored value of IDDA and IDDD of channel <chan> in mA
uint32_t i2c_mon_idda(uint32_t chan);
uint32_t i2c_mon_iddd(uint32_t chan);

void i2c_set_muxa(uint32_t val);
void i2c_set_muxb(uint32_t val);

#endif
