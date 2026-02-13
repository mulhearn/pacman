#ifndef ASIC_H
#define ASIC_H

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

//get the ASIC version currently in use:
asic_version_t asic_get_version();

//print a summary of a 64-bit ASIC packet:
void asic_print_packet_summary(hw_u32_t * word);

//access fields from an ASIC configuration word:
hw_u8_t asic_config_get_chip  (hw_u32_t * word);
hw_u8_t asic_config_get_addr  (hw_u32_t * word);
hw_u8_t asic_config_get_value (hw_u32_t * word);

void asic_batch_tx(hw_u32_t * payload, hw_u32_t n);
hw_u32_t asic_calc_parity(hw_u32_t * word);
void asic_config_write(hw_u32_t * word, hw_u8_t chip, hw_u8_t addr, hw_u8_t data);
void asic_config_read(hw_u32_t * word, hw_u8_t chip, hw_u8_t addr);

#ifdef __cplusplus
}
#endif

#endif // ASIC_H
