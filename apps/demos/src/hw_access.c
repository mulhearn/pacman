#include "xil_io.h"
#include "xtime_l.h"

#include "hw_access.h"


void init_axil_driver(){}

int axil_driver_status(){ return HW_SUCCESS; }

void clear_axil_driver_status() {}

hw_val_t axil_read_register  (hw_addr_t offset){
  return Xil_In32(AXIL_REGISTERS_BASEADDR+offset);
}

void     axil_write_register (hw_addr_t offset, hw_val_t value){
  Xil_Out32(AXIL_REGISTERS_BASEADDR+offset, value);
}

void init_dma_driver(){}

int dma_driver_status(){ return HW_SUCCESS; }

void clear_dma_driver_status() {}

hw_val_t dma_read_register  (hw_addr_t offset){
  return Xil_In32(DMA_REGISTERS_BASEADDR+offset);
}

void     dma_write_register (hw_addr_t offset, hw_val_t value){
  Xil_Out32(DMA_REGISTERS_BASEADDR+offset, value);
}

void init_dma_buffer(hw_addr_t baseaddr, hw_addr_t size){
}

hw_ptr_t dma_ptr(hw_addr_t addr){
  return (hw_ptr_t) addr;
}

static XTime G_START_TIME;
static XTime G_STOP_TIME;

void start_hw_timer(){
  XTime_GetTime(&G_START_TIME);
}
void stop_hw_timer(){
  XTime_GetTime(&G_STOP_TIME);
}

unsigned hw_timer_elapsed_us(){
  XTime elapsed_us = ((G_STOP_TIME - G_START_TIME) * 1000000ULL) / COUNTS_PER_SECOND ;
  return (unsigned) elapsed_us;
}
