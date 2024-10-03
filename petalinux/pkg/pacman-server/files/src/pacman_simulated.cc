//#define SIMULATED_PACMAN
#ifdef SIMULATED_PACMAN

#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>

#include "pacman.hh"
#include "tx_buffer.hh"
#include "rx_buffer.hh"

int pacman_init(int verbose){
  printf("WARNING:  *** Using simulated hardware driver.  ***\n");
  return EXIT_SUCCESS;
}

int pacman_init_rx(int verbose, int skip_reset){
  printf("WARNING:  *** Using simulated hardware driver.  ***\n");
  return EXIT_SUCCESS;
}

int pacman_init_tx(int verbose, int skip_reset){
  printf("WARNING:  *** Using simulated hardware driver.  ***\n");
  return EXIT_SUCCESS;
}

int pacman_poll_rx(){
  static int count=0;
  static int chan=0;
  static int tstamp=0;
  
  uint32_t rx_data[4];
  rx_data[0]=0x44 + ((chan+1)<<8) + (tstamp<<16);
  rx_data[1]=0x00001000;
  rx_data[2]=0xCCCCDDDD;
  rx_data[3]=0xAAAABBBB;

  if (count == 0){
    rx_buffer_in(rx_data);
    chan = (chan+1)%40;
    tstamp = (tstamp+2)%0x10000;
  }
  count = (count+1)%1000;

  usleep(2000);      
  return EXIT_SUCCESS;
}

uint32_t G_PACMAN_TXA = 0xA;
uint32_t G_PACMAN_TXB = 0xB;

int pacman_poll_tx(){
  uint32_t output[TX_BUFFER_BYTES/4];
  if (tx_buffer_out(output) == 0)
    return EXIT_SUCCESS;

  printf("DEBUG:  extracted output %x\n", output[2]);
  
  G_PACMAN_TXA = output[4];
  G_PACMAN_TXB = output[5];
  
  return EXIT_SUCCESS;
}

uint32_t G_PACMAN_SCRA = 0x0;
uint32_t G_PACMAN_SCRB = 0x0;

int pacman_write(uint32_t addr, uint32_t value){
  if (addr == 0x0)
    G_PACMAN_SCRA = value;
  else if (addr == 0x4)
    G_PACMAN_SCRB = value;
  
  return EXIT_SUCCESS;
}

uint32_t pacman_read(uint32_t addr, int * status){
  if (status)
    *status = EXIT_SUCCESS;
  if (addr == 0x0)
    return G_PACMAN_SCRA;
  else if (addr == 0x4)
    return G_PACMAN_SCRB;
  else if (addr == 0x8)
    return G_PACMAN_TXA;
  else if (addr == 0xC)
    return G_PACMAN_TXB;
  return 0x0;  
}

#endif
