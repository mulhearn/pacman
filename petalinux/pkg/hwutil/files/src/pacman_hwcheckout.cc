#include <stdlib.h>
#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <cstring>
#include <stdint.h>
//#include "version.hh"
//#include "addr_conf.hh"
#include <sys/time.h>

#include "led.hh"
#include "i2c.hh"

// THIS SHOULD GO INTO AN AXIL driver SOON
volatile uint32_t * G_UTIL_AXIL = NULL;

// PACMAN AXI-Lite interface HW Address:
#define PACMAN_AXIL_ADDR 0x40000000
#define PACMAN_AXIL_HIGH 0x4000FFFF
#define PACMAN_AXIL_LEN  0x00010000

#define SCOPE_GLOBAL 0xF000
#define ROLE_GLOBAL  0x0F00
#define ROLE_TIMING  0x0E00

#define C_ADDR_GLOBAL_SCRA      0x00
#define C_ADDR_GLOBAL_SCRB      0x04
#define C_ADDR_GLOBAL_FW_MAJOR  0x10
#define C_ADDR_GLOBAL_FW_MINOR  0x14
#define C_ADDR_GLOBAL_FW_BUILD  0x18
#define C_ADDR_GLOBAL_HW_CODE   0x1C
#define C_ADDR_GLOBAL_ENABLES   0x20
#define C_ADDR_GLOBAL_STATUS    0x30
#define C_ADDR_GLOBAL_LEDS      0x34
#define C_ADDR_GLOBAL_ADC_LOOK  0x40

#define C_ADDR_TIMING_STATUS   0x00
#define C_ADDR_TIMING_STAMP    0x04
#define C_ADDR_TIMING_TRIG     0x20
#define C_ADDR_TIMING_SYNC     0x24

void toggle_enables(){
  unsigned enables[] = {0x00000000, 0x00010000, 0x00010001,  0x000103FF, 0x001103FF};
  static int mode = 0;
  mode = (mode + 1) % 5;
  printf("INFO: setting enables to 0x%08x \n", enables[mode]);
  G_UTIL_AXIL[(SCOPE_GLOBAL+ROLE_GLOBAL+C_ADDR_GLOBAL_ENABLES)>>2] = enables[mode];
}

void vdda_vddd_checkout(){
  printf("INFO: Begin checkout of VDDA and VDDD setting and monitoring.\n");
  printf("INFO: setting tile 1 VDDD to full.\n");
  i2c_set_vddd(0, 0xab63);
  printf("INFO: reading VDDD.\n");
  uint32_t mv = i2c_mon_vddd(0);
  printf("INFO: monitored VDD:  %d mV", mv);
  printf("INFO: Done.\n");
}


void hw_led_checkout(){

  printf("Blinking PACMAN LED, via AXIL.\n");
  for (int i=0; i<20; i++){
    G_UTIL_AXIL[(SCOPE_GLOBAL+ROLE_GLOBAL+C_ADDR_GLOBAL_LEDS)>>2] = 0x1;
    usleep(50000);
    G_UTIL_AXIL[(SCOPE_GLOBAL+ROLE_GLOBAL+C_ADDR_GLOBAL_LEDS)>>2] = 0x0;
    usleep(50000);
  }

  printf("Blinking PACMAN LED, via AXIL.\n");
  for (int i=0; i<20; i++){
    G_UTIL_AXIL[(SCOPE_GLOBAL+ROLE_GLOBAL+C_ADDR_GLOBAL_LEDS)>>2] = 0x2;
    usleep(50000);
    G_UTIL_AXIL[(SCOPE_GLOBAL+ROLE_GLOBAL+C_ADDR_GLOBAL_LEDS)>>2] = 0x0;
    usleep(50000);
  }

}

void adc_look(){
  unsigned adc = G_UTIL_AXIL[(SCOPE_GLOBAL+ROLE_GLOBAL+C_ADDR_GLOBAL_ADC_LOOK)>>2];
  printf("INFO: ADC LOOK: 0x%08x \n", adc);
}


void toggle_adc_input(){
  i2c_set_vddd(0xa, 0x0);
  i2c_set_vdda(0xa, 0x0);
  i2c_set_muxa(11);
  i2c_set_muxb(11);
}

void full_checkout(){
    printf("Running full checkout...\n");
    printf("Done.\n");
}

void main_menu(){
  while(1){
    printf("choose an option:\n");
    printf("(1) run full checkout \n");
    printf("(2) LED (3) Toggle Enables (4) VDDA/VDDD (5) Read ADC LOOK (6) Toggle ADC input\n");

    int input;
    scanf("%d", &input);
    printf("pressed:  %d\n", input);

    switch(input){
    case 1:
      full_checkout();
      break;
    case 2:
      led_checkout();
      hw_led_checkout();
      break;
    case 3:
      toggle_enables();
      break;
    case 4:
      vdda_vddd_checkout();
      break;
    case 5:
      adc_look();
      break;
    case 6:
      toggle_adc_input();
      break;

    default:
      printf("invalid selection...\n\r");
    }
  }
  return;
}


int main(){
  printf("PACMAN Linux-Based Hardware Checkout \n");
  printf("Random Max:  0x%x Random Number:  0x%x \n", RAND_MAX, rand());

  printf("INFO:  Opening /dev/mem.\n");
  int dh = open("/dev/mem", O_RDWR|O_SYNC);

  printf("INFO:  Initializing PACMAN AXI-Lite interface.\n");
  G_UTIL_AXIL = (uint32_t*)mmap(NULL, PACMAN_AXIL_LEN, PROT_READ|PROT_WRITE, MAP_SHARED, dh, PACMAN_AXIL_ADDR);

  unsigned fwmajor = G_UTIL_AXIL[0XFF10>>2];
  unsigned fwminor = G_UTIL_AXIL[0XFF14>>2];
  unsigned fwbuild = G_UTIL_AXIL[0XFF18>>2];
  unsigned hwcode  = G_UTIL_AXIL[0XFF1C>>2];

  printf("INFO:  Running pacman firmware version %d.%d (Build: 0x%x  HW Code:  0x%x)\n", fwmajor, fwminor, fwbuild, hwcode);

  init_led();
  init_i2c();
  main_menu();

  //printf("INFO:  Initializing PACMAN AXI-Lite interface.\n");
  //G_UTIL_AXIL = (uint32_t*)mmap(NULL, PACMAN_AXIL_LEN, PROT_READ|PROT_WRITE, MAP_SHARED, dh, PACMAN_AXIL_ADDR);

  //unsigned fwmajor = G_UTIL_AXIL[0XFF10>>2];
  //unsigned fwminor = G_UTIL_AXIL[0XFF14>>2];
  //unsigned fwbuild = G_UTIL_AXIL[0XFF18>>2];
  //unsigned hwcode  = G_UTIL_AXIL[0XFF1C>>2];

  //printf("INFO:  Running pacman-server version %d.%d\n", PACMAN_SERVER_MAJOR_VERSION, PACMAN_SERVER_MINOR_VERSION);
  //printf("INFO:  Running pacman firmware version %d.%d (Build: 0x%x  HW Code:  0x%x)\n", fwmajor, fwminor, fwbuild, hwcode);

}
