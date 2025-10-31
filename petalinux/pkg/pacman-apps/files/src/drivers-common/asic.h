#ifndef __ADC_H_
#define __ADC_H_

#include "hw_access.h"

#ifdef __cplusplus
extern "C" {
#endif

hw_u32_t asic_calc_parity(hw_u32_t * word);
void     asic_config_write(hw_u32_t * word, hw_u8_t chip, hw_u8_t addr, hw_u8_t data);
void     asic_config_read(hw_u32_t * word, hw_u8_t chip, hw_u8_t addr);
void     asic_print(hw_u32_t * word);

void asic_full_reset();
void asic_internal_reset();
void asic_toggle_power();

void asic_root_chip_id();
void asic_config_root();
void asic_read_all();
void asic_hello();

#ifdef __cplusplus
}
#endif

#endif // __ADC_H_


