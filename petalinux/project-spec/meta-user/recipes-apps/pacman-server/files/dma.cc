#ifndef dma_cc
#define dma_cc

#include <stdio.h>

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

uint32_t dma_set(uint32_t* dma_virtual_address, int offset, uint32_t value) {
    dma_virtual_address[offset>>2] = value;
}

uint32_t dma_get(uint32_t* dma_virtual_address, int offset) {
    return dma_virtual_address[offset>>2];
}

uint32_t dma_s2mm_sync(uint32_t* dma_virtual_address) {
    uint32_t s2mm_status = dma_get(dma_virtual_address, DMA_S2MM_STAT_REG);
    while(!(s2mm_status & (DMA_IOC_IRQ | DMA_ERR_IRQ)) || !(s2mm_status & DMA_IDLE)){
        s2mm_status = dma_get(dma_virtual_address, DMA_S2MM_STAT_REG);
    }
    return s2mm_status;
}

void dma_print_status(uint32_t status) {
    if (status & DMA_HALTED)   printf(" halted"); else printf(" running");
    if (status & DMA_IDLE)     printf(" idle"); else printf(" busy");
    if (status & DMA_SG_INCLD) printf(" SGIncld");
    if (status & DMA_INTERR) printf(" DMAIntErr");
    if (status & DMA_SLVERR) printf(" DMASlvErr");
    if (status & DMA_DECERR) printf(" DMADecErr");
    if (status & DMA_SG_INTERR) printf(" SGIntErr");
    if (status & DMA_SG_SLVERR) printf(" SGSlvErr");
    if (status & DMA_SG_DECERR) printf(" SGDecErr");
    if (status & DMA_IOC_IRQ) printf(" IOC_Irq");
    if (status & DMA_DLY_IRQ) printf(" Dly_Irq");
    if (status & DMA_ERR_IRQ) printf(" Err_Irq");
    printf("\n");
};

void dma_s2mm_status(uint32_t* dma_virtual_address) {
    uint32_t status = dma_get(dma_virtual_address, DMA_S2MM_STAT_REG);
    printf("Stream to memory-mapped status (0x%08x@0x%02x):", status, DMA_S2MM_STAT_REG);
    dma_print_status(status);
}

void dma_mm2s_status(uint32_t* dma_virtual_address) {
    uint32_t status = dma_get(dma_virtual_address, DMA_MM2S_STAT_REG);
    printf("Memory-mapped to stream status (0x%08x@0x%02x):", status, DMA_MM2S_STAT_REG);
    dma_print_status(status);
}

uint32_t dma_mm2s_sync(uint32_t* dma_virtual_address) {
    uint32_t mm2s_status =  dma_get(dma_virtual_address, DMA_MM2S_STAT_REG);
    while(!(mm2s_status & (DMA_IOC_IRQ | DMA_ERR_IRQ)) || !(mm2s_status & DMA_IDLE) ){
        mm2s_status =  dma_get(dma_virtual_address, DMA_MM2S_STAT_REG);
    }
    return mm2s_status;
}

void memdump(void* virtual_address, int byte_count) {
    char *p = (char*)virtual_address;
    int offset;
    for (offset = 0; offset < byte_count; offset++) {
        printf("%02x", p[offset]);
        if (offset % 4 == 3) { printf(" "); }
        if (offset % 32 == 31) { printf("\n"); }
    }
    printf("\n");
};

#endif
