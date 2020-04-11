#ifndef fw_addr_conf_hh
#define fw_addr_conf_hh

/* ~~~ start PACMAN-PL interface ~~~ */

#define PACMAN_ADDR 0x60000000
#define PACMAN_LEN  0x00010000

/* ~~~ end PACMAN-PL interface ~~~ */

/* ~~~ start DMA interface ~~~ */

#define DMA_ADDR 0x40400000
#define DMA_LEN  0x00010000

#define DMA_TX_ADDR   0x38000000
#define DMA_TX_MAXLEN 0x01000000

#define DMA_RX_ADDR   0x39000000
#define DMA_RX_MAXLEN 0x07000000

/* ~~~ end DMA interface ~~~ */

#endif
