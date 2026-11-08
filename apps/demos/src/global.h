#ifndef __GLOBAL_H_
#define __GLOBAL_H_

#ifdef __cplusplus
extern "C" {
#endif

// GLOBAL REGISTERS:

#define SCOPE_GLOBAL 0xF000

#define C_ADDR_GLOBAL_STATUS          0x000
#define C_ADDR_GLOBAL_ENABLES         0x010
#define C_ADDR_GLOBAL_LEDS            0x014
#define C_ADDR_GLOBAL_SCRATCH_A       0x020
#define C_ADDR_GLOBAL_SCRATCH_B       0x024
#define C_ADDR_GLOBAL_FIRMWARE_MAJOR  0xF10
#define C_ADDR_GLOBAL_FIRMWARE_MINOR  0xF14
#define C_ADDR_GLOBAL_FIRMWARE_LETTER 0xF18
#define C_ADDR_GLOBAL_HARDWARE_MAJOR  0xF20
#define C_ADDR_GLOBAL_HARDWARE_MINOR  0xF24
#define C_ADDR_GLOBAL_HARDWARE_LETTER 0xF28
#define C_ADDR_GLOBAL_SYNTHESIS_DATE  0xF30
#define C_ADDR_GLOBAL_GIT_HASH_UPPER  0xF40
#define C_ADDR_GLOBAL_GIT_HASH_LOWER  0xF44
#define C_ADDR_GLOBAL_VIVADO_MAJOR    0xF50
#define C_ADDR_GLOBAL_VIVADO_MINOR    0xF54

void get_synthesis_date_string(char * buffer, size_t buffer_size);
void get_git_hash_string(char * buffer, size_t buffer_size);

void read_global_status();
void toggle_global_scratch();
void toggle_global_enables();

#ifdef __cplusplus
}
#endif

#endif // __GLOBAL_H_


