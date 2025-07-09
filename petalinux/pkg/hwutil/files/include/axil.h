#ifndef __AXIL_H__
#define __AXIL_H__

#include <stdint.h>

// GLOBAL REGISTERS:
#define C_SCOPE_GLOBAL          0xF000
#define C_ADDR_GLOBAL_SCRA      0xF00
#define C_ADDR_GLOBAL_SCRB      0xF04
#define C_ADDR_GLOBAL_FW_MAJOR  0xF10
#define C_ADDR_GLOBAL_FW_MINOR  0xF14
#define C_ADDR_GLOBAL_FW_BUILD  0xF18
#define C_ADDR_GLOBAL_HW_CODE   0xF1C
#define C_ADDR_GLOBAL_ENABLES   0xF20
#define C_ADDR_GLOBAL_STATUS    0xF30
#define C_ADDR_GLOBAL_LEDS      0xF34
#define C_ADDR_GLOBAL_ADC_LOOK  0xF40

// TIMING REGISTERS:
#define C_SCOPE_TIMING 0xE000

#define C_ADDR_TIMING_STATUS          0x000
#define C_ADDR_TIMING_STAMP           0x004
#define C_ADDR_TIMING_POKE_C          0x010
#define C_ADDR_TIMING_POKE_D          0x014
#define C_ADDR_TIMING_START_COUNTS    0x0B0
#define C_ADDR_TIMING_STOP_COUNTS     0x0B4
#define C_ADDR_TIMING_RESET_COUNTS    0x0B8

#define C_ADDR_TIMING_COUNT_LEMO_A_F  0x220
#define C_ADDR_TIMING_COUNT_LEMO_B_F  0x224
#define C_ADDR_TIMING_COUNT_LEMO_A_S  0x230
#define C_ADDR_TIMING_COUNT_LEMO_B_S  0x234
#define C_ADDR_TIMING_COUNT_POKE_C_S  0x238
#define C_ADDR_TIMING_COUNT_POKE_D_S  0x23C
#define C_ADDR_TIMING_COUNT_TS        0x244
#define C_ADDR_TIMING_COUNT_G_FIRST   0x250
#define C_ADDR_TIMING_COUNT_H_FIRST   0x280

#define C_ADDR_TIMING_CONFIG_POLARITY 0x440
#define C_ADDR_TIMING_CONFIG_TS       0x444
#define C_ADDR_TIMING_CONFIG_G_FIRST  0x450
#define C_ADDR_TIMING_CONFIG_H_FIRST  0x480

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

// UART RX/TX REGISTERS:
#define SCOPE_TX       0x0000
#define SCOPE_RX       0x4000
#define UART_GLOBAL    0x3F00
#define UART_BROADCAST 0x3B00

#define C_ADDR_RX_STATUS    0x00
#define C_ADDR_RX_CONFIG    0x04
#define C_ADDR_RX_LOOK_A    0x10
#define C_ADDR_RX_LOOK_B    0x14
#define C_ADDR_RX_LOOK_C    0x18
#define C_ADDR_RX_LOOK_D    0x1C
#define C_ADDR_RX_STARTS    0x20
#define C_ADDR_RX_BEATS     0x24
#define C_ADDR_RX_UPDATES   0x28
#define C_ADDR_RX_LOST      0x2C
#define C_ADDR_RX_NCHAN     0x50
#define C_ADDR_RX_GSTATUS   0xA0
#define C_ADDR_RX_GFLAGS    0xA4
#define C_ADDR_RX_ZERO_CNTS 0xA8
#define C_ADDR_RX_FRCNT     0xB0
#define C_ADDR_RX_FWCNT     0xB4
#define C_ADDR_RX_DMAITR    0xB8

#define C_ADDR_TX_STATUS    0x00
#define C_ADDR_TX_CONFIG    0x04
#define C_ADDR_TX_LOOK_C    0x18
#define C_ADDR_TX_LOOK_D    0x1C
#define C_ADDR_TX_GFLAGS    0x20
#define C_ADDR_TX_STARTS    0x30
#define C_ADDR_TX_NCHAN     0x40

uint32_t  get_axil_status();
void      clear_axil_status();
void      init_axil();
void      close_axil();

void      write_axil(uint32_t addr, uint32_t value);
uint32_t  read_axil(uint32_t addr);

#endif // __AXIL_H__
