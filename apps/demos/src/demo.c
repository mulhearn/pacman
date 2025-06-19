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
#include "axil.h"
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


void read_global_status(){
  xil_printf("fw major----------- %d   \r\n", Xil_In32(ADDR_AXIL_REGS+SCOPE_GLOBAL+C_ADDR_GLOBAL_FW_MAJOR));
  xil_printf("fw minor----------- %d   \r\n", Xil_In32(ADDR_AXIL_REGS+SCOPE_GLOBAL+C_ADDR_GLOBAL_FW_MINOR));
  xil_printf("fw build----------- 0x%x \r\n", Xil_In32(ADDR_AXIL_REGS+SCOPE_GLOBAL+C_ADDR_GLOBAL_FW_BUILD));
  xil_printf("hw code------------ 0x%x \r\n", Xil_In32(ADDR_AXIL_REGS+SCOPE_GLOBAL+C_ADDR_GLOBAL_HW_CODE));
  xil_printf("scratch a---------- 0x%x \r\n", Xil_In32(ADDR_AXIL_REGS+SCOPE_GLOBAL+C_ADDR_GLOBAL_SCRA));
  xil_printf("scratch b---------- 0x%x \r\n", Xil_In32(ADDR_AXIL_REGS+SCOPE_GLOBAL+C_ADDR_GLOBAL_SCRB));
  xil_printf("\r\n");
  xil_printf("enables------------ 0x%x \r\n", Xil_In32(ADDR_AXIL_REGS+SCOPE_GLOBAL+C_ADDR_GLOBAL_ENABLES));
  xil_printf("\r\n");
  //xil_printf("timing status-------0x%x \r\n", Xil_In32(ADDR_AXIL_REGS+SCOPE_GLOBAL+ROLE_TIMING+C_ADDR_TIMING_STATUS));
  //xil_printf("trig config---------0x%x \r\n", Xil_In32(ADDR_AXIL_REGS+SCOPE_GLOBAL+ROLE_TIMING+C_ADDR_TIMING_TRIG));
  //xil_printf("sync config---------0x%x \r\n", Xil_In32(ADDR_AXIL_REGS+SCOPE_GLOBAL+ROLE_TIMING+C_ADDR_TIMING_SYNC));
  //xil_printf("\r\n");
  //xil_printf("timestamp-----------0x%x \r\n", Xil_In32(ADDR_AXIL_REGS+SCOPE_GLOBAL+ROLE_TIMING+C_ADDR_TIMING_STAMP));
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
  xil_printf("INFO: setting scratch a to 0x%08x and scratch b to 0x%08x \r\n", scra, scrb);
  Xil_Out32(ADDR_AXIL_REGS+SCOPE_GLOBAL+C_ADDR_GLOBAL_SCRA, scra);
  Xil_Out32(ADDR_AXIL_REGS+SCOPE_GLOBAL+C_ADDR_GLOBAL_SCRB, scrb);
}

void toggle_enables(){
  unsigned enables[] = {0x00000000, 0x00010000, 0x00010001,  0x000103FF, 0x001103FF};
  static int mode = 0;
  mode = (mode + 1) % 5;
  xil_printf("INFO: setting enables to 0x%08x \r\n", enables[mode]);
  Xil_Out32(ADDR_AXIL_REGS+SCOPE_GLOBAL+C_ADDR_GLOBAL_ENABLES, enables[mode]);
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
    Xil_Out32(ADDR_AXIL_REGS+SCOPE_GLOBAL+C_ADDR_GLOBAL_LEDS, 0x1);
    usleep(wait_usec);
    Xil_Out32(ADDR_AXIL_REGS+SCOPE_GLOBAL+C_ADDR_GLOBAL_LEDS, 0x0);
    usleep(wait_usec);
  }

  xil_printf("BLINK LEDS:  blinking LED 4 via AXIL...\r\n");
  for (int iblink=0; iblink<nblink; iblink++){
    Xil_Out32(ADDR_AXIL_REGS+SCOPE_GLOBAL+C_ADDR_GLOBAL_LEDS, 0x2);
    usleep(wait_usec);
    Xil_Out32(ADDR_AXIL_REGS+SCOPE_GLOBAL+C_ADDR_GLOBAL_LEDS, 0x0);
    usleep(wait_usec);
  }

  


  
}

int main(){
  xil_printf("Demonstration Driver For PACMAN TX/RX \r\n");
  xil_printf("Sanity number:  2\r\n");
  xil_printf("Random Max:  0x%x Random Number:  0x%x \r\n", RAND_MAX, rand());

  int status = 0;
  status |= init_gpiops();
  status |= init_iic();
  mdio_init();
  if (status != XST_SUCCESS) {
    xil_printf("Hardware initialization has FAILED.\r\n");
    return 0;
  }
  
  while(1){
    xil_printf("choose an option:\r\n");
    xil_printf("(1) blink LEDs (2) read global status (3) toggle scratch (4) toggle enables (5) toggle dcache \r\n");
    xil_printf("(6) I2C menu (7) RX/TX menu (8) timing menu (9) ADC menu\r\n");
    xil_printf("(a) read MAC From CPLD (b) toggle CPLD config \r\n");
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
      toggle_scratch();
      break;
    case '4':
      toggle_enables();
      break;
    case '5':
      toggle_dcache();
      break;
    case '6':
      iic_menu();
      break;      
    case '7':
      rxtx_menu();
      break;      
    case '8':
      timing_menu();
      break;
    case '9':
      adc_menu();
      break;
    case 'a':
      read_mac_from_cpld();
      break;
    case 'b':
      toggle_cpld();
      break;
    default:
      xil_printf("invalid selection...\n\r");
    }
  }
  return 0;
}




