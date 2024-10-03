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

#include "dma.hh"
#include "larpix.hh"
#include "version.hh"
#include "addr_conf.hh"
#include "pacman.hh"
#include "tx_buffer.hh"
#include "rx_buffer.hh"
#include "pacman_i2c.hh"

static volatile uint32_t * G_PACMAN_AXIL = NULL;
static volatile uint32_t * G_PACMAN_DMA  = NULL;
static volatile uint32_t * G_PACMAN_DMA_TX_BUFFER = NULL;
static volatile uint32_t * G_PACMAN_DMA_RX_BUFFER = NULL;

int G_I2C_FH = -1;

//PACMAN SERVER Scratch Registers (Accessible at PACMAN_SERVER_VIRTUAL_START + (0, 1)
uint32_t G_PACMAN_SERVER_SCRA = 0x0; 
uint32_t G_PACMAN_SERVER_SCRB = 0x0;

void dma_restart(uint32_t* virtual_address, dma_desc* start) {
  printf("Restarting DMA...\n");
  dma_set(virtual_address, DMA_MM2S_CTRL_REG, DMA_RST); // reset
  dma_set(virtual_address, DMA_MM2S_CTRL_REG, 0); // halt
  dma_set(virtual_address, DMA_MM2S_CURR_REG, start->addr);
  dma_set(virtual_address, DMA_MM2S_CTRL_REG, DMA_RUN); // run
  dma_mm2s_status(virtual_address);
}

void transmit_data(uint32_t* virtual_address, dma_desc* start, uint32_t nwords) {
  if (nwords == 0) return;
  dma_desc* tail = start;
  while (nwords > 1) {
    tail = tail->next;
    nwords--;
  }
  dma_set(virtual_address, DMA_MM2S_TAIL_REG, tail->addr);
  while (!dma_desc_cmplt(tail->desc)){
    //std::this_thread::sleep_for(std::chrono::milliseconds(100));
    NULL;
  }
}

int pacman_init(int verbose){
  // initialize axi-lite 
  if (verbose){
    printf("INFO:  Initializing PACMAN AXI-Lite interface.\n");
  }

  int dh = open("/dev/mem", O_RDWR|O_SYNC);
  G_PACMAN_AXIL = (uint32_t*)mmap(NULL, PACMAN_LEN, PROT_READ|PROT_WRITE, MAP_SHARED, dh, PACMAN_ADDR);

  //unsigned fwversion = G_PACMAN_AXIL[TBD>>2];
  unsigned fwversion = 11;
  
  if (verbose){
    printf("INFO:  Running pacman-server version %d.%d\n", PACMAN_SERVER_MAJOR_VERSION, PACMAN_SERVER_MINOR_VERSION);
    printf("INFO:  Running pacman firmware version 1.%d\n", fwversion);
  }

  // I2C
  if (verbose){
    printf("INFO:  Initializing PACMAN I2C interface.\n");
  }
  G_I2C_FH = i2c_open(I2C_DEV);
  unsigned i2cmajor = i2c_read(G_I2C_FH, 0x220);
  unsigned i2cminor = i2c_read(G_I2C_FH, 0x221);
  unsigned i2cdebug = i2c_read(G_I2C_FH, 0x222);
  // I2C
  if (verbose){
    printf("INFO:  Running I2C firmware version %d.%d (Debug Code:  0x%x)\n", i2cmajor, i2cminor, i2cdebug);
  }

  // initialize dma
  uint32_t* dma = (uint32_t*)mmap(NULL, DMA_LEN, PROT_READ|PROT_WRITE, MAP_SHARED, dh, DMA_ADDR);
  uint32_t* dma_tx = (uint32_t*)mmap(NULL, DMA_TX_MAXLEN, PROT_READ|PROT_WRITE, MAP_SHARED, dh, DMA_TX_ADDR);
  dma_desc* curr = init_circular_buffer(dma_tx, DMA_TX_ADDR, DMA_TX_MAXLEN, LARPIX_PACKET_LEN);
  dma_desc* prev = curr;
  dma_restart(dma, curr);
  uint32_t dma_status = dma_get(dma, DMA_MM2S_STAT_REG);
  if ( dma_status & DMA_HALTED ) {
    printf("Error starting DMA\n");
    return 2;
  }
  printf("DMA started\n");
  
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
  
  return EXIT_SUCCESS;
}

int pacman_init_rx(int verbose, int skip_reset){
  // unused in this version...
  return EXIT_SUCCESS;
}

int pacman_poll_rx(){
  // unused in this version...
  
  return EXIT_SUCCESS;
}

int pacman_poll_tx(){
  
  return EXIT_SUCCESS;
}

int pacman_write(uint32_t addr, uint32_t value){
  if (addr < PACMAN_LEN){
    printf("DEBUG:  writing HW address 0x%x\n", addr);
    G_PACMAN_AXIL[addr>>2] = value;
    return EXIT_SUCCESS;
  } else {
    unsigned off = addr - PACMAN_LEN;
    printf("DEBUG:  writing I2C virtual address 0x%x\n", off);
    i2c_write(G_I2C_FH, off, value);
    return EXIT_SUCCESS;
  }
  printf("ERROR:  Invalid address 0x%x\n", addr);
  return EXIT_FAILURE;
}


uint32_t pacman_read(uint32_t addr, int * status){
  if (status)
    *status = EXIT_SUCCESS;  
  if (addr < PACMAN_LEN){
    return G_PACMAN_AXIL[addr>>2];
  } else {
    unsigned off = addr - PACMAN_LEN;
    printf("DEBUG:  reading I2C virtual address 0x%x\n", off);
    return i2c_read(G_I2C_FH, off);
  }
}
