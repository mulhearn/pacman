#include "xil_io.h"

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

hw_ptr_t dma_ptr(hw_addr_t addr){
  return (hw_ptr_t) addr;
}
