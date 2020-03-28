#ifndef dma_cc
#define dma_cc

#include <cstdint>
#include <cstdio>

#include "dma.hh"

uint32_t dma_set(uint32_t* dma_virtual_address, int offset, uint32_t value) {
    dma_virtual_address[offset>>2] = value;
}

uint32_t dma_get(uint32_t* dma_virtual_address, int offset) {
    return dma_virtual_address[offset>>2];
}

void dma_print_status(uint32_t status) {
    //std::this_thread::sleep_for(std::chrono::milliseconds(100));
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
}

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
    while(!(mm2s_status & (DMA_IOC_IRQ | DMA_ERR_IRQ)) || !(mm2s_status & DMA_IDLE)){
        mm2s_status =  dma_get(dma_virtual_address, DMA_MM2S_STAT_REG);
        //dma_mm2s_status(dma_virtual_address); //print status
        if (mm2s_status & DMA_HALTED) break;
    }
    return mm2s_status;
}

uint32_t dma_s2mm_sync(uint32_t* dma_virtual_address) {
    uint32_t s2mm_status = dma_get(dma_virtual_address, DMA_S2MM_STAT_REG);
    while(!(s2mm_status & (DMA_IOC_IRQ | DMA_ERR_IRQ)) || !(s2mm_status & DMA_IDLE)){
        s2mm_status = dma_get(dma_virtual_address, DMA_S2MM_STAT_REG);
        //dma_s2mm_status(dma_virtual_address); // print status
        if (s2mm_status & DMA_HALTED) break;
    }
    return s2mm_status;
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
}

#endif
