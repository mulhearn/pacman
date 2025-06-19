#include <stdio.h>
#include "xparameters.h"
#include "xil_io.h"
#include "xgpiops.h"
#include "xstatus.h"
#include "xil_printf.h"
#include "sleep.h"
#include "xiicps.h"
#include "xtime_l.h"
#include "xaxidma.h"

#include "iic.h"

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
void set_voltages(unsigned chan, unsigned vdda_up, unsigned vdda_dn,
		  unsigned vddd_up, unsigned vddd_dn){
  unsigned reg = 0x30 + chan;
  if (chan > 0xa)
    return;
  iic_set(ADDR_DAC_VDDA, reg, vdda_up, vdda_dn);
  iic_set(ADDR_DAC_VDDD, reg, vddd_up, vddd_dn);
}

// VDDA DAC is used for postive  end of differential test DAC output
// VDDD DAC is used for negative end of differntial test DAC output
void set_dac_voltages(unsigned vdda_up, unsigned vdda_dn,
		      unsigned vddd_up, unsigned vddd_dn){
  iic_set(ADDR_DAC_VDDA, 0b00111010, vdda_up, vdda_dn);
  iic_set(ADDR_DAC_VDDD, 0b00111010, vddd_up, vddd_dn);
}

void toggle_mux(){
  static int mode = 0;
  mode = (mode + 1) % 4;

  //  two muxes, one for positive one for negative of differential signal
  //  register 0x14 is CMDA switch,
  //  register 0x15 is CMDB switch,
  if (mode == 0) {
    xil_printf("setting MUX to no connection \r\n");
    // Setting switch to 0 is no connection.
    iic_byte(ADDR_MUX_P, 0x14, 0x10);
    iic_byte(ADDR_MUX_P, 0x15, 0x10);
    iic_byte(ADDR_MUX_N, 0x14, 0x10);
    iic_byte(ADDR_MUX_N, 0x15, 0x10);
  } else if (mode == 1) {
    xil_printf("setting MUX to DAC input \r\n");
    // Input channel 11 is DAC input
    iic_byte(ADDR_MUX_P, 0x14, 11);
    iic_byte(ADDR_MUX_P, 0x15, 11);
    iic_byte(ADDR_MUX_N, 0x14, 11);
    iic_byte(ADDR_MUX_N, 0x15, 11);
  } else if (mode == 2) {
    xil_printf("setting MUX to TILE 2 analog monitor input \r\n");
    iic_byte(ADDR_MUX_P, 0x14, 1);
    iic_byte(ADDR_MUX_P, 0x15, 1);
    iic_byte(ADDR_MUX_N, 0x14, 1);
    iic_byte(ADDR_MUX_N, 0x15, 1);
  } else if (mode == 3) {
    xil_printf("setting MUX to TILE 2 analog monitor input w/ 100 ohm termination\r\n");
    // SHDA registers: 0x10,0x11
    // SHDB registers: 0x12,0x13
    iic_byte(ADDR_MUX_P, 0x10, 0x02);
    iic_byte(ADDR_MUX_P, 0x11, 0x20);
    iic_byte(ADDR_MUX_P, 0x12, 0x02);
    iic_byte(ADDR_MUX_P, 0x13, 0x20);
    iic_byte(ADDR_MUX_N, 0x10, 0x02);
    iic_byte(ADDR_MUX_N, 0x11, 0x20);
    iic_byte(ADDR_MUX_N, 0x12, 0x02);
    iic_byte(ADDR_MUX_N, 0x13, 0x20);

    // Copy SHDA/SHDB to switches:
    iic_byte(ADDR_MUX_P, 0x14, 0x11);
    iic_byte(ADDR_MUX_P, 0x15, 0x11);
    iic_byte(ADDR_MUX_N, 0x14, 0x11);
    iic_byte(ADDR_MUX_N, 0x15, 0x11);
  }
}


void toggle_dac(){
  static int mode = 0;
  mode = (mode + 1) % 3;
  if (mode == 0) {
    xil_printf("setting DAC to +0 -0\r\n");
    set_dac_voltages(0x00, 0x00, 0x00, 0x00);
  } else if (mode == 1) {
    xil_printf("setting DAC to +0x4000,-0x0000,0\r\n");
    set_dac_voltages(0x40, 0x00, 0x00, 0x00);
  }  else if (mode == 2) {
    xil_printf("setting DAC to +0x0000,-0x4000\r\n");
    set_dac_voltages(0x00, 0x00, 0x40, 0x00);
  }
}

void pulse_dac(){
  set_dac_voltages(0x00, 0x00, 0x40, 0x00);
  usleep(1);
  set_dac_voltages(0x40, 0x00, 0x00, 0x00);
  usleep(1);
  set_dac_voltages(0x00, 0x00, 0x40, 0x00);
}

void toggle_voltages(){
  static int mode = 0;
  mode = (mode + 1) % 4;

  if (mode == 0) {
    xil_printf("setting VDDD and VDDA to zero \r\n");
    set_voltages(0, 0x00, 0x00, 0x00, 0x00);
  } else if (mode == 1) {
    xil_printf("setting VDDD and VDDA to full scale \r\n");
    set_voltages(0, 0xFF, 0xFF, 0xFF, 0xFF);
  } else if (mode == 2) {
    xil_printf("setting VDDD and VDDA to half scale\r\n");
    set_voltages(0, 0x80, 0x00, 0x80, 0x00);
  } else if (mode == 3) {
    xil_printf("setting VDDD and VDDA to quarter scale\r\n");
    set_voltages(0, 0x40, 0x00, 0x40, 0x00);
  }
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

void iic_menu(){
  xil_printf("I2C Menu: \r\n");
  while(1){
    xil_printf("choose an option:\r\n");
    xil_printf("(0) exit I2C Menu \r\n");
    xil_printf("(1) check I2C (2) toggle voltages (3) toggle DAC test voltages (4) pulse DAC (5) toggle MUX \r\n");
    xil_printf("(6) read voltages \r\n");
    unsigned char c=inbyte();
    xil_printf("pressed:  %c\n\r", c);
    switch(c){
    case '0':
      return;
    case '1':
      check_iic();
      break;
    case '2':
      toggle_voltages();
      break;
    case '3':
      toggle_dac();
      break;
    case '4':
      pulse_dac();
      break;
    case '5':
      toggle_mux();
      break;
    case '6':
      read_voltages();
      break;
    default:
      xil_printf("invalid selection...\n\r");
    }
  }
}
