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
#include "chan_map.hh"
#include "tx_buffer.hh"
#include "rx_buffer.hh"
#include "pacman_i2c.hh"
#include "message_format.hh"


static uint32_t * G_PACMAN_AXIL = NULL;
static uint32_t * dma  = NULL;
static uint32_t * dma_tx = NULL;
static dma_desc * curr_tx = NULL;
static dma_desc * prev_tx = NULL;
static uint32_t * dma_rx = NULL;
static dma_desc * curr_rx = NULL;
static dma_desc * prev_rx = NULL;

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

void restart_dma(uint32_t* dma, uint32_t curr) {
  printf("Restarting DMA...\n");
  dma_set(dma, DMA_S2MM_CTRL_REG, DMA_RST); // reset
  dma_set(dma, DMA_S2MM_CTRL_REG, 0); // halt
  dma_set(dma, DMA_S2MM_CURR_REG, curr); // set curr
  dma_set(dma, DMA_S2MM_CTRL_REG, DMA_RUN); // run
  dma_s2mm_status(dma);
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

  unsigned fwversion_maj = G_PACMAN_AXIL[0x0000>>2];
  unsigned fwversion_min = G_PACMAN_AXIL[0x0004>>2];
  unsigned build         = G_PACMAN_AXIL[0x0008>>2];
  unsigned debug         = G_PACMAN_AXIL[0x000C>>2];

  if ((fwversion_maj==0) && (fwversion_min==0)){
    printf("WARNING:  Legacy firmware detected!  The firmware version cannot be verified, and will be reported as v0.0\n");
  }

  if (verbose){
    printf("INFO:  Running pacman-server version %d.%d\n", PACMAN_SERVER_MAJOR_VERSION, PACMAN_SERVER_MINOR_VERSION);
    printf("INFO:  Running pacman firmware version %d.%d (build: %d debug: 0x%08x)\n", fwversion_maj, fwversion_min, build, debug);
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
    printf("INFO:  Running I2C sub-system firmware version %d.%d (Debug Code:  0x%x)\n", i2cmajor, i2cminor, i2cdebug);
  }


  printf("WARNING:  This version uses channel mapping that maps 40 uarts onto 32 as follows:\n");
  print_chan_map();

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

  // initialize dma
  int dh = open("/dev/mem", O_RDWR|O_SYNC);
  dma = (uint32_t*)mmap(NULL, DMA_LEN, PROT_READ|PROT_WRITE, MAP_SHARED, dh, DMA_ADDR);
  dma_tx = (uint32_t*)mmap(NULL, DMA_TX_MAXLEN, PROT_READ|PROT_WRITE, MAP_SHARED, dh, DMA_TX_ADDR);
  curr_tx = init_circular_buffer(dma_tx, DMA_TX_ADDR, DMA_TX_MAXLEN, LARPIX_WIDE_LEN);
  prev_tx = curr_tx;
  dma_restart(dma, curr_tx);
  uint32_t dma_status = dma_get(dma, DMA_MM2S_STAT_REG);
  if ( dma_status & DMA_HALTED ) {
    printf("Error starting DMA\n");
    return 2;
  }
  printf("DMA started\n");

  return EXIT_SUCCESS;
}

int pacman_init_rx(int verbose, int skip_reset){
  unsigned timeout, cr, sr;

  if (verbose){
    printf("INFO:  Running pacman-server version %d.%d\n", PACMAN_SERVER_MAJOR_VERSION, PACMAN_SERVER_MINOR_VERSION);
  }

  printf("WARNING:  This version uses channel mapping that maps 40 uarts onto 32 as follows:\n");
  print_chan_map();

  // initialize DMA TX
  if (verbose){
    printf("INFO:  Initializing PACMAN DMA RX interface.\n");
    printf("INFO:  Initializing DMA contol interface (AXIL).\n");
  }

  // initialize dma
  int dh = open("/dev/mem", O_RDWR|O_SYNC);
  dma = (uint32_t*)mmap(NULL, DMA_LEN, PROT_READ|PROT_WRITE, MAP_SHARED, dh, DMA_ADDR);
  dma_rx = (uint32_t*)mmap(NULL, DMA_RX_MAXLEN, PROT_READ|PROT_WRITE, MAP_SHARED, dh, DMA_RX_ADDR);
  dma_desc* buffer_start = init_circular_buffer(dma_rx, DMA_RX_ADDR, DMA_RX_MAXLEN, LARPIX_WIDE_LEN);
  dma_desc* buffer_end = buffer_start->prev;
  uint32_t  buffer_desc_size = sizeof(*buffer_start);
  curr_rx = buffer_start;
  prev_rx = buffer_start;
  restart_dma(dma, curr_rx->addr);
  dma_set(dma, DMA_S2MM_TAIL_REG, buffer_end->addr);
  uint32_t dma_status = dma_get(dma, DMA_S2MM_STAT_REG);
  if ( dma_status & DMA_HALTED ) {
    printf("Error starting DMA\n");
    return 2;
  }
  printf("DMA started\n");
  
  return EXIT_SUCCESS;
}

int pacman_poll_rx(){
  // unused in this version...
  bool err = false;
  unsigned words=0;

  while(dma_desc_cmplt(curr_rx->desc)) {
    curr_rx = curr_rx->next;
    words++;
    if (curr_rx == prev_rx->prev) break; // reached end of buffer
  }
  if (curr_rx == prev_rx){
    printf("INFO: No new data received...\n");
    return EXIT_SUCCESS; 
  }

  printf("INFO: RX received new data words=%d\n", words);
  
  // copy data into buffer
  for (int i=0; i<words ; i++){
    //memcpy(word, prev_rx->word, 16);

    // reset word
    if (dma_get(prev_rx->desc, DESC_STAT) & (DESC_INTERR | DESC_SLVERR | DESC_DECERR)) {
      printf("Descriptor error!\n");
      err = true;
      dma_desc_print(prev_rx->desc);
      // reset
      dma_set(prev_rx->desc, DESC_ADDR, prev_rx->word_addr);
      dma_set(prev_rx->desc, DESC_NEXT, (prev_rx->next)->addr);
      dma_desc_print(prev_rx->desc);
    }
    dma_set(prev_rx->desc, DESC_STAT, 0);

    prev_rx = prev_rx->next;
  }
  // update dma
  dma_set(dma, DMA_S2MM_TAIL_REG, (prev_rx->prev)->addr);

  prev_rx = curr_rx;
  if (err || dma_get(dma, DMA_S2MM_STAT_REG) & DMA_ERR_IRQ) {
    // try reset if errors occurred
    printf("An error occurred!\n");
    dma_s2mm_status(dma);
    restart_dma(dma, curr_rx->addr);
    dma_set(dma, DMA_S2MM_TAIL_REG, (prev_rx->prev)->addr);
    return EXIT_FAILURE;
  }
  
  return EXIT_SUCCESS;
}

int pacman_poll_tx(){
  uint32_t output[TX_BUFFER_BYTES/4];
  int tx_words = 0;
  char tx_t = WORD_TYPE_TX;
  char io_c = 0;
  while (tx_buffer_out(output)==1){
    tx_buffer_print_output(output);
    for (int i=0; i<40; i++){
      if ((output[i/32]>>(i%32))&1==1){
	io_c = i+1;
	tx_words++;
	memcpy(&curr_tx->word[WORD_TYPE_OFFSET], &tx_t, 1);
	memcpy(&curr_tx->word[IO_CHANNEL_OFFSET],&io_c, 1);
	memcpy(&curr_tx->word[LARPIX_DATA_OFFSET], (char*)&output[4+2*i], 8);
	dma_set(curr_tx->desc, DESC_STAT, 0);
	curr_tx = curr_tx->next;
      }
    }
  }
  // transmit
  printf("INFO: transmitting %d TX words\n", tx_words);
  transmit_data(dma, prev_tx, tx_words);
  prev_tx = curr_tx;
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
