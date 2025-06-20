#ifndef __AXIL_H_
#define __AXIL_H_

#define ADDR_AXIL_REGS  XPAR_AXIL_TO_REGBUS_0_BASEADDR

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

// RX/TX REGISTERS:

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

// TIMING REGISTERS:
// Still changing... these are located in timing.c

// ADC REGISTERS:
// Still changing... these are located in adc.c

#endif // __AXIL_H_


