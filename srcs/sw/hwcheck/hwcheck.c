
#include <stdio.h>
#include "xparameters.h"
#include "xgpio.h"
#include "xgpiops.h"
#include "xiicps.h"
#include "xstatus.h"
#include "xil_printf.h"

#define LED_DELAY         

// MIO pinout:
//12 - LED1
//13 - LED2
#define LED1 12
#define LED2 13


// GPIO pinout:
//0  - LED3
//1  - LED4
//2  - TILE1_CLK
//3  - TILE1_CUR_SEL
//4  - TILE1_RESET
//5  - TILE1_TRIG
//6  - TILE1_EN    
//7  - TILE1_MOSI_0
//8  - TILE1_MOSI_1
//9  - TILE1_MOSI_2
//10 - TILE1_MOSI_3
//11 - TILE1_MISO_0
//12 - TILE1_MISO_1
//13 - TILE1_MISO_2
//14 - TILE1_MISO_3
#define LED3 0
#define LED4 1

//GPIO AXI device:
#define GPIO_DEVICE_ID XPAR_GPIO_0_DEVICE_ID
#define GPIO_CHAN    1
#define GPIO_INPUTS     0b111100000000000
XGpio gpio;

//GPIO PS device:
#define GPIOPS_DEVICE_ID XPAR_XGPIOPS_0_DEVICE_ID
#define GPIOPS_CHAN    1
XGpioPs gpiops;

#define IIC_DEVICE_ID           XPAR_XIICPS_0_DEVICE_ID
#define IIC_SECONDARY_ADDR      0x3
#define IIC_SCLK_RATE           100000
#define IIC_BUFFER_SIZE         4
u8 iic_buffer[IIC_BUFFER_SIZE];
XIicPs iicps;

int init_gpiops(){
  xil_printf("initializing PS GPIO interface (MIO and EMIO pins)...");
  XGpioPs_Config *cfg = XGpioPs_LookupConfig(GPIOPS_DEVICE_ID);
  if (NULL == cfg) {
    xil_printf("FAILED.\r\n");
    return XST_FAILURE;
  }
  int status = XGpioPs_CfgInitialize(&gpiops, cfg, cfg->BaseAddr);
  if (status != XST_SUCCESS) {
    xil_printf("FAILED.\r\n");
    return XST_FAILURE;
  }
  XGpioPs_SetDirectionPin(&gpiops, LED1, 1);
  XGpioPs_SetOutputEnablePin(&gpiops, LED1, 1);
  XGpioPs_WritePin(&gpiops, LED1, 0x0);
  XGpioPs_SetDirectionPin(&gpiops, LED2, 1);
  XGpioPs_SetOutputEnablePin(&gpiops, LED2, 1);
  XGpioPs_WritePin(&gpiops, LED2, 0x0);
  xil_printf("success.\r\n");
  return XST_SUCCESS;
}

int init_gpio(){  
  xil_printf("initializing AXI GPIO interface (HR pins)...");
  int status = XGpio_Initialize(&gpio, GPIO_DEVICE_ID);
  if (status != XST_SUCCESS)  {
    xil_printf("FAILED.\r\n");
    return XST_FAILURE;
  }    
  // set inputs and outputs
  XGpio_SetDataDirection (&gpio, GPIO_CHAN, GPIO_INPUTS);
  // clear all outputs:
  XGpio_DiscreteClear(&gpio, GPIO_CHAN, ~GPIO_INPUTS);
  xil_printf("success.\r\n");
  return XST_SUCCESS;
}

int init_iic(){  
  xil_printf("initializing I2C interface...");
  XIicPs_Config *cfg = XIicPs_LookupConfig(IIC_DEVICE_ID);
  if (NULL == cfg) {
    xil_printf("FAILED.\r\n");
    return XST_FAILURE;
  }
  int status  = XIicPs_CfgInitialize(&iicps, cfg, cfg->BaseAddress);
  if (status != XST_SUCCESS)  {
    xil_printf("FAILED.\r\n");
    return XST_FAILURE;
  }
  xil_printf("success.\r\n");
  xil_printf("perfomring I2C selftest...");
  status = XIicPs_SelfTest(&iicps);
  if (status != XST_SUCCESS)  {
    xil_printf("FAILED.\r\n");
    return XST_FAILURE;
  }
  xil_printf("success.\r\n");
  xil_printf("setting IIC clk rate to %d...", IIC_SCLK_RATE);
  XIicPs_SetSClk(&iicps, IIC_SCLK_RATE);
  xil_printf("success.\r\n");

  return XST_SUCCESS;
}

void blink(){
  static const int nblink = 1;
  static const int DELAY = 100000000;
  volatile int idelay = 0;
  xil_printf("blinking LEDs:\r\n");
  xil_printf("LED 1 (MIO pin)...\r\n");
  for (int iblink=0; iblink<nblink; iblink++){
    XGpioPs_WritePin(&gpiops, LED1, 1);
    for (idelay=0; idelay<DELAY; idelay++);
    XGpioPs_WritePin(&gpiops, LED1, 0);
    for (idelay=0; idelay<DELAY; idelay++);
  }  
  xil_printf("LED 2 (MIO pin)...\r\n");
  for (int iblink=0; iblink<nblink; iblink++){
    XGpioPs_WritePin(&gpiops, LED2, 1);
    for (idelay=0; idelay<DELAY; idelay++);
    XGpioPs_WritePin(&gpiops, LED2, 0);
    for (idelay=0; idelay<DELAY; idelay++);
  }  
  xil_printf("LED 3 (HR pin)...\r\n");
  for (int iblink=0; iblink<nblink; iblink++){
    XGpio_DiscreteSet(&gpio, GPIO_CHAN, 1 << LED3);
    for (idelay=0; idelay<DELAY; idelay++);
    XGpio_DiscreteClear(&gpio, GPIO_CHAN, 1 << LED3);
    for (idelay=0; idelay<DELAY; idelay++);
  }
  xil_printf("LED 4 (HR pin)...\r\n");
  for (int iblink=0; iblink<nblink; iblink++){
    XGpio_DiscreteSet(&gpio, GPIO_CHAN, 1 << LED4);
    for (idelay=0; idelay<DELAY; idelay++);
    XGpio_DiscreteClear(&gpio, GPIO_CHAN, 1 << LED4);
    for (idelay=0; idelay<DELAY; idelay++);
  }
  xil_printf("done blinking LEDs.\r\n");
}

void iic(){
  xil_printf("testing iic:\r\n");
  xil_printf("sending buffer...");
  int status = XIicPs_MasterSendPolled
    (&iicps, iic_buffer, IIC_BUFFER_SIZE, IIC_SECONDARY_ADDR);
  if (status != XST_SUCCESS) {
    xil_printf("failed.\r\n");
  } else {
    xil_printf("success.\r\n");
  }
  xil_printf("waiting for bus...");
  while (XIicPs_BusIsBusy(&iicps)) {
    /* NOP */
  }
  xil_printf("done.\r\n");
  xil_printf("receiving buffer...");    
  status = XIicPs_MasterRecvPolled
    (&iicps, iic_buffer, IIC_BUFFER_SIZE, IIC_SECONDARY_ADDR);
  if (status != XST_SUCCESS) {
    xil_printf("failed.\r\n");
  } else {
    xil_printf("success.\r\n");
  }
  xil_printf("done testing iic.\r\n");
  
}


int main()
{
    xil_printf("Pac-Man Card Low-Level Hardware Testing\r\n");
    int status = 0;
    status |= init_gpiops();
    status |= init_gpio();
    status |= init_iic();    
    if (status != XST_SUCCESS) {
      xil_printf("Hardware initialization has FAILED.\r\n");
      return 0;
    }
    while(1){
      xil_printf("choose an option:  (1) blink LEDs, (2) I2C check\r\n");
      unsigned char c=inbyte();
      //xil_printf("pressed:  %c\n\r", c);
      switch(c){
      case '1':
	blink();
	break;
      case '2':
	iic();
	break;
      default:
	xil_printf("invalid selection...\n\r");
      }
    }
    return 0;
}
