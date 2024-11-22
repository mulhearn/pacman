#ifndef addr_conf_hh
#define addr_conf_hh

//
// pacman-server address space, at top level:
//
// All addresses less than PACMAN_AXIL_ADDR are treated as virtual addresses
// Addresses above this are treated as hardware addresses and read/write directly.
// 

// PACMAN AXI-Lite interface HW Address:
#define PACMAN_AXIL_ADDR 0x40000000
#define PACMAN_AXIL_HIGH 0x4000FFFF
#define PACMAN_AXIL_LEN  0x00010000

// PACMAN DMA interface HW Address:
#define DMA_ADDR 0x40400000
#define DMA_HIGH 0x4040FFFF
#define DMA_LEN  0x00010000

#define DMA_TX_ADDR   0x30000000
#define DMA_TX_MAXLEN 0x01000000

#define DMA_RX_ADDR   0x31000000
#define DMA_RX_MAXLEN 0x0F000000

#endif
