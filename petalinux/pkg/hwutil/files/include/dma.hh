#ifndef dma_hh
#define dma_hh

// PACMAN DMA interface HW Address:
#define DMA_ADDR 0x40400000
#define DMA_HIGH 0x4040FFFF
#define DMA_LEN  0x00010000

#define DMA_TX_ADDR   0x30000000
#define DMA_TX_MAXLEN 0x01000000

#define DMA_RX_ADDR   0x31000000
#define DMA_RX_MAXLEN 0x0F000000

void init_dma();
void reset_dma();
void dma_status();

#endif

