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

volatile uint32_t * G_UTIL_DMA  = NULL;
volatile uint32_t * G_UTIL_DMA_TX_BUFFER = NULL;
volatile uint32_t * G_UTIL_DMA_RX_BUFFER = NULL;

static uint32_t tx_mask_b = 0xFF;
static uint32_t tx_mask_a = 0xFFFFFFFF;

void dma_status(){
  unsigned cr, sr;
  cr = G_UTIL_DMA[(0x30)>>2];
  sr = G_UTIL_DMA[(0x34)>>2];
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

  cr = G_UTIL_DMA[(0x00)>>2];
  sr = G_UTIL_DMA[(0x04)>>2];

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

void single_tx(){
  // TX buffer is a 128 bit header plus 40 uarts allocated 64 bits each.
  // This is a total of 84 32-bit words (4 header words, 80 uart words)
  // The resulting AXI stream is 128 bits times 21 beats.

  static int count = 0;
  unsigned words = 84;

  printf("*** Sending run*** \n");
  G_UTIL_DMA[(0x00)>>2] = 0x01;

  dma_status();

  G_UTIL_DMA_TX_BUFFER[0] = tx_mask_a;
  G_UTIL_DMA_TX_BUFFER[1] = tx_mask_b;
  G_UTIL_DMA_TX_BUFFER[2] = 0x0;
  G_UTIL_DMA_TX_BUFFER[3] = 0x0;

  for (int i=0; i<(words-4); i++)
    G_UTIL_DMA_TX_BUFFER[i+4] = 0xB000F000 + i + (count<<16);

  printf("*** Sending write *** \n");
  printf(" count = %d \n", count);
  count++;

  G_UTIL_DMA[(0x18)>>2] = DMA_TX_ADDR;
  G_UTIL_DMA[(0x28)>>2] = words*4;

  unsigned timeout = 10000;
  unsigned start = 1;
  while(timeout){
    unsigned sr = G_UTIL_DMA[(0x04)>>2];
    if ((sr&0x2)!=0)
      break;
    if (start){
      printf("*** waiting for idle *** \n");
      start = 0;
    }
    usleep(1000);
    timeout--;
  }
  if (! timeout) {
    printf("*** ERROR:  failed to reach idle before timeout! *** \n");
    return;
  }
}

void single_rx(){
  unsigned max_words = 0x0400; // enough for > 20 read cycles of all 40 uarts
  unsigned bytes = 0x4; // bytes per word

  printf("*** Sending run*** \n");
  G_UTIL_DMA[(0x30)>>2] = 0x01;

  printf("*** Clearing RX buffer *** \n");
  for (int i=0; i<max_words; i++)
    G_UTIL_DMA_RX_BUFFER[i] = 0;

  printf("*** Sending read *** \n");
  G_UTIL_DMA[(0x48)>>2] = DMA_RX_ADDR;
  G_UTIL_DMA[(0x58)>>2] = max_words*bytes;

  unsigned timeout = 10000;
  unsigned start = 1;
  while(timeout){
    unsigned sr = G_UTIL_DMA[(0x34)>>2];
    if ((sr&0x2)!=0)
      break;
    if (start){
      printf("*** waiting for idle *** \n");
      start = 0;
    }
    usleep(1);
    timeout--;
  }

  for (int i=0; i<max_words/4; i++){
    unsigned d = G_UTIL_DMA_RX_BUFFER[4*i+3];
    unsigned c = G_UTIL_DMA_RX_BUFFER[4*i+2];
    unsigned b = G_UTIL_DMA_RX_BUFFER[4*i+1];
    unsigned a = G_UTIL_DMA_RX_BUFFER[4*i+0];
    printf("%d 0x%08x %08x %08x %08x\n", i, d, c, b, a);
    if (a==0) {
      if (c == i) {
	printf("Valid packet of size %d\n", i);
      } else {
	printf("*** Error Invalid Packet Detected ***\n");
      }
      break;
    }
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

  printf("*** Sending run*** \n");
  G_UTIL_DMA[(0x00)>>2] = 0x01;


  G_UTIL_DMA_TX_BUFFER[0] = tx_mask_a;
  G_UTIL_DMA_TX_BUFFER[1] = tx_mask_b;
  G_UTIL_DMA_TX_BUFFER[2] = 0x0;
  G_UTIL_DMA_TX_BUFFER[3] = 0x0;

  for (int i=0; i<(tx_words-4); i++)
    G_UTIL_DMA_TX_BUFFER[i+4] = 0xB000F000 + i + (count<<16);


  gettimeofday(&start, NULL);

  for (int i=0; i<10; i++){
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
  printf("maximum tx rate:      %d tx payloads (64-bit+2 @ 10 MHz) per ms\n", m);
  printf("practical max:        %d tx payloads (64-bit+3 @ 10 MHz) per ms\n", p);
}

void benchmark_rxtx_loopback(){
  struct timeval start, end;
  printf("*** Benchmarking RX *** \n");
  unsigned tx_words = 84;
  unsigned rx_words = 164;

  printf("*** Sending run to TX and RX *** \n");
  G_UTIL_DMA[(0x00)>>2] = 0x01; // TX
  G_UTIL_DMA[(0x30)>>2] = 0x01; // RX

  G_UTIL_DMA_TX_BUFFER[0] = tx_mask_a;
  G_UTIL_DMA_TX_BUFFER[1] = tx_mask_b;
  G_UTIL_DMA_TX_BUFFER[2] = 0x0;
  G_UTIL_DMA_TX_BUFFER[3] = 0x0;

  for (int i=0; i<(tx_words-4); i++)
    G_UTIL_DMA_TX_BUFFER[i+4] = 0xB000F000 + i;

  gettimeofday(&start, NULL);


  unsigned tx_packets = 10;
  unsigned packets_sent   = 0;
  unsigned packets_rcvd   = 0;
  unsigned timeout = 100000;

  while ((timeout>0) && (packets_rcvd < tx_packets)){
    unsigned fifocnt = read_axil(SCOPE_RX+0x3F00+C_ADDR_RX_FRCNT);
    unsigned gstatus = read_axil(SCOPE_TX+0x3F00+C_ADDR_TX_STATUS);
    unsigned sr = G_UTIL_DMA[(0x04)>>2];

    if ( (packets_sent < tx_packets) && (fifocnt<100) && (gstatus == 0x1) && (((sr&0x2)!=0) || (packets_sent==0)) ) {
      G_UTIL_DMA[(0x18)>>2] = DMA_TX_ADDR;
      G_UTIL_DMA[(0x28)>>2] = tx_words*4;
      packets_sent++;
    }

    if (fifocnt>=24) {
      unsigned sr = G_UTIL_DMA[(0x34)>>2];
      if (((sr&0x2)!=0) || (packets_rcvd==0)){
	G_UTIL_DMA[(0x48)>>2] = DMA_RX_ADDR;
	G_UTIL_DMA[(0x58)>>2] = rx_words*4;
	packets_rcvd += 1;
      }
    }
    usleep(1);
    timeout--;
  }

  // no cheating!  wait on receipt of final package before stopping timer.
  timeout = 1000;
  while(timeout){
    unsigned sr = G_UTIL_DMA[(0x34)>>2];
    if ((sr&0x2)!=0)
      break;
    usleep(1);
    timeout--;
  }

  gettimeofday(&end, NULL);
  double elapsed_time = 1000.0*(end.tv_sec - start.tv_sec) + (end.tv_usec - start.tv_usec) / 1000.0;

  printf("INFO: sent %d packets\n", packets_sent);
  printf("INFO: rcvd %d packets\n", packets_rcvd);
  printf("INFO: elapsed time %lf ms \n", elapsed_time);

  unsigned m = 40.0*10000/66;
  unsigned p = 40.0*10000/67;
  printf("maximum tx rate:      %d tx payloads (64-bit+2 @ 10 MHz) per ms\n", m);
  printf("practical max:        %d tx payloads (64-bit+3 @ 10 MHz) per ms\n", p);

  if (!timeout){
    printf("*** ERROR:  failed to complete packet loopack before timeout *** \r\n");
    return;
  }

}


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



