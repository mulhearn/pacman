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

// Get monitored value of VDDA and VDDD for TILE <chan>+1 in mV
hw_u32_t iic_mon_vdda_mv(hw_u32_t chan);
hw_u32_t iic_mon_vddd_mv(hw_u32_t chan);

// Get monitored value of IDDA and IDDD for TILE <chan>+1 in mA
hw_u32_t iic_mon_idda_ma(hw_u32_t chan);
hw_u32_t iic_mon_iddd_ma(hw_u32_t chan);

// Gen monitored value of board voltage for chan <chan>
// chan:  0= 3V6, 1=3V3, 2=3V0, 3=3V3 (Probe)
hw_u32_t iic_mon_vboard_mv(hw_u32_t chan);

// Gen monitored value of board voltage for chan <chan>
// chan:  0= 3V6, 1=3V3, 2=3V0
hw_u32_t iic_mon_iboard_ma(hw_u32_t chan);

// Get monitored value of votage drop across probe in raw counts:
hw_u32_t iic_mon_probe_dn();

void iic_set_muxa(hw_u32_t val);
void iic_set_muxb(hw_u32_t val);

#ifdef __cplusplus
}
#endif

#endif // IIC_H
