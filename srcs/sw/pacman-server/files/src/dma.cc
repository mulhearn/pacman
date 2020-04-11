#ifndef dma_cc
#define dma_cc

#include <cstdint>
#include <cstdio>
#include <cassert>
#include <cstring>

#include "dma.hh"

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

void dma_set(uint32_t* dma_virtual_address, int offset, uint32_t value) {
  dma_virtual_address[offset>>2] = value;
}

uint32_t dma_get(uint32_t* dma_virtual_address, int offset) {
  return dma_virtual_address[offset>>2];
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

bool dma_desc_cmplt(uint32_t* desc_virtual_address) {
  return dma_get(desc_virtual_address, DESC_STAT) & DESC_CMPLT;
}

void dma_desc_print(uint32_t* desc_virtual_address) {
  uint32_t next = dma_get(desc_virtual_address, DESC_NEXT);
  uint32_t addr = dma_get(desc_virtual_address, DESC_ADDR);
  uint32_t ctrl = dma_get(desc_virtual_address, DESC_CTRL);
  uint32_t stat = dma_get(desc_virtual_address, DESC_STAT);
  printf("Descriptor");
  printf(" next 0x%08x", next);
  printf(" addr: 0x%08x", addr);
  printf(" len: %d", ctrl & DESC_ADDR_LEN); 
  if (stat & DESC_INTERR) printf(" DMAIntErr");
  if (stat & DESC_SLVERR) printf(" DMASlvErr");
  if (stat & DESC_DECERR) printf(" DMADecErr");
  if (stat & DESC_CMPLT)  printf(" Complete"); else printf(" Not Complete");
  printf("\n");
}

uint32_t addr_padding(uint32_t bytes, uint32_t addr_bndry) {
  // calculates padding such that addr + addr_padding(nbytes, addr_bndry) is the next address boundary relative to addr
  // e.g. for addr = 0x0000_0000, nbytes = 52, addr_bndry = 64 => addr_padding = 12
  // so addr + addr_padding = 0x0000_0040
  return bytes % addr_bndry ? addr_bndry - bytes % addr_bndry : 0;
}

dma_desc* init_circular_buffer(uint32_t* virtual_address, uint32_t start, uint32_t len, uint32_t word_len) {
  // Sets up the descriptor chain for a circular DMA buffer (with proper address alignment)
  // Each chunk within the buffer is a 52-byte descriptor followed by a `word_len`-byte word
  //
  // virtual_address : virtual memory address for start of buffer
  // start : physical memory address for start of buffer
  // len : total length available to allocate in bytes
  // word_len : length of each word (1 word to 1 buffer descriptor)
  //
  // returns : bytes associated with each descriptor + word chunk
  
  uint32_t desc_len = DESC_LEN; // bytes
  desc_len += addr_padding(desc_len, 64);
  word_len += addr_padding(word_len, 64);
  uint32_t chunk_len = desc_len + word_len;
  
  // make sure chunks will fall on address boundaries
  printf("Init circular buffer with %d-byte chunks\n", chunk_len);
  assert(desc_len % 64 == 0); // insure descriptors fall on addr boundaries
  assert(chunk_len % 64 == 0); // insure chunks will fall on addr boundaries
  assert(word_len % 64 == 0); // insure words will fall on addr boundaries
  memset(virtual_address, 0, len);
  
  uint32_t  buffer_len = len / chunk_len; // words
  dma_desc* buffer = new dma_desc[buffer_len];
  uint32_t* chunk = virtual_address;
  uint32_t  chunk_addr = start;
  printf("Create buffer of %d words @ 0x%08x\n", buffer_len, start);
  for(uint32_t i = 0; i < buffer_len-1; i++) {
    buffer[i].desc = chunk;
    buffer[i].next = &buffer[i + 1];
    buffer[i].prev = i > 0 ? &buffer[i - 1] : &buffer[buffer_len - 1];
    buffer[i].word = (char*)chunk + desc_len;
    buffer[i].addr = chunk_addr;
    buffer[i].word_addr = chunk_addr + desc_len;

    dma_set(chunk, DESC_ADDR, buffer[i].word_addr);
    dma_set(chunk, DESC_CTRL, word_len & DESC_ADDR_LEN);
    dma_set(chunk, DESC_NEXT, buffer[i].addr + chunk_len);

    if (i < 3) {
      printf("Chunk desc @ %p\n", (void*)buffer[i].desc);
      printf("\tSelf @ %p\n", (void*)&buffer[i]);
      printf("\tNext @ %p\n", (void*)buffer[i].next);
      printf("\tPrev @ %p\n", (void*)buffer[i].prev);
      printf("\tWord @ %p\n", (void*)buffer[i].word);
      printf("\tAddr = %p\n", (void*)buffer[i].addr);
      printf("\tWord addr = %p\n", (void*)buffer[i].word_addr);
      dma_desc_print(buffer[i].desc);
    } else if (i == 4) { printf("...\n"); }

    chunk += chunk_len/sizeof(*virtual_address);
    chunk_addr += chunk_len;
  }
  buffer[buffer_len-1].desc = chunk;
  buffer[buffer_len-1].next = buffer;
  buffer[buffer_len-1].prev = &buffer[buffer_len - 2];
  buffer[buffer_len-1].word = (char*)chunk + desc_len;
  buffer[buffer_len-1].addr = chunk_addr;
  buffer[buffer_len-1].word_addr = chunk_addr + desc_len;
  
  dma_set(chunk, DESC_ADDR, buffer[buffer_len-1].word_addr);
  dma_set(chunk, DESC_CTRL, word_len & DESC_LEN);
  dma_set(chunk, DESC_NEXT, start);

  printf("Circular buffer initialzed\n");
  return buffer;
}

#endif
