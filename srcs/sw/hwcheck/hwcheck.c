
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
#define ANALOG_PWR_EN 0
#define TILE1_ENABLE  1
#define TILE2_ENABLE  2
#define TILE3_ENABLE  3
#define TILE4_ENABLE  4
#define TILE5_ENABLE  5
#define TILE6_ENABLE  6
#define TILE7_ENABLE  7
#define TILE8_ENABLE  8
#define LED3          9
#define LED4          10

//GPIO AXI device:
#define GPIO_DEVICE_ID XPAR_GPIO_0_DEVICE_ID
#define GPIO_CHAN    1
#define GPIO_INPUTS     0b00000000000
XGpio gpio;

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
  static const int wait_usec = 1000000;
  
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

void disable_all(){
   XGpio_DiscreteClear(&gpio, GPIO_CHAN, 1 << TILE1_ENABLE);
   XGpio_DiscreteClear(&gpio, GPIO_CHAN, 1 << TILE2_ENABLE);
   XGpio_DiscreteClear(&gpio, GPIO_CHAN, 1 << TILE3_ENABLE);
   XGpio_DiscreteClear(&gpio, GPIO_CHAN, 1 << TILE4_ENABLE);
   XGpio_DiscreteClear(&gpio, GPIO_CHAN, 1 << TILE5_ENABLE);
   XGpio_DiscreteClear(&gpio, GPIO_CHAN, 1 << TILE6_ENABLE);
   XGpio_DiscreteClear(&gpio, GPIO_CHAN, 1 << TILE7_ENABLE);
   XGpio_DiscreteClear(&gpio, GPIO_CHAN, 1 << TILE8_ENABLE);   
   XGpio_DiscreteClear(&gpio, GPIO_CHAN, 1 << ANALOG_PWR_EN);
}

void analog_power_enable(){  
   XGpio_DiscreteSet(&gpio, GPIO_CHAN, 1 << ANALOG_PWR_EN);
}

void tile_enable(){
   XGpio_DiscreteSet(&gpio, GPIO_CHAN, 1 << TILE1_ENABLE);
   XGpio_DiscreteSet(&gpio, GPIO_CHAN, 1 << TILE2_ENABLE);
   XGpio_DiscreteSet(&gpio, GPIO_CHAN, 1 << TILE3_ENABLE);
   XGpio_DiscreteSet(&gpio, GPIO_CHAN, 1 << TILE4_ENABLE);
   XGpio_DiscreteSet(&gpio, GPIO_CHAN, 1 << TILE5_ENABLE);
   XGpio_DiscreteSet(&gpio, GPIO_CHAN, 1 << TILE6_ENABLE);
   XGpio_DiscreteSet(&gpio, GPIO_CHAN, 1 << TILE7_ENABLE);
   XGpio_DiscreteSet(&gpio, GPIO_CHAN, 1 << TILE8_ENABLE);
}


#define ADDR_BAD          0b0001101  // Non-existent address
#define ADDR_DAC          0b0001100  // AD5677R for TILES 1-8
#define ADDR_ADC_VDDA     0b1000000  // INA220 for TILE 1
//...
#define ADDR_ADC_VDDD     0b1001000  // ADS1219 for TILES 1+2



void check_iic(){
  unsigned val;
  
  xil_printf("CHECK I2C:  sending NO OP to non-existent device... should fail:\r\n");
  iic_set(ADDR_BAD, 0, 0, 0); 
  
  xil_printf("CHECK I2C:  sending NO OP to DAC\r\n");
  iic_set(ADDR_DAC, 0, 0, 0); 

  xil_printf("CHECK I2C:  reseting VDDD ADC\r\n");
  iic_send(ADDR_ADC_VDDD, 0b0110);
  
  iic_send(ADDR_ADC_VDDD, 0b00100000); 
  val = iic_recv(ADDR_ADC_VDDD, 0b00100000, 1); 
  xil_printf("config register:  0x%x", val);
  iic_byte(ADDR_ADC_VDDD, 0b01000000, 0b01100000);
  //iic_byte(ADDR_ADC_VDDD, 0b01000000, 0b01100001); 
  iic_send(ADDR_ADC_VDDD, 0b00100000); 
  val = iic_recv(ADDR_ADC_VDDD, 0b00100000, 1); 
  xil_printf("config register:  0x%x", val);

  

}


void set_zero_voltages(){
  unsigned VDDA_UP = 0xff;
  unsigned VDDA_DN = 0xff;
  unsigned VDDD_UP = 0xff;
  unsigned VDDD_DN = 0xff;  
  iic_set(ADDR_DAC, 0b00110000, VDDA_UP, VDDA_DN);
  iic_set(ADDR_DAC, 0b00110001, VDDD_UP, VDDD_DN);  
  iic_set(ADDR_DAC, 0b00110010, VDDA_UP, VDDA_DN);
  iic_set(ADDR_DAC, 0b00110011, VDDD_UP, VDDD_DN);  
  iic_set(ADDR_DAC, 0b00110100, VDDA_UP, VDDA_DN);
  iic_set(ADDR_DAC, 0b00110101, VDDD_UP, VDDD_DN);  
  iic_set(ADDR_DAC, 0b00110110, VDDA_UP, VDDA_DN);
  iic_set(ADDR_DAC, 0b00110111, VDDD_UP, VDDD_DN);  
  iic_set(ADDR_DAC, 0b00111000, VDDA_UP, VDDA_DN);
  iic_set(ADDR_DAC, 0b00111001, VDDD_UP, VDDD_DN);  
  iic_set(ADDR_DAC, 0b00111010, VDDA_UP, VDDA_DN);
  iic_set(ADDR_DAC, 0b00111011, VDDD_UP, VDDD_DN);  
  iic_set(ADDR_DAC, 0b00111100, VDDA_UP, VDDA_DN);
  iic_set(ADDR_DAC, 0b00111101, VDDD_UP, VDDD_DN);  
  iic_set(ADDR_DAC, 0b00111110, VDDA_UP, VDDA_DN);
  iic_set(ADDR_DAC, 0b00111111, VDDD_UP, VDDD_DN);  
}

void set_voltages(unsigned vdda_up, unsigned vdda_dn,
		  unsigned vddd_up, unsigned vddd_dn){
  iic_set(ADDR_DAC, 0b00110000, vdda_up, vdda_dn);
  iic_set(ADDR_DAC, 0b00110001, vddd_up, vddd_dn);  
  iic_set(ADDR_DAC, 0b00110010, vdda_up, vdda_dn);
  iic_set(ADDR_DAC, 0b00110011, vddd_up, vddd_dn);  
  iic_set(ADDR_DAC, 0b00110100, vdda_up, vdda_dn);
  iic_set(ADDR_DAC, 0b00110101, vddd_up, vddd_dn);  
  iic_set(ADDR_DAC, 0b00110110, vdda_up, vdda_dn);
  iic_set(ADDR_DAC, 0b00110111, vddd_up, vddd_dn);  
  iic_set(ADDR_DAC, 0b00111000, vdda_up, vdda_dn);
  iic_set(ADDR_DAC, 0b00111001, vddd_up, vddd_dn);  
  iic_set(ADDR_DAC, 0b00111010, vdda_up, vdda_dn);
  iic_set(ADDR_DAC, 0b00111011, vddd_up, vddd_dn);  
  iic_set(ADDR_DAC, 0b00111100, vdda_up, vdda_dn);
  iic_set(ADDR_DAC, 0b00111101, vddd_up, vddd_dn);  
  iic_set(ADDR_DAC, 0b00111110, vdda_up, vdda_dn);
  iic_set(ADDR_DAC, 0b00111111, vddd_up, vddd_dn);  
}

void set_voltages_zero(){
  set_voltages(0,0,0,0);
}
void set_voltages_half(){
  set_voltages(0x7F,0xFF,0x7F,0xFF);
}
void set_voltages_full(){
  set_voltages(0xFF,0xFF,0xFF,0xFF);
}

void read_voltages(){
  unsigned val;
  int vdda_ma, vdda_mv;
  
  // Analog power (VDDA)
  xil_printf("READ VOLTAGES:  requesting bus voltage from VDDA ADC\r\n");
  val = iic_recv(ADDR_ADC_VDDA, 2, 2);  
  vdda_mv = (val >> 3) * 4;
  xil_printf("READ VOLTAGES:  bus voltage level:  %d mV\r\n", vdda_mv);

  xil_printf("READ VOLTAGES:  requesting shunt voltage from VDDA ADC\r\n");
  val = iic_recv(ADDR_ADC_VDDA, 1, 2);
  vdda_ma = 500 * 0.01 * val;
  xil_printf("READ VOLTAGES:  current  :  %d mA\r\n", vdda_ma);

  // Digital power (VDDD)
  iic_send(ADDR_ADC_VDDD, 0b0110);
  //iic_byte(ADDR_ADC_VDDD, 0b01000000, 0b01100000); // TILE1 - I
  iic_byte(ADDR_ADC_VDDD, 0b01000000, 0b10000000); // TILE1 - V
  //iic_byte(ADDR_ADC_VDDD, 0b01000000, 0b10100000); // TILE2 - I
  //iic_byte(ADDR_ADC_VDDD, 0b01000000, 0b11000000); // TILE2 - V
  iic_send(ADDR_ADC_VDDD, 0b00100000); 
  val = iic_recv(ADDR_ADC_VDDD, 0b00100000, 1); 
  xil_printf("config register:  0x%x\r\n", val);
  iic_send(ADDR_ADC_VDDD, 0b00100100); 
  val = iic_recv(ADDR_ADC_VDDD, 0b00100100, 1); 
  xil_printf("ready register:  0x%x\r\n", val);
  //start conversion:
  iic_send(ADDR_ADC_VDDD, 0b00001000);
  sleep(1);
  iic_send(ADDR_ADC_VDDD, 0b00100100); 
  val = iic_recv(ADDR_ADC_VDDD, 0b00100100, 1); 
  xil_printf("ready register:  0x%x\r\n", val);

  iic_send(ADDR_ADC_VDDD, 0b00010000); 
  val = iic_recv(ADDR_ADC_VDDD, 0b00010000, 3); 
  xil_printf("payload:  0x%x\r\n", val);

  unsigned vddd_mv = val*0.000476837;
  xil_printf("READ VOLTAGES: voltage %d mV\r\n", vddd_mv);
  
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
      xil_printf("choose an option:\r\n");
      xil_printf("(1) blink LEDs  (2) Disable All (3) Analog Power Enable (4) Tile Enable \r\n");
      xil_printf("(5) set voltages full (6) set voltages half (7) set voltages zero \r\n");      
      xil_printf("(8) check I2C (9) read voltages \r\n");
      unsigned char c=inbyte();
      //xil_printf("pressed:  %c\n\r", c);
      switch(c){
      case '1':
	blink();
	break;
      case '2':
	disable_all();
	break;
      case '3':
        analog_power_enable();
	break;
      case '4':
        tile_enable();
	break;
      case '5':
        set_voltages_full();
	break;
      case '6':
        set_voltages_half();
	break;
      case '7':
        set_voltages_zero();
	break;		
      case '8':
        check_iic();
	break;
      case '9':
        read_voltages();
	break;
      default:
	xil_printf("invalid selection...\n\r");
      }
    }
    return 0;
}
