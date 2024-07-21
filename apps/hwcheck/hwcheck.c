
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
#define TILE9_ENABLE  9
#define TILE10_ENABLE 10
#define CLK           11
#define TRIG          12
#define SYNC          13
#define POSI0         14
#define POSI1         15
#define POSI2         16
#define POSI3         17
#define PISO0         18
#define PISO1         19
#define PISO2         20
#define PISO3         21

//GPIO AXI device:
#define GPIO_DEVICE_ID XPAR_GPIO_0_DEVICE_ID
#define GPIO_CHAN    1
#define GPIO_INPUTS  0b1111000000000000000000
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
  static const int wait_usec = 100000;
  
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
  /*
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
  }*/
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
   XGpio_DiscreteClear(&gpio, GPIO_CHAN, 1 << TILE9_ENABLE);
   XGpio_DiscreteClear(&gpio, GPIO_CHAN, 1 << TILE10_ENABLE);   
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
   XGpio_DiscreteSet(&gpio, GPIO_CHAN, 1 << TILE9_ENABLE);
   XGpio_DiscreteSet(&gpio, GPIO_CHAN, 1 << TILE10_ENABLE);
}

//0001100   AD5677        16-chan. 16-bit DAC for VDDA setup                
//0001101   AD5677        16-chan. 16-bit DAC for VDDD setup                
//0010000   PAC1944       4-chan. Power Monitor VDDA+VDDD Tile1 + Tile2     
//0010001   PAC1944       4-chan. Power Monitor VDDA+VDDD Tile3 + Tile4     
//0010010   PAC1944       4-chan. Power Monitor VDDA+VDDD Tile5 + Tile6     
//0010011   PAC1944       4-chan. Power Monitor VDDA+VDDD Tile7 + Tile8     
//0010100   PAC1944       4-chan. Power Monitor VDDA+VDDD Tile9 + Tile10    
//0010101   PAC1944       4-chan. Power Monitor T3V0 + D3V6 + D3V3          
//1001100   MAX14661      16:2 Positive-Side MUX                            
//1001101   MAX14661      16:2 Negative-Side MUX                            
//1010000   SFP           SFP Module for Timing (primary addr.)             
//1010001   SFP           SFP Module for Timing (secondary addr.)           
//1100000   ADN2814       Clock & Data Recovery (CDR) for Timing  

#define ADDR_BAD          0b0001110  // Non-existent address
#define ADDR_DAC_VDDA     0b0001100  // AD5677 DAC for VDDA TILES 1-10
#define ADDR_DAC_VDDD     0b0001101  // AD5677 DAC for VDDD TILES 1-10
#define ADDR_ADC_TILES    0b0010000  // PAC1944 for Tiles 1+2 (ADDR+0), Tiles 3+4 (ADDR+1), ...
#define ADDR_ADC_BOARD    0b0010101  // PAC 1944 for Board Power and Temp
#define ADDR_MUX_P        0b1001100  // MAX14661 for TILES 1-8
#define ADDR_MUX_N        0b1001101  // MAX14661 for TILES 1-8

void check_iic(){
  //unsigned val;
  
  xil_printf("CHECK I2C:  sending NO OP to non-existent device... should fail:\r\n");
  iic_set(ADDR_BAD, 0, 0, 0); 

  xil_printf("CHECK I2C:  sending refesh to non-existent device... should fail:\r\n");
  iic_send(ADDR_BAD, 0); 
  
  xil_printf("CHECK I2C:  sending NO OP to DAC VDDA \r\n");
  iic_set(ADDR_DAC_VDDA, 0, 0, 0);

  xil_printf("CHECK I2C:  sending NO OP to DAC VDDD \r\n");
  iic_set(ADDR_DAC_VDDD, 0, 0, 0); 

  xil_printf("CHECK I2C:  setting MUX to TILE 1\r\n");
  //iic_byte(ADDR_MUX_P, 0x14, 0xa); // short to N
  iic_byte(ADDR_MUX_P, 0x14, 0xb);
  iic_byte(ADDR_MUX_P, 0x15, 0xe); 
  xil_printf("CHECK I2C:  setting MUX to TILE 2\r\n");
  //iic_byte(ADDR_MUX_N, 0x14, 0xa); // short to P
  iic_byte(ADDR_MUX_N, 0x14, 0xb);
  iic_byte(ADDR_MUX_N, 0x15, 0xe);

  xil_printf("CHECK I2C:  sending refesh to ADCs:\r\n");
  xil_printf("CHECK I2C:  TILES 1+2:\r\n");
  iic_send(ADDR_ADC_TILES+0, 0);
  xil_printf("CHECK I2C:  TILES 3+4:\r\n");
  iic_send(ADDR_ADC_TILES+1, 0);
  xil_printf("CHECK I2C:  TILES 5+6:\r\n");
  iic_send(ADDR_ADC_TILES+2, 0);
  xil_printf("CHECK I2C:  TILES 7+8:\r\n");
  iic_send(ADDR_ADC_TILES+3, 0);
  xil_printf("CHECK I2C:  TILES 9+10:\r\n");
  iic_send(ADDR_ADC_TILES+4, 0);
  xil_printf("CHECK I2C:  BOARD:\r\n");
  iic_send(ADDR_ADC_BOARD,   0); 
}

void set_voltages(unsigned vdda_up, unsigned vdda_dn,
		  unsigned vddd_up, unsigned vddd_dn){
  // VDDA
  iic_set(ADDR_DAC_VDDA, 0b00110000, vdda_up, vdda_dn);
  iic_set(ADDR_DAC_VDDA, 0b00110001, vdda_up, vdda_dn);
  iic_set(ADDR_DAC_VDDA, 0b00110010, vdda_up, vdda_dn);
  iic_set(ADDR_DAC_VDDA, 0b00110011, vdda_up, vdda_dn);
  iic_set(ADDR_DAC_VDDA, 0b00110100, vdda_up, vdda_dn);
  iic_set(ADDR_DAC_VDDA, 0b00110101, vdda_up, vdda_dn);
  iic_set(ADDR_DAC_VDDA, 0b00110110, vdda_up, vdda_dn);
  iic_set(ADDR_DAC_VDDA, 0b00110111, vdda_up, vdda_dn);
  iic_set(ADDR_DAC_VDDA, 0b00111000, vdda_up, vdda_dn);
  iic_set(ADDR_DAC_VDDA, 0b00111001, vdda_up, vdda_dn);

  // VDDD
  iic_set(ADDR_DAC_VDDD, 0b00110000, vddd_up, vddd_dn);
  iic_set(ADDR_DAC_VDDD, 0b00110001, vddd_up, vddd_dn);
  iic_set(ADDR_DAC_VDDD, 0b00110010, vddd_up, vddd_dn);
  iic_set(ADDR_DAC_VDDD, 0b00110011, vddd_up, vddd_dn);
  iic_set(ADDR_DAC_VDDD, 0b00110100, vddd_up, vddd_dn);
  iic_set(ADDR_DAC_VDDD, 0b00110101, vddd_up, vddd_dn);
  iic_set(ADDR_DAC_VDDD, 0b00110110, vddd_up, vddd_dn);
  iic_set(ADDR_DAC_VDDD, 0b00110111, vddd_up, vddd_dn);
  iic_set(ADDR_DAC_VDDD, 0b00111000, vddd_up, vddd_dn);
  iic_set(ADDR_DAC_VDDD, 0b00111001, vddd_up, vddd_dn);

  // Test inputs... setting to VDDA/VDDD for now:
  iic_set(ADDR_DAC_VDDA, 0b00111010, vdda_up, vdda_dn);
  iic_set(ADDR_DAC_VDDD, 0b00111010, vddd_up, vddd_dn);
}

void set_voltages_zero(){
  set_voltages(0,0,0,0);
}
void set_voltages_half(){
  set_voltages(0x7F,0xFF,0x7F,0xFF);
  // walk down to half from full...

  for (unsigned vdig = 0xFFFF; vdig>=0x7FFF; vdig-=0x1){
    unsigned up = 0xFF & (vdig>>8);
    unsigned dn = 0xFF & vdig;
    xil_printf(" set point:  0x%x 0x%x \r\n",up,dn);    
    set_voltages(up, dn, up, dn);
  }


}
void set_voltages_full(){
  set_voltages(0xFF,0xFF,0xFF,0xFF);

}

void read_voltages(){
  unsigned val;
  
  xil_printf("READ_VOLTAGES:  setting config registers:\r\n");
  iic_set(ADDR_ADC_TILES+0, 1, 0b10000101, 0x0);
  iic_set(ADDR_ADC_TILES+1, 1, 0b10000101, 0x0);
  iic_set(ADDR_ADC_TILES+2, 1, 0b10000101, 0x0);
  iic_set(ADDR_ADC_TILES+3, 1, 0b10000101, 0x0);
  iic_set(ADDR_ADC_TILES+4, 1, 0b10000101, 0x0);
  iic_set(ADDR_ADC_BOARD, 1, 0b10000101, 0x0);

  xil_printf("READ VOLTAGES:  sending refesh to ADCs:\r\n");
  iic_send(ADDR_ADC_TILES+0, 0);
  iic_send(ADDR_ADC_TILES+1, 0);
  iic_send(ADDR_ADC_TILES+2, 0);
  iic_send(ADDR_ADC_TILES+3, 0);
  iic_send(ADDR_ADC_TILES+4, 0);
  iic_send(ADDR_ADC_BOARD,   0); 
  
  usleep(50000);

  unsigned addr = ADDR_ADC_BOARD;
  xil_printf("READ_VOLTAGES:  reading board voltages:\r\n");
  val = iic_recv(addr, 0x7, 2);
  xil_printf(" value:  0x%x, %d --> %d mV \r\n",val,val, 9000*val/0xffff);
  val = iic_recv(addr, 0x8, 2);
  xil_printf(" value:  0x%x, %d --> %d mV \r\n",val,val, 9000*val/0xffff);
  val = iic_recv(addr, 0x9, 2);
  xil_printf(" value:  0x%x, %d --> %d mV \r\n",val,val, 9000*val/0xffff);

  xil_printf("READ_VOLTAGES:  reading board currents:\r\n");
  val = iic_recv(addr, 0xb, 2);
  xil_printf(" value:  0x%x, %d --> %d mA \r\n",val,val, 20000*val/0xffff);
  val = iic_recv(addr, 0xc, 2);
  xil_printf(" value:  0x%x, %d --> %d mA \r\n",val,val, 20000*val/0xffff);
  val = iic_recv(addr, 0xd, 2);
  xil_printf(" value:  0x%x, %d --> %d mA \r\n",val,val, 20000*val/0xffff);

  for(int i=0; i<5; i++){
    xil_printf("READ_VOLTAGES:  reading voltages and currents for tiles %d and %d:\r\n",2*i+1,2*i+2);

    unsigned addr = ADDR_ADC_TILES + i;
    xil_printf("READ_VOLTAGES:  reading board voltages:\r\n");
    val = iic_recv(addr, 0x7, 2);
    xil_printf(" value:  0x%x, %d --> %d mV \r\n",val,val, 9000*val/0xffff);
    val = iic_recv(addr, 0x8, 2);
    xil_printf(" value:  0x%x, %d --> %d mV \r\n",val,val, 9000*val/0xffff);
    val = iic_recv(addr, 0x9, 2);
    xil_printf(" value:  0x%x, %d --> %d mV \r\n",val,val, 9000*val/0xffff);
    val = iic_recv(addr, 0xa, 2);
    xil_printf(" value:  0x%x, %d --> %d mV \r\n",val,val, 9000*val/0xffff);

    xil_printf("READ_VOLTAGES:  reading board currents:\r\n");
    val = iic_recv(addr, 0xb, 2);
    xil_printf(" value:  0x%x, %d --> %d mA \r\n",val,val, 20000*val/0xffff);
    val = iic_recv(addr, 0xc, 2);
    xil_printf(" value:  0x%x, %d --> %d mA \r\n",val,val, 20000*val/0xffff);
    val = iic_recv(addr, 0xd, 2);
    xil_printf(" value:  0x%x, %d --> %d mA \r\n",val,val, 20000*val/0xffff);    
    val = iic_recv(addr, 0xe, 2);
    xil_printf(" value:  0x%x, %d --> %d mV \r\n",val,val, 9000*val/0xffff);

  }  
}


void static_lvds_check(){
  static int phase = 0;
  unsigned readback,a,b,c,d;
  
  phase = (phase+1)%2;

  unsigned mask = (1<<POSI0)|(1<<POSI1)|(1<<POSI2)|(1<<POSI3)|(1<<CLK)|(1<<TRIG)|(1<<SYNC);
  
  xil_printf("STATIC LVDS CHECK:  phase is %d and mask is: 0x%x \r\n",phase, mask);
 
  if (phase == 0){
    XGpio_DiscreteClear(&gpio, GPIO_CHAN, mask);
  } else {
    XGpio_DiscreteSet(&gpio, GPIO_CHAN, mask);
  }      

  usleep(100000);

  readback = XGpio_DiscreteRead(&gpio, GPIO_CHAN);
  a = (readback>>PISO0) &1;
  b = (readback>>PISO1) &1;
  c = (readback>>PISO2) &1;
  d = (readback>>PISO3) &1;
  xil_printf("STATIC LVDS CHECK:  readback:  0x%x -> %d %d %d %d\r\n", readback,a,b,c,d);
}


void loop_back(){
  //unsigned mask = (1<<POSI0)|(1<<POSI1)|(1<<POSI2)|(1<<POSI3);
  unsigned wa,wb,wc,wd,readback,a,b,c,d;

  // this is a dumb way to do it, entirely appropriate for loopback
  // being applied with leads from axial resistors...

  unsigned half_cycle = 10;  
  unsigned count = 0;
  //unsigned sends = 160000;
  unsigned sends = 16;
  for(int i=0;i<sends;i++){
    unsigned phase = i % 16;
    wa = (phase>>0)&0x1;
    wb = (phase>>1)&0x1;
    wc = (phase>>2)&0x1;
    wd = (phase>>3)&0x1;
    
    if (wa) {
      XGpio_DiscreteSet(&gpio, GPIO_CHAN, 1<<POSI0);        
    } else {
      XGpio_DiscreteClear(&gpio, GPIO_CHAN, 1<<POSI0);        
    }
    if (wb) {
      XGpio_DiscreteSet(&gpio, GPIO_CHAN, 1<<POSI1);        
    } else {
      XGpio_DiscreteClear(&gpio, GPIO_CHAN, 1<<POSI1);        
    }
    if (wc) {
      XGpio_DiscreteSet(&gpio, GPIO_CHAN, 1<<POSI2);        
    } else {
      XGpio_DiscreteClear(&gpio, GPIO_CHAN, 1<<POSI2);        
    }
    if (wd) {
      XGpio_DiscreteSet(&gpio, GPIO_CHAN, 1<<POSI3);        
    } else {
      XGpio_DiscreteClear(&gpio, GPIO_CHAN, 1<<POSI3);        
    }
    usleep(half_cycle);

    readback = XGpio_DiscreteRead(&gpio, GPIO_CHAN);
    a = (readback>>PISO0) &1;
    b = (readback>>PISO1) &1;
    c = (readback>>PISO2) &1;
    d = (readback>>PISO3) &1;

    unsigned erra = (a != wa);
    unsigned errb = (b != wb);
    unsigned errc = (c != wc);
    unsigned errd = (d != wd);
    count += erra + errb + errc + errd;
    if (erra||errb||errc||errd){
      xil_printf("LOOP BACK:  sent:  %d %d %d %d recv: %d %d %d %d\r\n", wa,wb,wc,wd,a,b,c,d);
      xil_printf("LOOP BACK:  BIT ERROR DETECTED\r\n");
    }
    
    usleep(half_cycle);
  }  
  xil_printf("LOOP BACK:  bit errs: %d bits checked: %d \r\n", count, 4*sends);
}


void io_check(){
  xil_printf("DIGITAL IO:  starting.\r\n");
  int half_cycle = 10;  
  for (int i=0;i<1000000;i++){
    for(int count=0;count<16;count++){     
      if (count == 0){
	XGpio_DiscreteSet(&gpio, GPIO_CHAN, 1 << POSI3);
      } else {
	XGpio_DiscreteClear(&gpio, GPIO_CHAN, 1 << POSI3);
      }      

      if (count == 1){
	XGpio_DiscreteSet(&gpio, GPIO_CHAN, 1 << TRIG);
      } else {
	XGpio_DiscreteClear(&gpio, GPIO_CHAN, 1 << TRIG);
      }      

      if (count == 2){
	XGpio_DiscreteSet(&gpio, GPIO_CHAN, 1 << SYNC);
      } else {
	XGpio_DiscreteClear(&gpio, GPIO_CHAN, 1 << SYNC);
      }

      if ((count&0x1) != 0){
	XGpio_DiscreteSet(&gpio, GPIO_CHAN, 1 << POSI2);
      }	else {
      	XGpio_DiscreteClear(&gpio, GPIO_CHAN, 1 << POSI2);
      }

      if ((count&0x2) != 0){
	XGpio_DiscreteSet(&gpio, GPIO_CHAN, 1 << POSI1);
      }	else {
      	XGpio_DiscreteClear(&gpio, GPIO_CHAN, 1 << POSI1);
      }

      if ((count&0x3) != 0){
	XGpio_DiscreteSet(&gpio, GPIO_CHAN, 1 << POSI0);
      }	else {
      	XGpio_DiscreteClear(&gpio, GPIO_CHAN, 1 << POSI0);
      }

      XGpio_DiscreteClear(&gpio, GPIO_CHAN, 1 << CLK);            
      usleep(half_cycle);
      XGpio_DiscreteSet(&gpio, GPIO_CHAN, 1 << CLK);            
      usleep(half_cycle);
    }
  }
  xil_printf("DIGITAL IO:  done.\r\n");
}


int main()
{
    xil_printf("Pac-Man Card Low-Level Hardware Testing  (V1.3)\r\n");
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
      xil_printf("(8) check I2C (9) read voltages (a) static LVDS check (b) I/O check (c) loop back \r\n ");
      unsigned char c=inbyte();
      xil_printf("pressed:  %c\n\r", c);
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
      case 'a':
        static_lvds_check();
	break;	
      case 'b':
        io_check();
	break;
      case 'c':
        loop_back();
	break;
      default:
	xil_printf("invalid selection...\n\r");
      }
    }
    return 0;
}
