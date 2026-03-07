#ifndef IIC_H
#define IIC_H

// iic.h
//
// I2C features for setting output voltages, monitoring power, and
// configuring MUX.
//
// This driver supports multiple HW versions, as selected via
// iic_set_hw_version (see below).  Unsupported features in legacy
// hardware generally do nothing and return 0, with no error.
//
// The TILE cards are labeled TILE 1- TILE 10 in PACMAN schematics.
// Here we use itile to denote the zero referenced tile index
// (e.g. TILE 1 has itile=0)
//

#include "hw_access.h"

#ifdef __cplusplus
extern "C" {
#endif

// confirm that I2C is up and running using NO-OPs
void check_iic();

// set the PACMAN HW version to use for I2C
void iic_set_hw_version(hw_val_t major, hw_val_t minor, hw_val_t patch);

// report IIC version currently in use:
hw_val_t iic_get_hw_version();

// set VDDA and VDDD of channel <itile> to value <val>
void iic_set_vdda_dn(hw_u32_t itile, hw_u32_t val);
void iic_set_vddd_dn(hw_u32_t itile, hw_u32_t val);

// Get monitored value of VDDA and VDDD for TILE <chan>+1 in mV
hw_u32_t iic_mon_vdda_mv(hw_u32_t itile);
hw_u32_t iic_mon_vddd_mv(hw_u32_t itile);

// Get monitored value of IDDA and IDDD for TILE <chan>+1 in mA
hw_u32_t iic_mon_idda_ma(hw_u32_t itile);
hw_u32_t iic_mon_iddd_ma(hw_u32_t itile);

// Gen monitored value of board voltage for chan <chan>
// chan:  0= 3V6, 1=3V3, 2=3V0, 3=3V3 (Probe)
hw_u32_t iic_mon_vboard_mv(hw_u32_t chan);

// Gen monitored value of board voltage for chan <chan>
// chan:  0= 3V6, 1=3V3, 2=3V0
hw_u32_t iic_mon_iboard_ma(hw_u32_t chan);

// Get monitored value of votage drop across probe in raw counts:
hw_u32_t iic_mon_probe_dn();

#ifdef __cplusplus
}
#endif

#endif // IIC_H
