
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

// these are the addresses for the interfaces as read off from the address editor of the block diagram in vivado
#define ADDR_AXI_BRAM   0x40000000
#define ADDR_AXIL_REGS  0x43C00000
#define ADDR_AXIL_FIFO  0x43C10000
#define ADDR_AXIF_FIFO  0x43C20000

void check_reg_ro(){
  xil_printf("Reg0 -- 0x%x  \r\n", Xil_In32(ADDR_AXIL_REGS+0x00));
  xil_printf("Reg1 -- 0x%x  \r\n", Xil_In32(ADDR_AXIL_REGS+0x04));
  xil_printf("Reg2 -- 0x%x  \r\n", Xil_In32(ADDR_AXIL_REGS+0x08));
  xil_printf("Reg3 -- 0x%x  \r\n", Xil_In32(ADDR_AXIL_REGS+0x0C));
  xil_printf("Reg4 -- 0x%x  \r\n", Xil_In32(ADDR_AXIL_REGS+0x10));
}

void check_reg_rw(){
  xil_printf("Reg0 -- 0x%x  \r\n", Xil_In32(ADDR_AXIL_REGS+0x00));
  xil_printf("Reg1 -- 0x%x  \r\n", Xil_In32(ADDR_AXIL_REGS+0x04));
  Xil_Out32(ADDR_AXIL_REGS+0x00, 0xFFFFFFFF);
  Xil_Out32(ADDR_AXIL_REGS+0x04, 0xABCDABCD);
  xil_printf("Reg0 -- 0x%x  \r\n", Xil_In32(ADDR_AXIL_REGS+0x00));
  xil_printf("Reg1 -- 0x%x  \r\n", Xil_In32(ADDR_AXIL_REGS+0x04));
  Xil_Out32(ADDR_AXIL_REGS+0x00, 0x0);
  Xil_Out32(ADDR_AXIL_REGS+0x04, 0x0);
}

void check_fifo(){
  xil_printf("TX Vacancy   0x%x  \r\n", Xil_In32(ADDR_AXIL_FIFO+0x0C));
  xil_printf("RX Occupancy 0x%x  \r\n", Xil_In32(ADDR_AXIL_FIFO+0x1C));

  Xil_Out32(ADDR_AXIL_FIFO+0x18,   0xA5);
  Xil_Out32(ADDR_AXIL_FIFO+0x28,   0xA5);  
  //Xil_Out32(ADDR_AXIL_FIFO+0x0000, 0x0);  
  
  xil_printf("TX Vacancy   0x%x  \r\n", Xil_In32(ADDR_AXIL_FIFO+0x0C));
  xil_printf("RX Occupancy 0x%x  \r\n", Xil_In32(ADDR_AXIL_FIFO+0x1C));

  //Xil_Out64(ADDR_AXIF_FIFO+0x0000, 0x1234567890ABCDEF);

  for (int i=0; i<5; i++){
    Xil_Out64(ADDR_AXIF_FIFO+0x0000, 0x1234567890ABCDEF);
    Xil_Out32(ADDR_AXIL_FIFO+0x0014, 0x8);  
    xil_printf("TX Vacancy   0x%x  \r\n", Xil_In32(ADDR_AXIL_FIFO+0x0C));
    xil_printf("RX Occupancy 0x%x  \r\n", Xil_In32(ADDR_AXIL_FIFO+0x1C));
    Xil_Out64(ADDR_AXIF_FIFO+0x0000, i);
    Xil_Out32(ADDR_AXIL_FIFO+0x0014, 0x8);  
    xil_printf("TX Vacancy   0x%x  \r\n", Xil_In32(ADDR_AXIL_FIFO+0x0C));
    xil_printf("RX Occupancy 0x%x  \r\n", Xil_In32(ADDR_AXIL_FIFO+0x1C));
  }  
  xil_printf("RLENGTH      0x%x  \r\n", Xil_In32(ADDR_AXIL_FIFO+0x24));

  for (int i=0 ; i< 10; i++){
    u64 value = Xil_In64(ADDR_AXIF_FIFO+0x1000);
    u32 upper  = (value >> 32) & 0xFFFFFFFF;
    u32 lower  = (value >> 0 ) & 0xFFFFFFFF;
    xil_printf("READ FIFO    0x%x  0x%x \r\n", upper, lower);
    xil_printf("RX Occupancy 0x%x  \r\n", Xil_In32(ADDR_AXIL_FIFO+0x1C));
  }
  xil_printf("TX Vacancy   0x%x  \r\n", Xil_In32(ADDR_AXIL_FIFO+0x0C));
  xil_printf("RX Occupancy 0x%x  \r\n", Xil_In32(ADDR_AXIL_FIFO+0x1C));
}

void check_bram(){
  xil_printf("INFO:  checking BRAM  \r\n");  
  Xil_Out64(ADDR_AXI_BRAM+0x0,   0x1234567890ABCDEF);
  Xil_Out64(ADDR_AXI_BRAM+0x8,   0x1);
  Xil_Out64(ADDR_AXI_BRAM+0x10,  0xFEEDDADA00000000);
  Xil_Out64(ADDR_AXI_BRAM+0x18,  0x7777777711111111);
  Xil_Out64(ADDR_AXI_BRAM+0x20,  0x0000000033333333);
  
  for (int i=0; i<5; i++){
    u64 value = Xil_In64(ADDR_AXI_BRAM+0x8*i);
    u32 upper  = (value >> 32) & 0xFFFFFFFF;
    u32 lower  = (value >> 0 ) & 0xFFFFFFFF;  
    xil_printf("READ BRAM    0x%x  0x%x 0x%x \r\n", 0x4*i, upper, lower);
  }
  xil_printf("INFO:  checking BRAM  (DONE) \r\n");  
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
      xil_printf("(1) blink LEDs  (2) check I2C (3) read registers (4) check RW registers (5) check FIFO (6) check BRAM \r\n");
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
      case '4':
        check_reg_rw();
	break;
      case '5':
        check_fifo();
	break;
      case '6':
        check_bram();
	break;
      default:
	xil_printf("invalid selection...\n\r");
      }
    }
    return 0;
}
