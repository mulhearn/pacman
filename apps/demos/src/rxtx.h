#ifndef __RXTX_H_
#define __RXTX_H_

#ifdef __cplusplus
extern "C" {
#endif

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
#define C_ADDR_RX_GCONFIG   0xA4
#define C_ADDR_RX_ZERO_CNTS 0xA8
#define C_ADDR_RX_FRCNT     0xB0
#define C_ADDR_RX_FWCNT     0xB4
#define C_ADDR_RX_DMAITR    0xB8

#define C_ADDR_TX_STATUS    0x00
#define C_ADDR_TX_CONFIG    0x04
#define C_ADDR_TX_LOOK_C    0x18
#define C_ADDR_TX_LOOK_D    0x1C
#define C_ADDR_TX_STARTS    0x20
#define C_ADDR_TX_NCHAN     0x50
#define C_ADDR_TX_GSTATUS   0xA0
#define C_ADDR_TX_ZERO_CNTS 0xA8


// pacman-server hooks:
void init_rxtx(void);
void init_tx_descriptor_ring_mode(int ring_size);
void init_rx_descriptor_ring_mode(int ring_size);

// menu hooks:
void read_tx_status(void);
void read_tx_look(void);
void toggle_tx_config(void);
void toggle_tx_mask(void);

void read_rx_status(void);
void read_rx_look(void);
void toggle_rx_config(void);
void toggle_rx_global_config(void);
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
