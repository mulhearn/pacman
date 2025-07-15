#include "hw_access.h"
#include <sys/mman.h>
#include <fcntl.h>
#include <time.h>

// move to header?
#define DMA_REGISTERS_LEN      0x00010000
#define AXIL_REGISTERS_LEN     0x00010000

//
// AXI-Lite Registers:
//

static volatile uint32_t * G_AXIL  = NULL;

void init_axil_driver(){
  clear_axil_driver_status();

  printf("INFO:  Opening /dev/mem.\n");
  int dh = open("/dev/mem", O_RDWR|O_SYNC);
  if (dh < 0) {
    printf("ERROR:  Failed to open /dev/mem");
    return;
  }

  printf("INFO:  Initializing PACMAN AXI-Lite interface of size %d at 0x%X\n", AXIL_REGISTERS_LEN, AXIL_REGISTERS_BASEADDR);
  G_AXIL = (uint32_t*) mmap(NULL, AXIL_REGISTERS_LEN, PROT_READ|PROT_WRITE, MAP_SHARED, dh, AXIL_REGISTERS_BASEADDR);
  if (G_AXIL == MAP_FAILED) {
    printf("ERROR:  mmap failed");
    close(dh);
    return;
  }
  close(dh);

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

//
// DMA Registers (AXI-Lite Interface):
//

static volatile uint32_t * G_DMA  = NULL;

void init_dma_driver(){
  clear_dma_driver_status();
  printf("INFO:  Opening /dev/mem.\n");
  int dh = open("/dev/mem", O_RDWR|O_SYNC);
  if (dh < 0) {
    printf("ERROR:  Failed to open /dev/mem");
    return;
  }

  printf("INFO:  Initializing DMA AXI-Lite interface of size %d at 0x%X\n", DMA_REGISTERS_LEN, DMA_REGISTERS_BASEADDR);
  G_DMA = (uint32_t*)mmap(NULL, DMA_REGISTERS_LEN, PROT_READ|PROT_WRITE, MAP_SHARED, dh, DMA_REGISTERS_BASEADDR);
  if (G_DMA == MAP_FAILED) {
    printf("ERROR:  mmap failed");
    close(dh);
    return;
  }

  close(dh);
}

int dma_driver_status(){ return HW_SUCCESS; }

void clear_dma_driver_status() {}

hw_val_t dma_read_register  (hw_addr_t offset){
  return G_DMA[offset>>2];
}

void     dma_write_register (hw_addr_t offset, hw_val_t value){
  G_DMA[offset>>2] = value;
}

//
// DMA buffer:
//

static volatile uint32_t * G_BUF  = NULL;
static hw_addr_t G_BUF_BASEADDR = 0;
static hw_addr_t G_BUF_SIZE = 0;

void init_dma_buffer(hw_addr_t baseaddr, hw_addr_t size){
  G_BUF_BASEADDR = baseaddr;
  G_BUF_SIZE     = size;

  printf("INFO:  Opening /dev/mem.\n");
  int dh = open("/dev/mem", O_RDWR|O_SYNC);
    if (dh < 0) {
    printf("ERROR:  Failed to open /dev/mem");
    return;
  }

  printf("INFO:  Initializing DMA buffer of size %d at 0x%X\n", G_BUF_SIZE, G_BUF_BASEADDR);
  G_BUF = (uint32_t*) mmap(NULL, G_BUF_SIZE, PROT_READ|PROT_WRITE, MAP_SHARED, dh, G_BUF_BASEADDR);
  if (G_BUF == MAP_FAILED) {
    printf("ERROR:  mmap failed");
    close(dh);
    return;
  }
  close(dh);
}

hw_ptr_t dma_ptr(hw_addr_t addr){
  if (addr < G_BUF_BASEADDR)
    return NULL;
  hw_addr_t offset = addr - G_BUF_BASEADDR;
  if (offset > G_BUF_SIZE)
    return NULL;
  return &G_BUF[offset>>2];
}

//
// Timer:
//

static struct timespec start;
static struct timespec stop;


void start_hw_timer(){
  clock_gettime(CLOCK_MONOTONIC, &start);
}
void stop_hw_timer(){
  clock_gettime(CLOCK_MONOTONIC, &stop);
}

unsigned hw_timer_elapsed_us(){
  long seconds        = stop.tv_sec  - start.tv_sec;
  long nanoseconds    = stop.tv_nsec - start.tv_nsec;
  unsigned elapsed_us = seconds * 1000000 + nanoseconds / 1000;
  return elapsed_us;
}
