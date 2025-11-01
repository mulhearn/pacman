#ifndef __ADC_H_
#define __ADC_H_

#include "hw_access.h"

#ifdef __cplusplus
extern "C" {
#endif

// ASIC versions supported by this interface:
typedef enum {
    LARPIX_V3=0,
    UNKNOWN
} asic_version_t;

//set the ASIC version currently in use:
void asic_set_version(asic_version_t ver);

//print a summary of a 64-bit ASIC packet:
void asic_print_packet_summary(hw_u32_t * word);


// menu interface:
void asic_full_reset();
void asic_internal_reset();
void asic_toggle_version();
void asic_toggle_power();
void asic_config_root();
void asic_read_all();
void asic_hello();


// HELPERS:
hw_u32_t asic_calc_parity(hw_u32_t * word);
void     asic_config_write(hw_u32_t * word, hw_u8_t chip, hw_u8_t addr, hw_u8_t data);
void     asic_config_read(hw_u32_t * word, hw_u8_t chip, hw_u8_t addr);
void     asic_print(hw_u32_t * word);


#ifdef __cplusplus
}
#endif

#endif // __ADC_H_
