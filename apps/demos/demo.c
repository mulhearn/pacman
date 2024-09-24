#include <stdio.h>
#include <stdlib.h>
#include "xparameters.h"
#include "xtime_l.h"
#include "xil_io.h"
#include "xaxidma.h"
#include "xstatus.h"
#include "xil_printf.h"
#include "sleep.h"


#define ADDR_AXIL_REGS  XPAR_AXIL_TO_REGBUS_0_BASEADDR 
#define SCOPE_TX  0x0000
#define SCOPE_RX  0x4000
#define GLOBAL_TX 0x3F00
#define GLOBAL_RX 0x3F00

#define C_ADDR_RX_STATUS    0x00
#define C_ADDR_RX_CONFIG    0x04
#define C_ADDR_RX_LOOK_A    0x10
#define C_ADDR_RX_LOOK_B    0x14
#define C_ADDR_RX_LOOK_C    0x18
#define C_ADDR_RX_LOOK_D    0x1C 
#define C_ADDR_RX_STARTS    0x20
#define C_ADDR_RX_BEATS     0x24
#define C_ADDR_RX_UPDATES   0x28
#define C_ADDR_RX_LOST      0x2C
#define C_ADDR_RX_NCHAN     0x50
#define C_ADDR_RX_GSTATUS   0xA0
#define C_ADDR_RX_GFLAGS    0xA4
#define C_ADDR_RX_ZERO_CNTS 0xA8
#define C_ADDR_RX_FRCNT     0xB0
#define C_ADDR_RX_FWCNT     0xB4
#define C_ADDR_RX_DMAITR    0xB8

#define C_ADDR_TX_STATUS    0x00
#define C_ADDR_TX_CONFIG    0x04 
#define C_ADDR_TX_LOOK_C    0x18
#define C_ADDR_TX_LOOK_D    0x1C 
#define C_ADDR_TX_GFLAGS    0x20 
#define C_ADDR_TX_STARTS    0x30
#define C_ADDR_TX_NCHAN     0x40

u32 rx_mask_b = 0xFF;
u32 rx_mask_a = 0xFFFFFFFF;

void read_rx_status(){
  for (int i=0; i<40; i++){
    unsigned cshift = (i<<8);
    unsigned status = Xil_In32(ADDR_AXIL_REGS+SCOPE_RX+cshift+C_ADDR_RX_STATUS);
    unsigned config = Xil_In32(ADDR_AXIL_REGS+SCOPE_RX+cshift+C_ADDR_RX_CONFIG);
    unsigned starts  = Xil_In32(ADDR_AXIL_REGS+SCOPE_RX+cshift+C_ADDR_RX_STARTS);
    unsigned beats   = Xil_In32(ADDR_AXIL_REGS+SCOPE_RX+cshift+C_ADDR_RX_BEATS);
    unsigned updates = Xil_In32(ADDR_AXIL_REGS+SCOPE_RX+cshift+C_ADDR_RX_UPDATES);
    unsigned lost    = Xil_In32(ADDR_AXIL_REGS+SCOPE_RX+cshift+C_ADDR_RX_LOST);
    unsigned nchan  = Xil_In32(ADDR_AXIL_REGS+SCOPE_RX+cshift+C_ADDR_RX_NCHAN);
    xil_printf("%2d: ch: %2d cfg: 0x%08x status: 0x%08x s: %d b: %d u: %d l: %d\r\n",i, nchan, config, status, starts, beats, updates, lost);
  }
  xil_printf("gstatus----------- 0x%x    \r\n", Xil_In32(ADDR_AXIL_REGS+SCOPE_RX+0x3F00+C_ADDR_RX_GSTATUS));
  xil_printf("gflags------------ 0x%x    \r\n", Xil_In32(ADDR_AXIL_REGS+SCOPE_RX+0x3F00+C_ADDR_RX_GFLAGS));
  xil_printf("FIFO R count-------%d      \r\n", Xil_In32(ADDR_AXIL_REGS+SCOPE_RX+0x3F00+C_ADDR_RX_FRCNT));
  xil_printf("FIFO W count-------%d      \r\n", Xil_In32(ADDR_AXIL_REGS+SCOPE_RX+0x3F00+C_ADDR_RX_FWCNT));
  xil_printf("DMA ITR------------0x%x    \r\n", Xil_In32(ADDR_AXIL_REGS+SCOPE_RX+0x3F00+C_ADDR_RX_DMAITR));
}

void read_rx_look(){
  for (int i=0; i<40; i++){
    unsigned cshift = (i<<8);
    unsigned a = Xil_In32(ADDR_AXIL_REGS+SCOPE_RX+cshift+C_ADDR_RX_LOOK_A);
    unsigned b = Xil_In32(ADDR_AXIL_REGS+SCOPE_RX+cshift+C_ADDR_RX_LOOK_B);
    unsigned c = Xil_In32(ADDR_AXIL_REGS+SCOPE_RX+cshift+C_ADDR_RX_LOOK_C);
    unsigned d = Xil_In32(ADDR_AXIL_REGS+SCOPE_RX+cshift+C_ADDR_RX_LOOK_D);
    xil_printf("Channel %2d Look:  0x%08x %08x %08x %08x\r\n", i, d, c, b, a);
  }
}


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
    xil_printf("Channel %2d Look:  0x%08x %08x\r\n", i, d, c);
  }
}

void toggle_rx_mask(){
  static int mode = 0;
  mode = (mode + 1) % 3;  
  switch(mode){
    case 1:
      rx_mask_b = 0x0;
      rx_mask_a = 0xFFFFFFFF;      
      break;
    case 2:
      rx_mask_b = 0x0;
      rx_mask_a = 0x1;
      break;
    default:
      rx_mask_b = 0xFF;
      rx_mask_a = 0xFFFFFFFF;      
  }
  xil_printf("RX mask:  0x%08x %08x \r\n", rx_mask_b, rx_mask_a);
}

void zero_counts(){
  Xil_Out32(ADDR_AXIL_REGS+SCOPE_TX+0x3F00+C_ADDR_TX_STARTS, 0x0);
  Xil_Out32(ADDR_AXIL_REGS+SCOPE_RX+0x3F00+C_ADDR_RX_ZERO_CNTS, 0x0);
}

void dma_status(){
  unsigned cr, sr;
  cr = Xil_In32(XPAR_AXI_DMA_0_BASEADDR+0x30);
  sr = Xil_In32(XPAR_AXI_DMA_0_BASEADDR+0x34);
  xil_printf("DMA control register (S2MM) - 0x%x \r\n", cr);
  xil_printf("DMA status register  (S2MM) - 0x%x \r\n", sr);

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

  xil_printf("INFO:  Sending DMA reset \r\n");
  Xil_Out32(XPAR_AXI_DMA_0_BASEADDR+0x00, 0x04);
  Xil_Out32(XPAR_AXI_DMA_0_BASEADDR+0x30, 0x04);

  unsigned timeout = 10;
  while(timeout){
    unsigned cw = Xil_In32(XPAR_AXI_DMA_0_BASEADDR+0x00);
    unsigned cr = Xil_In32(XPAR_AXI_DMA_0_BASEADDR+0x30);

    if (((cw&0x4)==0) && ((cr&0x4)==0))
      break;
    xil_printf("INFO: ...waiting on reset... \r\n");
    timeout--;
  }
  if (! timeout) {
    xil_printf("*** ERROR:  failed to reset... *** \r\n");
    return;
  } else {
    xil_printf("INFO:  DMA reset complete.  \r\n");
  }
}


//#define ADDR_DMA        XPAR_AXI_DMA_0_BASEADDR

void single_tx(){
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

  tx_buf[0]= rx_mask_a;
  tx_buf[1]= rx_mask_b;
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

void single_rx(){
  // RX buffer is 32 beats of 128 bit each.

  unsigned rx_base = 0x1300000;
  u32 *rx_buf = (u32 *)rx_base;
  unsigned max_words = 0x0400; // enough for > 20 read cycles of all 40 uarts
  unsigned bytes = 0x4; // bytes per word
  
  //xil_printf("*** Sending run*** \r\n");
  Xil_Out32(XPAR_AXI_DMA_0_BASEADDR+0x30, 0x01);
  
  for (int i=0; i<max_words; i++)
    rx_buf[i] = 0;
    
  Xil_DCacheFlushRange((UINTPTR)rx_buf, max_words*bytes);

  xil_printf("*** Sending read *** \r\n");  
  Xil_Out32(XPAR_AXI_DMA_0_BASEADDR+0x48, (u32) rx_buf);
  Xil_Out32(XPAR_AXI_DMA_0_BASEADDR+0x58, max_words*bytes);
  
  unsigned timeout = 10000;
  unsigned start = 1;
  while(timeout){
    unsigned sr = Xil_In32(XPAR_AXI_DMA_0_BASEADDR+0x34);
    if ((sr&0x2)!=0) 
      break;
    if (start){
      xil_printf("*** waiting for idle *** \r\n");
      start = 0;
    }
    usleep(1);
    timeout--;
  }

  Xil_DCacheInvalidateRange((UINTPTR) rx_buf, max_words*bytes);
  
  for (int i=0; i<max_words/4; i++){
    unsigned d = rx_buf[4*i+3];
    unsigned c = rx_buf[4*i+2];
    unsigned b = rx_buf[4*i+1];
    unsigned a = rx_buf[4*i+0];    
    xil_printf("%d 0x%08x %08x %08x %08x\r\n", i, d, c, b, a);
    if (a==0) {
      if (c == i) {
	xil_printf("Valid packet of size %d\r\n", i);
      } else {
	xil_printf("*** Error Invalid Packet Detected ***\r\n", i);
      }
      break;
    }
  }
  if (! timeout) {
    xil_printf("*** TIMEOUT ERROR *** \r\n");
  }  
}


void benchmark_dma_loopback(){
  unsigned timeout;
  unsigned tx_base = 0x1100000;
  unsigned rx_base = 0x2100000;
  u32 *tx_buf = (u32 *) tx_base;
  u32 *rx_buf = (u32 *) rx_base;

  const unsigned bytes = 4;         // bytes per word (32-bit words)  
  const unsigned tx_words = 84;     // words in each packet (4 header + 2 words per 40 uarts)
  const unsigned tx_packets = 10000; // tx_packets to write
  //const unsigned rx_words = 128*4;
  // no extra:
  const unsigned rx_words = 164;

  XTime start_time;
  XTime stop_time;

  reset_dma();

  xil_printf("INFO:  Sending run to DMA TX and RX \r\n");
  Xil_Out32(XPAR_AXI_DMA_0_BASEADDR+0x00, 0x01); // TX
  Xil_Out32(XPAR_AXI_DMA_0_BASEADDR+0x30, 0x01); // RX

  for (int ipacket = 0; ipacket < tx_packets; ipacket++){
    //unsigned lastbit = rand();
    unsigned tx_pstart = ipacket*tx_words;
    tx_buf[tx_pstart+0]=0xFFFFFFFF;
    tx_buf[tx_pstart+1]=0x000000FF;
    tx_buf[tx_pstart+2]=0x00000000;
    tx_buf[tx_pstart+3]=0x00000000;    
    for (int ichan=0; ichan<40; ichan++){
      //if ((i%30)==0)
      //lastbit = rand();
      //tx_buf[tx_pstart+4+i]=(rand()<<1) | (lastbit&1);
      //lastbit = lastbit>>1;
      tx_buf[tx_pstart+4+2*ichan]  =rand();
      tx_buf[tx_pstart+4+2*ichan+1]=rand();
    }
  }  

  for (int iword=0; iword<rx_words*tx_packets; iword++)
    rx_buf[iword] = 0; 

  Xil_DCacheFlushRange((UINTPTR)tx_buf, tx_words*bytes*tx_packets);
  Xil_DCacheFlushRange((UINTPTR)rx_buf, rx_words*bytes*tx_packets);
    
  unsigned packets_sent   = 0;
  unsigned packets_rcvd   = 0;
  timeout = 100000;
  XTime_GetTime(&start_time);  
  while ((timeout>0) && (packets_rcvd < tx_packets)){
    unsigned fifocnt = Xil_In32(ADDR_AXIL_REGS+SCOPE_RX+0x3F00+C_ADDR_RX_FRCNT);
    unsigned gstatus = Xil_In32(ADDR_AXIL_REGS+SCOPE_TX+0x3F00+C_ADDR_TX_STATUS);
    unsigned sr = Xil_In32(XPAR_AXI_DMA_0_BASEADDR+0x04);

    if ( (packets_sent < tx_packets) && (fifocnt<100) && (gstatus == 0x1) && (((sr&0x2)!=0) || (packets_sent==0)) ) {
      Xil_Out32(XPAR_AXI_DMA_0_BASEADDR+0x18, ((u32) &tx_buf[packets_sent*tx_words]) );
      Xil_Out32(XPAR_AXI_DMA_0_BASEADDR+0x28, tx_words*bytes);
      packets_sent++;
    }

    if (fifocnt>=24) {
      unsigned sr = Xil_In32(XPAR_AXI_DMA_0_BASEADDR+0x34);
      if (((sr&0x2)!=0) || (packets_rcvd==0)){	
	Xil_Out32(XPAR_AXI_DMA_0_BASEADDR+0x48, ((u32) &rx_buf[packets_rcvd*rx_words]));
	Xil_Out32(XPAR_AXI_DMA_0_BASEADDR+0x58, rx_words*bytes);
	packets_rcvd += 1;
      }
    }    
    timeout--;
  }

  // no cheating!  wait on receipt of final package before stopping timer.
  timeout = 1000;
  while(timeout){
    unsigned sr = Xil_In32(XPAR_AXI_DMA_0_BASEADDR+0x34);
    if ((sr&0x2)!=0) 
      break;
    usleep(1);
    timeout--;
  }
  XTime_GetTime(&stop_time);

  xil_printf("INFO: packets sent:     %d \r\n", packets_sent);
  xil_printf("INFO: packets received: %d \r\n", packets_rcvd);
  xil_printf("INFO: validating packages received (outside timing loop)...\r\n", packets_rcvd);
  Xil_DCacheInvalidateRange((UINTPTR) rx_buf, rx_words*tx_packets*bytes);
  unsigned valid_payloads = 0;

  for (int ipacket = 0; ipacket < packets_rcvd; ipacket++){
    unsigned rx_pstart = ipacket*rx_words;
    unsigned tx_pstart = ipacket*tx_words+4;
    unsigned rx_a, rx_b, rx_c, rx_d, tx_c, tx_d;

    int valid = 1;
    for (int i=0; i<41; i++){
      rx_d = rx_buf[rx_pstart + 4*i+3];
      rx_c = rx_buf[rx_pstart + 4*i+2];
      rx_b = rx_buf[rx_pstart + 4*i+1];
      rx_a = rx_buf[rx_pstart + 4*i+0];

      if (i<40){
	tx_d = tx_buf[tx_pstart + 2*i+1];
	tx_c = tx_buf[tx_pstart + 2*i+0];
      } else {
	tx_d = 0;
	tx_c = 0;
      }
      
      if ((rx_a&0xFF) == 0x44){
	int status = 1;
	status &= ((rx_a&0x00FF) == 0x44);
	status &= (((rx_a&0xFF00)>>8) == i);
	status &= (rx_c == tx_c);
	status &= (rx_d == tx_d);
	if (status==0){      
	  xil_printf("DISCREPANCY FOUND:  %d tx: 0x%08x %08x rx: %08x %08x %08x %08x\r\n", i, tx_d, tx_c, rx_d, rx_c, rx_b, rx_a );
	  valid=0;
	}
      } else if (rx_a == 0) {
	int status = 1;
	status &= (rx_c == i);
	if (status==0){
	  xil_printf("DISCREPANCY FOUND:  %d rx: %08x %08x %08x %08x\r\n", i, rx_d, rx_c, rx_b, rx_a );
	  valid=0;
	}
	if (valid==1) {
	  valid_payloads += rx_c;
	}
      } else {
	xil_printf("DISCREPANCY FOUND:  %d rx: %08x %08x %08x %08x\r\n", i, rx_d, rx_c, rx_b, rx_a );
	valid=0;
      }
    }
  }

  
  xil_printf("INFO: valid payloads:   %d\r\n", valid_payloads);

  if (!timeout){
    xil_printf("*** ERROR:  failed to complete packet loopack before timeout *** \r\n");
    xil_printf("*** (This error message delayed so contents could be viewed) *** \r\n");
    return;
  }

  u32 delta = (u32) (stop_time - start_time);
  unsigned payloads = 40; 
  xil_printf("RESULTS: elapsed timer counts:      %d (0x%x)\r\n", delta, delta);
  xil_printf("RESULTS: counts per second:         %d\r\n", COUNTS_PER_SECOND);
  xil_printf("RESULTS: tx payloads per packet:    %d\r\n", payloads);
  xil_printf("RESULTS: tx_packets:                   %d\r\n", tx_packets);

  unsigned r = (unsigned) (((float) COUNTS_PER_SECOND) * payloads * tx_packets / delta / 1000);
  unsigned m = 40.0*10000/66;
  unsigned p = 40.0*10000/67;

  xil_printf("RESULTS: achieved throughput:  %d tx payloads per ms\r\n", r);
  xil_printf("RESULTS: maximum tx rate:      %d tx payloads (64-bit+2 @ 10 MHz) per ms\r\n", m);  
  xil_printf("RESULTS: practical max:        %d tx payloads (64-bit+3 @ 10 MHz) per ms\r\n", p);  
}


void benchmark_dma_write(){
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

void toggle_dcache(){
  static int mode = 0;
  mode = (mode + 1) % 2;  

  if (mode == 0) {
    xil_printf("enabling dcache\r\n");
    Xil_DCacheEnable();
  } else {
    xil_printf("disabling dcache\r\n");
    Xil_DCacheDisable();
  }
}
		
int main(){
  xil_printf("Demonstration Driver For PACMAN TX/RX \r\n");
  xil_printf("Sanity number:  2\r\n");
  xil_printf("Random Max:  0x%x Random Number:  0x%x \r\n", RAND_MAX, rand());
  
  while(1){
    xil_printf("choose an option:\r\n");
    xil_printf("TX: (1) read tx status (2) read tx look (3) single tx \r\n");
    xil_printf("RX: (4) read rx status (5) read rx look (6) single rx (7) toggle_rx_mask \r\n");
    xil_printf("Both: (8) zero counts (9) toggle dcache \r\n");
    xil_printf("DMA:  (a) read DMA status (b) DMA reset (c) benchmark DMA loopback (d) benchmark DMA write \r\n");
    
    unsigned char c=inbyte();
    xil_printf("pressed:  %c\n\r", c);
    switch(c){
    case '1':
      read_tx_status();
      break;
    case '2':
      read_tx_look();
      break;
    case '3':
      single_tx();
      break;      
    case '4':
      read_rx_status();
      break;
    case '5':
      read_rx_look();
      break;
    case '6':
      single_rx();
      break;      
    case '7':
      toggle_rx_mask();
      break;      
    case '8':
      zero_counts();
      break;
    case '9':
      toggle_dcache();
      break;
    case 'a':
      dma_status();
      break;
    case 'b':
      reset_dma();
      break;      
    case 'c':
      benchmark_dma_loopback();
      break;      
    case 'd':
      benchmark_dma_write();
      break;      
    default:
      xil_printf("invalid selection...\n\r");
    }
  }
  return 0;
}




