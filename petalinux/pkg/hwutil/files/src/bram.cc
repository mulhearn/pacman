#include <stdlib.h>
#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <cstring>
#include <stdint.h>
#include <sys/time.h>

#include "bram.hh"

// PACMAN AXI-Lite interface to BRAM:
#define PACMAN_BRAM_ADDR 0x42000000
#define PACMAN_BRAM_HIGH 0x42001FFF
#define PACMAN_BRAM_LEN  0x00002000

static uint32_t G_BRAM_STATUS = 0;

static volatile uint32_t * G_BRAM = NULL;

uint32_t  get_bram_status(){
  return G_BRAM_STATUS;
}

void      clear_bram_status(){
  G_BRAM_STATUS = 0;
}

void      init_bram(){
  clear_bram_status();

  printf("INFO:  Opening /dev/mem.\n");
  int dh = open("/dev/mem", O_RDWR|O_SYNC);

  printf("INFO:  Initializing PACMAN BRAM (AXI-LITE) interface.\n");
  G_BRAM = (uint32_t*)mmap(NULL, PACMAN_BRAM_LEN, PROT_READ|PROT_WRITE, MAP_SHARED, dh, PACMAN_BRAM_ADDR);
}

void      close_bram(){
}

void      write_bram(uint32_t addr, uint32_t value){
  G_BRAM[addr>>2] = value;
}

uint32_t  read_bram(uint32_t addr){
  return G_BRAM[addr>>2];
}

