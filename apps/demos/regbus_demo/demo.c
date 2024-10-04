#include <stdio.h>
#include "xparameters.h"
#include "xil_io.h"
#include "xstatus.h"
#include "xil_printf.h"
#include "sleep.h"


// Base address obtained through xparameters.h header file:
#define ADDR_AXIL_REGS  XPS_FPGA_AXI_S0_BASEADDR
// Alternative, the address can be read off from the address editor of the block diagram in vivado:
//#define ADDR_AXIL_REGS  0x40000000

void check_read_reg(){
  xil_printf("Reg0 -- 0x%x  \r\n", Xil_In32(ADDR_AXIL_REGS+0x0000));
  xil_printf("Reg1 -- 0x%x  \r\n", Xil_In32(ADDR_AXIL_REGS+0x0004));
  xil_printf("Reg2 -- 0x%x  \r\n", Xil_In32(ADDR_AXIL_REGS+0x0008));
  xil_printf("Reg3 -- 0x%x  \r\n", Xil_In32(ADDR_AXIL_REGS+0x000C));
}

void check_write_reg(){
  static unsigned count=0;
  
  xil_printf("Count is 0x%x  \r\n", count);

  Xil_Out32(ADDR_AXIL_REGS+0x0000, 0xAAAA0000 + count);
  Xil_Out32(ADDR_AXIL_REGS+0x0004, 0xBBBB0000 + count*2);

  count = (count + 1)&0xFFFF;
}

		
int main(){
  xil_printf("SANITY NUMBER:  1\r\n");
  xil_printf("Pac-Man Card Low-Level Hardware Testing (Development)\r\n");
  while(1){
    xil_printf("choose an option:\r\n");
    xil_printf("(1) test read registers (2) test write register \r\n");
      
    unsigned char c=inbyte();
    xil_printf("pressed:  %c\n\r", c);
    switch(c){
    case '1':
      check_read_reg();
      break;
    case '2':
      check_write_reg();
      break;
    default:
      xil_printf("invalid selection...\n\r");
    }
  }
  return 0;
}




