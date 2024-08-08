
#include <stdio.h>
#include "xparameters.h"
#include "xil_io.h"
#include "xgpiops.h"
#include "xiicps.h"
#include "xstatus.h"
#include "xil_printf.h"
#include "sleep.h"


// MIO pinout:
#define LED0 12
#define LED1 13

//GPIO PS device:
#define GPIOPS_DEVICE_ID XPAR_XGPIOPS_0_DEVICE_ID
#define GPIOPS_CHAN    1
XGpioPs gpiops;

// Device initialization:
// GPIO (MIO and EMIO):

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
  XGpioPs_SetDirectionPin(&gpiops, LED0, 1);
  XGpioPs_SetOutputEnablePin(&gpiops, LED0, 1);
  XGpioPs_WritePin(&gpiops, LED0, 0x0);
  XGpioPs_SetDirectionPin(&gpiops, LED1, 1);
  XGpioPs_SetOutputEnablePin(&gpiops, LED1, 1);
  XGpioPs_WritePin(&gpiops, LED1, 0x0);

  xil_printf("success.\r\n");
  return XST_SUCCESS;
}


// Device initialization:
// I2C:
#define IIC_DEVICE_ID     XPAR_XIICPS_0_DEVICE_ID
#define IIC_SCLK_RATE     200000
XIicPs iicps;

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


// Low-level I2C drivers:

void iic_send(unsigned addr, unsigned reg){
  u8 buf = reg;

  xil_printf("I2C:  sending register 0x%x at address 0x%x...", reg, addr);
  int status = XIicPs_MasterSendPolled
  (&iicps, &buf, 1, addr);  
  if (status != XST_SUCCESS) {
    xil_printf("failed.\r\n");
  } else {
    xil_printf("success.\r\n");
  } 
  xil_printf("I2C:  waiting for bus...");
  while (XIicPs_BusIsBusy(&iicps)) {
    /* NOP */
  }
  xil_printf("done.\r\n");
}

void iic_set(unsigned addr, unsigned reg, unsigned up, unsigned dn){
  u8 buf[3];
  buf[0] = reg;
  buf[1] = up;
  buf[2] = dn;

  xil_printf("I2C:  setting register 0x%x to 0x %x %x at address 0x%x...", reg, up, dn, addr);
  int status = XIicPs_MasterSendPolled
  (&iicps, buf, 3, addr);  
  if (status != XST_SUCCESS) {
    xil_printf("failed.\r\n");
  } else {
    xil_printf("success.\r\n");
  } 
  xil_printf("I2C:  waiting for bus...");
  while (XIicPs_BusIsBusy(&iicps)) {
    /* NOP */
  }
  xil_printf("done.\r\n");  
}

void iic_byte(unsigned addr, unsigned reg, unsigned byte){
  u8 buf[2];
  buf[0] = reg;
  buf[1] = byte;

  xil_printf("I2C:  setting register 0x%x to 0x %x at address 0x%x...", reg, byte, addr);
  int status = XIicPs_MasterSendPolled
  (&iicps, buf, 2, addr);  
  if (status != XST_SUCCESS) {
    xil_printf("failed.\r\n");
  } else {
    xil_printf("success.\r\n");
  } 
  xil_printf("I2C:  waiting for bus...");
  while (XIicPs_BusIsBusy(&iicps)) {
    /* NOP */
  }
  xil_printf("done.\r\n");  
}


unsigned iic_recv(unsigned addr, unsigned reg, unsigned nbytes){
  int status;
  iic_send(addr, reg);
  u8 buff[nbytes];
  for (int i=0; i<nbytes; i++){
    buff[i] = 0;
  }
  xil_printf("I2C:  reading back register...");    
  status = XIicPs_MasterRecvPolled
    (&iicps, buff, nbytes, addr);  
  if (status != XST_SUCCESS) {
    xil_printf("failed.\r\n");
  } else {
    xil_printf("success.\r\n");
  }
  xil_printf("I2C:  register:  0x%x value:  ", reg);
  unsigned value = 0;
  for (int i=0; i<nbytes; i++){
    xil_printf("0x%x  ", buff[i]);
    value = (value<<8) + buff[i];    
  }  
  xil_printf("--> 0x%x (%d)\r\n", value, value);  
  return value;
}

void blink(){
  static const int nblink = 5;
  static const int wait_usec = 100000;
  
  xil_printf("BLINK LEDS:  blinking LED 1 (MIO pin)...\r\n");
  for (int iblink=0; iblink<nblink; iblink++){
    XGpioPs_WritePin(&gpiops, LED0, 1);
    usleep(wait_usec);
    XGpioPs_WritePin(&gpiops, LED0, 0);
    usleep(wait_usec);
  }  
  xil_printf("BLINK LEDS:  blinking LED 2 (MIO pin)...\r\n");
  for (int iblink=0; iblink<nblink; iblink++){
    XGpioPs_WritePin(&gpiops, LED1, 1);
    usleep(wait_usec);
    XGpioPs_WritePin(&gpiops, LED1, 0);
    usleep(wait_usec);
  }
  xil_printf("BLINK LEDS:  done.\r\n");  
}

void check_iic(){
}

void check_reg_ro(){
  xil_printf("Reg0 -- 0x%x  \r\n", Xil_In32(0x40000000));
  xil_printf("Reg1 -- 0x%x  \r\n", Xil_In32(0x40000004));
  xil_printf("Reg2 -- 0x%x  \r\n", Xil_In32(0x40000008));
  xil_printf("Reg3 -- 0x%x  \r\n", Xil_In32(0x4000000C));
  xil_printf("Reg4 -- 0x%x  \r\n", Xil_In32(0x40000010));
}

int main()
{
    xil_printf("Pac-Man Card Low-Level Hardware Testing  (V1.3)\r\n");
    int status = 0;
    status |= init_gpiops();
    status |= init_iic();    
    if (status != XST_SUCCESS) {
      xil_printf("Hardware initialization has FAILED.\r\n");
      return 0;
    }
    while(1){
      xil_printf("choose an option:\r\n");
      xil_printf("(1) blink LEDs  (2) check I2C (3) check RO registers \r\n");
      unsigned char c=inbyte();
      xil_printf("pressed:  %c\n\r", c);
      switch(c){
      case '1':
	blink();
	break;
      case '2':
	check_iic();
	break;
      case '3':
        check_reg_ro();
	break;
      default:
	xil_printf("invalid selection...\n\r");
      }
    }
    return 0;
}
