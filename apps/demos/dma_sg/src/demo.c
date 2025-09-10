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

#include "dma.h"

#define EMAC_DEVICE_ID      XPAR_XEMACPS_0_DEVICE_ID
#define PHY_ADDRESS         0x1A    // Your CPLD PHY address

XEmacPs EmacPs;

void mdio_init()
{
    XEmacPs_Config *Config;
    Config = XEmacPs_LookupConfig(EMAC_DEVICE_ID);
    XEmacPs_CfgInitialize(&EmacPs, Config, Config->BaseAddress);

    // stop the annoying RED blinking LED:
    xil_printf("Setting CPLD LED configuration to RED: OFF:  Green: MIO \r\n");
    XEmacPs_PhyWrite(&EmacPs, PHY_ADDRESS, 0x5, 0x64);
}

//
// RX/TX menu:
//
#define TX_BD_BASEADDR     0x1100000
#define RX_BD_BASEADDR     0x1100040
#define TX_BUF_BASEADDR    0x1200000
#define RX_BUF_BASEADDR    0x1300000

#define TX_BUF_BYTES 0x100
#define RX_BUF_BYTES 0x100

void init_bds(){
  dma_init_single_bd_tx((u32*) TX_BD_BASEADDR, (u32*) TX_BUF_BASEADDR, TX_BUF_BYTES);
  dma_init_single_bd_rx((u32*) RX_BD_BASEADDR, (u32*) RX_BUF_BASEADDR, RX_BUF_BYTES);
}

void show_bds(){
  xil_printf("INFO:  TX BD:\r\n");
  dma_show_bd((u32*) TX_BD_BASEADDR);
  xil_printf("INFO:  RX BD:\r\n");
  dma_show_bd((u32*) RX_BD_BASEADDR);
}

void clear_bds(){
  xil_printf("INFO:  clearing TX BD.\r\n");
  dma_clear_bd_status((u32*) TX_BD_BASEADDR);
  xil_printf("INFO:  clearing RX BD\r\n");
  dma_clear_bd_status((u32*) RX_BD_BASEADDR);
}


void clear_ioc(){
  xil_printf("INFO:  clearing DMA TX IOC flag.\r\n");
  dma_clear_tx_ioc(DMA_TIMEOUT);
  xil_printf("INFO:  clearing DMA RX IOC flag\r\n");
  dma_clear_rx_ioc(DMA_TIMEOUT);
}

void single_tx(){
  // fill new data each time ...
  static unsigned count = 0;

  u32* buf = (u32*) TX_BUF_BASEADDR;
  buf[0] = 0xA;
  buf[1] = 0xB;
  buf[2] = 0xC;
  buf[3] = 0xD;
  buf[4] = count;
  buf[5] = count;
  buf[6] = count;
  buf[7] = count;
  Xil_DCacheFlushRange((UINTPTR)buf, 32);
  count++;

  dma_single_tx((u32*) TX_BD_BASEADDR);

  dma_wait_tx_ioc(DMA_TIMEOUT);
}

void show_tx_buffer(){
  xil_printf("INFO:  TX Buffer:\r\n");
  dma_show_buffer((u32*) TX_BD_BASEADDR, 4);
}

void single_rx(){

  dma_single_rx((u32*) RX_BD_BASEADDR);

  dma_wait_rx_ioc(DMA_TIMEOUT);
}

void show_rx_buffer(){
  xil_printf("INFO:  RX Buffer:\r\n");
  dma_show_transferred((u32*) RX_BD_BASEADDR, 4);
}

void rxtx_menu(){
  xil_printf("RX/TX Menu: \r\n");

  while(1){
    xil_printf("choose an option:\r\n");
    xil_printf("(1) reset TX (2) TX status (3) reset RX (4) RX status (5) long status \r\n");
    xil_printf("(6) init BDs (7) clear BDs (8) show BDs (9) clear IOC flags\r\n");
    xil_printf("(a) single TX (b) show TX (c) single RX (d) show RX \r\n");

    unsigned char c=inbyte();
    xil_printf("pressed:  %c\n\r", c);
    switch(c){
    case '1':
      dma_reset_tx(DMA_TIMEOUT);
      break;
    case '2':
      dma_show_tx_status();
      break;
    case '3':
      dma_reset_rx(DMA_TIMEOUT);
      break;
    case '4':
      dma_show_rx_status();
      break;
    case '5':
      dma_show_long_status();
      break;
    case '6':
      init_bds();
      break;
    case '7':
      clear_bds();
      break;
    case '8':
      show_bds();
      break;
    case '9':
      clear_ioc();
      break;
    case 'a':
      single_tx();
      break;
    case 'b':
      show_tx_buffer();
      break;
    case 'c':
      single_rx();
      break;
    case 'd':
      show_rx_buffer();
      break;
    default:
      xil_printf("invalid selection...\n\r");
    }
  }
}

int main(){
  xil_printf("Demonstration Driver For PACMAN DMA \r\n");
  xil_printf("Sanity number:  1\r\n");

  int status = 0;
  mdio_init();
  init_bds();

  if (status != XST_SUCCESS) {
    xil_printf("Hardware initialization has FAILED.\r\n");
    return 0;
  }

  rxtx_menu();

  return 0;
}




