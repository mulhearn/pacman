#include "iic.h"
#include <stdio.h>

#include "iic.h"

void check_iic(){}

// Enum for HW selection
typedef enum {
    HW_DISABLE = 0,
    HW_1V5,
    HW_1V4,
    HW_1V3
} iic_hw_t;

// forward declarations from iic_hw1v5.c
void iic_hw1v5_set_vdda_dn(hw_u32_t itile, hw_u32_t val);
void iic_hw1v5_set_vddd_dn(hw_u32_t itile, hw_u32_t val);

hw_u32_t iic_hw1v5_mon_vdda_mv(hw_u32_t itile);
hw_u32_t iic_hw1v5_mon_vddd_mv(hw_u32_t itile);
hw_u32_t iic_hw1v5_mon_idda_ma(hw_u32_t itile);
hw_u32_t iic_hw1v5_mon_iddd_ma(hw_u32_t itile);

hw_val_t iic_hw1v5_mon_vboard_mv(hw_val_t chan);
hw_val_t iic_hw1v5_mon_iboard_ma(hw_val_t chan);
hw_u32_t iic_hw1v5_mon_probe_dn();

void iic_hw1v5_set_mux_front_panel(hw_val_t itile);
void iic_hw1v5_set_mux_adc(hw_val_t itile);

// forward declarations from iic_hw1v4.c
void iic_hw1v4_set_vdda_dn(hw_val_t itile, hw_val_t val);
void iic_hw1v4_set_vddd_dn(hw_val_t itile, hw_val_t val);

hw_val_t iic_hw1v4_mon_vdda_mv(hw_val_t itile);
hw_val_t iic_hw1v4_mon_idda_ma(hw_val_t itile);
hw_val_t iic_hw1v4_mon_vddd_mv(hw_val_t itile);
hw_val_t iic_hw1v4_mon_iddd_ma(hw_val_t itile);

void iic_hw1v4_set_mux_front_panel(hw_val_t itile);

// selected hardware version for implmentation:
static iic_hw_t current_hw = HW_1V5;

void iic_set_hw_version(hw_val_t major, hw_val_t minor, hw_val_t patch){
  if ((major == 1) && (minor == 5)) {
    current_hw = HW_1V5;
  }
  else if ((major == 1) && (minor == 4)) {
    current_hw = HW_1V4;
  }
  else if ((major == 1) && (minor == 3)) {
    current_hw = HW_1V3;
  }
  else if (major == 0) { // support EVAL board as PACMAN V0 with I2C disabled
    current_hw = HW_DISABLE;
  }
  else {
    current_hw = HW_DISABLE;
    printf("iic_dispatch_init: unknown HW version %u.%u.%u\n",
	   (unsigned int) major, (unsigned int) minor, (unsigned int) patch);
  }
}

hw_val_t iic_get_hw_version(){
  return current_hw;
}

void iic_set_vdda_dn(hw_u32_t itile, hw_u32_t val) {
  switch (current_hw) {
  case HW_1V5: iic_hw1v5_set_vdda_dn(itile, val); break;
  case HW_1V4: iic_hw1v4_set_vdda_dn(itile, val); break;
  default: break;
  }
}

void iic_set_vddd_dn(hw_u32_t itile, hw_u32_t val){
  switch (current_hw) {
  case HW_1V5: iic_hw1v5_set_vddd_dn(itile, val); break;
  case HW_1V4: iic_hw1v4_set_vddd_dn(itile, val); break;
  default: break;
  }
}

hw_u32_t iic_mon_vdda_mv(hw_u32_t itile){
  switch (current_hw) {
  case HW_1V5: return iic_hw1v5_mon_vdda_mv(itile);
  case HW_1V4: return iic_hw1v4_mon_vdda_mv(itile);
  default: return 0;
  }
}

hw_u32_t iic_mon_vddd_mv(hw_u32_t itile){
  switch (current_hw) {
  case HW_1V5: return iic_hw1v5_mon_vddd_mv(itile);
  case HW_1V4: return iic_hw1v4_mon_vddd_mv(itile);
  default: return 0;
  }
}

hw_u32_t iic_mon_idda_ma(hw_u32_t itile){
  switch (current_hw) {
  case HW_1V5: return iic_hw1v5_mon_idda_ma(itile);
  case HW_1V4: return iic_hw1v4_mon_idda_ma(itile);
  default: return 0;
  }
}

hw_u32_t iic_mon_iddd_ma(hw_u32_t itile){
  switch (current_hw) {
  case HW_1V5: return iic_hw1v5_mon_iddd_ma(itile);
  case HW_1V4: return iic_hw1v4_mon_iddd_ma(itile);
  default: return 0;
  }
}

hw_val_t iic_mon_vboard_mv(hw_val_t chan){
  switch (current_hw) {
  case HW_1V5: return iic_hw1v5_mon_vboard_mv(chan);
  default: return 0;
  }
}

hw_val_t iic_mon_iboard_ma(hw_val_t chan){
  switch (current_hw) {
  case HW_1V5: return iic_hw1v5_mon_iboard_ma(chan);
  default: return 0;
  }
}

hw_val_t iic_mon_probe_dn(){
  switch (current_hw) {
  case HW_1V5: return iic_hw1v5_mon_probe_dn();
  default: return 0;
  }
}

void iic_set_mux_front_panel(hw_val_t itile){
  switch (current_hw) {
  case HW_1V5: return iic_hw1v5_set_mux_front_panel(itile);
  case HW_1V4: return iic_hw1v4_set_mux_front_panel(itile);
  default: return;
  }
}

void iic_set_mux_adc(hw_val_t itile){
  switch (current_hw) {
  case HW_1V5: return iic_hw1v5_set_mux_adc(itile);
  default: return;
  }
}
