#include <stdio.h>
#include "xparameters.h"
#include "xtime_l.h"
#include "xil_io.h"
#include "xaxidma.h"
#include "xstatus.h"
#include "xil_printf.h"
#include "sleep.h"

#define ADDR_AXIL_REGS  XPAR_AXIL_TO_REGBUS_0_BASEADDR 

void read_demo_reg(){
  xil_printf("FIFO read------- 0x%x  \r\n", Xil_In32(ADDR_AXIL_REGS+0x0000));
  xil_printf("FIFO write------ 0x%x  \r\n", Xil_In32(ADDR_AXIL_REGS+0x0004));
  xil_printf("Config---------- 0x%x  \r\n", Xil_In32(ADDR_AXIL_REGS+0x0008));
  xil_printf("RO Test--------- 0x%x  \r\n", Xil_In32(ADDR_AXIL_REGS+0x000C));
}

void start_demo(unsigned lmask){
  unsigned config = ((0xFFFF&lmask)<<16) | 0x1;
  Xil_Out32(ADDR_AXIL_REGS+0x0008, config);
}

void stop_demo(){
  Xil_Out32(ADDR_AXIL_REGS+0x0008, 0x0);
}

void dma_status(){
  //xil_printf("DMA control register (MM2S) - 0x%x \r\n", Xil_In32(XPAR_AXI_DMA_0_BASEADDR+0x00));
  //xil_printf("DMA status register (MM2S)  - 0x%x \r\n", Xil_In32(XPAR_AXI_DMA_0_BASEADDR+0x04));

  unsigned cr = Xil_In32(XPAR_AXI_DMA_0_BASEADDR+0x30);
  unsigned sr = Xil_In32(XPAR_AXI_DMA_0_BASEADDR+0x34);
  xil_printf("DMA control register (S2MM) - 0x%x \r\n", cr);
  xil_printf("DMA status register (S2MM)  - 0x%x \r\n", sr);
  xil_printf("Control Bits: \r\n");
  xil_printf("RS (Run/Stop)-----%d\r\n", ((cr&0x00000001)!=0));
  xil_printf("Always One--------%d\r\n", ((cr&0x00000002)!=0));
  xil_printf("Reset-------------%d\r\n", ((cr&0x00000004)!=0));
  xil_printf("Keyhole-----------%d\r\n", ((cr&0x00000008)!=0));
  xil_printf("Cycle BD Enable---%d\r\n", ((cr&0x00000010)!=0));
  xil_printf("Always Zero-------%d\r\n", ((cr&0x00000FE0)!=0));
  xil_printf("Itr En (Comp)-----%d\r\n", ((cr&0x00001000)!=0));
  xil_printf("Itr En (Delay)----%d\r\n", ((cr&0x00002000)!=0));
  xil_printf("Itr En (Error)----%d\r\n", ((cr&0x00004000)!=0));
  xil_printf("Always Zero-------%d\r\n", ((cr&0x00008000)!=0));
  xil_printf("IRQ Threshold-----%d\r\n", ((cr&0x00FF0000)>>16));
  xil_printf("IRQ Delay---------%d\r\n", ((cr&0xFF000000)>>24));  
  xil_printf("Status Bits: \r\n");
  xil_printf("Halted------------%d\r\n", ((sr&0x00000001)!=0));
  xil_printf("Idle--------------%d\r\n", ((sr&0x00000002)!=0));
  xil_printf("Always Zero-------%d\r\n", ((sr&0x00000004)!=0));
  xil_printf("SGIncld-----------%d\r\n", ((sr&0x00000008)!=0));
  xil_printf("DMAIntErr---------%d\r\n", ((sr&0x00000010)!=0));
  xil_printf("DMASecErr---------%d\r\n", ((sr&0x00000020)!=0));
  xil_printf("DMADecErr---------%d\r\n", ((sr&0x00000040)!=0));
  xil_printf("Always Zero-------%d\r\n", ((sr&0x00000080)!=0));
  xil_printf("SGIntErr----------%d\r\n", ((sr&0x00000100)!=0));
  xil_printf("SGSecErr----------%d\r\n", ((sr&0x00000200)!=0));
  xil_printf("SGDecErr----------%d\r\n", ((sr&0x00000400)!=0));
  xil_printf("Always Zero-------%d\r\n", ((sr&0x00000800)!=0));
  xil_printf("Itr (IOC)---------%d\r\n", ((sr&0x00000100)!=0));
  xil_printf("Itr (Delay)-------%d\r\n", ((sr&0x00000200)!=0));
  xil_printf("Itr (Error)-------%d\r\n", ((sr&0x00000400)!=0));
  xil_printf("Always Zero-------%d\r\n", ((sr&0x00000800)!=0));
  xil_printf("Stat Irq Thresh---%d\r\n", ((cr&0x00FF0000)>>16));
  xil_printf("Stay Irq Delay----%d\r\n", ((cr&0xFF000000)>>24));  
}

void reset_dma(){
  // Using XPAR_AXI_DMA_0_BASEADDR  defined in xparameters.h

  xil_printf("*** Sending DMA reset*** \r\n");
  Xil_Out32(XPAR_AXI_DMA_0_BASEADDR+0x30, 0x04);

  unsigned timeout = 10;
  while(timeout){
    unsigned cr_s2mm = Xil_In32(XPAR_AXI_DMA_0_BASEADDR+0x30);
    if ((cr_s2mm&0x4)==0)
      break;
    xil_printf("*** waiting on reset *** \r\n");
    timeout--;
  }
  if (! timeout) {
    xil_printf("*** ERROR:  failed to reset... *** \r\n");
    return;
  } else {
    xil_printf("*** DMA reset complete. *** \r\n");
  }
  dma_status();
}


//#define ADDR_DMA        XPAR_AXI_DMA_0_BASEADDR

void single_read_dma(){
  unsigned rx_base = 0x1100000;
  u32 *rx_buf = (u32 *)rx_base;
  unsigned words = 4;
  
  xil_printf("*** Sending run*** \r\n");
  Xil_Out32(XPAR_AXI_DMA_0_BASEADDR+0x30, 0x01);

  dma_status();
  
  for (int i=0; i<words; i++)
    rx_buf[i] = 0x0;
  
  Xil_DCacheFlushRange((UINTPTR)rx_buf, words*4);
    
  xil_printf("*** Sending read *** \r\n");    
  Xil_Out32(XPAR_AXI_DMA_0_BASEADDR+0x48, (u32) rx_buf);
  Xil_Out32(XPAR_AXI_DMA_0_BASEADDR+0x58, words*4);

  unsigned timeout = 10000;
  unsigned start = 1;
  while(timeout){
    unsigned sr_s2mm = Xil_In32(XPAR_AXI_DMA_0_BASEADDR+0x34);
    if ((sr_s2mm&0x2)!=0) 
      break;
    if (start){
      xil_printf("*** waiting for idle *** \r\n");
      start = 0;
    }
    usleep(1000);
    timeout--;
  }
  if (! timeout) {
    xil_printf("*** ERROR:  failed to reach idle before timeout! *** \r\n");
    return;
  }

  dma_status();
  
  Xil_DCacheInvalidateRange((UINTPTR) rx_buf, words*4);
  for (int i=0; i<words; i++)
    xil_printf("received[%d]:  0x%x\r\n", i, rx_buf[i]);
  
}

void check_dma(){
  unsigned rx_base = 0x1100000;
  u32 *rx_buf = (u32 *)rx_base;
  unsigned timeout;
  unsigned bytes = 4; // bytes per word (32 bit words)
  unsigned words = 4; // words per payload (128 bit responses)
  unsigned payloads = 32; // payloads per packet 
  unsigned packets = 1024; // packets to read
  XTime start_time;
  XTime stop_time;

  
  reset_dma();
  dma_status();

  xil_printf("*** Sending run*** \r\n");
  Xil_Out32(XPAR_AXI_DMA_0_BASEADDR+0x30, 0x01);

  dma_status();
  start_demo(0xF);

  for (int i=0; i<packets*payloads*words; i++)
    rx_buf[i] = 0x0;  
  Xil_DCacheFlushRange((UINTPTR)rx_buf, packets*payloads*words*bytes);

  XTime_GetTime(&start_time);
  
  for (int i=0;i<packets; i++){
    Xil_Out32(XPAR_AXI_DMA_0_BASEADDR+0x48, (u32) &rx_buf[payloads*words*i]);
    Xil_Out32(XPAR_AXI_DMA_0_BASEADDR+0x58, payloads*words*bytes);
    
    timeout = 10000;
    while(timeout){
      unsigned sr_s2mm = Xil_In32(XPAR_AXI_DMA_0_BASEADDR+0x34);
      if ((sr_s2mm&0x2)!=0) 
	break;
      //usleep(1);
      timeout--;
    }
    if (! timeout) {
      xil_printf("*** ERROR:  failed to reach idle before timeout! *** \r\n");
      return;
    }
  }
  XTime_GetTime(&stop_time);
  
  Xil_DCacheInvalidateRange((UINTPTR) rx_buf, packets*payloads*words*bytes);


  stop_demo();
  reset_dma();
  
  for (int i=0; i<packets*payloads*words; i++){
    xil_printf("received[%d]:  0x%x\r\n", i, rx_buf[i]);
    if (i==5*words) {
      xil_printf("...\r\n");
      i=(packets*payloads*words - 5*words); 
    }  
  }

  u32 delta = (u32) (stop_time - start_time);
  xil_printf("elapsed timer counts:    %d (0x%x)\r\n", delta, delta);
  xil_printf("counts per second:       %d\r\n", COUNTS_PER_SECOND);
  xil_printf("payloads per packet:     %d\r\n", payloads);  
  xil_printf("packets:                 %d\r\n", packets);


  unsigned r = ((COUNTS_PER_SECOND / 1000) * payloads / delta ) * packets;
  unsigned m = 40*10000/64;
  xil_printf("achieved throughput:  %d rx payloads (128-bit) per ms\r\n", r);
  xil_printf("maximum demand:       %d rx payloads (128-bit) per ms\r\n", m);
  
}

		
int main(){
  xil_printf("Demonstration Driver For *** axis_demo *** \r\n");
  xil_printf("Sanity number:  1\r\n");
  
  while(1){
    xil_printf("choose an option:\r\n");
    xil_printf("(1) read demo registers (2) start demo (3) stop demo \r\n");
    xil_printf("(4) DMA status (5) reset DMA (6) single DMA read \r\n");
    xil_printf("(7) run DMA benchmark \r\n");
      
    unsigned char c=inbyte();
    xil_printf("pressed:  %c\n\r", c);
    switch(c){
    case '1':
      read_demo_reg();
      break;
    case '2':
      start_demo(0);
      break;
    case '3':
      stop_demo();
      break;
    case '4':
      dma_status();
      break;
    case '5':
      reset_dma();
      break;
    case '6':
      single_read_dma();
      break;
    case '7':
      check_dma();
      break;
    default:
      xil_printf("invalid selection...\n\r");
    }
  }
  return 0;
}




