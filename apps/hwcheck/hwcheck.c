#include <stdio.h>
#include "xparameters.h"
#include "xil_io.h"
#include "xgpiops.h"
#include "xstatus.h"
#include "xil_printf.h"
#include "sleep.h"
#include "xiicps.h"

// MIO pinout:
#define ADC_SLEEP 0
#define LEDA 7
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
  XGpioPs_SetDirectionPin(&gpiops, ADC_SLEEP, 1);
  XGpioPs_SetOutputEnablePin(&gpiops, ADC_SLEEP, 1);
  XGpioPs_WritePin(&gpiops, ADC_SLEEP, 0x1);

  XGpioPs_SetDirectionPin(&gpiops, LEDA, 1);
  XGpioPs_SetOutputEnablePin(&gpiops, LEDA, 1);
  XGpioPs_WritePin(&gpiops, LEDA, 0x0);
  XGpioPs_SetDirectionPin(&gpiops, LED0, 1);
  XGpioPs_SetOutputEnablePin(&gpiops, LED0, 1);
  XGpioPs_WritePin(&gpiops, LED0, 0x0);
  XGpioPs_SetDirectionPin(&gpiops, LED1, 1);
  XGpioPs_SetOutputEnablePin(&gpiops, LED1, 1);
  XGpioPs_WritePin(&gpiops, LED1, 0x0);

  xil_printf("success.\r\n");
  return XST_SUCCESS;
}

void blink(){
  static const int nblink = 5;
  static const int wait_usec = 100000;

  xil_printf("BLINK LEDS:  blinking LED 1 (MIO pin)...\r\n");
  for (int iblink=0; iblink<nblink; iblink++){
    XGpioPs_WritePin(&gpiops, LEDA, 1);
    usleep(wait_usec);
    XGpioPs_WritePin(&gpiops, LEDA, 0);
    usleep(wait_usec);
  }
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


// Device initialization:
// I2C:
#define IIC_DEVICE_ID     XPAR_XIICPS_0_DEVICE_ID
//#define IIC_DEVICE_ID     XPAR_XIICPS_1_DEVICE_ID
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
  xil_printf("performing I2C selftest...");
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


// VDDA DAC is used for postive  end of differential test DAC output
// VDDD DAC is used for negative end of differntial test DAC output

void set_voltages(unsigned vdda_up, unsigned vdda_dn,
		  unsigned vddd_up, unsigned vddd_dn){
  // Test inputs... setting to VDDA/VDDD for now:
  iic_set(ADDR_DAC_VDDA, 0b00111010, vdda_up, vdda_dn);
  //iic_set(ADDR_DAC_VDDD, 0b00111010, vddd_up, vddd_dn);
  iic_set(ADDR_DAC_VDDD, 0b00111010, vddd_up, vddd_dn);
}

void set_voltages_zero(){
  set_voltages(0x00, 0x00, 0x00, 0x00);
}

void set_voltages_full(){
  set_voltages(0xFF, 0xFF, 0xFF, 0xFF);
}


void set_mux_dac(){
  //  two muxes, one for positive one for negative of differential signal
  //  register 0x14 is CMDA switch, 11 is for DAC input
  //  register 0x15 is CMDA switch, 11 is for DAC input
  iic_byte(ADDR_MUX_P, 0x14, 11);
  iic_byte(ADDR_MUX_P, 0x15, 11);
  iic_byte(ADDR_MUX_N, 0x14, 11);
  iic_byte(ADDR_MUX_N, 0x15, 11);
}

// these are the addresses for the interfaces as read off from the address editor of the block diagram in vivado
#define ADDR_AXIL_REGS  0x40000000

void global_registers(){
  Xil_Out32(ADDR_AXIL_REGS+0xFF20, 0x001103FF);
  xil_printf("Enables  -- 0x%x  \r\n", Xil_In32(ADDR_AXIL_REGS+0xFF20));
  xil_printf("ADC Look -- 0x%x  \r\n", Xil_In32(ADDR_AXIL_REGS+0xFF40));
}


void test_adc(){

  xil_printf("test ADCs  \r\n");
  set_mux_dac();
  XGpioPs_WritePin(&gpiops, ADC_SLEEP, 0x0);

  xil_printf("Set Voltage Near (Postive) Half Scale  \r\n");
  set_voltages(0x40, 0x40, 0x0, 0x0);
  usleep(1000);

  xil_printf("ADC REGISTER -- 0x%x  \r\n", Xil_In32(ADDR_AXIL_REGS+0xFF40));
  xil_printf("ADC REGISTER -- 0x%x  \r\n", Xil_In32(ADDR_AXIL_REGS+0xFF40));
  xil_printf("ADC REGISTER -- 0x%x  \r\n", Xil_In32(ADDR_AXIL_REGS+0xFF40));

  xil_printf("Set Voltage Near Negative Half Scale  \r\n");
  set_voltages(0x00, 0x00, 0x40, 0x40);
  usleep(1000);
  xil_printf("ADC REGISTER -- 0x%x  \r\n", Xil_In32(ADDR_AXIL_REGS+0xFF40));
  xil_printf("ADC REGISTER -- 0x%x  \r\n", Xil_In32(ADDR_AXIL_REGS+0xFF40));
  xil_printf("ADC REGISTER -- 0x%x  \r\n", Xil_In32(ADDR_AXIL_REGS+0xFF40));

  XGpioPs_WritePin(&gpiops, ADC_SLEEP, 0x1);
  xil_printf("done testing ADCs  \r\n");
}



void write_bram(){
  for (int i=0; i<10; i++){
    Xil_Out32(XPAR_BRAM_0_BASEADDR+4*i, i);
  }
}

void read_bram(){
  for (int i=0; i<10; i++){
    xil_printf("BRAM %d -- 0x%x  \r\n", i, Xil_In32(XPAR_BRAM_0_BASEADDR+4*i));
  }
}


int main(){
  xil_printf("SANITY NUMBER:  1\r\n");
  xil_printf("Trenz Eval Board Hardware Testing (Development)\r\n");
  int status = 0;
  status |= init_gpiops();
  status |= init_iic();
  if (status != XST_SUCCESS) {
    xil_printf("Hardware initialization has FAILED.\r\n");
    return 0;
  }
  while(1){
    xil_printf("choose an option:\r\n");
    xil_printf("(1) blink LEDS \r\n");
    xil_printf("(2) global registers \r\n");
    xil_printf("(3) check iic (4) set P voltage zero (5) set P voltage full \r\n");
    xil_printf("(6) set mux to DAC (7) test ADC  \r\n");
    xil_printf("(8) write BRAM (9) read BRAM  \r\n");

    unsigned char c=inbyte();
    xil_printf("pressed:  %c\n\r", c);
    switch(c){
    case '1':
      blink();
      break;
    case '2':
      global_registers();
      break;
    case '3':
      check_iic();
      break;
    case '4':
      set_voltages_zero();
      break;
    case '5':
      set_voltages_full();
      break;
    case '6':
      set_mux_dac();
      break;
    case '7':
      test_adc();
      break;
    case '8':
      write_bram();
      break;
    case '9':
      read_bram();
      break;
   
   default:
      xil_printf("invalid selection...\n\r");
    }
  }
  return 0;
}
