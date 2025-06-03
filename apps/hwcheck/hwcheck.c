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
  mode = (mode + 1) % 3;

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
    xil_printf("setting MUX to TILE 1 analog monitor input \r\n");    
    // Input channel 1 is Tile 1
    iic_byte(ADDR_MUX_P, 0x14, 0);
    iic_byte(ADDR_MUX_P, 0x15, 0);
    iic_byte(ADDR_MUX_N, 0x14, 0);
    iic_byte(ADDR_MUX_N, 0x15, 0);
  } else if (mode == 3) {
    xil_printf("setting MUX to TILE 1 analog monitor input w/ 100 ohm termination\r\n");    
    // SHDA registers: 0x10,0x11
    // SHDB registers: 0x12,0x13
    iic_byte(ADDR_MUX_P, 0x10, 0x00);
    iic_byte(ADDR_MUX_P, 0x11, 0x04);
    iic_byte(ADDR_MUX_P, 0x12, 0x01);
    iic_byte(ADDR_MUX_P, 0x13, 0x04);    
    iic_byte(ADDR_MUX_N, 0x10, 0x00);
    iic_byte(ADDR_MUX_N, 0x11, 0x04);
    iic_byte(ADDR_MUX_N, 0x12, 0x01);
    iic_byte(ADDR_MUX_N, 0x13, 0x04);    
    
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

// these are the addresses for the interfaces as read off from the address editor of the block diagram in vivado
#define ADDR_AXIL_REGS  0x40000000


void read_global_registers(){
  //Xil_Out32(ADDR_AXIL_REGS+0xFF20, 0x001103FF);
  //Xil_Out32(ADDR_AXIL_REGS+0xD100, 0x000000FF);
  xil_printf("Enables  -- 0x%x  \r\n", Xil_In32(ADDR_AXIL_REGS+0xFF20));
  xil_printf("Global Look  -- 0x%x  \r\n", Xil_In32(ADDR_AXIL_REGS+0xFF40));
  xil_printf("ADC status   -- 0x%x  \r\n", Xil_In32(ADDR_AXIL_REGS+0xD100));
  xil_printf("ADC look     -- 0x%x  \r\n", Xil_In32(ADDR_AXIL_REGS+0xD104));
  xil_printf("ADC last     -- 0x%x  \r\n", Xil_In32(ADDR_AXIL_REGS+0xD108));
  xil_printf("ADC state    -- 0x%x  \r\n", Xil_In32(ADDR_AXIL_REGS+0xD10C));
  xil_printf("ADC config   -- 0x%x  \r\n", Xil_In32(ADDR_AXIL_REGS+0xD110));
  xil_printf("ADC clkpar   -- 0x%x  \r\n", Xil_In32(ADDR_AXIL_REGS+0xD114));
  xil_printf("ADC scratch  -- 0x%x  \r\n", Xil_In32(ADDR_AXIL_REGS+0xD200));
  xil_printf("ADC roa      -- 0x%x  \r\n", Xil_In32(ADDR_AXIL_REGS+0xD204));      
}

void set_adc_mode_to_run(){
  Xil_Out32(ADDR_AXIL_REGS+0xD118, 0x2);
}

void toggle_enables(){
  static int mode = 0;
  mode = (mode + 1) % 2;  

  if (mode == 1) {
    xil_printf("enable all\r\n");
    Xil_Out32(ADDR_AXIL_REGS+0xFF20, 0x001103FF);
   } else {
    xil_printf("disable all\r\n");
    Xil_Out32(ADDR_AXIL_REGS+0xFF20, 0x00000000);
  }
}


void toggle_adc_sleep(){
  static int mode = 0;
  mode = (mode + 1) % 2;  

  if (mode == 0) {
    xil_printf("set ADC to sleep  \r\n");
    XGpioPs_WritePin(&gpiops, ADC_SLEEP, 0x1);
  } else {
    xil_printf("set ADC to awake \r\n");
    XGpioPs_WritePin(&gpiops, ADC_SLEEP, 0x0);
  }
}

void toggle_adc_circular_buffer(){
  static int mode = 0;
  mode = (mode + 1) % 2;
  unsigned config = 0;
  if (mode == 0) {
    config = 0x00000000;
  } else {
    config = 0x04000013;
  }
  xil_printf("setting ADC config to %x \r\n", config);
  Xil_Out32(ADDR_AXIL_REGS+0xD110, config);
}


void toggle_adc_trigger(){
  static int mode = 0;
  mode = (mode + 1) % 2;
  unsigned config = 0;
  if (mode == 0) {
    config = 0x00000000;
  } else {
    config = 0x04000013;
  }  
  xil_printf("setting ADC config to %x \r\n", config);
  Xil_Out32(ADDR_AXIL_REGS+0xD110, config);    

  if (mode == 1){
    usleep(100000);
    config = 0x04000033;
  }
  xil_printf("setting ADC config to %x \r\n", config);
  Xil_Out32(ADDR_AXIL_REGS+0xD110, config);    

}

void toggle_adc_patterns(){
  static int mode = 0;
  mode = (mode + 1) % 6;
  unsigned config = 0;
  if (mode == 0) {
    config = 0x00000000;
  } else if (mode == 1) {
    config = 0x000000A3;
  }  else if (mode == 2) {
    config = 0x000403B3;
  } else if (mode == 3) {
    config = 0x00080FB3;
  } else if (mode == 4) {
    config = 0x000CABC3;
  } else if (mode == 5) {
    config = 0x000C12C3;
  } else {
    return;
  }
  xil_printf("setting ADC config to %x \r\n", config);
  Xil_Out32(ADDR_AXIL_REGS+0xD110, config);
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

void write_bram(){
  for (int i=0; i<30; i++){
    Xil_Out32(XPAR_BRAM_0_BASEADDR+4*i, i);
  }
}

void read_bram(){
  for (int i=0; i<=256; i++){    
    xil_printf("0x%x, ", Xil_In32(XPAR_BRAM_0_BASEADDR+4*i));
    if ((i+1)%10==0)
      xil_printf("\r\n");
  }
  xil_printf("\r\n");
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


void send_atc_signals(){
  
}


int main(){
  xil_printf("SANITY NUMBER:  1\r\n");
  xil_printf("PACMAN HW check\r\n");
  int status = 0;
  status |= init_gpiops();
  status |= init_iic();
  if (status != XST_SUCCESS) {
    xil_printf("Hardware initialization has FAILED.\r\n");
    return 0;
  }
  while(1){
    xil_printf("choose an option:\r\n");
    xil_printf("(1) blink LEDS (2) read global registers (3) toggle enables\r\n");
    xil_printf("(4) check iic (5) toggle MUX (6) toggle DAC (7) pulse DAC\r\n");
    xil_printf("(8) enable ADC (9) toggle ADC circular buffer (a) toggle ADC trigger mode (b) toggle ADC patterns \r\n");
    xil_printf("(c) read BRAM  (d) write BRAM (e) toggle VDDD/VDDA voltages \r\n");
    xil_printf("(f) send ATC signals \r\n");

    unsigned char c=inbyte();
    xil_printf("pressed:  %c\n\r", c);
    switch(c){
    case '1':
      blink();
      break;
    case '2':
      read_global_registers();
      break;
    case '3':
      toggle_enables();
      break;
    case '4':
      check_iic();
      break;
    case '5':
      toggle_mux();
      break;
    case '6':
      toggle_dac();
      break;
    case '7':
      pulse_dac();
      break;
    case '8':
      toggle_adc_sleep();
      break;      
    case '9':
      toggle_adc_circular_buffer();
      break;
    case 'a':
      toggle_adc_trigger();
      break;      
    case 'b':
      toggle_adc_patterns();
      break;      
    case 'c':
      read_bram();
      break;
    case 'd':
      write_bram();
      break;   
    case 'e':
      toggle_voltages();
      break;   
    default:
      xil_printf("invalid selection...\n\r");
    }
  }
  return 0;
}
