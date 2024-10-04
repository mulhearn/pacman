#include <stdio.h>
#include "xparameters.h"
#include "xil_io.h"
#include "xgpiops.h"
#include "xiicps.h"
#include "xaxidma.h"
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
#define C_ADDR_RX_CNT_ACK     0x38
#define C_ADDR_RX_CNT_LOST    0x3C
//  -- Channel number (loopback test of channel id)

#define C_ADDR_RX_NCHAN       0x40


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


void read_rx(){
  xil_printf(" *** READING RX REGISTERS *** \r\n");

  unsigned chan=0;
  //for (unsigned chan=0; chan<40; chan++){    
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

  addr = ADDR_AXIL_REGS+chan_off+C_ADDR_RX_CNT_CYCLES;
  xil_printf("cycle count (0x%x) -- 0x%x  \r\n", addr, Xil_In32(addr));

  addr = ADDR_AXIL_REGS+chan_off+C_ADDR_RX_CNT_BUSY;
  xil_printf("busy count  (0x%x) -- 0x%x  \r\n", addr, Xil_In32(addr));

  addr = ADDR_AXIL_REGS+chan_off+C_ADDR_RX_CNT_ACK;
  xil_printf("ack count   (0x%x) -- 0x%x  \r\n", addr, Xil_In32(addr));

  addr = ADDR_AXIL_REGS+chan_off+C_ADDR_RX_CNT_LOST;
  xil_printf("lost count   (0x%x) -- 0x%x  \r\n", addr, Xil_In32(addr));

}

void single_rx(){

  unsigned chan=0;
  //for (unsigned chan=0; chan<40; chan++){    
  unsigned chan_off = (chan<<10) + (0x1<<9);
  unsigned addr = 0;
  unsigned val = 0;
  xil_printf("UART RX channel:  %d   Address Offset:  0x%x \r\n", chan, chan_off);

  addr = ADDR_AXIL_REGS+chan_off+C_ADDR_TX_COMMAND;
  val  = 0x1;
  xil_printf("sending command(0x%x) with value 0x%x  \r\n", addr, val);
  Xil_Out32(addr, val);      
  //}
}


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

  addr = ADDR_AXIL_REGS+chan_off+C_ADDR_TX_LOOK_C;
  xil_printf("look C (0x%x) -- 0x%x  \r\n", addr, Xil_In32(addr));
  addr = ADDR_AXIL_REGS+chan_off+C_ADDR_TX_LOOK_D;
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

  addr = ADDR_AXIL_REGS+chan_off+C_ADDR_TX_CNT_CYCLES;
  xil_printf("cycle count (0x%x) -- 0x%x  \r\n", addr, Xil_In32(addr));

  addr = ADDR_AXIL_REGS+chan_off+C_ADDR_TX_CNT_BUSY;
  xil_printf("busy count  (0x%x) -- 0x%x  \r\n", addr, Xil_In32(addr));

  addr = ADDR_AXIL_REGS+chan_off+C_ADDR_TX_CNT_ACK;
  xil_printf("ack count   (0x%x) -- 0x%x  \r\n", addr, Xil_In32(addr));
  
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

  
  addr = ADDR_AXIL_REGS+chan_off+C_ADDR_TX_CONFIG;
  val  = 0x00002001;
  xil_printf("setting config (0x%x) to 0x%x  \r\n", addr, val);
  Xil_Out32(addr, val);

  addr = ADDR_AXIL_REGS+chan_off+C_ADDR_TX_SEND_C;
  val  = 0xCCCC0000 + count;
  xil_printf("setting SEND C (0x%x) to 0x%x  \r\n", addr, val);
  Xil_Out32(addr, val);  

  addr = ADDR_AXIL_REGS+chan_off+C_ADDR_TX_SEND_D;
  val  = 0xDDDD0000 + count;
  xil_printf("setting SEND D  (0x%x) to 0x%x  \r\n", addr, val);
  Xil_Out32(addr, val);  

  addr = ADDR_AXIL_REGS+chan_off+C_ADDR_TX_COMMAND;
  val  = 0x1;
  xil_printf("sending command(0x%x) with value 0x%x  \r\n", addr, val);
  Xil_Out32(addr, val);  
  //}
}

void send_command(unsigned mask){
  for (unsigned chan=0; chan<40; chan++){    
    unsigned chan_off = (chan<<10);
    unsigned val = 0;
    unsigned addr = 0;

    addr = ADDR_AXIL_REGS+chan_off+C_ADDR_TX_COMMAND;
    val  = mask;
    //xil_printf("sending command(0x%x) with value 0x%x  \r\n", addr, val);
    Xil_Out32(addr, val);  
  }

  for (unsigned chan=0; chan<40; chan++){
    unsigned chan_off = (chan<<10) + (0x1<<9);
    unsigned val = 0;
    unsigned addr = 0;

    addr = ADDR_AXIL_REGS+chan_off+C_ADDR_TX_COMMAND;
    val  = mask;
    //xil_printf("sending command(0x%x) with value 0x%x  \r\n", addr, val);
    Xil_Out32(addr, val);  
  }
}


void set_mode_single(){

  // config TX
  for (unsigned chan=0; chan<40; chan++){    
    unsigned chan_off = (chan<<10);
    unsigned val = 0;
    unsigned addr = 0;
  
    addr = ADDR_AXIL_REGS+chan_off+C_ADDR_TX_CONFIG;
    val  = 0x00002001;
    xil_printf("setting config (0x%x) to 0x%x  \r\n", addr, val);
    Xil_Out32(addr, val);
  }

  // config RX
  for (unsigned chan=0; chan<40; chan++){    
    unsigned chan_off = (chan<<10) + (0x1<<9);
    unsigned val = 0;
    unsigned addr = 0;
  
    addr = ADDR_AXIL_REGS+chan_off+C_ADDR_RX_CONFIG;
    val  = 0x00002001;
    xil_printf("setting config (0x%x) to 0x%x  \r\n", addr, val);
    Xil_Out32(addr, val);
  }
  
}

void set_mode_continuous(){
  
  for (unsigned chan=0; chan<40; chan++){    
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
  }

  // config RX
  for (unsigned chan=0; chan<40; chan++){    
    unsigned chan_off = (chan<<10) + (0x1<<9);
    unsigned val = 0;
    unsigned addr = 0;
  
    addr = ADDR_AXIL_REGS+chan_off+C_ADDR_RX_CONFIG;
    val  = 0x00003001;
    xil_printf("setting config (0x%x) to 0x%x  \r\n", addr, val);
    Xil_Out32(addr, val);
  }  
}




void dma_status(){
  xil_printf("DMA control register (MM2S) - 0x%x \r\n", Xil_In32(XPAR_AXI_DMA_0_BASEADDR+0x00));
  xil_printf("DMA status register (MM2S)  - 0x%x \r\n", Xil_In32(XPAR_AXI_DMA_0_BASEADDR+0x04));
  xil_printf("DMA control register (S2MM) - 0x%x \r\n", Xil_In32(XPAR_AXI_DMA_0_BASEADDR+0x30));
  xil_printf("DMA status register (S2MM)  - 0x%x \r\n", Xil_In32(XPAR_AXI_DMA_0_BASEADDR+0x34));
}

void dma_loopback(){
  unsigned tx_base = 0x1100000;
  unsigned rx_base = 0x1300000;
  u32 *tx_buf = (u32 *)tx_base;
  u32 *rx_buf = (u32 *)rx_base;
  unsigned timeout;
  unsigned words = 4;
  
  // Using XPAR_AXI_DMA_0_BASEADDR  defined in xparameters.h

  xil_printf("*** Sending DMA reset*** \r\n");
  Xil_Out32(XPAR_AXI_DMA_0_BASEADDR+0x00, 0x04);
  Xil_Out32(XPAR_AXI_DMA_0_BASEADDR+0x30, 0x04);

  timeout = 10;
  while(timeout){
    unsigned cr_mm2s = Xil_In32(XPAR_AXI_DMA_0_BASEADDR+0x00);
    unsigned cr_s2mm = Xil_In32(XPAR_AXI_DMA_0_BASEADDR+0x30);
    if (((cr_mm2s&0x4)==0) && ((cr_s2mm&0x4)==0))
      break;
    xil_printf("*** waiting on reset *** \r\n");
    timeout--;
  }
  if (! timeout) {
    xil_printf("*** ERROR:  failed to reset... *** \r\n");
    return;
  } else {
    xil_printf("*** DMA reset complete. *** \r\n");
  }

  dma_status();

  xil_printf("*** Sending run*** \r\n");
  Xil_Out32(XPAR_AXI_DMA_0_BASEADDR+0x00, 0x01);
  Xil_Out32(XPAR_AXI_DMA_0_BASEADDR+0x30, 0x01);

  dma_status();
  
  xil_printf("*** Preparing buffers*** \r\n");  
  tx_buf[0] = 0xBBBBAAAA;
  tx_buf[1] = 0xDDDDCCCC;
  tx_buf[2] = 0x11111111;
  tx_buf[3] = 0x22222222;

  for (int i=0; i<words; i++)
    rx_buf[i] = 0x0;

  
  Xil_DCacheFlushRange((UINTPTR)tx_buf, words*4);
  Xil_DCacheFlushRange((UINTPTR)rx_buf, words*4);
  
  xil_printf("*** Sending write *** \r\n");    
  Xil_Out32(XPAR_AXI_DMA_0_BASEADDR+0x18, (u32) tx_buf);
  Xil_Out32(XPAR_AXI_DMA_0_BASEADDR+0x28, words*4);

  timeout = 10;
  while(timeout){
    unsigned sr_mm2s = Xil_In32(XPAR_AXI_DMA_0_BASEADDR+0x04);
    if ((sr_mm2s&0x2)!=0) 
      break;
    xil_printf("*** waiting for idle *** \r\n");
    timeout--;
  }
  if (! timeout) {
    xil_printf("*** ERROR:  failed to reach idle before timeout! *** \r\n");
    return;
  }
  
  xil_printf("*** Sending read *** \r\n");    
  Xil_Out32(XPAR_AXI_DMA_0_BASEADDR+0x48, (u32) rx_buf);
  Xil_Out32(XPAR_AXI_DMA_0_BASEADDR+0x58, words*4);

  timeout = 10;
  while(timeout){
    unsigned sr_s2mm = Xil_In32(XPAR_AXI_DMA_0_BASEADDR+0x34);
    if ((sr_s2mm&0x2)!=0) 
      break;
    xil_printf("*** waiting for idle *** \r\n");
    timeout--;
  }
  if (! timeout) {
    xil_printf("*** ERROR:  failed to reach idle before timeout! *** \r\n");
    return;
  }

  dma_status();
  
  Xil_DCacheInvalidateRange((UINTPTR) rx_buf, words*4);
  for (int i=0; i<words; i++)
    xil_printf("sent[%d]:  0x%x --> received[%d]:  0x%x\r\n", i, tx_buf[i], i, rx_buf[i]);
  
}


void dma_loopback_xilinx(){
  int Status;

  unsigned tx_base = 0x1100000;
  unsigned rx_base = 0x1300000;
  u32 *tx_buf = (u32 *)tx_base;
  u32 *rx_buf = (u32 *)rx_base;
  unsigned words = 4;
  
  XAxiDma AxiDma;
  XAxiDma_Config *CfgPtr;

  //Initialize the XAxiDma device.

  xil_printf("Initialize DMA... \r\n");

  CfgPtr = XAxiDma_LookupConfig(XPAR_AXIDMA_0_DEVICE_ID);
  if (!CfgPtr) {
    xil_printf("No config found for %d\r\n", XPAR_AXIDMA_0_DEVICE_ID);
    return;
  }
	
  Status = XAxiDma_CfgInitialize(&AxiDma, CfgPtr);
  if (Status != XST_SUCCESS) {
    xil_printf("Initialization failed %d\r\n", Status);
    return;
  }

  tx_buf[0] = 0xBBBBAAAA;
  tx_buf[1] = 0xDDDDCCCC;
  tx_buf[2] = 0x11111111;
  tx_buf[3] = 0x22222222;

  for (int i=0; i<words; i++)
    rx_buf[i] = 0x0;
    
  Xil_DCacheFlushRange((UINTPTR)tx_buf, words*4);
  Xil_DCacheFlushRange((UINTPTR)rx_buf, words*4);

  xil_printf("simple transfer: TX\r\n");
  Status = XAxiDma_SimpleTransfer(&AxiDma, (UINTPTR) rx_buf,
				  words*4, XAXIDMA_DEVICE_TO_DMA);
  
  if (Status != XST_SUCCESS) {
    xil_printf("dma_loopback failure\r\n");
  }

  xil_printf("simple transfer: RX\r\n");
  Status = XAxiDma_SimpleTransfer(&AxiDma, (UINTPTR) tx_buf,
				  words*4, XAXIDMA_DMA_TO_DEVICE);

  if (Status != XST_SUCCESS) {
    xil_printf("dma_loopback failure\r\n");
  }
  
  /*Wait till tranfer is done or 1usec * 10^6 iterations of timeout occurs*/
  int TimeOut = 1000;
  while (TimeOut) {
    if (!(XAxiDma_Busy(&AxiDma, XAXIDMA_DEVICE_TO_DMA)) &&
	!(XAxiDma_Busy(&AxiDma, XAXIDMA_DMA_TO_DEVICE))) {
      break;
    }
    xil_printf("idle...\r\n");
    TimeOut--;
    usleep(1U);
  }

  Xil_DCacheInvalidateRange((UINTPTR) rx_buf, words*4);
  
  for (int i=0; i<words; i++)
    xil_printf("sent[%d]:  0x%x --> received[%d]:  0x%x\r\n", i, tx_buf[i], i, rx_buf[i]);

}
		
int main(){
  xil_printf("SANITY NUMBER:  1\r\n");
  xil_printf("Pac-Man Card Low-Level Hardware Testing (Development)\r\n");
  int status = 0;
  status |= init_gpiops();
  status |= init_iic();    
  if (status != XST_SUCCESS) {
    xil_printf("Hardware initialization has FAILED.\r\n");
    return 0;
  }
  while(1){
    xil_printf("choose an option:\r\n");
    xil_printf("(1) set mode single RX/TX (2) set mode continuous RX/TX\r\n");
    xil_printf("(3) read TX registers (4) single TX \r\n");
    xil_printf("(5) read RX registers (6) single RX \r\n");
    xil_printf("(7) start (8) stop (9) clear\r\n");
    xil_printf("(a) DMA status (b) DMA loopback (c) DMA loopback (Xilinx) \r\n");
      
    unsigned char c=inbyte();
    xil_printf("pressed:  %c\n\r", c);
    switch(c){
    case '1':
      set_mode_single();
      break;
    case '2':
      set_mode_continuous();
      break;
    case '3':
      read_tx();
      break;
    case '4':
      single_tx();
      break;
    case '5':
      read_rx();
      break;
    case '6':
      single_rx();
      break;
    case '7':
      send_command(2);
      break;
    case '8':
      send_command(4);
      break;
    case '9':
      send_command(8);
      break;
    case 'a':
      dma_status();
      break;	
    case 'b':
      dma_loopback();
      break;	
    case 'c':
      dma_loopback_xilinx();
      break;	
    default:
      xil_printf("invalid selection...\n\r");
    }
  }
  return 0;
}




