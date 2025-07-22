#ifndef __GLOBAL_H_
#define __GLOBAL_H_

// GLOBAL REGISTERS:

#define SCOPE_GLOBAL 0xF000

#define C_ADDR_GLOBAL_STATUS    0x000
#define C_ADDR_GLOBAL_ENABLES   0x010
#define C_ADDR_GLOBAL_LEDS      0x014
#define C_ADDR_GLOBAL_SCRA      0x020
#define C_ADDR_GLOBAL_SCRB      0x024
#define C_ADDR_GLOBAL_FW_MAJOR  0xF10
#define C_ADDR_GLOBAL_FW_MINOR  0xF14
#define C_ADDR_GLOBAL_FW_BUILD  0xF18
#define C_ADDR_GLOBAL_HW_CODE   0xF1C

void read_global_status();
void toggle_global_scratch();
void toggle_global_enables();

#endif // __GLOBAL_H_


