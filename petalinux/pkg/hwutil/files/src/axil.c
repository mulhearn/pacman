#include <stdlib.h>
#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <string.h>
#include <stdint.h>
#include <sys/time.h>

#include "axil.h"

// PACMAN AXI-Lite interface HW Address:
#define PACMAN_AXIL_ADDR 0x40000000
#define PACMAN_AXIL_HIGH 0x4000FFFF
#define PACMAN_AXIL_LEN  0x00010000

static uint32_t G_AXIL_STATUS = 0;

static volatile uint32_t * G_AXIL = NULL;

uint32_t  get_axil_status(){
  return G_AXIL_STATUS;
}

void      clear_axil_status(){
  G_AXIL_STATUS = 0;
}

void      init_axil(){
  clear_axil_status();

  printf("INFO:  Opening /dev/mem.\n");
  int dh = open("/dev/mem", O_RDWR|O_SYNC);

  printf("INFO:  Initializing PACMAN AXI-Lite interface.\n");
  G_AXIL = (uint32_t*)mmap(NULL, PACMAN_AXIL_LEN, PROT_READ|PROT_WRITE, MAP_SHARED, dh, PACMAN_AXIL_ADDR);

  unsigned fwmajor = G_AXIL[0XFF10>>2];
  unsigned fwminor = G_AXIL[0XFF14>>2];
  unsigned fwbuild = G_AXIL[0XFF18>>2];
  unsigned hwcode  = G_AXIL[0XFF1C>>2];

  printf("INFO:  Running pacman firmware version %d.%d (Build: 0x%x  HW Code:  0x%x)\n", fwmajor, fwminor, fwbuild, hwcode);

}

void      close_axil(){
}

void      write_axil(uint32_t addr, uint32_t value){
  G_AXIL[addr>>2] = value;
}
uint32_t  read_axil(uint32_t addr){
  return G_AXIL[addr>>2];
}

