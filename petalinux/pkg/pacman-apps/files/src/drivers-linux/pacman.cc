#ifndef SIMULATED_PACMAN

#include <stdlib.h>
#include <stdio.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <unistd.h>
#include <cstring>

#include "version.hh"
#include "addr_conf.hh"
#include "pacman.hh"
#include "tx_buffer.hh"
#include "rx_buffer.hh"
#include "pacman_i2c.hh"

// new common drivers:
#include "hw_access.h"
#include "dma.h"
#include "rxtx.h"

volatile uint32_t * G_PACMAN_AXIL = NULL;

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

  if (verbose){
    printf("INFO:  Running pacman-server version %d.%d.%d\n",
	   PACMAN_SERVER_MAJOR_VERSION, PACMAN_SERVER_MINOR_VERSION, PACMAN_SERVER_PATCH_VERSION);
    printf("INFO:  Running pacman firmware version %d.%d\n", fwmajor, fwminor);
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
    printf("INFO:  Setting number of cycles per DMA package to 31 (0x1F) as appropriate for DMA buffer length.\n");
    printf("INFO:  Enabling Trigger, Sync, and Heartbeat words in the RX unit.\n");
  }
  G_PACMAN_AXIL[0x7FB4>>2] = 0x001F;
  G_PACMAN_AXIL[0x7FB8>>2] = 0x0003;

  if (verbose){
    printf("INFO:  Setting RX clock scale factor to 1 \n");
  }
  G_PACMAN_AXIL[0x7B04>>2] = 0x00001001;

  if (verbose){
    printf("INFO:  Limiting TX bandwidth, with clock scale factor 1 \n");
  }
  // G_PACMAN_AXIL[0x3B04>>2] = 0x05281602;
  G_PACMAN_AXIL[0x3B04>>2] = 0x07BC1601;

  //polarity configuration: 0xE108
  // 0x0HHHGGGI H=H output mask(10 bits) G=G output mask (10 bits) I = input mask (2 bits)
  G_PACMAN_AXIL[0xE108>>2] = 0x03FF3FF0;

  //destination configurations:
  // 0x0MMMDDDO M=tile enables, D=duration O=output enables (1 = G, 2 = H, 4 = T)
  //LEMO A destination configuration:  This is a SYNC pulse, H+T, duration 5
  G_PACMAN_AXIL[0xE110>>2] = 0x03FF0056;
  //LEMO B destination configuration:  This is a SYNC pulse, H+T, duration 5
  G_PACMAN_AXIL[0xE114>>2] = 0x03FF0056;

  //POKE C destination configuration:  This is an INTERNAL_RESET pulse, G, duration 24
  G_PACMAN_AXIL[0xE118>>2] = 0x03FF0181;
  //POKE D destination configuration:  This is a FULL_RESET pulse, G, duration 1024
  G_PACMAN_AXIL[0xE11C>>2] = 0x03FF4001;

  //POKE D destination configuration:  This is a SYNC pulse, H+T, duration 2
  //G_PACMAN_AXIL[0xE11C>>2] = 0x03FF0056;

  //Request ATC configuration update:
  G_PACMAN_AXIL[0xE100>>2] = 0x0;

  // duplicate (harmless) effort here while merging new driver code into PACMAN server.
  axil_platform_init();

  return EXIT_SUCCESS;
}

int pacman_init_tx(int verbose, int skip_reset){
  init_rxtx();

  // reset of S2MM halts MM2S in DMA SG mode, so cmdserver (TX) handles both resets:
  dma_reset_tx(DMA_TIMEOUT);
  dma_reset_rx(DMA_TIMEOUT);

  init_tx_descriptor_ring_mode(512);
  return EXIT_SUCCESS;
}

int pacman_init_rx(int verbose, int skip_reset){
  init_rxtx();

  printf("INFO:  Waiting for TX server to initialize first.\r\n");
  // give pacman_cmdserver a head start:
  usleep(100000);

  // confirm it is running:
  unsigned timeout = dma_wait_tx_run(100000);
  if (timeout == 0){
    printf("ERROR:  RX is not running.  Due to single DMA core, must initialize TX (pacman_cmdserver) before starting RX (pacman_dataserver\r\n");
    exit(0);
  }

  printf("INFO:  Initializing RX descriptor ring.\r\n");
  init_rx_descriptor_ring_mode(512);
  return EXIT_SUCCESS;
}

int pacman_poll_rx(){
  const unsigned rx_trailer_bytes = 24; // current firmware, each DMA RX packet has a 192-bit trailer
  const unsigned batch_size = 100;
  unsigned batch_count = 0;
  hw_addr_t nxta;
  uint32_t rx_data[6];

  while((batch_count < batch_size) && dma_next_available_rx_bd(&nxta)){
    // several checks are possible here: xbytes size makes sense, trailer matches, etc...
    // but keeping as simple as possible for integration of new driver ...
    unsigned xbytes = dma_poll_bd_transferred(nxta);
    hw_ptr_t rx_buf = dma_get_buffer(nxta);
    if (xbytes > rx_trailer_bytes) {
      unsigned full_words = (xbytes - rx_trailer_bytes) / 24;
      for (unsigned i=0; i<full_words; i++){
	rx_data[0] = rx_buf[6*i+0];
	rx_data[1] = rx_buf[6*i+1];
	rx_data[2] = rx_buf[6*i+2];
	rx_data[3] = rx_buf[6*i+3];
	rx_data[4] = rx_buf[6*i+4];
	rx_data[5] = rx_buf[6*i+5];
	rx_buffer_in(rx_data);
      }
    }
    batch_count++;
    dma_add_rx_bd(nxta);
  }
  if (batch_count > 0){
    printf("INFO:  returning %d RX buffers \r\n", batch_count);
    dma_rx_batch();
  }
  return EXIT_SUCCESS;
}

int pacman_poll_tx(){
  const unsigned frags = TX_BUFFER_BYTES/4; // number of u32 fragments per buffer
  static uint32_t output[frags];

  const unsigned batch_size = 100;
  unsigned batch_count = 0;
  hw_addr_t nxta;

  while((batch_count < batch_size) && dma_next_available_tx_bd(&nxta)){
    if (tx_buffer_out(output)==1){
      tx_buffer_print_output(output);
      hw_ptr_t tx_buf = dma_get_buffer(nxta);
      for (unsigned i=0; i<frags; i++)
	tx_buf[i] = output[i];
      dma_add_tx_bd(nxta);
      batch_count++;
    } else {
      break;
    }
  }
  if (batch_count > 0){
    printf("INFO:  sending %d TX buffers \r\n", batch_count);
    dma_tx_batch();
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

#endif
