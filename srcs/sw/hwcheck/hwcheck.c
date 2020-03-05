
#include <stdio.h>
#include "xparameters.h"
#include "xgpio.h"
#include "xgpiops.h"
#include "xiicps.h"
#include "xstatus.h"
#include "xil_printf.h"
#include "sleep.h"

// MIO pinout:
#define LED1 12
#define LED2 13

// GPIO pinout:
#define LED3 0
#define LED4 1
#define TILE1_CLK 2
//#define TILE1_CUR_SEL 3
#define TILE1_RESET 4
#define TILE1_TRIG 5
#define TILE1_EN 6   
#define TILE1_MOSI_0 7
#define TILE1_MOSI_1 8
#define TILE1_MOSI_2 9
#define TILE1_MOSI_3 10
#define TILE1_MISO_0 11
#define TILE1_MISO_1 12
#define TILE1_MISO_2 13
#define TILE1_MISO_3 14



#define TILE1_EN 6

//GPIO AXI device:
#define GPIO_DEVICE_ID XPAR_GPIO_0_DEVICE_ID
#define GPIO_CHAN    1
#define GPIO_INPUTS     0b111100000000000
XGpio gpio;

//GPIO PS device:
#define GPIOPS_DEVICE_ID XPAR_XGPIOPS_0_DEVICE_ID
#define GPIOPS_CHAN    1
XGpioPs gpiops;

//I2C peripherals:
#define ADDR_ADC_VPLUS    0b1001000   
#define ADDR_DAC_VDDD     0b0011100  // ADDR -> GND
#define ADDR_DAC_VDDA     0b0011101  // ADDR -> NC
#define ADDR_ADC_VDDD     0b1001100  // A1-> SCL. A0-> GND
#define ADDR_ADC_VDDA     0b1000000  // A1-> GND, A0-> GND 
#define LEVEL_VDDD_UPPER  0xFF       
#define LEVEL_VDDD_LOWER  0xFF       
#define LEVEL_VDDA_UPPER  0xFF       
#define LEVEL_VDDA_LOWER  0xFF       
#define IIC_DEVICE_ID     XPAR_XIICPS_0_DEVICE_ID
#define IIC_SCLK_RATE     200000
XIicPs iicps;

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
  XGpioPs_SetDirectionPin(&gpiops, LED1, 1);
  XGpioPs_SetOutputEnablePin(&gpiops, LED1, 1);
  XGpioPs_WritePin(&gpiops, LED1, 0x0);
  XGpioPs_SetDirectionPin(&gpiops, LED2, 1);
  XGpioPs_SetOutputEnablePin(&gpiops, LED2, 1);
  XGpioPs_WritePin(&gpiops, LED2, 0x0);

  xil_printf("success.\r\n");
  return XST_SUCCESS;
}

// Device initialization:
// GPIO (AXI):

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


// Device initialization:
// I2C:

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
  static const int nblink = 3;
  static const int wait_usec = 200000;
  
  xil_printf("BLINK LEDS:  blinking LED 1 (MIO pin)...\r\n");
  for (int iblink=0; iblink<nblink; iblink++){
    XGpioPs_WritePin(&gpiops, LED1, 1);
    usleep(wait_usec);
    XGpioPs_WritePin(&gpiops, LED1, 0);
    usleep(wait_usec);
  }  
  xil_printf("BLINK LEDS:  blinking LED 2 (MIO pin)...\r\n");
  for (int iblink=0; iblink<nblink; iblink++){
    XGpioPs_WritePin(&gpiops, LED2, 1);
    usleep(wait_usec);
    XGpioPs_WritePin(&gpiops, LED2, 0);
    usleep(wait_usec);
  }
  xil_printf("BLINK LEDS:  blinking LED 3 (HR pin)...\r\n");
  for (int iblink=0; iblink<nblink; iblink++){
    XGpio_DiscreteSet(&gpio, GPIO_CHAN, 1 << LED3);
    usleep(wait_usec);
    XGpio_DiscreteClear(&gpio, GPIO_CHAN, 1 << LED3);
    usleep(wait_usec);
  }
  xil_printf("BLINK LEDS:  blinking LED 4 (HR pin)...\r\n");
  for (int iblink=0; iblink<nblink; iblink++){
    XGpio_DiscreteSet(&gpio, GPIO_CHAN, 1 << LED4);
    usleep(wait_usec);
    XGpio_DiscreteClear(&gpio, GPIO_CHAN, 1 << LED4);
    usleep(wait_usec);
  }
  xil_printf("BLINK LEDS:  done.\r\n");  
}

void check_iic(){
  XGpio_DiscreteClear(&gpio, GPIO_CHAN, 1 << LED3);
  XGpio_DiscreteClear(&gpio, GPIO_CHAN, 1 << TILE1_EN);

  xil_printf("CHECK I2C:  reading code-load register from VDDD DAC:\r\n");
  iic_recv(ADDR_DAC_VDDD, 1,4);

  xil_printf("CHECK I2C:  reading code-load register from VDDA DAC:\r\n");
  iic_recv(ADDR_DAC_VDDA, 1,4);
  
  xil_printf("CHECK I2C:  sending NOP to VDDD DAC and reading register:\r\n");
  iic_recv(ADDR_DAC_VDDD, 0,2);

  xil_printf("CHECK I2C:  sending NOP to VDDA DAC and reading register:\r\n");
  iic_recv(ADDR_DAC_VDDA, 0,2);

  xil_printf("CHECK I2C:  reading config register from VDDD DAC:\r\n");
  iic_recv(ADDR_DAC_VDDD, 8,2);

  xil_printf("CHECK I2C:  reading config register from VDDA DAC:\r\n");
  iic_recv(ADDR_DAC_VDDA, 8,2);
  
  xil_printf("CHECK I2C:  sending CONFIG to VDDD DAC:\r\n");
  iic_set(ADDR_DAC_VDDD, 8,0,0);
  iic_recv(ADDR_DAC_VDDD, 8,2);

  xil_printf("CHECK I2C:  sending CONFIG to VDDA DAC...\r\n");
  iic_set(ADDR_DAC_VDDA, 8,0,0);
  iic_recv(ADDR_DAC_VDDA, 8,2);
     
  xil_printf("CHECK I2C:  sending SW reset to VDDD DAC...\r\n");
  iic_set(ADDR_DAC_VDDD, 5,0,0);

  xil_printf("CHECK I2C:  sending SW reset to VDDA DAC...\r\n");
  iic_set(ADDR_DAC_VDDD, 5,0,0);

  xil_printf("CHECK I2C:  reading code-load register from VDDD DAC:\r\n");
  iic_recv(ADDR_DAC_VDDD, 1,4);

  xil_printf("CHECK I2C:  reading code-load register from VDDA DAC:\r\n");
  iic_recv(ADDR_DAC_VDDA, 1,4);
  
}

void read_voltages(){  
  unsigned val;
  int vplus_mv, vplus_ma, vddd_mv, vddd_ma, vdda_mv, vdda_ma;
  
  // Main supply (VPLUS)  
  xil_printf("READ VOLTAGES:  requesting bus voltage from V+ ADC\r\n");
  val = iic_recv(ADDR_ADC_VPLUS, 2, 2);
  // from specs, section 9.2.2, shift register by 3 to align, then LSB=4 mV
  vplus_mv = (val >> 3) * 4;
  xil_printf("READ VOLTAGES:  bus voltage level:  %d mV\r\n", vplus_mv);

  xil_printf("READ VOLTAGES:  requesting shunt voltage from V+ ADC\r\n");
  val = iic_recv(ADDR_ADC_VPLUS, 1, 2);
  // R = 0.02 = 1/500 Ohms, LSB = 10 uV
  vplus_ma = 500 * 0.01 * val;
  xil_printf("READ_VOLTAGES:  V+ current  :  %d mA\r\n", vplus_ma);

  // Digital power (VDDD)
  xil_printf("READ VOLTAGES:  requesting bus voltage from VDDD ADC\r\n");
  val = iic_recv(ADDR_ADC_VDDD, 2, 2);  
  vddd_mv = (val >> 3) * 4;
  xil_printf("READ VOLTAGES:  bus voltage level:  %d mV\r\n", vddd_mv);

  xil_printf("READ VOLTAGES:  requesting shunt voltage from VDDD ADC\r\n");
  val = iic_recv(ADDR_ADC_VDDD, 1, 2);  
  vddd_ma = 500 * 0.01 * val;
  xil_printf("READ VOLTAGES:  V+ current  :  %d mA\r\n", vddd_ma);

  // Digital power (VDDA)
  xil_printf("READ VOLTAGES:  requesting bus voltage from VDDA ADC\r\n");
  val = iic_recv(ADDR_ADC_VDDA, 2, 2);  
  vdda_mv = (val >> 3) * 4;
  xil_printf("READ VOLTAGES:  bus voltage level:  %d mV\r\n", vdda_mv);

  xil_printf("READ VOLTAGES:  requesting shunt voltage from VDDA ADC\r\n");
  val = iic_recv(ADDR_ADC_VDDA, 1, 2);
  vdda_ma = 500 * 0.01 * val;
  xil_printf("READ VOLTAGES:  V+ current  :  %d mA\r\n", vdda_ma);

  xil_printf("SUMMARY:  V+:    V=%d mV I=%d mA\r\n", vplus_mv, vplus_ma);
  xil_printf("SUMMARY:  VDDD:  V=%d mV I=%d mA\r\n", vddd_mv, vddd_ma);
  xil_printf("SUMMARY:  VDDA:  V=%d mV I=%d mA\r\n", vdda_mv, vdda_ma);  
}

void power_down(){
  XGpio_DiscreteClear(&gpio, GPIO_CHAN, 1 << LED3);
  XGpio_DiscreteClear(&gpio, GPIO_CHAN, 1 << TILE1_EN);

  xil_printf("POWER DOWN:  setting VDDD level to zero:\r\n");    
  iic_set(ADDR_DAC_VDDD, 1, 0, 0);
  iic_recv(ADDR_DAC_VDDD, 1, 2);

  xil_printf("POWER DOWN:  setting VDDA level to zero:\r\n");    
  iic_set(ADDR_DAC_VDDA, 1, 0, 0);
  iic_recv(ADDR_DAC_VDDA, 1, 2);
  
  xil_printf("SUMMARY:  V+:  VDDA and VDDD power is OFF.\r\n");
}

void power_up(){
  XGpio_DiscreteClear(&gpio, GPIO_CHAN, 1 << LED3);
  XGpio_DiscreteClear(&gpio, GPIO_CHAN, 1 << TILE1_EN);

  xil_printf("POWER UP:  setting VDDD level:\r\n");    
  iic_set(ADDR_DAC_VDDD, 1, LEVEL_VDDD_UPPER, LEVEL_VDDD_LOWER);
  iic_recv(ADDR_DAC_VDDD, 1, 2);

  xil_printf("POWER UP:  setting VDDA level:\r\n");    
  iic_set(ADDR_DAC_VDDA, 1, LEVEL_VDDA_UPPER, LEVEL_VDDA_LOWER);
  iic_recv(ADDR_DAC_VDDA, 1, 2);

  xil_printf("POWER UP:  Enabling Tile 1 and setting LED3.\r\n");
  XGpio_DiscreteSet(&gpio, GPIO_CHAN, 1 << LED3);
  XGpio_DiscreteSet(&gpio, GPIO_CHAN, 1 << TILE1_EN);
  
  xil_printf("SUMMARY:  V+:  VDDA and VDDD power is ON.\r\n");
}


void digital_io(){
  int half_cycle = 5;
  XGpio_DiscreteClear(&gpio, GPIO_CHAN, ~(GPIO_INPUTS|LED3|LED4));
  xil_printf("DIGITAL IO:  begin bit banging digital I/O at nominal f=%d kHz\r\n", 500/half_cycle);
  for (int i=0;i<10000000;i++){
    // this assumes MOSI are four consequtive bits startgin at MOSI_0
    for(int count=0;count<16;count++){
      
      //falling edge:
      XGpio_DiscreteClear(&gpio, GPIO_CHAN, 1 << TILE1_CLK);
      if (count==0){
	XGpio_DiscreteSet(&gpio, GPIO_CHAN, 1 << TILE1_TRIG);
      } else {
	XGpio_DiscreteClear(&gpio, GPIO_CHAN, 1 << TILE1_TRIG);
      }
      if (count==1){
	XGpio_DiscreteSet(&gpio, GPIO_CHAN, 1 << TILE1_RESET);
      } else {
	XGpio_DiscreteClear(&gpio, GPIO_CHAN, 1 << TILE1_RESET);
      }
      unsigned set_mask = (count<<TILE1_MOSI_0);
      unsigned clr_mask = (~set_mask)&(0xf<<TILE1_MOSI_0);
      XGpio_DiscreteClear(&gpio, GPIO_CHAN, clr_mask);
      XGpio_DiscreteSet(&gpio, GPIO_CHAN, set_mask);
      usleep(half_cycle);
      //rising edge:
      XGpio_DiscreteSet(&gpio, GPIO_CHAN, 1 << TILE1_CLK);
      // here's where we should read MISO...
      usleep(half_cycle);
    }
  }
  XGpio_DiscreteClear(&gpio, GPIO_CHAN, ~(GPIO_INPUTS|LED3|LED4));
  xil_printf("DIGITAL IO:  done.\r\n");
  
}


void loopback_io(){
  int half_cycle = 5;

  xil_printf("LOOPBACK IO:  pausing...\r\n");
  usleep(5000000);
  XGpio_DiscreteClear(&gpio, GPIO_CHAN, ~(GPIO_INPUTS|LED3|LED4));
  xil_printf("LOOPBACK IO:  begin bit banging digital I/O at nominal f=%d kHz\r\n", 500/half_cycle);

  for(int count=0;count<16;count++){
      unsigned set_mask = (count<<TILE1_MOSI_0);
      unsigned clr_mask = (~set_mask)&(0xf<<TILE1_MOSI_0);
      XGpio_DiscreteClear(&gpio, GPIO_CHAN, clr_mask);
      XGpio_DiscreteSet(&gpio, GPIO_CHAN, set_mask);
      usleep(half_cycle);
      //rising edge:
      u32 readback = XGpio_DiscreteRead(&gpio, GPIO_CHAN);
      xil_printf("LOOPBACK IO:  count:  0x%x read: 0x%x  out: %x in: %x (%d%d)\r\n",
		 count, readback,
		 (readback>>TILE1_MOSI_0)&0xf, (readback>>TILE1_MISO_0)&0xf,
		 (readback>>TILE1_MISO_0)&1, (readback>>TILE1_MISO_1)&1);
      usleep(half_cycle);
  }
  XGpio_DiscreteClear(&gpio, GPIO_CHAN, ~(GPIO_INPUTS|LED3|LED4));
  xil_printf("LOOPBACK IO:  done.\r\n");  
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
      xil_printf("choose an option:\r\n   (1) blink LEDs          (2) read voltage levels\r\n   (3) power up tile 1     (4) power down tile 1\r\n   (5) init and check I2C  (6) check digital I/O \r\n   (7) loopback I/O \r\n");
      unsigned char c=inbyte();
      //xil_printf("pressed:  %c\n\r", c);
      switch(c){
      case '1':
	blink();
	break;
      case '2':
	read_voltages();
	break;
      case '3':
        power_up();
	break;
      case '4':
        power_down();
	break;
      case '5':
        check_iic();
	break;
      case '6':
        digital_io();
	break;
      case '7':
        loopback_io();
	break;	
      default:
	xil_printf("invalid selection...\n\r");
      }
    }
    return 0;
}
