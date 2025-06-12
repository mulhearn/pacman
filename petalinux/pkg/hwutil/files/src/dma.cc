#include <stdlib.h>
#include <stdio.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <unistd.h>
#include <cstring>
#include <stdint.h>
#include <sys/time.h>

#include "axil.hh"
#include "dma.hh"
#include "rxtx.hh"

volatile uint32_t * G_UTIL_DMA  = NULL;
volatile uint32_t * G_UTIL_DMA_TX_BUFFER = NULL;
volatile uint32_t * G_UTIL_DMA_RX_BUFFER = NULL;

static uint32_t tx_mask_b = 0xFF;
static uint32_t tx_mask_a = 0xFFFFFFFF;

void init_dma(){
  printf("INFO:  Opening /dev/mem.\n");
  int dh = open("/dev/mem", O_RDWR|O_SYNC);

  printf("INFO:  Initializing DMA contol interface (AXIL).\n");
  G_UTIL_DMA = (uint32_t*)mmap(NULL, DMA_LEN, PROT_READ|PROT_WRITE, MAP_SHARED, dh, DMA_ADDR);

  printf("INFO:  Initializing DMA TX_BUFFER.\n");
  G_UTIL_DMA_TX_BUFFER = (uint32_t*)mmap(NULL, DMA_TX_MAXLEN, PROT_READ|PROT_WRITE, MAP_SHARED, dh, DMA_TX_ADDR);

  printf("INFO:  Initializing DMA RX_BUFFER.\n");
  G_UTIL_DMA_RX_BUFFER = (uint32_t*)mmap(NULL, DMA_RX_MAXLEN, PROT_READ|PROT_WRITE, MAP_SHARED, dh, DMA_RX_ADDR);
}

void reset_dma(){
  printf("INFO:  Sending DMA reset \n");
  G_UTIL_DMA[(0x00)>>2] = 0x04;
  G_UTIL_DMA[(0x30)>>2] = 0x04;

  unsigned timeout = 10;
  while(timeout){
    unsigned cw = G_UTIL_DMA[(0x00)>>2];
    unsigned cr = G_UTIL_DMA[(0x30)>>2];

    if (((cw&0x4)==0) && ((cr&0x4)==0))
      break;
    printf("INFO: ...waiting on reset... \n");
    timeout--;
  }
  if (! timeout) {
    printf("*** ERROR:  failed to reset... *** \n");
    return;
  } else {
    printf("INFO:  DMA reset complete.  \n");
  }

  printf("DEBUG:  enabling interrupts:  \n");
  unsigned cr = G_UTIL_DMA[(0x30)>>2];
  G_UTIL_DMA[(0x30)>>2] = (cr | 0x00001000);
}

void dma_status(){
  unsigned cr, sr;
  printf("INFO: Control and status registers for DMA TX \n");  

  cr = G_UTIL_DMA[C_ADDR_DMA_TX_CONTROL>>2];
  sr = G_UTIL_DMA[C_ADDR_DMA_TX_STATUS>>2];
  printf("DMA control register (MM2S) - 0x%x \n", cr);
  printf("DMA status register  (MM2S) - 0x%x \n", sr);

  printf("Control Bits: \n");
  printf("RS (Run/Stop)-----%d\n", ((cr&0x00000001)!=0));
  printf("Always One--------%d\n", ((cr&0x00000002)!=0));
  printf("Reset-------------%d\n", ((cr&0x00000004)!=0));
  printf("Keyhole-----------%d\n", ((cr&0x00000008)!=0));
  printf("Cycle BD Enable---%d\n", ((cr&0x00000010)!=0));
  printf("Always Zero-------%d\n", ((cr&0x00000FE0)!=0));
  printf("Itr En (Comp)-----%d\n", ((cr&0x00001000)!=0));
  printf("Itr En (Delay)----%d\n", ((cr&0x00002000)!=0));
  printf("Itr En (Error)----%d\n", ((cr&0x00004000)!=0));
  printf("Always Zero-------%d\n", ((cr&0x00008000)!=0));
  printf("IRQ Threshold-----%d\n", ((cr&0x00FF0000)>>16));
  printf("IRQ Delay---------%d\n", ((cr&0xFF000000)>>24));
  printf("Status Bits: \n");
  printf("Halted------------%d\n", ((sr&0x00000001)!=0));
  printf("Idle--------------%d\n", ((sr&0x00000002)!=0));
  printf("Always Zero-------%d\n", ((sr&0x00000004)!=0));
  printf("SGIncld-----------%d\n", ((sr&0x00000008)!=0));
  printf("DMAIntErr---------%d\n", ((sr&0x00000010)!=0));
  printf("DMASecErr---------%d\n", ((sr&0x00000020)!=0));
  printf("DMADecErr---------%d\n", ((sr&0x00000040)!=0));
  printf("Always Zero-------%d\n", ((sr&0x00000080)!=0));
  printf("SGIntErr----------%d\n", ((sr&0x00000100)!=0));
  printf("SGSecErr----------%d\n", ((sr&0x00000200)!=0));
  printf("SGDecErr----------%d\n", ((sr&0x00000400)!=0));
  printf("Always Zero-------%d\n", ((sr&0x00000800)!=0));
  printf("Itr (IOC)---------%d\n", ((sr&0x00000100)!=0));
  printf("Itr (Delay)-------%d\n", ((sr&0x00000200)!=0));
  printf("Itr (Error)-------%d\n", ((sr&0x00000400)!=0));
  printf("Always Zero-------%d\n", ((sr&0x00000800)!=0));
  printf("Stat Irq Thresh---%d\n", ((cr&0x00FF0000)>>16));
  printf("Stay Irq Delay----%d\n", ((cr&0xFF000000)>>24));

  printf("INFO: Control and status registers for DMA RX \n");
  
  cr = G_UTIL_DMA[C_ADDR_DMA_RX_CONTROL>>2];
  sr = G_UTIL_DMA[C_ADDR_DMA_RX_STATUS>>2];
  printf("DMA control register (S2MM) - 0x%x \n", cr);
  printf("DMA status register  (S2MM) - 0x%x \n", sr);

  printf("Control Bits: \n");
  printf("RS (Run/Stop)-----%d\n", ((cr&0x00000001)!=0));
  printf("Always One--------%d\n", ((cr&0x00000002)!=0));
  printf("Reset-------------%d\n", ((cr&0x00000004)!=0));
  printf("Keyhole-----------%d\n", ((cr&0x00000008)!=0));
  printf("Cycle BD Enable---%d\n", ((cr&0x00000010)!=0));
  printf("Always Zero-------%d\n", ((cr&0x00000FE0)!=0));
  printf("Itr En (Comp)-----%d\n", ((cr&0x00001000)!=0));
  printf("Itr En (Delay)----%d\n", ((cr&0x00002000)!=0));
  printf("Itr En (Error)----%d\n", ((cr&0x00004000)!=0));
  printf("Always Zero-------%d\n", ((cr&0x00008000)!=0));
  printf("IRQ Threshold-----%d\n", ((cr&0x00FF0000)>>16));
  printf("IRQ Delay---------%d\n", ((cr&0xFF000000)>>24));
  printf("Status Bits: \n");
  printf("Halted------------%d\n", ((sr&0x00000001)!=0));
  printf("Idle--------------%d\n", ((sr&0x00000002)!=0));
  printf("Always Zero-------%d\n", ((sr&0x00000004)!=0));
  printf("SGIncld-----------%d\n", ((sr&0x00000008)!=0));
  printf("DMAIntErr---------%d\n", ((sr&0x00000010)!=0));
  printf("DMASecErr---------%d\n", ((sr&0x00000020)!=0));
  printf("DMADecErr---------%d\n", ((sr&0x00000040)!=0));
  printf("Always Zero-------%d\n", ((sr&0x00000080)!=0));
  printf("SGIntErr----------%d\n", ((sr&0x00000100)!=0));
  printf("SGSecErr----------%d\n", ((sr&0x00000200)!=0));
  printf("SGDecErr----------%d\n", ((sr&0x00000400)!=0));
  printf("Always Zero-------%d\n", ((sr&0x00000800)!=0));
  printf("Itr (IOC)---------%d\n", ((sr&0x00000100)!=0));
  printf("Itr (Delay)-------%d\n", ((sr&0x00000200)!=0));
  printf("Itr (Error)-------%d\n", ((sr&0x00000400)!=0));
  printf("Always Zero-------%d\n", ((sr&0x00000800)!=0));
  printf("Stat Irq Thresh---%d\n", ((cr&0x00FF0000)>>16));
  printf("Stay Irq Delay----%d\n", ((cr&0xFF000000)>>24));






}

void set_dma_tx_to_run(){
  printf("INFO:  Setting DMA TX To RUN.\n");
  G_UTIL_DMA[(C_ADDR_DMA_TX_CONTROL)>>2] = MASK_DMA_CR_RUN;

  // verify that we leave the HALTED state:
  unsigned timeout=100;
  while(timeout){
    usleep(1);
    if ((G_UTIL_DMA[C_ADDR_DMA_TX_STATUS>>2] & MASK_DMA_SR_HALTED) == 0)
      break;
    timeout--;
  }
  if (! timeout) {
    printf("ERROR:  *** Timeout waiting for DMA TX to leave the HALTED state. *** ");
  } else {
    printf("INFO:  DMA TX has left the HALTED state successfully. (timeout=%d)\n", timeout);
  }
}

void set_dma_rx_to_run(){
  
  printf("INFO:  Setting DMA RX To RUN.\n");
  G_UTIL_DMA[(C_ADDR_DMA_RX_CONTROL)>>2] = MASK_DMA_CR_RUN;

  // verify that we leave the HALTED state:
  unsigned timeout=100;
  while(timeout){
    usleep(1);
    if ((G_UTIL_DMA[C_ADDR_DMA_RX_STATUS>>2] & MASK_DMA_SR_HALTED) == 0)
      break;
    timeout--;
  }
  if (! timeout) {
    printf("ERROR:  *** Timeout waiting for DMA RX to leave the HALTED state. *** ");
  } else {
    printf("INFO:  DMA RX has left the HALTED state successfully. (timeout=%d)\n", timeout);
  }
  
}

void single_tx(){
  // TX buffer is a 128 bit header plus 40 uarts allocated 64 bits each.
  // This is a total of 84 32-bit words (4 header words, 80 uart words)
  // The resulting AXI stream is 128 bits times 21 beats.

  static int count = 0;
  unsigned tx_words = 84;

  set_dma_tx_to_run();
  //dma_status();

  G_UTIL_DMA_TX_BUFFER[0] = tx_mask_a;
  G_UTIL_DMA_TX_BUFFER[1] = tx_mask_b;
  G_UTIL_DMA_TX_BUFFER[2] = 0x0;
  G_UTIL_DMA_TX_BUFFER[3] = 0x0;

  for (int i=0; i<(tx_words-4); i++)
    G_UTIL_DMA_TX_BUFFER[i+4] = 0xB000F000 + i + (count<<16);

  printf("INFO:  Sending write, count = % d \n", count);
  count++;

  G_UTIL_DMA[(0x18)>>2] = DMA_TX_ADDR;
  G_UTIL_DMA[(0x28)>>2] = tx_words*DMA_BYTES_PER_WORD;

  unsigned timeout = 10000;
  unsigned start = 1;
  while(timeout){
    unsigned sr = G_UTIL_DMA[(0x04)>>2];
    if ((sr&0x2)!=0)
      break;
    if (start){
      printf("INFO: waiting for idle ... \n");
      start = 0;
    }
    usleep(10);
    timeout--;
  }
  if (! timeout) {
    printf("ERROR:  *** Failed to reach idle before timeout! *** \n");
    return;
  }
  printf("INFO:  Single DMA TX was successfull.\n");
}

void clear_dma_rx_buffer(unsigned max_words){
  //printf("INFO:  Clearing RX buffer \n");
  for (int i=0; i<max_words; i++)
    G_UTIL_DMA_RX_BUFFER[i] = 0;
}

void start_dma_rx(unsigned max_words){
  //printf("INFO: starting DMA RX cycle \n");
  G_UTIL_DMA[(0x48)>>2] = DMA_RX_ADDR;
  G_UTIL_DMA[(0x58)>>2] = max_words*DMA_BYTES_PER_WORD;
}

int  wait_dma_rx_idle(unsigned timeout){
  unsigned start = 1;
  while(timeout){
    unsigned sr = G_UTIL_DMA[(0x34)>>2];
    if ((sr&0x2)!=0)
      break;
    if (start){
      printf("INFO: waiting for idle... \n");
      start = 0;
    }
    usleep(1);
    timeout--;
  }
  return timeout;
}

int  count_dma_rx_buffer(unsigned max_words, int verbose){
  if (verbose>1){
    printf("INFO: contents of RX buffer:\n");
  }
  for (int i=0; i<max_words/4; i++){
    unsigned a = G_UTIL_DMA_RX_BUFFER[4*i+0];
    if (verbose>1){
      unsigned d = G_UTIL_DMA_RX_BUFFER[4*i+3];
      unsigned c = G_UTIL_DMA_RX_BUFFER[4*i+2];
      unsigned b = G_UTIL_DMA_RX_BUFFER[4*i+1];
      printf("%d 0x%08x %08x %08x %08x\n", i, d, c, b, a);
    }
    if (a==0) {
      unsigned c = G_UTIL_DMA_RX_BUFFER[4*i+2];
      if (c == i) {
	if (verbose>0){
	  printf("INFO: valid packet of size %d\n", i);
	}
	return i;
      } else {
	printf("ERROR:  Invalid buffer detected at %d with reported size %d\n",i,c);
	return 0;
      }
      break;
    }
  }
  return 0;
}

void single_rx(){
  unsigned max_words = 0x0400; 
  set_dma_rx_to_run();
  clear_dma_rx_buffer(max_words);
  start_dma_rx(max_words);
  resume_rx();
}

void resume_rx(){
  unsigned max_words = 0x0400; 
  unsigned timeout = wait_dma_rx_idle(10000);
  if (timeout > 0){
    printf("INFO: RX IDLE reached with timeout %d\n", timeout);
  } else {
    printf("ERROR: *** Failed to reach RX IDLE before timeout. *** \n");
    return;
  }

  int count = count_dma_rx_buffer(max_words,2);
  if(count > 0){
    printf("INFO: count %d\n", count);
  }
  
  if (! timeout) {
    printf("*** TIMEOUT ERROR *** \n");
  }
}

void benchmark_tx(){
  struct timeval start, end;
  printf("*** Benchmarking RX *** \n");
  unsigned tx_words = 84;
  int count = 0;

  int tx_packets=10000;
  
  printf("*** Sending run*** \n");
  G_UTIL_DMA[(0x00)>>2] = 0x01;


  G_UTIL_DMA_TX_BUFFER[0] = tx_mask_a;
  G_UTIL_DMA_TX_BUFFER[1] = tx_mask_b;
  G_UTIL_DMA_TX_BUFFER[2] = 0x0;
  G_UTIL_DMA_TX_BUFFER[3] = 0x0;

  for (int i=0; i<(tx_words-4); i++)
    G_UTIL_DMA_TX_BUFFER[i+4] = 0xB000F000 + i + (count<<16);


  gettimeofday(&start, NULL);

  for (int i=0; i<tx_packets; i++){
    //printf("*** Sending write*** \n");
    count++;
    G_UTIL_DMA[(0x18)>>2] = DMA_TX_ADDR;
    G_UTIL_DMA[(0x28)>>2] = tx_words*4;

    unsigned timeout = 1000000;
    while(timeout){
      unsigned sr = G_UTIL_DMA[(0x04)>>2];
      if ((sr&0x2)!=0)
	break;
      timeout--;
      //usleep(1);
    }
    if (! timeout) {
      printf("*** ERROR:  failed to reach idle before timeout! *** \n");
      return;
    }
    //printf("DEBUG:  count %d\n", count);
  }
  gettimeofday(&end, NULL);
  double elapsed_time = 1000.0*(end.tv_sec - start.tv_sec) + (end.tv_usec - start.tv_usec) / 1000.0;

  printf("INFO: sent %d packets\n", count);
  printf("INFO: elapsed time %lf ms \n", elapsed_time);

  unsigned m = 40.0*10000/66;
  unsigned p = 40.0*10000/67;
  unsigned a = 40*tx_packets/elapsed_time;
  
  printf("maximum tx rate:      %d tx payloads (64-bit+2 @ 10 MHz) per ms\n", m);
  printf("practical max:        %d tx payloads (64-bit+3 @ 10 MHz) per ms\n", p);
  printf("achieved:             %d tx payloads (64-bit+3 @ 10 MHz) per ms\n", a);
}

void benchmark_rxtx_loopback(){
  int verbose = 0;
  
  struct timeval start, end;
  printf("INFO: benchmarking RX/TX loopback\n");
  unsigned tx_words  = 84;

  set_dma_tx_to_run();
  set_dma_rx_to_run();

  G_UTIL_DMA_TX_BUFFER[0] = tx_mask_a;
  G_UTIL_DMA_TX_BUFFER[1] = tx_mask_b;
  G_UTIL_DMA_TX_BUFFER[2] = 0x0;
  G_UTIL_DMA_TX_BUFFER[3] = 0x0;

  for (int i=0; i<(tx_words-4); i++)
    G_UTIL_DMA_TX_BUFFER[i+4] = 0xB000F000 + i;

  gettimeofday(&start, NULL);

  unsigned total_uarts    = 40000;
  unsigned uarts_sent     = 0;
  unsigned uarts_rcvd     = 0;
  unsigned timeout        = 1000000;
  unsigned dma_requested  = 0;
  unsigned dma_reads      = 0;

  while ((timeout>0) && (uarts_rcvd < total_uarts)){
    unsigned fifocnt = read_axil(SCOPE_RX+0x3F00+C_ADDR_RX_FRCNT);
    unsigned gstatus = read_axil(SCOPE_TX+0x3F00+C_ADDR_TX_STATUS);
    unsigned txsr    = G_UTIL_DMA[(0x04)>>2];

    if ( (uarts_sent < total_uarts) && (fifocnt<2000) && (gstatus == 0x1) && (((txsr&0x2)!=0) || (uarts_sent==0)) ) {
      G_UTIL_DMA[(0x18)>>2] = DMA_TX_ADDR;
      G_UTIL_DMA[(0x28)>>2] = tx_words*4;
      uarts_sent += 40; // TODO:  use tx mask to determine number of words instead.
      if (verbose)
	printf("DMA TX started, total uart packets sent: %d \n", uarts_sent); 
    }

    if (dma_requested==1){
      unsigned rxsr    = G_UTIL_DMA[(0x34)>>2];
      unsigned fifocnt = read_axil(SCOPE_RX+0x3F00+C_ADDR_RX_FRCNT);      
      if ((rxsr&0x2)!=0) {
	if (verbose)
	  printf("DMA state is IDLE, checking buffer.  FIFO count is %d\n", fifocnt); 
	dma_requested=0;
	unsigned count = count_dma_rx_buffer();
	if (verbose)
	  printf("INFO: received %d uart packets from single DMA RX\n", count);	
	uarts_rcvd += count;
	dma_reads += 1;
      }
    }

    if ((uarts_rcvd < uarts_sent) && (dma_requested==0)){
      if (verbose)
	printf("INFO: clearing the RX buffer in preparation for DMA RX.\n");
      clear_dma_rx_buffer(4);

      if (verbose){
	unsigned fifocnt = read_axil(SCOPE_RX+0x3F00+C_ADDR_RX_FRCNT);	
	printf("DMA RX started, total uart packets received: %d fifo count: %d \n", uarts_rcvd, fifocnt);
      }
      start_dma_rx();
      dma_requested=1;
    }

    usleep(1);
    timeout--;
  }  
  //printf("INFO: outside loop, DMA requested = %d\n", dma_requested);
  //dma_status();
  
  gettimeofday(&end, NULL);
  double elapsed_time = 1000.0*(end.tv_sec - start.tv_sec) + (end.tv_usec - start.tv_usec) / 1000.0;

  printf("INFO: sent %d words\n", uarts_sent);
  printf("INFO: rcvd %d words\n", uarts_rcvd);
  printf("INFO: elapsed time %lf ms \n", elapsed_time);
  printf("INFO: DMA read cycles %d \n", dma_reads);
  if (dma_reads > 0)
    printf("INFO: uart packets per DMA read cycle %d \n", uarts_rcvd/dma_reads);
  unsigned m = 40.0*10000/66;
  unsigned p = 40.0*10000/67;
  unsigned a = uarts_rcvd/elapsed_time;
  
  printf("maximum tx rate:      %d tx payloads (64-bit+2 @ 10 MHz) per ms\n", m);
  printf("practical max:        %d tx payloads (64-bit+3 @ 10 MHz) per ms\n", p);
  printf("achieved:             %d tx payloads (64-bit+3 @ 10 MHz) per ms\n", a);
  
  if (!timeout){
    printf("ERROR:  *** failed to complete RX/TX loopack before timeout *** \r\n");
    return;
  }

}




