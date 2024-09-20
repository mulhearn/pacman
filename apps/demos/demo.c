#include <stdio.h>
#include "xparameters.h"
#include "xtime_l.h"
#include "xil_io.h"
#include "xaxidma.h"
#include "xstatus.h"
#include "xil_printf.h"
#include "sleep.h"

#define ADDR_AXIL_REGS  XPAR_AXIL_TO_REGBUS_0_BASEADDR 
#define SCOPE_TX 0x0000


#define C_ADDR_TX_STATUS  0x00
#define C_ADDR_TX_CONFIG  0x04 
#define C_ADDR_TX_LOOK_C  0x18
#define C_ADDR_TX_LOOK_D  0x1C 
#define C_ADDR_TX_GFLAGS  0x20 
#define C_ADDR_TX_STARTS  0x30
#define C_ADDR_TX_NCHAN   0x40

void read_tx_status(){
  for (int i=0; i<40; i++){
    unsigned cshift = (i<<8);
    unsigned status = Xil_In32(ADDR_AXIL_REGS+SCOPE_TX+cshift+C_ADDR_TX_STATUS);
    unsigned config = Xil_In32(ADDR_AXIL_REGS+SCOPE_TX+cshift+C_ADDR_TX_CONFIG);
    unsigned starts = Xil_In32(ADDR_AXIL_REGS+SCOPE_TX+cshift+C_ADDR_TX_STARTS);
    unsigned nchan  = Xil_In32(ADDR_AXIL_REGS+SCOPE_TX+cshift+C_ADDR_TX_NCHAN);
    xil_printf("%2d:  chan: %2d config: 0x%08x status: 0x%08x starts: %d\r\n",i, nchan, config, status, starts);
  }
  xil_printf("gflags------------ 0x%x    \r\n", Xil_In32(ADDR_AXIL_REGS+SCOPE_TX+0x3F00+C_ADDR_TX_GFLAGS));
  xil_printf("bstatus----------- 0x%x    \r\n", Xil_In32(ADDR_AXIL_REGS+SCOPE_TX+0x3F00+C_ADDR_TX_STATUS));
}

void read_tx_look(){
  for (int i=0; i<40; i++){
    unsigned cshift = (i<<8);
    unsigned d = Xil_In32(ADDR_AXIL_REGS+SCOPE_TX+cshift+C_ADDR_TX_LOOK_D);
    unsigned c = Xil_In32(ADDR_AXIL_REGS+SCOPE_TX+cshift+C_ADDR_TX_LOOK_C);
    xil_printf("Channel %2d Look:  0x%x %x\r\n", i, d, c);
  }
}

void set_txoff(){
  unsigned gflags = Xil_In32(ADDR_AXIL_REGS+SCOPE_TX+0x3F00+C_ADDR_TX_GFLAGS);  
  Xil_Out32(ADDR_AXIL_REGS+SCOPE_TX+0x3F00+C_ADDR_TX_GFLAGS, gflags|0x1);
}

void set_hrdy(){
  unsigned gflags = Xil_In32(ADDR_AXIL_REGS+SCOPE_TX+0x3F00+C_ADDR_TX_GFLAGS);  
  Xil_Out32(ADDR_AXIL_REGS+SCOPE_TX+0x3F00+C_ADDR_TX_GFLAGS, gflags|0x2);
}

void clear_gflags(){
  Xil_Out32(ADDR_AXIL_REGS+SCOPE_TX+0x3F00+C_ADDR_TX_GFLAGS, 0x0);
}

void reset_counts(){
  Xil_Out32(ADDR_AXIL_REGS+SCOPE_TX+0x3F00+C_ADDR_TX_STARTS, 0x0);
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
  //dma_status();
}


//#define ADDR_DMA        XPAR_AXI_DMA_0_BASEADDR

void single_write_dma(){
  // TX buffer is a 128 bit header plus 40 uarts allocated 64 bits each.
  // This is a total of 84 32-bit words (4 header words, 80 uart words)
  // The resulting AXI stream is 128 bits times 21 beats.

  static int count = 0;
  unsigned tx_base = 0x1100000;
  u32 *tx_buf = (u32 *)tx_base;
  unsigned words = 84;
  
  xil_printf("*** Sending run*** \r\n");
  Xil_Out32(XPAR_AXI_DMA_0_BASEADDR+0x00, 0x01);

  dma_status();

  tx_buf[0]=0xFFFFFFFF;
  tx_buf[1]=0x000000FF;
  tx_buf[2]=0x00000000;
  tx_buf[3]=0x00000000;
  
  for (int i=0; i<(words-4); i++)
    tx_buf[i+4] = 0xB000F000 + i + (count<<16);
  
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
  unsigned timeout;
  unsigned tx_base = 0x1100000;
  u32 *tx_buf = (u32 *)tx_base;
  const unsigned bytes = 4;      // bytes per word (32-bit words)  
  const unsigned words = 84;     // words in each packet (4 header + 2 words per 40 uarts)
  const unsigned packets = 10000; // packets to write
  XTime start_time;
  XTime stop_time;

  reset_dma();
  dma_status();

  xil_printf("*** Sending run*** \r\n");
  Xil_Out32(XPAR_AXI_DMA_0_BASEADDR+0x00, 0x01);

  XTime_GetTime(&start_time);

  tx_buf[0]=0xFFFFFFFF;
  tx_buf[1]=0x000000FF;
  tx_buf[2]=0x00000000;
  tx_buf[3]=0x00000000;
  
  for (int iword=0; iword<(words-4); iword++)
    tx_buf[iword+4] = 1; 
  
  Xil_DCacheFlushRange((UINTPTR)tx_buf, words*bytes);


  for (int i=0;i<packets; i++){

    timeout = 10000;
    while(timeout){
      unsigned bstatus = Xil_In32(ADDR_AXIL_REGS+SCOPE_TX+0x3F00+C_ADDR_TX_STATUS);
      if (bstatus == 0x1)
	break;
      //xil_printf("*** waiting for ready *** \r\n");
      //usleep(1);
      timeout--;
    }
    
    Xil_Out32(XPAR_AXI_DMA_0_BASEADDR+0x18, ((u32) &tx_buf[0]) );
    Xil_Out32(XPAR_AXI_DMA_0_BASEADDR+0x28, words*bytes);
        
    timeout = 10000;
    while(timeout){
      unsigned sr = Xil_In32(XPAR_AXI_DMA_0_BASEADDR+0x04);
      if ((sr&0x2)!=0) 
	break;
      //xil_printf("*** waiting for idle *** \r\n");
      //usleep(1);
      timeout--;
    }
    if (! timeout) {
      xil_printf("*** ERROR:  failed to reach idle before timeout! *** \r\n");
      return;
    }

  }
  XTime_GetTime(&stop_time);
  
  Xil_DCacheInvalidateRange((UINTPTR) tx_buf, words*bytes);

  reset_dma();
  
  u32 delta = (u32) (stop_time - start_time);
  unsigned payloads = 40; 
  xil_printf("elapsed timer counts:      %d (0x%x)\r\n", delta, delta);
  xil_printf("counts per second:         %d\r\n", COUNTS_PER_SECOND);
  xil_printf("tx payloads per packet:    %d\r\n", payloads);
  xil_printf("packets:                   %d\r\n", packets);

  unsigned r = (unsigned) (((float) COUNTS_PER_SECOND) * payloads * packets / delta / 1000);
  unsigned m = 40.0*10000/66;
  unsigned p = 40.0*10000/67;

  xil_printf("achieved throughput:  %d tx payloads per ms\r\n", r);
  xil_printf("maximum tx rate:      %d tx payloads (64-bit+2 @ 10 MHz) per ms\r\n", m);  
  xil_printf("practical max:        %d tx payloads (64-bit+3 @ 10 MHz) per ms\r\n", p);  
}


		
int main(){
  xil_printf("Demonstration Driver For PACMAN TX \r\n");
  xil_printf("Sanity number:  1\r\n");
  
  while(1){
    xil_printf("choose an option:\r\n");
    xil_printf("(1) read tx registers (2) set tx off (3) set hold ready (4) clear tx flags (5) reset counts\r\n");
    xil_printf("(6) read tx look registers (7) read DMA status (8) DMA reset (9) single DMA write\r\n");
    xil_printf("(a) check DMA \r\n"); 

    unsigned char c=inbyte();
    xil_printf("pressed:  %c\n\r", c);
    switch(c){
    case '1':
      read_tx_status();
      break;
    case '2':
      set_txoff();
      break;
    case '3':
      set_hrdy();
      break;
    case '4':
      clear_gflags();
      break;
    case '5':
      reset_counts();
      break;
    case '6':
      read_tx_look();
      break;
    case '7':
      dma_status();
      break;
    case '8':
      reset_dma();
      break;      
    case '9':
      single_write_dma();
      break;      
    case 'a':
      check_dma();
      break;      
    default:
      xil_printf("invalid selection...\n\r");
    }
  }
  return 0;
}




