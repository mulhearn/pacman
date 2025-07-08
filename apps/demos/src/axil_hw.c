#include "xil_io.h"

#include "hardware.h"
#include "axil_hw.h"

void init_axil_hw(){}

int axil_status(){ return HW_SUCCESS; }

void axil_clear_status() {}

hw_val_t axil_read_register  (hw_adr_t offset){
  return Xil_In32(ADDR_AXIL_REGS+offset);  
}

void     axil_write_register (hw_adr_t offset, hw_val_t value){
  Xil_Out32(ADDR_AXIL_REGS+offset, value);  
}




