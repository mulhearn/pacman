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

// these are the addresses for the interfaces as read off from the address editor of the block diagram in vivado
#define ADDR_AXIL_REGS  0x40000000

#define SCOPE_GLOBAL 0xF000
#define ROLE_GLOBAL  0x0F00
#define ROLE_TIMING  0x0E00
#define C_SCOPE_TIMING 0xE000
#define C_TIMING_REGULAR 0x0000
#define C_TIMING_COUNTER 0x0200
#define C_TIMING_CFG     0x0400
#define C_ADDR_GLOBAL_SCRA      0x00
#define C_ADDR_GLOBAL_SCRB      0x04
#define C_ADDR_GLOBAL_FW_MAJOR  0x10
#define C_ADDR_GLOBAL_FW_MINOR  0x14
#define C_ADDR_GLOBAL_FW_BUILD  0x18
#define C_ADDR_GLOBAL_HW_CODE   0x1C
#define C_ADDR_GLOBAL_ENABLES   0x20

#define C_ADDR_TIMING_STATUS  0x00
#define C_ADDR_TIMING_STAMP   0x04
#define C_ADDR_ATC_POKE_C     0x10
#define C_ADDR_ATC_POKE_D     0x14


#define C_ADDR_COUNT_START    0xB0
#define C_ADDR_COUNT_STOP     0xB4
#define C_ADDR_COUNT_RESET    0xB8

#define C_ADDR_LEMO_A_F    0x20
#define C_ADDR_LEMO_B_F    0x24
#define C_ADDR_LEMO_A_S    0x30
#define C_ADDR_LEMO_B_S    0x34
#define C_ADDR_POKE_C_S    0x38
#define C_ADDR_POKE_D_S    0x3C

#define C_ADDR_ATC_POLARITY  0x40
#define C_ADDR_ATC_TS        0x44
#define C_ADDR_G_START       0x50
#define C_ADDR_H_START       0x80

void check_reg_ro(){
  xil_printf("fw major----------- %d   \r\n", Xil_In32(ADDR_AXIL_REGS+SCOPE_GLOBAL+ROLE_GLOBAL+C_ADDR_GLOBAL_FW_MAJOR));
  xil_printf("fw minor----------- %d   \r\n", Xil_In32(ADDR_AXIL_REGS+SCOPE_GLOBAL+ROLE_GLOBAL+C_ADDR_GLOBAL_FW_MINOR));
  xil_printf("fw build----------- 0x%x \r\n", Xil_In32(ADDR_AXIL_REGS+SCOPE_GLOBAL+ROLE_GLOBAL+C_ADDR_GLOBAL_FW_BUILD));
  xil_printf("hw code------------ 0x%x \r\n", Xil_In32(ADDR_AXIL_REGS+SCOPE_GLOBAL+ROLE_GLOBAL+C_ADDR_GLOBAL_HW_CODE));
  xil_printf("scratch a---------- 0x%x \r\n", Xil_In32(ADDR_AXIL_REGS+SCOPE_GLOBAL+ROLE_GLOBAL+C_ADDR_GLOBAL_SCRA));
  xil_printf("scratch b---------- 0x%x \r\n", Xil_In32(ADDR_AXIL_REGS+SCOPE_GLOBAL+ROLE_GLOBAL+C_ADDR_GLOBAL_SCRB));
  xil_printf("\r\n");
  xil_printf("enables------------ 0x%x \r\n", Xil_In32(ADDR_AXIL_REGS+SCOPE_GLOBAL+ROLE_GLOBAL+C_ADDR_GLOBAL_ENABLES));
  xil_printf("\r\n");
  xil_printf("timing status-------0x%x \r\n", Xil_In32(ADDR_AXIL_REGS+C_SCOPE_TIMING+C_TIMING_REGULAR+C_ADDR_TIMING_STATUS));
  //xil_printf("trig config---------0x%x \r\n", Xil_In32(ADDR_AXIL_REGS+SCOPE_GLOBAL+ROLE_TIMING+C_ADDR_TIMING_TRIG));
  //xil_printf("sync config---------0x%x \r\n", Xil_In32(ADDR_AXIL_REGS+SCOPE_GLOBAL+ROLE_TIMING+C_ADDR_TIMING_SYNC));
  xil_printf("\r\n");
  xil_printf("timestamp-----------0x%x \r\n", Xil_In32(ADDR_AXIL_REGS+C_SCOPE_TIMING+C_TIMING_REGULAR+C_ADDR_TIMING_STAMP));
  xil_printf("\r\n");
  
  xil_printf("LEMO_A_COUNT_Fast-----------0x%x \r\n", Xil_In32(ADDR_AXIL_REGS+C_SCOPE_TIMING+C_TIMING_COUNTER+C_ADDR_LEMO_A_F));  
  xil_printf("LEMO_B_COUNT_Fast-----------0x%x \r\n", Xil_In32(ADDR_AXIL_REGS+C_SCOPE_TIMING+C_TIMING_COUNTER+C_ADDR_LEMO_B_F));
  xil_printf("LEMO_A_COUNT_Slow-----------0x%x \r\n", Xil_In32(ADDR_AXIL_REGS+C_SCOPE_TIMING+C_TIMING_COUNTER+C_ADDR_LEMO_A_S));  
  xil_printf("LEMO_B_COUNT_Slow-----------0x%x \r\n", Xil_In32(ADDR_AXIL_REGS+C_SCOPE_TIMING+C_TIMING_COUNTER+C_ADDR_LEMO_B_S));
  xil_printf("POKE_C_COUNT_Slow-----------0x%x \r\n", Xil_In32(ADDR_AXIL_REGS+C_SCOPE_TIMING+C_TIMING_COUNTER+C_ADDR_POKE_C_S));  
  xil_printf("POKE_D_COUNT_Slow-----------0x%x \r\n", Xil_In32(ADDR_AXIL_REGS+C_SCOPE_TIMING+C_TIMING_COUNTER+C_ADDR_POKE_D_S));
  xil_printf("TS_OUT_COUNT-----------0x%x \r\n", Xil_In32(ADDR_AXIL_REGS+C_SCOPE_TIMING+C_TIMING_COUNTER+C_ADDR_ATC_TS ));  
  for (int i =0; i<10; ++i){
  unsigned addr_offset_g =C_ADDR_G_START + (i*4);
  unsigned addr_offset_h =C_ADDR_H_START + (i*4);
  xil_printf("G_OUT_COUNT_%u-----------0x%x \r\n", i,Xil_In32(ADDR_AXIL_REGS+C_SCOPE_TIMING+C_TIMING_COUNTER+addr_offset_g));  
  xil_printf("H_OUT_COUNT_%u-----------0x%x \r\n", i,Xil_In32(ADDR_AXIL_REGS+C_SCOPE_TIMING+C_TIMING_COUNTER+addr_offset_h));  
  }
    
  xil_printf("INPUT_POLARITY_CFG-----------0x%x \r\n", Xil_In32(ADDR_AXIL_REGS+C_SCOPE_TIMING+C_TIMING_CFG+C_ADDR_ATC_POLARITY  ));    
  xil_printf("TS_OUT_CFG-----------0x%x \r\n", Xil_In32(ADDR_AXIL_REGS+C_SCOPE_TIMING+C_TIMING_CFG+C_ADDR_ATC_TS ));  
  for (int i =0; i<10; ++i){
  unsigned addr_offset_g =C_ADDR_G_START + (i*4);
  unsigned addr_offset_h =C_ADDR_H_START + (i*4);
  xil_printf("G_OUT_CFG_%u-----------0x%x \r\n", i,Xil_In32(ADDR_AXIL_REGS+C_SCOPE_TIMING+C_TIMING_CFG+addr_offset_g));  
  xil_printf("H_OUT_CFG_%u-----------0x%x \r\n", i,Xil_In32(ADDR_AXIL_REGS+C_SCOPE_TIMING+C_TIMING_CFG+addr_offset_h));  
  }
  
}
void poke_c(){
  Xil_Out32(ADDR_AXIL_REGS+C_SCOPE_TIMING+C_TIMING_REGULAR+C_ADDR_ATC_POKE_C,0x00000000);
  xil_printf("poke_c\r\n");

}
void poke_d(){
  Xil_Out32(ADDR_AXIL_REGS+C_SCOPE_TIMING+C_TIMING_REGULAR+C_ADDR_ATC_POKE_D,0x00000000);
  xil_printf("poke_d\r\n");
}

void count_start(){
  Xil_Out32(ADDR_AXIL_REGS+C_SCOPE_TIMING+C_TIMING_REGULAR+C_ADDR_COUNT_START,0x00000000);
  xil_printf("Counter start\r\n");

}
void count_stop(){
  Xil_Out32(ADDR_AXIL_REGS+C_SCOPE_TIMING+C_TIMING_REGULAR+C_ADDR_COUNT_STOP,0x00000000);
  xil_printf("Counter stop\r\n");
}
void count_reset(){
  Xil_Out32(ADDR_AXIL_REGS+C_SCOPE_TIMING+C_TIMING_REGULAR+C_ADDR_COUNT_RESET,0x00000000);
  xil_printf("Counter reset\r\n");
}
void write_cfg(){
  for (int i =0; i<10; ++i){
  unsigned addr_offset_g =C_ADDR_G_START + (i*4);
  unsigned addr_offset_h =C_ADDR_H_START + (i*4);
  unsigned config_g = (i<<8) | 0x04;
  unsigned config_h = 0x00000000;
  Xil_Out32(ADDR_AXIL_REGS+C_SCOPE_TIMING+C_TIMING_CFG+addr_offset_g,config_g);
  Xil_Out32(ADDR_AXIL_REGS+C_SCOPE_TIMING+C_TIMING_CFG+addr_offset_h,config_h);
  }
  Xil_Out32(ADDR_AXIL_REGS+C_SCOPE_TIMING+C_TIMING_CFG+C_ADDR_ATC_POLARITY,0x00000000);
  Xil_Out32(ADDR_AXIL_REGS+C_SCOPE_TIMING+C_TIMING_CFG+C_ADDR_ATC_TS,0x00000104);
}


int main(){
  xil_printf("SANITY NUMBER:  1\r\n");
  xil_printf("Pac-Man Card Low-Level Hardware Testing (Development)\r\n");
  int status = 0;
  status |= init_gpiops();
  if (status != XST_SUCCESS) {
    xil_printf("Hardware initialization has FAILED.\r\n");
    return 0;
  }
  while(1){
    xil_printf("choose an option:\r\n");
    xil_printf("(1) blink LEDs \r\n");
    xil_printf("(2) check RO regs \r\n");
    xil_printf("(3) poke c \r\n");
    xil_printf("(4) poke d \r\n");
    xil_printf("(5) write config \r\n");
    xil_printf("(6) start counters \r\n");
    xil_printf("(7) stop counters \r\n");
    xil_printf("(8) reset counters \r\n");
    unsigned char c=inbyte();
    xil_printf("pressed:  %c\n\r", c);
    switch(c){
    case '1':
      blink();
      break;
    case '2':
      check_reg_ro();
      break;
    case '3':
      poke_c();
      break;
    case '4':
      poke_d();
      break;
    case '5':
      write_cfg();
      break;
    case '6':
      count_start();
      break;
    case '7':
      count_stop();
      break;
    case '8':
      count_reset();
      break;
    default:
      xil_printf("invalid selection...\n\r");
    }
  }
  return 0;
}
