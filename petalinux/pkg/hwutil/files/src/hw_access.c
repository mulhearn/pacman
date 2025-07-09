#include "hw_access.h"
#include <sys/mman.h>
#include <fcntl.h>

// move to header?
#define DMA_REGISTERS_LEN      0x00010000
#define AXIL_REGISTERS_LEN     0x00010000

static volatile uint32_t * G_AXIL  = NULL;

void init_axil_driver(){
  clear_axil_driver_status();
  
  printf("INFO:  Opening /dev/mem.\n");
  int dh = open("/dev/mem", O_RDWR|O_SYNC);

  printf("INFO:  Initializing PACMAN AXI-Lite interface.\n");
  G_AXIL = (uint32_t*) mmap(NULL, AXIL_REGISTERS_LEN, PROT_READ|PROT_WRITE, MAP_SHARED, dh, AXIL_REGISTERS_BASEADDR);

  unsigned fwmajor = G_AXIL[0XFF10>>2];
  unsigned fwminor = G_AXIL[0XFF14>>2];
  unsigned fwbuild = G_AXIL[0XFF18>>2];
  unsigned hwcode  = G_AXIL[0XFF1C>>2];

  printf("INFO:  Running pacman firmware version %d.%d (Build: 0x%x  HW Code:  0x%x)\n", fwmajor, fwminor, fwbuild, hwcode);
}

int axil_driver_status(){ return HW_SUCCESS; }

void clear_axil_driver_status() {}

hw_val_t axil_read_register  (hw_addr_t offset){
  return G_AXIL[offset>>2];
}

void     axil_write_register (hw_addr_t offset, hw_val_t value){
  G_AXIL[offset>>2] = value;
}

static volatile uint32_t * G_DMA  = NULL;

void init_dma_driver(){
  clear_dma_driver_status();
  printf("INFO:  Opening /dev/mem.\n");
  int dh = open("/dev/mem", O_RDWR|O_SYNC);

  printf("INFO:  Initializing DMA contol interface (AXIL).\n");
  G_DMA = (uint32_t*)mmap(NULL, DMA_REGISTERS_LEN, PROT_READ|PROT_WRITE, MAP_SHARED, dh, DMA_REGISTERS_BASEADDR);
}

int dma_driver_status(){ return HW_SUCCESS; }

void clear_dma_driver_status() {}

hw_val_t dma_read_register  (hw_addr_t offset){
  return G_DMA[offset>>2];
}

void     dma_write_register (hw_addr_t offset, hw_val_t value){
  G_DMA[offset>>2] = value;
}

void init_dma_buffer(hw_addr_t baseaddr, hw_addr_t size){
}

hw_ptr_t dma_ptr(hw_addr_t addr){
  return NULL;
}

void start_hw_timer(){
}
void stop_hw_timer(){
}

unsigned hw_timer_elapsed_us(){
  unsigned elapsed_us = 1;
  return (unsigned) elapsed_us;
}
