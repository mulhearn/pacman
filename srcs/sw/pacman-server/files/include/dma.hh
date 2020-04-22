#ifndef dma_hh
#define dma_hh

#include <cstdint>

// dma address space
// mm2s
#define DMA_MM2S_CTRL_REG 0x00
#define DMA_MM2S_STAT_REG 0x04
#define DMA_MM2S_CURR_REG 0x08
#define DMA_MM2S_TAIL_REG 0x10
#define DMA_MM2S_ADDR_REG 0x18
#define DMA_MM2S_LEN_REG  0x28
// s2mm
#define DMA_S2MM_CTRL_REG 0x30
#define DMA_S2MM_STAT_REG 0x34
#define DMA_S2MM_CURR_REG 0x38
#define DMA_S2MM_TAIL_REG 0x40
#define DMA_S2MM_ADDR_REG 0x48
#define DMA_S2MM_LEN_REG  0x58
// status bits
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
// control bits
#define DMA_RUN       0x00000001
#define DMA_RST       0x00000002
#define DMA_IOC_IRQEN 0x00001000
#define DMA_DLY_IRQEN 0x00002000
#define DMA_ERR_IRQEN 0x00004000

// descriptor chain
#define DESC_LEN  0x40
#define DESC_NEXT 0x00
#define DESC_ADDR 0x08
#define DESC_CTRL 0x18
#define DESC_STAT 0x1C
#define DESC_USER 0x20
// status bits
#define DESC_INTERR 0x10000000
#define DESC_SLVERR 0x20000000
#define DESC_DECERR 0x40000000
#define DESC_CMPLT  0x80000000
// control bits
#define DESC_ADDR_LEN 0x02FFFFFF

struct dma_desc {
  uint32_t* desc; // virtual address of descriptor
  dma_desc* next; // pointer to next descriptor in chain
  dma_desc* prev; // pointer to previous descriptor in chain
  char*     word; // virtual address of data word
  uint32_t  addr; // physical address of this descriptor
  uint32_t  word_addr; // physical address of this descriptor's data word
};

void memdump(void* virtual_address, int byte_count);

// basic dma
void dma_set(uint32_t* dma_virtual_address, int offset, uint32_t value);
uint32_t dma_get(uint32_t* dma_virtual_address, int offset);

void dma_print_status(uint32_t status);

void dma_s2mm_status(uint32_t* dma_virtual_address);
void dma_mm2s_status(uint32_t* dma_virtual_address);

uint32_t dma_mm2s_sync(uint32_t* dma_virtual_address);
uint32_t dma_s2mm_sync(uint32_t* dma_virtual_address);

// scatter / gather
bool dma_desc_cmplt(uint32_t* desc_virtual_address);
void dma_desc_print(uint32_t* desc_virtual_address);
void dma_desc_print(dma_desc* desc);

uint32_t addr_padding(uint32_t bytes, uint32_t addr_bndry);
dma_desc* init_circular_buffer(uint32_t* virtual_address, uint32_t start, uint32_t len, uint32_t word_len);

#endif
