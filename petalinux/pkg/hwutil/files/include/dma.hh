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

// Use 32-bit word addressing:
#define DMA_BYTES_PER_WORD 4

// TODO: confirm this is the limit:
#define DMA_RX_MAX_WORDS 0xFFFF

#define C_ADDR_DMA_TX_CONTROL 0x0000
#define C_ADDR_DMA_TX_STATUS  0x0004
#define C_ADDR_DMA_RX_CONTROL 0x0030
#define C_ADDR_DMA_RX_STATUS  0x0034

#define MASK_DMA_CR_RUN       0x0001
#define MASK_DMA_CR_RESET     0x0004

#define MASK_DMA_SR_HALTED    0x0001
#define MASK_DMA_SR_IDLE      0x0002



void init_dma();
void reset_dma();
void dma_status();

void set_dma_tx_to_run();
void set_dma_rx_to_run();

void clear_dma_rx_buffer(unsigned max_words = DMA_RX_MAX_WORDS);
void start_dma_rx(unsigned max_words = DMA_RX_MAX_WORDS);
int  wait_dma_rx_idle(unsigned timeout = 10000);
int  count_dma_rx_buffer(unsigned max_words = DMA_RX_MAX_WORDS, int verbose=0);

#endif
