#ifndef __RXTX_H_
#define __RXTX_H_

#include<stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

// RX/TX REGISTERS:

#define SCOPE_TX       0x0000
#define SCOPE_RX       0x4000
#define UART_GLOBAL    0x3F00
#define UART_BROADCAST 0x3B00

#define C_ADDR_RX_UART_STATUS       0x00
#define C_ADDR_RX_UART_CONFIG       0x04
#define C_ADDR_RX_UART_CHAN         0x08

#define C_ADDR_RX_UART_STARTS       0x20
#define C_ADDR_RX_UART_BEATS        0x24
#define C_ADDR_RX_UART_UPDATES      0x28
#define C_ADDR_RX_UART_LOST         0x2C

#define C_ADDR_RX_LOOK_SELECT       0xA0
#define C_ADDR_RX_LOOK_UA           0xA4
#define C_ADDR_RX_LOOK_UB           0xA8

#define C_ADDR_RX_BUFFER_STATUS     0xB0
#define C_ADDR_RX_BUFFER_CONFIG     0xB4
#define C_ADDR_RX_BUFFER_ENABLES    0xB8
#define C_ADDR_RX_PACMAN            0xBC

#define C_ADDR_RX_FIFO_CNT          0xF0
#define C_ADDR_RX_FIFO_MAX          0xF4
#define C_ADDR_RX_ZERO_CNTS         0xF8
#define C_ADDR_RX_HEARTBEAT_CONFIG  0xC0
#define C_ADDR_RX_ROLLOVER_CONFIG   0xC4
#define C_ADDR_RX_WORD_TYPE_LUT     0xC8
#define C_ADDR_RX_HEARTBEAT_HEADER  0xD0
#define C_ADDR_RX_ROLLOVER_HEADER   0xD4
#define C_ADDR_RX_TRIG_HEADER       0xD8
#define C_ADDR_RX_EOP_HEADER        0xDC

#define C_ADDR_TX_UART_STATUS   0x00
#define C_ADDR_TX_UART_CONFIG   0x04
#define C_ADDR_TX_UART_STARTS   0x20
#define C_ADDR_TX_UART_BEATS    0x24

#define C_ADDR_TX_LOOK_SELECT   0xA0
#define C_ADDR_TX_LOOK_UA       0xA4
#define C_ADDR_TX_LOOK_UB       0xA8
#define C_ADDR_TX_BUFFER_STATUS 0xB0
#define C_ADDR_TX_ZERO_CNTS     0xF8

// this is reserved in system-user.dtsi and located within the HP AXI interface for DMA (0x00000000 - 0x3FFFFFFF):
#define DMA_BUFFER_BASEADDR  0x20000000
#define DMA_BUFFER_SIZE      0x10000000  // 256 MB

#define TX_BD_BASEADDR       0x21000000
#define RX_BD_BASEADDR       0x22000000

// 40 uarts x 64 bits + 1-64 bit header => 328 bits = 0x148
// Note: DMA driver will alighn buffer *spacing* to 0x150
#define TX_PACKET_BYTES 0x148
#define TX_HEADER_BYTES 8
#define TX_PAYLOAD_U32_WORDS ((TX_PACKET_BYTES - TX_HEADER_BYTES)/4)
#define TX_HEADER_U32_WORDS  (TX_HEADER_BYTES/4)

// Buffer sizes:
// 1 single UART        (1+1)*24    =  48  = 0x30   <-- size MMMM=0x0001
// 40 UART              (40+1)*24   = 984  = 0x3D8  <-- typical test pattern size
// 40 UART + 3 Extra    (40+3+1)*24 = 1056 = 0x420  <-- max for CCCC=0x0001
//#define RX_BUF_BYTES 0x800
// Enough for single cycles, max (40 uarts + header + 3 T/S/HB) * 16 bytes = 0x2c0 bytes
// Each uart rx takes 10 cycles, so for 10 cycles, the maximum buffer size is:
//    (40 + 1 + 10*3)*16 = 0x470 (1136) bytes
// So the buffer size below is enough for more than 140 cycles (0x8C) which you should see in settings
// Note:  when switching to 64 bit timestamps, each cycle will take three times as long, and so this becomes:
//    (3*40 + 1 + 30*3)*24 = 5064 (0x13c8)
// and the buffer size below is enough for 32 (0x20)  cycles (about 1/4 of 0x8C)
// More directly, that is large enough for 682 words (0x2aa)
#define RX_BUF_BYTES 0x4000

#define RX_TRAILER_BYTES 24
#define RX_WORD_BYTES    24


#define TX_BATCH_NEXTDESC_ADDR       0x20000000
#define RX_BATCH_NEXTDESC_ADDR       0x20000004

// pacman-server hooks:
void init_rxtx(void);
void init_tx_descriptor_ring_mode(int ring_size);
void init_rx_descriptor_ring_mode(int ring_size);

void rx_disable_uart(unsigned chan);
void rx_enable_uart(unsigned chan);
bool rx_uart_is_enabled(unsigned chan);

// menu hooks:
void read_tx_status(void);
void read_tx_look(void);
void toggle_tx_config(void);
void toggle_tx_mask(void);

void read_rx_status(void);
void read_rx_look(void);
void toggle_rx_config(void);
void toggle_rx_buffer_config(void);
void toggle_rx_buffer_enables(void);
void zero_rxtx_counts(void);

void init_rxtx_descriptor_ring_mode(int ring_size);
void show_rxtx_bds(void);
void show_rxtx_head_tail(void);

void clear_rxtx_ioc(void);
void show_tx_buffer(void);
void show_rx_buffer(void);
void show_rx_transferred(void);

void single_tx(void);
void single_rx(void);

void batch_tx(void);
void batch_rx(void);


void benchmark_tx(void);
void benchmark_rxtx_loopback(void);

#ifdef __cplusplus
}
#endif

#endif // __RXTX_H_
