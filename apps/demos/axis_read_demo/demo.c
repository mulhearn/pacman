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
  xil_printf("Status---------- 0x%x    \r\n", Xil_In32(ADDR_AXIL_REGS+0x0200));

  for (unsigned i=0; i<40; i++){
    xil_printf("TX(%2d)----------- 0x%x %x \r\n", i, Xil_In32(ADDR_AXIL_REGS+8*i+4), Xil_In32(ADDR_AXIL_REGS+8*i));
  }  
  
}

void dma_status(){
  unsigned cr, sr;
  cr = Xil_In32(XPAR_AXI_DMA_0_BASEADDR+0x30);
  sr = Xil_In32(XPAR_AXI_DMA_0_BASEADDR+0x34);
  xil_printf("DMA control register (S2MM) - 0x%x \r\n", cr);
  xil_printf("DMA status register  (S2MM) - 0x%x \r\n", sr);
  
  cr = Xil_In32(XPAR_AXI_DMA_0_BASEADDR+0x00);
  sr = Xil_In32(XPAR_AXI_DMA_0_BASEADDR+0x04);
  xil_printf("DMA control register (MM2S) - 0x%x \r\n", cr);
  xil_printf("DMA status register  (MM2S) - 0x%x \r\n", sr);

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
  Xil_Out32(XPAR_AXI_DMA_0_BASEADDR+0x00, 0x04);
  //Xil_Out32(XPAR_AXI_DMA_0_BASEADDR+0x30, 0x04);

  unsigned timeout = 10;
  while(timeout){
    //unsigned cr = Xil_In32(XPAR_AXI_DMA_0_BASEADDR+0x30);
    unsigned cr = Xil_In32(XPAR_AXI_DMA_0_BASEADDR+0x30);
    if ((cr&0x4)==0)
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

void single_write_dma(){
  // TX buffer is 40 uarts times 64 bits each, or 80 32-bit words.
  // (Resulting TX stream is 512 bits times 5 beats)

  static int count = 0;
  unsigned tx_base = 0x1100000;
  u32 *tx_buf = (u32 *)tx_base;
  unsigned words = 80;
  
  xil_printf("*** Sending run*** \r\n");
  Xil_Out32(XPAR_AXI_DMA_0_BASEADDR+0x00, 0x01);

  dma_status();
  
  for (int i=0; i<words; i++)
    tx_buf[i] = 0xB000F000 + i + (count<<16);

  
  Xil_DCacheFlushRange((UINTPTR)tx_buf, words*4);
    
  xil_printf("*** Sending write *** \r\n");
  xil_printf(" count = %d \r\n", count);
  count++;
  
  Xil_Out32(XPAR_AXI_DMA_0_BASEADDR+0x18, (u32) tx_buf);
  Xil_Out32(XPAR_AXI_DMA_0_BASEADDR+0x28, words*4);

  unsigned timeout = 10000;
  unsigned start = 1;
  while(timeout){
    unsigned sr = Xil_In32(XPAR_AXI_DMA_0_BASEADDR+0x04);
    if ((sr&0x2)!=0) 
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
    
}

void check_dma(){
  unsigned tx_base = 0x1100000;
  u32 *tx_buf = (u32 *)tx_base;
  unsigned bytes = 4; // bytes per word (32 bit words)
  unsigned words = 2; // 64-bit payloads (2 32 bits words)
  unsigned payloads = 40; // 40 paylots
  unsigned packets = 1024; // packets to write
  XTime start_time;
  XTime stop_time;

  reset_dma();
  dma_status();

  xil_printf("*** Sending run*** \r\n");
  Xil_Out32(XPAR_AXI_DMA_0_BASEADDR+0x00, 0x01);

  dma_status();

  for (int i=0; i<packets*payloads*words; i++)
    tx_buf[i] = i;  
  Xil_DCacheFlushRange((UINTPTR)tx_buf, packets*payloads*words*bytes);

  XTime_GetTime(&start_time);
  
  for (int i=0;i<packets; i++){

    Xil_Out32(XPAR_AXI_DMA_0_BASEADDR+0x18, ((u32) tx_buf)+i*payloads*words*bytes);
    Xil_Out32(XPAR_AXI_DMA_0_BASEADDR+0x28, payloads*words*4);

    unsigned timeout = 10000;
    while(timeout){
      unsigned sr = Xil_In32(XPAR_AXI_DMA_0_BASEADDR+0x04);
      if ((sr&0x2)!=0) 
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
  
  Xil_DCacheInvalidateRange((UINTPTR) tx_buf, packets*payloads*words*bytes);

  reset_dma();
  read_demo_reg();
  
  u32 delta = (u32) (stop_time - start_time);
  xil_printf("elapsed timer counts:      %d (0x%x)\r\n", delta, delta);
  xil_printf("counts per second:         %d\r\n", COUNTS_PER_SECOND);
  xil_printf("tx payloads per packet:    %d\r\n", payloads);
  xil_printf("packets:                   %d\r\n", packets);

  unsigned r = ((COUNTS_PER_SECOND / 1000) * payloads / delta ) * packets;
  unsigned m = 40*10000/64;
  xil_printf("achieved throughput:  %6d tx payloads (64-bit) per ms\r\n", r);
  xil_printf("maximum tx rate:      %6d tx payloads (64-bit) per ms\r\n", m);  
}

		
int main(){
  xil_printf("Demonstration Driver For *** axis_demo *** \r\n");
  xil_printf("Sanity number:  1\r\n");
  
  while(1){
    xil_printf("choose an option:\r\n");
    xil_printf("(1) read demo registers (2) DMA status \r\n");
    xil_printf("(3) reset DMA (4) single DMA write \r\n");
    xil_printf("(5) run DMA benchmark \r\n");
      
    unsigned char c=inbyte();
    xil_printf("pressed:  %c\n\r", c);
    switch(c){
    case '1':
      read_demo_reg();
      break;
    case '2':
      dma_status();
      break;
    case '3':
      reset_dma();
      break;
    case '4':
      single_write_dma();
      break;
    case '5':
      check_dma();
      break;
    default:
      xil_printf("invalid selection...\n\r");
    }
  }
  return 0;
}




