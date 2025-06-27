#include <stdio.h>
#include <stdlib.h>
#include "xparameters.h"
#include "xtime_l.h"
#include "xil_io.h"
#include "xaxidma.h"
#include "xstatus.h"
#include "xil_printf.h"
#include "sleep.h"

#include "axil.h"
#include "dma.h"
#include "rxtx.h"

void toggle_tx_config();
void toggle_rx_config();
void read_rx_status();
void read_rx_look();
void read_tx_status();
void read_tx_look();
void toggle_tx_mask();
void zero_counts();
void dma_status();
void reset_dma();
void single_tx();
void single_rx();
void benchmark_dma_loopback();
void benchmark_dma_write();

u32 tx_mask_b = 0xFF;
u32 tx_mask_a = 0xFFFFFFFF;

#define TX_BD_BASEADDR     0x1200000
#define RX_BD_BASEADDR     0x1200040
#define TX_BUF_BASEADDR    0x1100000
#define RX_BUF_BASEADDR    0x2100000

#define TX_BUF_BYTES 0x150  // 40 uarts x 64 bits => 20 128 bit word plus 1 128 bit header => 21*4*4 = 336 bytes 
#define RX_BUF_BYTES 0x400  // More than enough for now...

void init_bds(){
  xil_printf("INFO:  initializing single TX BD:\r\n");
  dma_init_single_bd_tx((u32*) TX_BD_BASEADDR, (u32*) TX_BUF_BASEADDR, TX_BUF_BYTES);
  xil_printf("INFO:  initializing single RX BD:\r\n");  
  dma_init_single_bd_rx((u32*) RX_BD_BASEADDR, (u32*) RX_BUF_BASEADDR, RX_BUF_BYTES);
}

void init_rxtx(){
  init_bds();
}

void show_bds(){
  xil_printf("INFO:  TX BD:\r\n");
  dma_show_bd((u32*) TX_BD_BASEADDR);
  xil_printf("INFO:  RX BD:\r\n");
  dma_show_bd((u32*) RX_BD_BASEADDR);
}

void clear_bds(){
  xil_printf("INFO:  clearing TX BD.\r\n");
  dma_clear_bd_status((u32*) TX_BD_BASEADDR);
  xil_printf("INFO:  clearing RX BD\r\n");
  dma_clear_bd_status((u32*) RX_BD_BASEADDR);
}


void clear_ioc(){
  xil_printf("INFO:  clearing DMA TX IOC flag.\r\n");
  dma_clear_tx_ioc(DMA_TIMEOUT);
  xil_printf("INFO:  clearing DMA RX IOC flag\r\n");
  dma_clear_rx_ioc(DMA_TIMEOUT);
}


void single_tx(){
  // TX buffer is a 128 bit header plus 40 uarts allocated 64 bits each.
  // This is a total of 84 32-bit words (4 header words, 80 uart words)
  // The resulting AXI stream is 128 bits times 21 beats.

  static int count = 0;
  u32 *tx_buf = (u32 *) TX_BUF_BASEADDR;
  unsigned words = TX_BUF_BYTES/4;

  tx_buf[0]= tx_mask_a;
  tx_buf[1]= tx_mask_b;
  tx_buf[2]=0x00000000;
  tx_buf[3]=0x00000000;

  for (int i=0; i<(words-4); i++)
    tx_buf[i+4] = 0xB000F000 + i + (count<<16);
  count++;
  
  Xil_DCacheFlushRange((UINTPTR)tx_buf, words*4);

  dma_single_tx((u32*) TX_BD_BASEADDR);

  if (dma_wait_tx_ioc(DMA_TIMEOUT) > 0){
    xil_printf("INFO: single TX yielded TX IOC flag high (SUCCESS)\r\n");
  }
  
}

void show_tx_buffer(){
  xil_printf("INFO:  TX Buffer:\r\n");
  dma_show_buffer((u32*) TX_BD_BASEADDR, 4, 1000);
}

void single_rx(){
  dma_single_rx((u32*) RX_BD_BASEADDR);

  if (dma_wait_rx_ioc(DMA_TIMEOUT) > 0){
    xil_printf("INFO: single RX yielded RX IOC flag high (SUCCESS)\r\n");
  }

}

void show_rx_buffer(){
  xil_printf("INFO:  RX Buffer:\r\n");
  dma_show_buffer((u32*) RX_BD_BASEADDR, 4, 1000);
}

void show_rx_transferred(){
  xil_printf("INFO:  RX Buffer:\r\n");
  dma_show_transferred((u32*) RX_BD_BASEADDR, 4, 1000);
}

void dma_menu(){
  xil_printf("DMA Menu: \r\n");

  while(1){
    xil_printf("choose an option:\r\n");
    xil_printf("(0) exit DMA Menu \r\n");
    xil_printf("(1) reset TX (2) TX status (3) reset RX (4) RX status (5) long status \r\n");
    xil_printf("(6) init BDs (7) clear BDs (8) show BDs (9) clear IOC flags\r\n");

    unsigned char c=inbyte();
    xil_printf("pressed:  %c\n\r", c);
    switch(c){
    case '0':
      return;
    case '1':
      dma_reset_tx(DMA_TIMEOUT);
      break;
    case '2':
      dma_show_tx_status();
      break;
    case '3':
      dma_reset_rx(DMA_TIMEOUT);
      break;
    case '4':
      dma_show_rx_status();
      break;
    case '5':
      dma_show_long_status();
      break;
    case '6':
      init_bds();
      break;
    case '7':
      clear_bds();
      break;
    case '8':
      show_bds();
      break;
    case '9':
      clear_ioc();
      break;
    default:
      xil_printf("invalid selection...\n\r");
    }
  }
}

void benchmark_dma_tx();

void rxtx_menu(){
  xil_printf("RX/TX Menu: \r\n");

  while(1){
    xil_printf("choose an option:\r\n");
    xil_printf("(0) exit RX/TX Menu \r\n");
    xil_printf("(1) read tx status (2) read tx look (3) toggle tx mask (4) toggle tx config \r\n");
    xil_printf("(5) read rx status (6) read rx look (7) toggle rx config (8) zero counts \r\n");
    xil_printf("(a) single TX (b) show TX buffer (c) single RX (d) show RX buffer (e) show RX transferred \r\n");
    xil_printf("(f) benchmark TX \r\n");

    unsigned char c=inbyte();
    xil_printf("pressed:  %c\n\r", c);
    switch(c){
    case '0':
      return;
    case '1':
      read_tx_status();
      break;
    case '2':
      read_tx_look();
      break;
    case '3':
      toggle_tx_mask();
      break;
    case '4':
      toggle_tx_config();
      break;
    case '5':
      read_rx_status();
      break;
    case '6':
      read_rx_look();
      break;
    case '7':
      toggle_rx_config();
      break;
    case '8':
      zero_counts();
      break;
    case 'a':
      single_tx();
      break;
    case 'b':
      show_tx_buffer();
      break;
    case 'c':
      single_rx();
      break;
    case 'd':
      show_rx_buffer();
      break;
    case 'e':
      show_rx_transferred();
      break;
    case 'f':
      benchmark_dma_tx();
      break;
    default:
      xil_printf("invalid selection...\n\r");
    }
  }
}

void toggle_tx_config(){
  static int mode = 0;
  mode = (mode + 1) % 3;
  if (mode==0){
    unsigned config = 0x00001602;
    xil_printf("INFO: No Delay.  Broadcasting tx config write 0x%08x \r\n", config);
    Xil_Out32(ADDR_AXIL_REGS+SCOPE_TX+UART_BROADCAST+C_ADDR_TX_CONFIG, config);
  } else if (mode==1) {
    unsigned config = 0x05281602;
    xil_printf("INFO: Half Speed.  Broadcasting tx config write 0x%08x \r\n", config);
    Xil_Out32(ADDR_AXIL_REGS+SCOPE_TX+UART_BROADCAST+C_ADDR_TX_CONFIG, config);
  } else if (mode==2) {
    unsigned config = 0x00001601;
    xil_printf("INFO: Double speed.  Broadcasting tx config write 0x%08x \r\n", config);
    Xil_Out32(ADDR_AXIL_REGS+SCOPE_TX+UART_BROADCAST+C_ADDR_TX_CONFIG, config);
  }
}

void toggle_rx_config(){
  static int mode = 0;
  mode = (mode + 1) % 4;
  if (mode==0){
    unsigned config = 0x00001002;
    xil_printf("INFO: No internal loopback.  Broadcasting rx config write 0x%08x \r\n", config);
    Xil_Out32(ADDR_AXIL_REGS+SCOPE_RX+UART_BROADCAST+C_ADDR_RX_CONFIG, config);
  } else if (mode==1) {
    unsigned config = 0x00011002;
    xil_printf("INFO: Full internal loopback.  Broadcasting rx configs write 0x%08x \r\n", config);
    Xil_Out32(ADDR_AXIL_REGS+SCOPE_RX+UART_BROADCAST+C_ADDR_RX_CONFIG, config);
  } else if (mode==2) {
    unsigned config = 0x00011001;
    xil_printf("INFO: Full internal loopback at full speed.  Broadcasting rx configs write 0x%08x \r\n", config);
    Xil_Out32(ADDR_AXIL_REGS+SCOPE_RX+UART_BROADCAST+C_ADDR_RX_CONFIG, config);
  } else if (mode==3) {
    unsigned config;
    config = 0x00011002;
    xil_printf("INFO: Tiles 2-10 use internal loopback.  Broadcasting rx configs t 0x%08x \r\n", config);
    Xil_Out32(ADDR_AXIL_REGS+SCOPE_RX+UART_BROADCAST+C_ADDR_RX_CONFIG, config);
    config = 0x00001002;
    xil_printf("INFO: Tile 1 does not use internal loopback.  Setting Tile 1 rx config 0x%08x \r\n", config);
    Xil_Out32(ADDR_AXIL_REGS+SCOPE_RX+(0<<8)+C_ADDR_RX_CONFIG, config);
    Xil_Out32(ADDR_AXIL_REGS+SCOPE_RX+(1<<8)+C_ADDR_RX_CONFIG, config);
    Xil_Out32(ADDR_AXIL_REGS+SCOPE_RX+(2<<8)+C_ADDR_RX_CONFIG, config);
    Xil_Out32(ADDR_AXIL_REGS+SCOPE_RX+(3<<8)+C_ADDR_RX_CONFIG, config);
  }
}

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

void toggle_tx_mask(){
  static int mode = 0;
  mode = (mode + 1) % 3;
  switch(mode){
    case 1:
      tx_mask_b = 0x0;
      tx_mask_a = 0xFFFFFFFF;
      break;
    case 2:
      tx_mask_b = 0x0;
      tx_mask_a = 0x1;
      break;
    default:
      tx_mask_b = 0xFF;
      tx_mask_a = 0xFFFFFFFF;
  }
  xil_printf("RX mask:  0x%08x %08x \r\n", tx_mask_b, tx_mask_a);
}

void zero_counts(){
  Xil_Out32(ADDR_AXIL_REGS+SCOPE_TX+0x3F00+C_ADDR_TX_STARTS, 0x0);
  Xil_Out32(ADDR_AXIL_REGS+SCOPE_RX+0x3F00+C_ADDR_RX_ZERO_CNTS, 0x0);
}


//
// Benchmarks:
//

void benchmark_dma_tx(){
  u32 *bd  = (u32 *) TX_BD_BASEADDR;
  u32 *buf = (u32 *) TX_BUF_BASEADDR;
  const unsigned words = TX_BUF_BYTES/4; // words in TX buffer (= 1 DMA packet)
  const unsigned packets = 10000;        // DMA packets to send
 
  buf[0]= tx_mask_a;
  buf[1]= tx_mask_b;
  buf[2]=0x00000000;
  buf[3]=0x00000000;

  for (int i=0; i<(words-4); i++)
    buf[i+4] = rand();

  dma_halt_tx(DMA_TIMEOUT);
  dma_clear_bd_status(bd);

  dma_clear_tx_ioc(DMA_TIMEOUT);

  xil_printf("INFO: setting current descriptor address to 0x%08x\r\n", bd);
  dma_write_register(MM2S_CURDESC, (u32) bd);

  dma_run_tx(DMA_TIMEOUT);

  
  XTime start_time;
  XTime stop_time;

  XTime_GetTime(&start_time);
  unsigned timeout = 0;
  for (int i=0;i<packets; i++){
    dma_clear_tx_ioc(DMA_TIMEOUT);
    dma_clear_bd_status(bd);
    //usleep(1);
    dma_write_register(MM2S_TAILDESC, (u32) bd);
    timeout = dma_wait_tx_ioc(DMA_TIMEOUT);
    if (timeout==0){
      xil_printf("ERROR: timeout waiting on IOC flag at packet %d \r\n", i);
      return;
    } else if (timeout < 5){
      xil_printf("INFO: timeout %d \r\n", timeout);
    }
  }
  XTime_GetTime(&stop_time);

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



// *** NOT YET CONVERTED TO SG SINGLE BD MODE ***


void benchmark_dma_loopback(){
  unsigned timeout;
  unsigned tx_base = 0x1100000;
  unsigned rx_base = 0x2100000;
  u32 *tx_buf = (u32 *) tx_base;
  u32 *rx_buf = (u32 *) rx_base;

  const unsigned bytes = 4;         // bytes per word (32-bit words)
  const unsigned tx_words = 84;     // words in each packet (4 header + 2 words per 40 uarts)
  const unsigned tx_packets = 10000; // tx_packets to write
  const unsigned rx_words = 164;

  XTime start_time;
  XTime stop_time;

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

    //xil_printf("DEBUG:  ipacket:  %d\r\n", ipacket);

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
	status &= (((rx_a&0xFF00)>>8) == (i+1));
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
    //if (valid=0) break;
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


