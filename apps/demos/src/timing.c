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

#include "axil.h"

#define C_SCOPE_TIMING 0xE000

#define C_ADDR_TIMING_STATUS          0x000
#define C_ADDR_TIMING_STAMP           0x004
#define C_ADDR_TIMING_POKE_C          0x010
#define C_ADDR_TIMING_POKE_D          0x014
#define C_ADDR_TIMING_START_COUNTS    0x0B0
#define C_ADDR_TIMING_STOP_COUNTS     0x0B4
#define C_ADDR_TIMING_RESET_COUNTS    0x0B8

#define C_ADDR_TIMING_COUNT_LEMO_A_F  0x220
#define C_ADDR_TIMING_COUNT_LEMO_B_F  0x224
#define C_ADDR_TIMING_COUNT_LEMO_A_S  0x230
#define C_ADDR_TIMING_COUNT_LEMO_B_S  0x234
#define C_ADDR_TIMING_COUNT_POKE_C_S  0x238
#define C_ADDR_TIMING_COUNT_POKE_D_S  0x23C
#define C_ADDR_TIMING_COUNT_TS        0x24
#define C_ADDR_TIMING_COUNT_G_FIRST   0x250
#define C_ADDR_TIMING_COUNT_H_FIRST   0x280

#define C_ADDR_TIMING_CONFIG_POLARITY 0x440
#define C_ADDR_TIMING_CONFIG_TS       0x444
#define C_ADDR_TIMING_CONFIG_G_FIRST  0x450
#define C_ADDR_TIMING_CONFIG_H_FIRST  0x480

void read_timing_registers(){
  const unsigned BASE = ADDR_AXIL_REGS+C_SCOPE_TIMING;

  xil_printf("timing status---------------0x%x \r\n", Xil_In32(BASE+C_ADDR_TIMING_STATUS));
  xil_printf("timestamp-------------------0x%x \r\n", Xil_In32(BASE+C_ADDR_TIMING_STAMP));
  xil_printf("LEMO A count (fast)---------0x%x \r\n", Xil_In32(BASE+C_ADDR_TIMING_COUNT_LEMO_A_F));
  xil_printf("LEMO B_count (fast)---------0x%x \r\n", Xil_In32(BASE+C_ADDR_TIMING_COUNT_LEMO_B_F));
  xil_printf("LEMO A count (slow)---------0x%x \r\n", Xil_In32(BASE+C_ADDR_TIMING_COUNT_LEMO_A_S));
  xil_printf("LEMO B count (slow)---------0x%x \r\n", Xil_In32(BASE+C_ADDR_TIMING_COUNT_LEMO_B_S));
  xil_printf("poke C count----------------0x%x \r\n", Xil_In32(BASE+C_ADDR_TIMING_COUNT_POKE_C_S));
  xil_printf("poke D count----------------0x%x \r\n", Xil_In32(BASE+C_ADDR_TIMING_COUNT_POKE_D_S));
  xil_printf("TS count--------------------0x%x \r\n", Xil_In32(BASE+C_ADDR_TIMING_COUNT_TS));
  for (int i=0; i<10; i++){
    xil_printf("G count (TILE %d)----------0x%x \r\n", i,Xil_In32(BASE+C_ADDR_TIMING_COUNT_G_FIRST+4*i));
    xil_printf("H count (TILE %d)----------0x%x \r\n", i,Xil_In32(BASE+C_ADDR_TIMING_COUNT_H_FIRST+4*i));
  }

  xil_printf("INPUT_POLARITY_CFG----------0x%x \r\n", Xil_In32(BASE+C_ADDR_TIMING_CONFIG_POLARITY  ));
  xil_printf("TS_OUT_CFG------------------0x%x \r\n", Xil_In32(BASE+C_ADDR_TIMING_CONFIG_TS ));
  for (int i=0; i<10; i++){
    xil_printf("G_OUT_CFG_%u-----------0x%x \r\n", i,Xil_In32(BASE+C_ADDR_TIMING_CONFIG_G_FIRST+4*i));
    xil_printf("H_OUT_CFG_%u-----------0x%x \r\n", i,Xil_In32(BASE+C_ADDR_TIMING_CONFIG_H_FIRST+4*i));
  }
}

void toggle_timing_counts(){
  const unsigned BASE = ADDR_AXIL_REGS+C_SCOPE_TIMING;
  static int mode = 0;
  mode = (mode + 1) % 2;
  if (mode == 0) {
    xil_printf("stopping counts \r\n");
    Xil_Out32(BASE+C_ADDR_TIMING_STOP_COUNTS,  0x0);
  } else {
    xil_printf("reseting and starting counts \r\n");
    Xil_Out32(BASE+C_ADDR_TIMING_STOP_COUNTS,  0x0);
    Xil_Out32(BASE+C_ADDR_TIMING_RESET_COUNTS, 0x0);
    Xil_Out32(BASE+C_ADDR_TIMING_START_COUNTS, 0x0);
  }
}

void toggle_timing_config(){
  const unsigned BASE = ADDR_AXIL_REGS+C_SCOPE_TIMING;

  static int mode = 0;
  mode = (mode + 1) % 3;
  if (mode == 0) {
    xil_printf("clearing timing config ... \r\n");

    for (int i=0; i<10; i++){
      unsigned config_g = 0x00000000;
      unsigned config_h = 0x00000000;
      Xil_Out32(BASE + C_ADDR_TIMING_CONFIG_G_FIRST+4*i, config_g);
      Xil_Out32(BASE + C_ADDR_TIMING_CONFIG_H_FIRST+4*i, config_h);
    }
    Xil_Out32(BASE + C_ADDR_TIMING_CONFIG_POLARITY, 0x00000000);
    Xil_Out32(BASE + C_ADDR_TIMING_CONFIG_TS,       0x00000010);
  } else if (mode == 1) {
    xil_printf("configure timing for active low on POKE C \r\n");
    for (int i=0; i<10; i++){
      unsigned config_g = (0x0F<<8) | 0x14;
      unsigned config_h = (0x1F<<8) | 0x14;
      Xil_Out32(BASE + C_ADDR_TIMING_CONFIG_G_FIRST+4*i, config_g);
      Xil_Out32(BASE + C_ADDR_TIMING_CONFIG_H_FIRST+4*i, config_h);
    }
    Xil_Out32(BASE + C_ADDR_TIMING_CONFIG_POLARITY, 0x00000000);
    Xil_Out32(BASE + C_ADDR_TIMING_CONFIG_TS,       0x00000010);
  } else {

    xil_printf("configure timing for active high on POKE C \r\n");

    for (int i=0; i<10; i++){
      unsigned config_g = (0x0F<<8) | 0x04;
      unsigned config_h = (0x1F<<8) | 0x04;
      Xil_Out32(BASE + C_ADDR_TIMING_CONFIG_G_FIRST+4*i, config_g);
      Xil_Out32(BASE + C_ADDR_TIMING_CONFIG_H_FIRST+4*i, config_h);
    }
    Xil_Out32(BASE + C_ADDR_TIMING_CONFIG_POLARITY, 0x00000000);
    Xil_Out32(BASE + C_ADDR_TIMING_CONFIG_TS,       0x00000010);
  }
}

void poke_timing(){
  const unsigned BASE = ADDR_AXIL_REGS+C_SCOPE_TIMING;
  Xil_Out32(BASE+C_ADDR_TIMING_POKE_C,0x0);
  Xil_Out32(BASE+C_ADDR_TIMING_POKE_D,0x0);
}

void timing_menu(){
  xil_printf("Timing Unit menu:  \r\n");
  while(1){
    xil_printf("choose an option:\r\n");
    xil_printf("(0) Exit timing menu\r\n");
    xil_printf("(1) read timing registers (2) toggle counts (3) toggle ATC config (4) poke ATC \r\n");

    unsigned char c=inbyte();
    xil_printf("pressed:  %c\n\r", c);
    switch(c){
    case '0':
      return;
    case '1':
      read_timing_registers();
      break;
    case '2':
      toggle_timing_counts();
      break;
    case '3':
      toggle_timing_config();
    case '4':
      poke_timing();
      break;
    default:
      xil_printf("invalid selection...\n\r");
    }
  }
}
