#include <stdlib.h>
#include <stdio.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <unistd.h>
#include <cstring>

//#include <sys/types.h>
//#include <sys/stat.h>
//#include <sys/mman.h>
//#include <zmq.h>
//#include <cerrno>

#include "version.hh"
#include "addr_conf.hh"
#include "pacman.hh"
#include "tx_buffer.hh"
#include "rx_buffer.hh"
#include "pacman_i2c.hh"

volatile uint32_t * G_PACMAN_AXIL = NULL;
volatile uint32_t * G_PACMAN_DMA  = NULL;
volatile uint32_t * G_PACMAN_DMA_TX_BUFFER = NULL;
volatile uint32_t * G_PACMAN_DMA_RX_BUFFER = NULL;

//PACMAN SERVER Scratch Registers (Accessible at PACMAN_SERVER_VIRTUAL_START + (0, 1)
uint32_t G_PACMAN_SERVER_SCRA = 0x0;
uint32_t G_PACMAN_SERVER_SCRB = 0x0;

int pacman_init(int verbose){
  // initialize axi-lite
  if (verbose){
    printf("INFO:  Initializing PACMAN AXI-Lite interface.\n");
  }

  int dh = open("/dev/mem", O_RDWR|O_SYNC);
  G_PACMAN_AXIL = (uint32_t*)mmap(NULL, PACMAN_AXIL_LEN, PROT_READ|PROT_WRITE, MAP_SHARED, dh, PACMAN_AXIL_ADDR);

  unsigned fwmajor = G_PACMAN_AXIL[0XFF10>>2];
  unsigned fwminor = G_PACMAN_AXIL[0XFF14>>2];
  unsigned fwbuild = G_PACMAN_AXIL[0XFF18>>2];
  unsigned hwcode  = G_PACMAN_AXIL[0XFF1C>>2];

  if (verbose){
    printf("INFO:  Running pacman-server version %d.%d\n", PACMAN_SERVER_MAJOR_VERSION, PACMAN_SERVER_MINOR_VERSION);
    printf("INFO:  Running pacman firmware version %d.%d (Build: 0x%x  HW Code:  0x%x)\n", fwmajor, fwminor, fwbuild, hwcode);
  }

  // I2C
  if (verbose){
    printf("INFO:  Initializing PACMAN I2C interface.\n");
  }
  if (! (i2c_open()==EXIT_SUCCESS)){
    printf("ERROR:  Could not open PACMAN I2C interface...\n");
  }
  unsigned i2cmajor = i2c_read(0x220);
  unsigned i2cminor = i2c_read(0x221);
  unsigned i2cdebug = i2c_read(0x222);
  
  // I2C
  if (verbose){
    printf("INFO:  Running I2C firmware version %d.%d (Debug Code:  0x%x)\n", i2cmajor, i2cminor, i2cdebug);
  }

  // DEFAULT parameters
  if (verbose){
    printf("INFO:  Enabling Trigger, Sync, and Heartbeat words in the RX unit.\n");
  }
  G_PACMAN_AXIL[0x7FA4>>2] = 0x7;

  //if (verbose){
  //  printf("INFO:  Limiting TX bandwidth.\n");
  //}
  //G_PACMAN_AXIL[0x3B04>>2] = 0x05281602;
  G_PACMAN_AXIL[0x3B04>>2] = 0x00001602;

  return EXIT_SUCCESS;
}

#define REG_DMA_TX_CONTROL 0x0000
#define REG_DMA_TX_STATUS  0x0004
#define REG_DMA_RX_CONTROL 0x0030
#define REG_DMA_RX_STATUS  0x0034

#define MASK_DMA_CR_RUN    0x0001
#define MASK_DMA_CR_RESET  0x0004

#define MASK_DMA_SR_HALTED 0x0001
#define MASK_DMA_SR_IDLE   0x0002

void print_dma_status(unsigned cr, unsigned sr){
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

int pacman_init_tx(int verbose, int skip_reset){
  unsigned timeout, cr, sr;
  // initialize DMA TX
  if (verbose){
    printf("INFO:  Initializing PACMAN DMA TX interface.\n");
    printf("INFO:  Initializing DMA contol interface (AXIL).\n");
  }

  int dh = open("/dev/mem", O_RDWR|O_SYNC);
  G_PACMAN_DMA = (uint32_t*)mmap(NULL, DMA_LEN, PROT_READ|PROT_WRITE, MAP_SHARED, dh, DMA_ADDR);

  if (verbose){
    printf("INFO:  Initializing DMA TX_BUFFER.\n");
  }

  G_PACMAN_DMA_TX_BUFFER = (uint32_t*)mmap(NULL, DMA_TX_MAXLEN, PROT_READ|PROT_WRITE, MAP_SHARED, dh, DMA_TX_ADDR);

  if (skip_reset) {
    if (verbose)
      printf("INFO:  Skipping reset of DMA TX.\n");
  } else {
    if (verbose)
      printf("INFO:  Reseting DMA TX.\n");
    G_PACMAN_DMA[REG_DMA_TX_CONTROL>>2] = MASK_DMA_CR_RESET;

    timeout=100;
    while(timeout){
      usleep(1);
      if ((G_PACMAN_DMA[REG_DMA_TX_CONTROL>>2] & MASK_DMA_CR_RESET) == 0)
	break;
      timeout--;
    }
    if (! timeout) {
      printf("ERROR:  Timeout waiting on DMA reset.");
      return EXIT_FAILURE;
    }
    if (verbose)
      printf("INFO:  Reset of DMA TX was successful. (timeout=%d)\n", timeout);
  }


  if (verbose)
    printf("INFO:  Setting DMA TX to RUN.\n");

  G_PACMAN_DMA[REG_DMA_TX_CONTROL>>2] = MASK_DMA_CR_RUN;

  // verify that we leave the HALTED state:
  timeout=100;
  while(timeout){
    usleep(1);
    if ((G_PACMAN_DMA[REG_DMA_TX_STATUS>>2] & MASK_DMA_SR_HALTED) == 0)
      break;
    timeout--;
  }
  if (! timeout) {
    printf("ERROR:  Timeout waiting for DMA TX to leave the HALTED state.");
    return EXIT_FAILURE;
  } else {
    printf("INFO:  DMA TX has left the HALTED state successfully. (timeout=%d)\n", timeout);
  }

  // verify that we enter the RUN state:
  timeout=100;
  while(timeout){
    usleep(1);
    if ((G_PACMAN_DMA[REG_DMA_TX_CONTROL>>2] & MASK_DMA_CR_RUN) != 0)
      break;
    timeout--;
  }
  if (! timeout) {
    printf("ERROR:  Timeout waiting for DMA TX to enter RUN state.");
    return EXIT_FAILURE;
  } else {
    printf("INFO:  DMA TX has entered RUN state successfully. (timeout=%d)\n", timeout);
  }

  cr = G_PACMAN_DMA[REG_DMA_TX_CONTROL>>2];
  sr = G_PACMAN_DMA[REG_DMA_TX_STATUS>>2];
  printf("DMA TX control register (MM2S) - 0x%x \n", cr);
  printf("DMA TX status register  (MM2S) - 0x%x \n", sr);
  print_dma_status(cr, sr);



  return EXIT_SUCCESS;
}

int pacman_init_rx(int verbose, int skip_reset){
  unsigned timeout, cr, sr;
  // initialize DMA RX
  if (verbose){
    printf("INFO:  Initializing PACMAN DMA RX interface.\n");
    printf("INFO:  Initializing DMA contol interface (AXIL).\n");
  }

  int dh = open("/dev/mem", O_RDWR|O_SYNC);
  G_PACMAN_DMA = (uint32_t*)mmap(NULL, DMA_LEN, PROT_READ|PROT_WRITE, MAP_SHARED, dh, DMA_ADDR);

  if (verbose){
    printf("INFO:  Initializing DMA RX_BUFFER.\n");
  }

  G_PACMAN_DMA_RX_BUFFER = (uint32_t*)mmap(NULL, DMA_RX_MAXLEN, PROT_READ|PROT_WRITE, MAP_SHARED, dh, DMA_RX_ADDR);

  if (skip_reset) {
    if (verbose)
      printf("INFO:  Skipping reset of DMA RX.\n");
  } else {
    if (verbose)
      printf("INFO:  Reseting DMA RX.\n");
    G_PACMAN_DMA[REG_DMA_RX_CONTROL>>2] = MASK_DMA_CR_RESET;

    timeout=100;
    while(timeout){
      usleep(1);
      if ((G_PACMAN_DMA[REG_DMA_RX_CONTROL>>2] & MASK_DMA_CR_RESET) == 0)
	break;
      timeout--;
    }
    if (! timeout) {
      printf("ERROR:  Timeout waiting on DMA reset.");
      return EXIT_FAILURE;
    }
    if (verbose)
      printf("INFO:  Reset of DMA RX was successful. (timeout=%d)\n", timeout);
  }


  if (verbose)
    printf("INFO:  Setting DMA RX to RUN.\n");

  G_PACMAN_DMA[REG_DMA_RX_CONTROL>>2] = MASK_DMA_CR_RUN;

  // verify that we leave the HALTED state:
  timeout=100;
  while(timeout){
    usleep(1);
    if ((G_PACMAN_DMA[REG_DMA_RX_STATUS>>2] & MASK_DMA_SR_HALTED) == 0)
      break;
    timeout--;
  }
  if (! timeout) {
    printf("ERROR:  Timeout waiting for DMA RX to leave the HALTED state.");
    return EXIT_FAILURE;
  } else {
    printf("INFO:  DMA RX has left the HALTED state successfully. (timeout=%d)\n", timeout);
  }

  // verify that we enter the RUN state:
  timeout=100;
  while(timeout){
    usleep(1);
    if ((G_PACMAN_DMA[REG_DMA_RX_CONTROL>>2] & MASK_DMA_CR_RUN) != 0)
      break;
    timeout--;
  }
  if (! timeout) {
    printf("ERROR:  Timeout waiting for DMA RX to enter RUN state.");
    return EXIT_FAILURE;
  } else {
    printf("INFO:  DMA RX has entered RUN state successfully. (timeout=%d)\n", timeout);
  }

  printf("INFO:  Sending initial DMA read request.\n");
  G_PACMAN_DMA[0x0048>>2] = DMA_RX_ADDR;
  G_PACMAN_DMA[0x0058>>2] = DMA_RX_MAXLEN;


  cr = G_PACMAN_DMA[REG_DMA_RX_CONTROL>>2];
  sr = G_PACMAN_DMA[REG_DMA_RX_STATUS>>2];
  printf("DMA RX control register (MM2S) - 0x%x \n", cr);
  printf("DMA RX status register  (MM2S) - 0x%x \n", sr);
  print_dma_status(cr, sr);

  return EXIT_SUCCESS;
}

int pacman_poll_rx(){
  static int read_requested = 0;
  static int start = 0;
  unsigned max_words = 0x0400; // enough for > 20 read cycles of all 40 uarts
  unsigned bytes = 0x4; // bytes per word
  uint32_t rx_data[4];

  if (! read_requested) {
    read_requested = 1;
    start = 1;
    //printf("*** Sending run*** \n");
    G_PACMAN_DMA[(0x30)>>2] = 0x01;

    //printf("*** Clearing RX buffer *** \n");
    for (int i=0; i<max_words; i++)
      G_PACMAN_DMA_RX_BUFFER[i] = 0;

    //printf("INFO:  DMA request to read data.\n");
    G_PACMAN_DMA[0x0048>>2] = DMA_RX_ADDR;
    G_PACMAN_DMA[0x0058>>2] = max_words*bytes;
  }
  
  //printf("INFO:  Checking for IDLE.\n");
  
  unsigned sr = G_PACMAN_DMA[(0x34)>>2];
  if ((sr&0x2)==0){
    if (start){
      //printf("DEBUG:  *** waiting for idle *** \n");
      start = 0;
    }
    return EXIT_SUCCESS;
  }
  
  read_requested = 0;  
  for (int i=0; i<max_words/4; i++){
    rx_data[3] = G_PACMAN_DMA_RX_BUFFER[4*i+3];
    rx_data[2] = G_PACMAN_DMA_RX_BUFFER[4*i+2];
    rx_data[1] = G_PACMAN_DMA_RX_BUFFER[4*i+1];
    rx_data[0] = G_PACMAN_DMA_RX_BUFFER[4*i+0];
    //printf("%d 0x%08x %08x %08x %08x\n", i, rx_data[3], rx_data[2], rx_data[1], rx_data[0]);
    if (rx_data[0]==0) {
      if (rx_data[2] == i) {
	//printf("Valid packet of size %d\n", i);
      } else {
	printf("ERROR: *** Invalid Packet Detected ***\n");
	printf("ERROR: 0x%x(%d) 0x%x %x %x %x \n", i, i, rx_data[0], rx_data[1], rx_data[2], rx_data[3]);
      }
      break;
    }
    rx_buffer_in(rx_data);
  }

  return EXIT_SUCCESS;
}

int pacman_poll_tx(){
  unsigned cr, sr;
  static uint32_t output[TX_BUFFER_BYTES/4];

  //cr = G_PACMAN_DMA[REG_DMA_TX_CONTROL>>2];
  //sr = G_PACMAN_DMA[REG_DMA_TX_STATUS>>2];
  //printf("DMA TX control register (MM2S) - 0x%x \n", cr);
  //printf("DMA TX status register  (MM2S) - 0x%x \n", sr);
  //print_dma_status(cr, sr);

  while (tx_buffer_out(output)==1){
    tx_buffer_print_output(output);

    for (int i=0; i<84*4; i++)
      G_PACMAN_DMA_TX_BUFFER[i] = output[i];

    G_PACMAN_DMA[0x0018>>2] = DMA_TX_ADDR;
    G_PACMAN_DMA[0x0028>>2] = 84*4;

    usleep(100);
    //cr = G_PACMAN_DMA[REG_DMA_TX_CONTROL>>2];
    //sr = G_PACMAN_DMA[REG_DMA_TX_STATUS>>2];
    //printf("DMA TX control register (MM2S) - 0x%x \n", cr);
    //printf("DMA TX status register  (MM2S) - 0x%x \n", sr);
    //print_dma_status(cr, sr);
  }
  return EXIT_SUCCESS;
}

int pacman_write(uint32_t addr, uint32_t value){
  printf("DEBUG:  writing HW address 0x%x\n", addr);
  G_PACMAN_AXIL[addr>>2] = value;
  return EXIT_SUCCESS;
}


uint32_t pacman_read(uint32_t addr, int * status){
  if (status)
    *status = EXIT_SUCCESS;
  return G_PACMAN_AXIL[addr>>2];
}
