#include <stdio.h>
#include <stdlib.h>
#include "xparameters.h"
#include "xtime_l.h"
#include "xil_io.h"
#include "xaxidma.h"
#include "xstatus.h"
#include "xil_printf.h"
#include "sleep.h"
#include "xemacps.h"

#include "hw_access.h"
#include "dma.h"
#include "global.h"
#include "iic.h"
#include "rxtx.h"
#include "atc.h"
#include "adc.h"
#include "asic.h"
#include "led.h"

#include "iic_menu.h"
#include "asic_menu.h"
#include "atc_menu.h"

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
  blink_red_led();
  blink_pacman_leds();
}

void rxtx_menu(){
  printf("RX/TX Menu: \r\n");

  while(1){
    printf("choose an option:\r\n");
    printf("(0) exit RX/TX Menu \r\n");
    printf("(1) read tx status (2) read rx status (3) read tx look (4) read rx look\r\n");
    printf("(5) toggle tx UART configs (6) toggle rx UART configs (7) zero counts\r\n");
    printf("(8) toggle rx buffer config (9) toggle rx enables (a) toggle tx mask \r\n");
    printf("...\r\n");
    printf("(e) init descriptor ring mode (f) show BDs (g) show head/tail (h) clear IOC flags \r\n");
    printf("(i) single TX (j) single RX (k) batch TX (l) batch RX \r\n");
    printf("(m) show TX buffer (n) show RX buffer (o) show RX transferred \r\n");
    printf("...\r\n");
    printf("(t) reset TX DMA (u) TX DMA status (v) reset RX DMA (w) RX DMA status (x) long DMA status \r\n");
    printf("(y) benchmark TX (z) benchmark RX/TX loopback \r\n");
    unsigned char c=inbyte();
    printf("pressed:  %c\r\n", c);
    switch(c){
    case '0':
      return;
    case '1':
      read_tx_status();
      break;
    case '2':
      read_rx_status();
      break;
    case '3':
      read_tx_look();
      break;
    case '4':
      read_rx_look();
      break;
    case '5':
      toggle_tx_config();
      break;
    case '6':
      toggle_rx_config();
      break;
    case '7':
      zero_rxtx_counts();
      break;
    case '8':
      toggle_rx_buffer_config();
      break;
    case '9':
      toggle_rx_buffer_enables();
      break;
    case 'a':
      toggle_tx_mask();
      break;
    case 'e':
      init_rxtx_descriptor_ring_mode(8);
      break;
    case 'f':
      show_rxtx_bds();
      break;
    case 'g':
      show_rxtx_head_tail();
      break;
    case 'h':
      clear_rxtx_ioc();
      break;
    case 'i':
      single_tx();
      break;
    case 'j':
      single_rx();
      break;
    case 'k':
      batch_tx();
      break;
    case 'l':
      batch_rx();
      break;
    case 'm':
      show_tx_buffer();
      break;
    case 'n':
      show_rx_buffer();
      break;
    case 'o':
      show_rx_transferred();
      break;
    case 't':
      dma_reset_tx(DMA_TIMEOUT);
      break;
    case 'u':
      dma_show_tx_status();
      break;
    case 'v':
      dma_reset_rx(DMA_TIMEOUT);
      break;
    case 'w':
      dma_show_rx_status();
      break;
    case 'x':
      dma_show_long_status();
      break;
    case 'y':
      benchmark_tx();
      break;
    case 'z':
      benchmark_rxtx_loopback();
      break;
    default:
      printf("invalid selection...\r\n");
    }
  }
}


void adc_menu(){
}


int main(){
  printf("Menu-Driver Demonstration Driver For PACMAN\r\n");
  printf("Sanity number:  1\r\n");
  printf("Random Max:  0x%x Random Number:  0x%x \r\n", RAND_MAX, rand());

  int status = 0;
  axil_platform_init();
  iic_platform_init();
  gpio_platform_init();

  mdio_init();
  init_rxtx();
  init_led();
  if (status != XST_SUCCESS) {
    printf("Hardware initialization has FAILED.\r\n");
    return 0;
  }

  while(1){
    printf("choose an option:\r\n");
    printf("(1) blink LEDs (2) read global status (3) toggle scratch (4) toggle enables (5) toggle dcache \r\n");
    printf("(6) read MAC From CPLD (7) toggle CPLD config \r\n");
    printf("(a) I2C menu (b) RX/TX menu (c) ATC menu (d) ADC menu (e) single ASIC menu\r\n");
    unsigned char c=inbyte();
    printf("pressed:  %c\r\n", c);
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
      atc_menu();
      break;
    case 'd':
      adc_menu();
      break;
    case 'e':
      asic_menu();
      break;
    default:
      printf("invalid selection...\r\n");
    }
  }
  return 0;
}

