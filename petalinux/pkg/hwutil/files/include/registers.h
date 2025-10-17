#ifndef __REGISTERS_H__
#define __REGISTERS_H__

#include <stdint.h>

// TIMING REGISTERS:
#define C_SCOPE_ATC 0xE000


#define C_ADDR_ATC_STATUS          0x000 //read only
#define C_ADDR_ATC_TIMESTAMP       0x004 //read only

#define C_ADDR_ATC_POKE_C          0x0C0
#define C_ADDR_ATC_POKE_D          0x0D0

#define C_ADDR_ATC_CONFIG_REQ      0x100
#define C_ADDR_ATC_POLARITY        0x108
#define C_ADDR_ATC_LOGIC           0x10C
#define C_ADDR_ATC_DST_LEMO_A      0x110
#define C_ADDR_ATC_DST_LEMO_B      0x114
#define C_ADDR_ATC_DST_POKE_C      0x118
#define C_ADDR_ATC_DST_POKE_D      0x11C
#define C_ADDR_ATC_DST_LOGIC_E     0x120
#define C_ADDR_ATC_DST_LOGIC_F     0x124

#define C_ADDR_ATC_COUNT_REQ       0x200
#define C_ADDR_ATC_COUNT           0x204 //read only

// ADC registers:
#define C_SCOPE_ADC 0xD000
#define C_ADDR_ADC_STATUS   0x100
#define C_ADDR_ADC_LOOK     0x104
#define C_ADDR_ADC_LAST     0x108
#define C_ADDR_ADC_STATE    0x10C
#define C_ADDR_ADC_CONFIG   0x110
#define C_ADDR_ADC_CLKPAR   0x114
#define C_ADDR_ADC_COMMAND  0x118
#define C_ADDR_ADC_SCRATCH  0x200
#define C_ADDR_ADC_ROA      0x204


#endif // __REGISTERS_H__
