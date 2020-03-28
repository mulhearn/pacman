#ifndef dma_hh
#define dma_hh

#include <cstdint>

#define DMA_MM2S_CTRL_REG 0x00
#define DMA_MM2S_STAT_REG 0x04
#define DMA_MM2S_ADDR_REG 0x18
#define DMA_MM2S_LEN_REG  0x28

#define DMA_S2MM_CTRL_REG 0x30
#define DMA_S2MM_STAT_REG 0x34
#define DMA_S2MM_ADDR_REG 0x48
#define DMA_S2MM_LEN_REG  0x58

#define DMA_HALTED    0x00000001
#define DMA_IDLE      0x00000002
#define DMA_SG_INCLD  0x00000008
#define DMA_INTERR    0x00000010
#define DMA_SLVERR    0x00000020
#define DMA_DECERR    0x00000040
#define DMA_SG_INTERR 0x00000100
#define DMA_SG_SLVERR 0x00000200
#define DMA_SG_DECERR 0x00000400
#define DMA_IOC_IRQ   0x00001000
#define DMA_DLY_IRQ   0x00002000
#define DMA_ERR_IRQ   0x00004000

#define DMA_RUN 0x00000001
#define DMA_RST 0x00000002
#define DMA_IOC_IRQEN 0x00001000
#define DMA_DLY_IRQEN 0x00002000
#define DMA_ERR_IRQEN 0x00004000

uint32_t dma_set(uint32_t* dma_virtual_address, int offset, uint32_t value);
uint32_t dma_get(uint32_t* dma_virtual_address, int offset);

void dma_print_status(uint32_t status);

void dma_s2mm_status(uint32_t* dma_virtual_address);
void dma_mm2s_status(uint32_t* dma_virtual_address);

uint32_t dma_mm2s_sync(uint32_t* dma_virtual_address);
uint32_t dma_s2mm_sync(uint32_t* dma_virtual_address);

void memdump(void* virtual_address, int byte_count);

#endif
