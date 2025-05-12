#ifndef axil_hh
#define axil_hh

// GLOBAL REGISTERS:
#define SCOPE_GLOBAL            0xFF00
#define C_ADDR_GLOBAL_SCRA      0x00
#define C_ADDR_GLOBAL_SCRB      0x04
#define C_ADDR_GLOBAL_FW_MAJOR  0x10
#define C_ADDR_GLOBAL_FW_MINOR  0x14
#define C_ADDR_GLOBAL_FW_BUILD  0x18
#define C_ADDR_GLOBAL_HW_CODE   0x1C
#define C_ADDR_GLOBAL_ENABLES   0x20
#define C_ADDR_GLOBAL_STATUS    0x30
#define C_ADDR_GLOBAL_LEDS      0x34
#define C_ADDR_GLOBAL_ADC_LOOK  0x40

// TIMING REGISTERS:
#define SCOPE_TIMING            0xFE00
#define C_ADDR_TIMING_STATUS    0x00
#define C_ADDR_TIMING_STAMP     0x04
#define C_ADDR_TIMING_TRIG      0x20
#define C_ADDR_TIMING_SYNC      0x24

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
  
#endif
