#include <stdio.h>
#include <stdlib.h>
#include "xparameters.h"
#include "xtime_l.h"
#include "xil_io.h"
#include "xaxidma.h"
#include "xstatus.h"
#include "xil_printf.h"
#include "sleep.h"

#include "gpiops.h"
#include "hw_access.h"
#include "global.h"
#include "iic.h"
#include "rxtx.h"
#include "timing.h"
#include "adc.h"


#include "xemacps.h"

#define EMAC_DEVICE_ID      XPAR_XEMACPS_0_DEVICE_ID
#define PHY_ADDRESS         0x1A    // Your CPLD PHY address

XEmacPs EmacPs;

void mdio_init()
{
    XEmacPs_Config *Config;
    Config = XEmacPs_LookupConfig(EMAC_DEVICE_ID);
    XEmacPs_CfgInitialize(&EmacPs, Config, Config->BaseAddress);
}

void read_mac_from_cpld(){
  xil_printf("INFO: reading MAC address from CPLD \r\n");

  u16 a,b,c,d,e,f;
  long stat = 0;

  stat |= XEmacPs_PhyRead(&EmacPs, PHY_ADDRESS, 0x9, &a);
  stat |= XEmacPs_PhyRead(&EmacPs, PHY_ADDRESS, 0xA, &c);
  stat |= XEmacPs_PhyRead(&EmacPs, PHY_ADDRESS, 0xB, &e);

  if (stat != XST_SUCCESS) {
    return;
  }

  b = a&0xFF;
  a = (a>>8)&0xFF;
  d = c&0xFF;
  c = (c>>8)&0xFF;
  f = e&0xFF;
  e = (e>>8)&0xFF;

  xil_printf("INFO: success reading MAC address from CPLD: %02x:%02x:%02x:%02x:%02x:%02x \r\n",
	     a,b,c,d,e,f);
}

void toggle_cpld(){
  u16 cr;
  long stat = 0;

  stat |= XEmacPs_PhyRead(&EmacPs, PHY_ADDRESS, 0x5, &cr);

  if (stat != XST_SUCCESS) {
    return;
  }
  xil_printf("INFO: success reading CR1 (LEDs) from CPLD: 0x%04x \r\n", cr);


  static int mode = 0;
  mode = (mode + 1) % 5;
  if (mode == 0) {
    xil_printf("Setting CPLD LED configuration to default (RED: slow blink for SD card bood, GREEN: MIO \r\n");
    XEmacPs_PhyWrite(&EmacPs, PHY_ADDRESS, 0x5, 0x00);
  } else if (mode == 1) {
    xil_printf("Setting CPLD LED configuration to RED: MIO:  Green: On \r\n");
    XEmacPs_PhyWrite(&EmacPs, PHY_ADDRESS, 0x5, 0x47);
  } else if (mode == 2) {
    xil_printf("Setting CPLD LED configuration to RED: MIO:  Green: Off \r\n");
    XEmacPs_PhyWrite(&EmacPs, PHY_ADDRESS, 0x5, 0x46);
  } else if (mode == 3) {
    xil_printf("Setting CPLD LED configuration to RED: OFF:  Green: MIO \r\n");
    XEmacPs_PhyWrite(&EmacPs, PHY_ADDRESS, 0x5, 0x64);
  } else if (mode == 4) {
    xil_printf("Setting CPLD LED configuration to RED: MIO:  Green: MIO \r\n");
    XEmacPs_PhyWrite(&EmacPs, PHY_ADDRESS, 0x5, 0x44);
  }
}

void toggle_dcache(){
  static int mode = 0;
  mode = (mode + 1) % 2;

  if (mode == 0) {
    xil_printf("enabling dcache\r\n");
    Xil_DCacheEnable();
  } else {
    xil_printf("disabling dcache\r\n");
    Xil_DCacheDisable();
  }
}

void blink_leds(){
  blink_mio_leds();

  static const int nblink = 5;
  static const int wait_usec = 100000;

  xil_printf("BLINK LEDS:  blinking LED 3 via AXIL...\r\n");
  for (int iblink=0; iblink<nblink; iblink++){
    Xil_Out32(AXIL_REGISTERS_BASEADDR+SCOPE_GLOBAL+C_ADDR_GLOBAL_LEDS, 0x1);
    usleep(wait_usec);
    Xil_Out32(AXIL_REGISTERS_BASEADDR+SCOPE_GLOBAL+C_ADDR_GLOBAL_LEDS, 0x0);
    usleep(wait_usec);
  }

  xil_printf("BLINK LEDS:  blinking LED 4 via AXIL...\r\n");
  for (int iblink=0; iblink<nblink; iblink++){
    Xil_Out32(AXIL_REGISTERS_BASEADDR+SCOPE_GLOBAL+C_ADDR_GLOBAL_LEDS, 0x2);
    usleep(wait_usec);
    Xil_Out32(AXIL_REGISTERS_BASEADDR+SCOPE_GLOBAL+C_ADDR_GLOBAL_LEDS, 0x0);
    usleep(wait_usec);
  }
}

int main(){
  xil_printf("Menu-Driver Demonstration Driver For PACMAN\r\n");
  xil_printf("Sanity number:  1\r\n");
  xil_printf("Random Max:  0x%x Random Number:  0x%x \r\n", RAND_MAX, rand());

  int status = 0;
  status |= init_gpiops();
  status |= init_iic();
  mdio_init();
  init_rxtx();
  if (status != XST_SUCCESS) {
    xil_printf("Hardware initialization has FAILED.\r\n");
    return 0;
  }

  while(1){
    xil_printf("choose an option:\r\n");
    xil_printf("(1) blink LEDs (2) read global status (3) toggle scratch (4) toggle enables (5) toggle dcache \r\n");
    xil_printf("(6) read MAC From CPLD (7) toggle CPLD config \r\n");
    xil_printf("(a) I2C menu (b) RX/TX menu (c) timing menu (d) ADC menu\r\n");
    unsigned char c=inbyte();
    xil_printf("pressed:  %c\n\r", c);
    switch(c){
    case '1':
      blink_leds();
      break;
    case '2':
      read_global_status();
      break;
    case '3':
      toggle_global_scratch();
      break;
    case '4':
      toggle_global_enables();
      break;
    case '5':
      toggle_dcache();
      break;
    case '6':
      read_mac_from_cpld();
      break;
    case '7':
      toggle_cpld();
      break;
    case 'a':
      iic_menu();
      break;
    case 'b':
      rxtx_menu();
      break;
    case 'c':
      timing_menu();
      break;
    case 'd':
      adc_menu();
      break;
    default:
      xil_printf("invalid selection...\n\r");
    }
  }
  return 0;
}




