#ifndef IIC_H
#define IIC_H

#include "hw_access.h"

#ifdef __cplusplus
extern "C" {
#endif

#define IIC_MAJOR_VERSION 5
#define IIC_MINOR_VERSION 4

// confirm that I2C is up and running using NO-OPs
void check_iic();

// set VDDA and VDDD of channel <chan> to value <val>
void iic_set_vdda(hw_u32_t chan, hw_u32_t val);
void iic_set_vddd(hw_u32_t chan, hw_u32_t val);

// Get monitored value of VDDA and VDDD of channel <chan> in mV
hw_u32_t iic_mon_vdda(hw_u32_t chan);
hw_u32_t iic_mon_vddd(hw_u32_t chan);

// Get monitored value of IDDA and IDDD of channel <chan> in mA
hw_u32_t iic_mon_idda(hw_u32_t chan);
hw_u32_t iic_mon_iddd(hw_u32_t chan);

void iic_set_muxa(hw_u32_t val);
void iic_set_muxb(hw_u32_t val);

#ifdef __cplusplus
}
#endif

#endif // IIC_H
