
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
#define ADDR_AXIL_REGS  0x40010000
#define ADDR_AXIL_FIFO  0x43C10000
#define ADDR_AXIF_FIFO  0x43C20000

void check_reg_ro(){
  xil_printf("Reg0 -- 0x%x  \r\n", Xil_In32(ADDR_AXIL_REGS+0xFF00));
  xil_printf("Reg1 -- 0x%x  \r\n", Xil_In32(ADDR_AXIL_REGS+0xFF04));
  xil_printf("Reg2 -- 0x%x  \r\n", Xil_In32(ADDR_AXIL_REGS+0xFF08));
  xil_printf("Reg3 -- 0x%x  \r\n", Xil_In32(ADDR_AXIL_REGS+0xFF0C));
  xil_printf("Reg4 -- 0x%x  \r\n", Xil_In32(ADDR_AXIL_REGS+0xFF10));

  xil_printf("Reg0 -- 0x%x  \r\n", Xil_In32(ADDR_AXIL_REGS+0x0000));
  xil_printf("Reg1 -- 0x%x  \r\n", Xil_In32(ADDR_AXIL_REGS+0x0004));
  xil_printf("Reg2 -- 0x%x  \r\n", Xil_In32(ADDR_AXIL_REGS+0x0008));
  xil_printf("Reg3 -- 0x%x  \r\n", Xil_In32(ADDR_AXIL_REGS+0x000C));
  xil_printf("Reg4 -- 0x%x  \r\n", Xil_In32(ADDR_AXIL_REGS+0x0010));

  xil_printf("Reg0 -- 0x%x  \r\n", Xil_In32(ADDR_AXIL_REGS+0x1000));
  xil_printf("Reg1 -- 0x%x  \r\n", Xil_In32(ADDR_AXIL_REGS+0x1004));
  xil_printf("Reg2 -- 0x%x  \r\n", Xil_In32(ADDR_AXIL_REGS+0x1008));
  xil_printf("Reg3 -- 0x%x  \r\n", Xil_In32(ADDR_AXIL_REGS+0x100C));
  xil_printf("Reg4 -- 0x%x  \r\n", Xil_In32(ADDR_AXIL_REGS+0x1010));
}

void check_reg_rw(){
  static unsigned count=0;
  
  xil_printf("Count is 0x%x  \r\n", count);

  if ((count % 2)){
    Xil_Out32(ADDR_AXIL_REGS+0xFF00, 0x0);
    Xil_Out32(ADDR_AXIL_REGS+0x0000, 0x0);
    Xil_Out32(ADDR_AXIL_REGS+0x1000, 0x0);    
  } else {
    Xil_Out32(ADDR_AXIL_REGS+0xFF00, 0xAAAA1111);
    Xil_Out32(ADDR_AXIL_REGS+0x0000, 0xBBBB2222);
    Xil_Out32(ADDR_AXIL_REGS+0x1000, 0xCCCC4444);        
  }
  Xil_Out32(ADDR_AXIL_REGS+0xFF04, 0xDDDD0000 + count);
  Xil_Out32(ADDR_AXIL_REGS+0x0004, 0xEEEE0000 + count*2);
  Xil_Out32(ADDR_AXIL_REGS+0x1004, 0xFFFF0000 + count);        

  count = (count + 1)&0xF;
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

//  -- RX Unit Registers --
//  -- UART channel  (C = 0bCCCCCC 0<=C<40)
//  -- Broadcast at C=63=0b111111 on indicated registers only
//  -- Full (32 bit) Address: 0bCCCCCC10RRRRRRRR
#define C_ADDR_RX_STATUS      0x00
#define C_ADDR_RX_CONFIG      0x04
//  -- 128 RX register (LSB) A B C D (MSB)
#define C_ADDR_RX_LOOK_A      0x10
#define C_ADDR_RX_LOOK_B      0x14
#define C_ADDR_RX_LOOK_C      0x18
#define C_ADDR_RX_LOOK_D      0x1C
#define C_ADDR_RX_COMMAND     0x20
//  -- Counters (via start/stop command)

#define C_ADDR_RX_CNT_CYCLES  0x30
#define C_ADDR_RX_CNT_BUSY    0x34
#define C_ADDR_RX_CNT_RCVD    0x38
#define C_ADDR_RX_CNT_LOST    0x3C
//  -- Channel number (loopback test of channel id)

#define C_ADDR_RX_NCHAN       0x40


void check_rx(){
  xil_printf(" *** READING RX REGISTERS *** \r\n");
  
  for (unsigned chan=0; chan<40; chan++){    
    unsigned chan_off = (chan<<10) + (0x1<<9);
    unsigned addr = 0;
    
    xil_printf("UART RX channel:  %d   Address Offset:  0x%x \r\n", chan, chan_off);
    addr = ADDR_AXIL_REGS+chan_off+C_ADDR_RX_STATUS;
    xil_printf("status (0x%x) -- 0x%x  \r\n", addr, Xil_In32(addr));
    addr = ADDR_AXIL_REGS+chan_off+C_ADDR_RX_CONFIG;
    xil_printf("config (0x%x) -- 0x%x  \r\n", addr, Xil_In32(addr));
    addr = ADDR_AXIL_REGS+chan_off+C_ADDR_RX_LOOK_A;
    xil_printf("reg A (0x%x) -- 0x%x  \r\n", addr, Xil_In32(addr));
    addr = ADDR_AXIL_REGS+chan_off+C_ADDR_RX_LOOK_B;
    xil_printf("reg B (0x%x) -- 0x%x  \r\n", addr, Xil_In32(addr));    
    addr = ADDR_AXIL_REGS+chan_off+C_ADDR_RX_LOOK_C;
    xil_printf("reg C (0x%x) -- 0x%x  \r\n", addr, Xil_In32(addr));
    addr = ADDR_AXIL_REGS+chan_off+C_ADDR_RX_LOOK_D;
    xil_printf("reg D (0x%x) -- 0x%x  \r\n", addr, Xil_In32(addr));
    addr = ADDR_AXIL_REGS+chan_off+C_ADDR_RX_NCHAN;
    xil_printf("nchan (0x%x) -- 0x%x  \r\n", addr, Xil_In32(addr));
  }

  xil_printf(" *** WRITING RX REGISTERS *** \r\n");
  
  for (unsigned chan=0; chan<40; chan++){    
    unsigned chan_off = (chan<<10) + (0x1<<9);
    unsigned addr = 0;
    unsigned val = 0;
    xil_printf("UART RX channel:  %d   Address Offset:  0x%x \r\n", chan, chan_off);

    addr = ADDR_AXIL_REGS+chan_off+C_ADDR_RX_CONFIG;
    val  = 0xFF000101 + (chan<<16);
    xil_printf("setting config (0x%x) to 0x%x  \r\n", addr, val);
    Xil_Out32(addr, val);  
  }    

  xil_printf(" *** READING RX REGISTERS *** \r\n");
  
  for (unsigned chan=0; chan<40; chan++){    
    unsigned chan_off = (chan<<10) + (0x1<<9);
    unsigned addr = 0;

    xil_printf(" *** READING RX REGISTERS *** \r\n", chan, chan_off);

    xil_printf("UART RX channel:  %d   Address Offset:  0x%x \r\n", chan, chan_off);
    addr = ADDR_AXIL_REGS+chan_off+C_ADDR_RX_STATUS;
    xil_printf("status (0x%x) -- 0x%x  \r\n", addr, Xil_In32(addr));
    addr = ADDR_AXIL_REGS+chan_off+C_ADDR_RX_CONFIG;
    xil_printf("config (0x%x) -- 0x%x  \r\n", addr, Xil_In32(addr));
  }
}

//  -- TX Unit Registers --
//  -- UART channel  (C = 0bCCCCCC 0<=C<40)
//  -- Broadcast write at C=63=0b111111
//  -- Full (32 bit) Address: 0bCCCCCC00RRRRRRRR
#define C_ADDR_TX_STATUS    0x00
#define C_ADDR_TX_CONFIG    0x04
//  -- 64 RX register (LSB) C D (MSB) --
#define C_ADDR_TX_SEND_C    0x10
#define C_ADDR_TX_SEND_D    0x14
//  -- 64 RX register (LSB) C D (MSB) --
#define C_ADDR_TX_LOOK_C    0x18
#define C_ADDR_TX_LOOK_D    0x1C
#define C_ADDR_TX_COMMAND   0x20
//  -- Counters (via start/stop command)
#define C_ADDR_TX_CNT_CYCLES  0x30
#define C_ADDR_TX_CNT_BUSY    0x34
#define C_ADDR_TX_CNT_ACK     0x38
//  -- Channel number (loopback test of channel id)
#define C_ADDR_TX_NCHAN     0x40

void read_tx(){

  xil_printf(" *** READING TX REGISTERS *** \r\n");

  unsigned chan=0;
  //for (unsigned chan=0; chan<40; chan++){    
  unsigned chan_off = (chan<<10);
  unsigned addr = 0;
  unsigned status, config;
  xil_printf("UART TX channel:  %d   Address Offset:  0x%x \r\n", chan, chan_off);
  addr   = ADDR_AXIL_REGS+chan_off+C_ADDR_TX_STATUS;
  status = Xil_In32(addr);
  xil_printf("status (0x%x) -- 0x%x  \r\n", addr, status);
  addr = ADDR_AXIL_REGS+chan_off+C_ADDR_TX_CONFIG;
  config = Xil_In32(addr);
  xil_printf("config (0x%x) -- 0x%x  \r\n", addr, config);
  addr = ADDR_AXIL_REGS+chan_off+C_ADDR_TX_SEND_C;
  xil_printf("send C (0x%x) -- 0x%x  \r\n", addr, Xil_In32(addr));
  addr = ADDR_AXIL_REGS+chan_off+C_ADDR_TX_SEND_D;
  xil_printf("send D (0x%x) -- 0x%x  \r\n", addr, Xil_In32(addr));

  addr = ADDR_AXIL_REGS+chan_off+C_ADDR_TX_SEND_C;
  xil_printf("look C (0x%x) -- 0x%x  \r\n", addr, Xil_In32(addr));
  addr = ADDR_AXIL_REGS+chan_off+C_ADDR_TX_SEND_D;
  xil_printf("look D (0x%x) -- 0x%x  \r\n", addr, Xil_In32(addr));

  addr = ADDR_AXIL_REGS+chan_off+C_ADDR_TX_NCHAN;
  xil_printf("nchan (0x%x) -- 0x%x  \r\n", addr, Xil_In32(addr));

  xil_printf("status(0)  -       valid - %d\r\n", (status&0x001)!=0);
  xil_printf("status(1)  -        busy - %d\r\n", (status&0x002)!=0);
  xil_printf("status(2)  -         ack - %d\r\n", (status&0x004)!=0);
  xil_printf("status(3)  -          tx - %d\r\n", (status&0x008)!=0);
  xil_printf("\r\n");
  xil_printf("status(4)  -  valid_seen - %d\r\n", (status&0x010)!=0); 
  xil_printf("status(5)  -   busy_seen - %d\r\n", (status&0x020)!=0); 
  xil_printf("status(6)  -    ack_seen - %d\r\n", (status&0x040)!=0);  
  xil_printf("status(7)  -     tx_seen - %d\r\n", (status&0x080)!=0);   
  xil_printf("\r\n");
  xil_printf("status(8)  - single_seen - %d\r\n", (status&0x100)!=0);
  xil_printf("status(9)  -  start_seen - %d\r\n", (status&0x200)!=0); 
  xil_printf("status(10) -  stop_seen  - %d\r\n", (status&0x400)!=0);  
  xil_printf("status(11) -    running  - %d\r\n", (status&0x800)!=0);  
  xil_printf("\r\n");
  unsigned count = (0xFFFF0000&status)>>16;
  xil_printf("status(31 ... 16) -- count:  0x%x (%d)\r\n", count, count);
  //}
}

void single_tx(){
  static int count = 0;
  count = count + 1;

  unsigned chan=0;
  //for (unsigned chan=0; chan<40; chan++){    
  unsigned chan_off = (chan<<10);
  unsigned val = 0;
  unsigned addr = 0;

  
  addr = ADDR_AXIL_REGS+chan_off+C_ADDR_RX_CONFIG;
  val  = 0x00002001;
  xil_printf("setting config (0x%x) to 0x%x  \r\n", addr, val);
  Xil_Out32(addr, val);

  addr = ADDR_AXIL_REGS+chan_off+C_ADDR_TX_SEND_C;
  val  = 0xCCCC0000 + count;
  xil_printf("setting config (0x%x) to 0x%x  \r\n", addr, val);
  Xil_Out32(addr, val);  

  addr = ADDR_AXIL_REGS+chan_off+C_ADDR_TX_SEND_D;
  val  = 0xDDDD0000 + count;
  xil_printf("setting config (0x%x) to 0x%x  \r\n", addr, val);
  Xil_Out32(addr, val);  

  addr = ADDR_AXIL_REGS+chan_off+C_ADDR_TX_COMMAND;
  val  = 0x1;
  xil_printf("sending command(0x%x) with value 0x%x  \r\n", addr, val);
  Xil_Out32(addr, val);  
  //}
}

void send_tx_command(unsigned mask){
  for (unsigned chan=0; chan<40; chan++){    
    unsigned chan_off = (chan<<10);
    unsigned val = 0;
    unsigned addr = 0;

    addr = ADDR_AXIL_REGS+chan_off+C_ADDR_TX_COMMAND;
    val  = mask;
    xil_printf("sending command(0x%x) with value 0x%x  \r\n", addr, val);
    Xil_Out32(addr, val);  
  }
}


void continuous_tx(){

  unsigned chan=0;
  //for (unsigned chan=0; chan<40; chan++){    
  unsigned chan_off = (chan<<10);
  unsigned val = 0;
  unsigned addr = 0;

  addr = ADDR_AXIL_REGS+chan_off+C_ADDR_TX_SEND_C;
  val  = 0xCCCC1111;
  xil_printf("setting config (0x%x) to 0x%x  \r\n", addr, val);
  Xil_Out32(addr, val);  

  addr = ADDR_AXIL_REGS+chan_off+C_ADDR_TX_SEND_D;
  val  = 0xDDDD2222;
  xil_printf("setting config (0x%x) to 0x%x  \r\n", addr, val);
  Xil_Out32(addr, val);  
  
  addr = ADDR_AXIL_REGS+chan_off+C_ADDR_RX_CONFIG;
  val  = 0x00003001;
  xil_printf("setting config (0x%x) to 0x%x  \r\n", addr, val);
  Xil_Out32(addr, val);

  //}
}


void toggle_tx_c(){  
}

void toggle_clear(){  
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
      xil_printf("(1) read TX registers (2) single TX (3) continuous TX\r\n");
      xil_printf("(4) TX start (5) TX stop (6) TX clear\r\n");
      xil_printf("(7) RX check \r\n");

      unsigned char c=inbyte();
      xil_printf("pressed:  %c\n\r", c);
      switch(c){
      case '1':
        read_tx();
	break;
      case '2':
        single_tx();
	break;
      case '3':
        continuous_tx();
	break;
      case '4':
        send_tx_command(2);
	break;
      case '5':
	send_tx_command(4);
	break;
      case '6':
	send_tx_command(8);
	break;
      case '7':
        check_rx();
	break;
      default:
	xil_printf("invalid selection...\n\r");
      }
    }
    return 0;
}
