#include <stdlib.h>
#include <stdio.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <unistd.h>
#include <cstring>
#include <stdint.h>
#include "version.hh"
#include "addr_conf.hh"

volatile uint32_t * G_UTIL_AXIL = NULL;
volatile uint32_t * G_UTIL_DMA  = NULL;
volatile uint32_t * G_UTIL_DMA_TX_BUFFER = NULL;
volatile uint32_t * G_UTIL_DMA_RX_BUFFER = NULL;

//#define ADDR_AXIL_REGS  XPAR_AXIL_TO_REGBUS_0_BASEADDR 

#define SCOPE_GLOBAL 0xF000
#define ROLE_GLOBAL  0x0F00
#define ROLE_TIMING  0x0E00

#define SCOPE_TX       0x0000
#define SCOPE_RX       0x4000
#define UART_GLOBAL    0x3F00
#define UART_BROADCAST 0x3B00

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

uint32_t tx_mask_b = 0xFF;
uint32_t tx_mask_a = 0xFFFFFFFF;

#define C_ADDR_GLOBAL_SCRA      0x00
#define C_ADDR_GLOBAL_SCRB      0x04
#define C_ADDR_GLOBAL_FW_MAJOR  0x10
#define C_ADDR_GLOBAL_FW_MINOR  0x14
#define C_ADDR_GLOBAL_FW_BUILD  0x18
#define C_ADDR_GLOBAL_HW_CODE   0x1C
#define C_ADDR_GLOBAL_ENABLES   0x20

#define C_ADDR_TIMING_STATUS  0x00
#define C_ADDR_TIMING_STAMP   0x04
#define C_ADDR_TIMING_TRIG    0x20
#define C_ADDR_TIMING_SYNC    0x24

void read_global_status(){
  printf("fw major----------- %d   \n", G_UTIL_AXIL[(SCOPE_GLOBAL+ROLE_GLOBAL+C_ADDR_GLOBAL_FW_MAJOR)>>2]);
  printf("fw minor----------- %d   \n", G_UTIL_AXIL[(SCOPE_GLOBAL+ROLE_GLOBAL+C_ADDR_GLOBAL_FW_MINOR)>>2]);
  printf("fw build----------- 0x%x \n", G_UTIL_AXIL[(SCOPE_GLOBAL+ROLE_GLOBAL+C_ADDR_GLOBAL_FW_BUILD)>>2]);
  printf("hw code------------ 0x%x \n", G_UTIL_AXIL[(SCOPE_GLOBAL+ROLE_GLOBAL+C_ADDR_GLOBAL_HW_CODE)>>2]);
  printf("scratch a---------- 0x%x \n", G_UTIL_AXIL[(SCOPE_GLOBAL+ROLE_GLOBAL+C_ADDR_GLOBAL_SCRA)>>2]);
  printf("scratch b---------- 0x%x \n", G_UTIL_AXIL[(SCOPE_GLOBAL+ROLE_GLOBAL+C_ADDR_GLOBAL_SCRB)>>2]);
  printf("\n");
  printf("enables------------ 0x%x \n", G_UTIL_AXIL[(SCOPE_GLOBAL+ROLE_GLOBAL+C_ADDR_GLOBAL_ENABLES)>>2]);
  printf("\n");
  printf("timing status-------0x%x \n", G_UTIL_AXIL[(SCOPE_GLOBAL+ROLE_TIMING+C_ADDR_TIMING_STATUS)>>2]);
  printf("trig config---------0x%x \n", G_UTIL_AXIL[(SCOPE_GLOBAL+ROLE_TIMING+C_ADDR_TIMING_TRIG)>>2]);
  printf("sync config---------0x%x \n", G_UTIL_AXIL[(SCOPE_GLOBAL+ROLE_TIMING+C_ADDR_TIMING_SYNC)>>2]);
  printf("\n");
  printf("timestamp-----------0x%x \n", G_UTIL_AXIL[(SCOPE_GLOBAL+ROLE_TIMING+C_ADDR_TIMING_STAMP)>>2]);
}

void toggle_scratch(){
  unsigned scra, scrb;
  static int mode = 0;
  mode = (mode + 1) % 3;  
  switch(mode){
    case 1:
      scra = 0xAAAAAAAA;
      scrb = 0xBBBBBBBB;
      break;
    case 2:
      scra = 0x12341234;
      scrb = 0x7777FFFF;
      break;
    default:
      scra = 0x0;
      scrb = 0x0;
  }
  printf("INFO: setting scratch a to 0x%08x and scratch b to 0x%08x \n", scra, scrb);  
  G_UTIL_AXIL[(SCOPE_GLOBAL+ROLE_GLOBAL+C_ADDR_GLOBAL_SCRA)>>2] = scra;
  G_UTIL_AXIL[(SCOPE_GLOBAL+ROLE_GLOBAL+C_ADDR_GLOBAL_SCRB)>>2] = scrb;
}

void toggle_enables(){
  unsigned enables[] = {0x00000000, 0x00010000, 0x00010001,  0x000103FF, 0x010103FF};
  static int mode = 0;
  mode = (mode + 1) % 5;  
  printf("INFO: setting enables to 0x%08x \n", enables[mode]);
  G_UTIL_AXIL[(SCOPE_GLOBAL+ROLE_GLOBAL+C_ADDR_GLOBAL_ENABLES)>>2] = enables[mode];
}

void toggle_rx_config(){
  static int mode = 0;
  mode = (mode + 1) % 3;
  if (mode==0){
    unsigned config = 0x00001001;
    printf("INFO: No internal loopback.  Broadcasting rx config write 0x%08x \n", config);
    G_UTIL_AXIL[(SCOPE_RX+UART_BROADCAST+C_ADDR_RX_CONFIG)>>2] = config;
  } else if (mode==1) {
    unsigned config = 0x00011001;
    printf("INFO: Full internal loopback.  Broadcasting rx configs write 0x%08x \n", config);
    G_UTIL_AXIL[(SCOPE_RX+UART_BROADCAST+C_ADDR_RX_CONFIG)>>2] = config;
  } else if (mode==2) {
    unsigned config;
    config = 0x00011001;
    printf("INFO: Tiles 2-10 use internal loopback.  Broadcasting rx configs t 0x%08x \n", config);
    G_UTIL_AXIL[(SCOPE_RX+UART_BROADCAST+C_ADDR_RX_CONFIG)>>2] = config;
    config = 0x00001001;
    printf("INFO: Tile 1 does not use internal loopback.  Setting Tile 1 rx config 0x%08x \n", config);
    G_UTIL_AXIL[(SCOPE_RX+(0<<8)+C_ADDR_RX_CONFIG)>>2] = config;
    G_UTIL_AXIL[(SCOPE_RX+(1<<8)+C_ADDR_RX_CONFIG)>>2] = config;
    G_UTIL_AXIL[(SCOPE_RX+(2<<8)+C_ADDR_RX_CONFIG)>>2] = config;
    G_UTIL_AXIL[(SCOPE_RX+(3<<8)+C_ADDR_RX_CONFIG)>>2] = config;
  }
}


void read_rx_status(){
  for (int i=0; i<40; i++){
    unsigned cshift  = (i<<8);
    unsigned status  = G_UTIL_AXIL[(SCOPE_RX+cshift+C_ADDR_RX_STATUS)>>2];
    unsigned config  = G_UTIL_AXIL[(SCOPE_RX+cshift+C_ADDR_RX_CONFIG)>>2];
    unsigned starts  = G_UTIL_AXIL[(SCOPE_RX+cshift+C_ADDR_RX_STARTS)>>2];
    unsigned beats   = G_UTIL_AXIL[(SCOPE_RX+cshift+C_ADDR_RX_BEATS)>>2];
    unsigned updates = G_UTIL_AXIL[(SCOPE_RX+cshift+C_ADDR_RX_UPDATES)>>2];
    unsigned lost    = G_UTIL_AXIL[(SCOPE_RX+cshift+C_ADDR_RX_LOST)>>2];
    unsigned nchan   = G_UTIL_AXIL[(SCOPE_RX+cshift+C_ADDR_RX_NCHAN)>>2];
    printf("%2d: ch: %2d cfg: 0x%08x status: 0x%08x s: %d b: %d u: %d l: %d\n",i, nchan, config, status, starts, beats, updates, lost);
  }
  printf("gstatus----------- 0x%x    \n", G_UTIL_AXIL[(SCOPE_RX+0x3F00+C_ADDR_RX_GSTATUS)>>2]);
  printf("gflags------------ 0x%x    \n", G_UTIL_AXIL[(SCOPE_RX+0x3F00+C_ADDR_RX_GFLAGS)>>2]);
  printf("FIFO R count-------%d      \n", G_UTIL_AXIL[(SCOPE_RX+0x3F00+C_ADDR_RX_FRCNT)>>2]);
  printf("FIFO W count-------%d      \n", G_UTIL_AXIL[(SCOPE_RX+0x3F00+C_ADDR_RX_FWCNT)>>2]);
  printf("DMA ITR------------0x%x    \n", G_UTIL_AXIL[(SCOPE_RX+0x3F00+C_ADDR_RX_DMAITR)>>2]);
}

void read_rx_look(){
  for (int i=0; i<40; i++){
    unsigned cshift = (i<<8);
    unsigned a = G_UTIL_AXIL[(SCOPE_RX+cshift+C_ADDR_RX_LOOK_A)>>2];
    unsigned b = G_UTIL_AXIL[(SCOPE_RX+cshift+C_ADDR_RX_LOOK_B)>>2];
    unsigned c = G_UTIL_AXIL[(SCOPE_RX+cshift+C_ADDR_RX_LOOK_C)>>2];
    unsigned d = G_UTIL_AXIL[(SCOPE_RX+cshift+C_ADDR_RX_LOOK_D)>>2];
    printf("Channel %2d Look:  0x%08x %08x %08x %08x\n", i, d, c, b, a);
  }
}

void read_tx_status(){
  for (int i=0; i<40; i++){
    unsigned cshift = (i<<8);
    unsigned status = G_UTIL_AXIL[(SCOPE_TX+cshift+C_ADDR_TX_STATUS)>>2];
    unsigned config = G_UTIL_AXIL[(SCOPE_TX+cshift+C_ADDR_TX_CONFIG)>>2];
    unsigned starts = G_UTIL_AXIL[(SCOPE_TX+cshift+C_ADDR_TX_STARTS)>>2];
    unsigned nchan  = G_UTIL_AXIL[(SCOPE_TX+cshift+C_ADDR_TX_NCHAN)>>2];
    printf("%2d:  chan: %2d config: 0x%08x status: 0x%08x starts: %d\n",i, nchan, config, status, starts);
  }
  printf("gflags------------ 0x%x    \n", G_UTIL_AXIL[(SCOPE_TX+0x3F00+C_ADDR_TX_GFLAGS)>>2]);
  printf("bstatus----------- 0x%x    \n", G_UTIL_AXIL[(SCOPE_TX+0x3F00+C_ADDR_TX_STATUS)>>2]);
}

void read_tx_look(){
  for (int i=0; i<40; i++){
    unsigned cshift = (i<<8);
    unsigned d = G_UTIL_AXIL[(SCOPE_TX+cshift+C_ADDR_TX_LOOK_D)>>2];
    unsigned c = G_UTIL_AXIL[(SCOPE_TX+cshift+C_ADDR_TX_LOOK_C)>>2];
    printf("Channel %2d Look:  0x%08x %08x\n", i, d, c);
  }
}


void check_trig_sync(){
  unsigned stat, tstamp;
  stat   = G_UTIL_AXIL[(SCOPE_GLOBAL+ROLE_TIMING+C_ADDR_TIMING_STATUS)>>2];
  tstamp = G_UTIL_AXIL[(SCOPE_GLOBAL+ROLE_TIMING+C_ADDR_TIMING_STAMP)>>2];
  printf("timing status-------0x%x \n", stat);
  printf("time stamp----------0x%x \n", tstamp);
  printf("trig config---------0x%x \n", G_UTIL_AXIL[(SCOPE_GLOBAL+ROLE_TIMING+C_ADDR_TIMING_TRIG)>>2]);
  printf("sync config---------0x%x \n", G_UTIL_AXIL[(SCOPE_GLOBAL+ROLE_TIMING+C_ADDR_TIMING_SYNC)>>2]);

  G_UTIL_AXIL[(SCOPE_GLOBAL+ROLE_TIMING+C_ADDR_TIMING_TRIG)>>2] = 0x00FF03FF;
  G_UTIL_AXIL[(SCOPE_GLOBAL+ROLE_TIMING+C_ADDR_TIMING_SYNC)>>2] = 0x00FF03FF;
  stat   = G_UTIL_AXIL[(SCOPE_GLOBAL+ROLE_TIMING+C_ADDR_TIMING_STATUS)>>2];
  tstamp = G_UTIL_AXIL[(SCOPE_GLOBAL+ROLE_TIMING+C_ADDR_TIMING_STAMP)>>2];
  printf("timing status-------0x%x \n", stat);
  printf("time stamp----------0x%x \n", tstamp);  
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
  printf("RX mask:  0x%08x %08x \n", tx_mask_b, tx_mask_a);
}

void zero_counts(){
  G_UTIL_AXIL[(SCOPE_TX+0x3F00+C_ADDR_TX_STARTS)>>2] = 0x0;
  G_UTIL_AXIL[(SCOPE_RX+0x3F00+C_ADDR_RX_ZERO_CNTS)>>2] = 0x0;
}

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

  dma_status();
    
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

		
int main(){
  printf("PACMAN command line utility driver \n");
  printf("Sanity number:  3\n");
  printf("Random Max:  0x%x Random Number:  0x%x \n", RAND_MAX, rand());

  printf("INFO:  Opening /dev/mem.\n");
  int dh = open("/dev/mem", O_RDWR|O_SYNC);
  
  printf("INFO:  Initializing PACMAN AXI-Lite interface.\n");
  G_UTIL_AXIL = (uint32_t*)mmap(NULL, PACMAN_AXIL_LEN, PROT_READ|PROT_WRITE, MAP_SHARED, dh, PACMAN_AXIL_ADDR);

  printf("INFO:  Initializing DMA contol interface (AXIL).\n");  
  G_UTIL_DMA = (uint32_t*)mmap(NULL, DMA_LEN, PROT_READ|PROT_WRITE, MAP_SHARED, dh, DMA_ADDR);

  printf("INFO:  Initializing DMA TX_BUFFER.\n");
  G_UTIL_DMA_TX_BUFFER = (uint32_t*)mmap(NULL, DMA_TX_MAXLEN, PROT_READ|PROT_WRITE, MAP_SHARED, dh, DMA_TX_ADDR);

  printf("INFO:  Initializing DMA RX_BUFFER.\n");
  G_UTIL_DMA_RX_BUFFER = (uint32_t*)mmap(NULL, DMA_RX_MAXLEN, PROT_READ|PROT_WRITE, MAP_SHARED, dh, DMA_RX_ADDR);
  
  unsigned fwmajor = G_UTIL_AXIL[0XFF10>>2];
  unsigned fwminor = G_UTIL_AXIL[0XFF14>>2];
  unsigned fwbuild = G_UTIL_AXIL[0XFF18>>2];
  unsigned hwcode  = G_UTIL_AXIL[0XFF1C>>2];

  printf("INFO:  Running pacman-server version %d.%d\n", PACMAN_SERVER_MAJOR_VERSION, PACMAN_SERVER_MINOR_VERSION);
  printf("INFO:  Running pacman firmware version %d.%d (Build: 0x%x  HW Code:  0x%x)\n", fwmajor, fwminor, fwbuild, hwcode);

  
  while(1){
    printf("choose an option:\n");
    printf("(1) read global status (2) toggle scratch (3) toggle enables (4) test trig and sync \n");
    printf("TX: (10) read tx status (11) read tx look (12) single tx (13) toggle_tx_mask \n");
    printf("RX: (20) read rx status (21) read rx look (22) single rx (23) toggle_rx_config \n");
    printf("TX&RX: (30) zero counts \n");
    printf("DMA: (40) read DMA status (41) reset DMA \n");

    int input;
    scanf("%d", &input);
    printf("pressed:  %d\n", input);

    switch(input){
    case 1:
      read_global_status();
      break;      
    case 2:
      toggle_scratch();
      break;      
    case 3:
      toggle_enables();
      break;      
    case 4:
      check_trig_sync();
      break;      
    case 10:
      read_tx_status();
      break;
    case 11:
      read_tx_look();
      break;
    case 12:
      single_tx();
      break;
    case 13:
      toggle_tx_mask();
      break;            
    case 20:
      read_rx_status();
      break;
    case 21:
      read_rx_look();
      break;
    case 22:
      single_rx();
      break;            
    case 23:
      toggle_rx_config();
      break;      
    case 30:
      zero_counts();
      break;
    case 40:
      dma_status();
      break;
    case 41:
      reset_dma();
      break;

    default:
      printf("invalid selection...\n\r");
    }
  }
  return 0;
}




