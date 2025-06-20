#ifndef __RXTX_H_
#define __RXTX_H_

void rxtx_menu();

void toggle_tx_config();
void toggle_rx_config();
void read_rx_status();
void read_rx_look();
void read_tx_status();
void read_tx_look();
void toggle_tx_mask();
void zero_counts();
void dma_status();
void reset_dma();
void single_tx();
void single_rx();
void benchmark_dma_loopback();
void benchmark_dma_write();

#endif // __RXTX_H_


