#ifndef __GLOBAL_H_
#define __GLOBAL_H_

// GLOBAL REGISTERS:

#define SCOPE_GLOBAL 0xF000
#define C_ADDR_GLOBAL_SCRA      0xF00
#define C_ADDR_GLOBAL_SCRB      0xF04
#define C_ADDR_GLOBAL_FW_MAJOR  0xF10
#define C_ADDR_GLOBAL_FW_MINOR  0xF14
#define C_ADDR_GLOBAL_FW_BUILD  0xF18
#define C_ADDR_GLOBAL_HW_CODE   0xF1C
#define C_ADDR_GLOBAL_ENABLES   0xF20
#define C_ADDR_GLOBAL_LEDS      0xF34
#define C_ADDR_GLOBAL_ADC_LOOK  0xF40

void read_global_status();
void toggle_global_scratch();
void toggle_global_enables();

#endif // __GLOBAL_H_


