#ifndef addr_conf_hh
#define addr_conf_hh

//
// pacman-server address space, at top level:
//
// Address less than PACMAN_SERVER_VIRTUAL_START => real hardware address (AXI-Lite Interface)
// Else address less than PACMAN_SERVER_I2C_START => virtual address
// Address >- PACMAN_SERVER_I2C_START => virtual I2C address
//

// Start of pacman-server virtual address space
#define PACMAN_SERVER_VIRTUAL_START 0x00010000
// Start of pacman-server virtual address space
#define PACMAN_SERVER_I2C_START     0x00024000

// PACMAN AXI-Lite interface HW Address:
#define PACMAN_AXIL_ADDR 0x40000000
#define PACMAN_AXIL_HIGH 0x4000FFFF
#define PACMAN_AXIL_LEN  0x00010000

// PACMAN DMA interface HW Address:
#define DMA_ADDR 0x40400000
#define DMA_HIGH 0x4040FFFF
#define DMA_LEN  0x00010000


// TODO:  With Simple DMA these can get significantly smaller...
#define DMA_TX_ADDR   0x30000000
#define DMA_TX_MAXLEN 0x01000000

#define DMA_RX_ADDR   0x31000000
#define DMA_RX_MAXLEN 0x0F000000

#endif
