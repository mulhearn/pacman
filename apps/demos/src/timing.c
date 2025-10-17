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

#include "hw_access.h"
#include "global.h"

#define C_SCOPE_ATC 0xE000


#define C_ADDR_ATC_STATUS          0x000 //read only
#define C_ADDR_ATC_TIMESTAMP       0x004 //read only

#define C_ADDR_ATC_POKE_C          0x0C0
#define C_ADDR_ATC_POKE_D          0x0D0

#define C_ADDR_ATC_CONFIG_REQ      0x100
#define C_ADDR_ATC_POLARITY        0x108
#define C_ADDR_ATC_LOGIC           0x10C
#define C_ADDR_ATC_DST_LEMO_A      0x110
#define C_ADDR_ATC_DST_LEMO_B      0x114
#define C_ADDR_ATC_DST_POKE_C      0x118
#define C_ADDR_ATC_DST_POKE_D      0x11C
#define C_ADDR_ATC_DST_LOGIC_E     0x120
#define C_ADDR_ATC_DST_LOGIC_F     0x124

#define C_ADDR_ATC_COUNT_REQ       0x200
#define C_ADDR_ATC_COUNT           0x204 //read only

void read_atc_registers(){
  const unsigned BASE = AXIL_REGISTERS_BASEADDR+C_SCOPE_ATC;

  xil_printf("timing status---------------0x%x \r\n", Xil_In32(BASE+C_ADDR_ATC_STATUS));
  xil_printf("timestamp-------------------0x%x \r\n", Xil_In32(BASE+C_ADDR_ATC_TIMESTAMP));
  xil_printf("polarity--------------------0x%x \r\n", Xil_In32(BASE+C_ADDR_ATC_POLARITY));
  xil_printf("destination LEMO A----------0x%x \r\n", Xil_In32(BASE+C_ADDR_ATC_DST_LEMO_A));
  xil_printf("destination LEMO B----------0x%x \r\n", Xil_In32(BASE+C_ADDR_ATC_DST_LEMO_B));
  xil_printf("destination poke C----------0x%x \r\n", Xil_In32(BASE+C_ADDR_ATC_DST_POKE_C));
  xil_printf("destination poke D----------0x%x \r\n", Xil_In32(BASE+C_ADDR_ATC_DST_POKE_D));
  xil_printf("destination logic E---------0x%x \r\n", Xil_In32(BASE+C_ADDR_ATC_DST_LOGIC_E));
  xil_printf("destination logic F---------0x%x \r\n", Xil_In32(BASE+C_ADDR_ATC_DST_LOGIC_F));
}


#define C_ATC_BUSY_WAIT 10
int wait_atc_busy(int timeout){
  const unsigned BASE = AXIL_REGISTERS_BASEADDR+C_SCOPE_ATC;
  while (timeout && ( Xil_In32(BASE+C_ADDR_ATC_STATUS) & 0xF)){ usleep(1); timeout--; }
  return timeout;
}



void read_atc_counts(){
  const unsigned BASE = AXIL_REGISTERS_BASEADDR+C_SCOPE_ATC;
  unsigned count = 0;

  wait_atc_busy(C_ATC_BUSY_WAIT);

  Xil_Out32(BASE+C_ADDR_ATC_COUNT_REQ, 0b01110000);
  wait_atc_busy(C_ATC_BUSY_WAIT);
  count = Xil_In32(BASE+C_ADDR_ATC_COUNT);
  xil_printf("LEMO A----------------------%4d (0x%x) \r\n", count, count);

  Xil_Out32(BASE+C_ADDR_ATC_COUNT_REQ, 0b01110001);
  wait_atc_busy(C_ATC_BUSY_WAIT);
  count = Xil_In32(BASE+C_ADDR_ATC_COUNT);
  xil_printf("LEMO B----------------------%4d (0x%x) \r\n", count, count);

  Xil_Out32(BASE+C_ADDR_ATC_COUNT_REQ, 0b01110010);
  wait_atc_busy(C_ATC_BUSY_WAIT);
  count = Xil_In32(BASE+C_ADDR_ATC_COUNT);
  xil_printf("POKE C----------------------%4d (0x%x) \r\n", count, count);

  Xil_Out32(BASE+C_ADDR_ATC_COUNT_REQ, 0b01110011);
  wait_atc_busy(C_ATC_BUSY_WAIT);
  count = Xil_In32(BASE+C_ADDR_ATC_COUNT);
  xil_printf("POKE D----------------------%4d (0x%x) \r\n", count, count);

  for (int i=0; i<10; i++){
    Xil_Out32(BASE+C_ADDR_ATC_COUNT_REQ, 0b01010000 + i);
    wait_atc_busy(C_ATC_BUSY_WAIT);
    count = Xil_In32(BASE+C_ADDR_ATC_COUNT);
    xil_printf("OUTPUT G(%d)-----------------%4d (0x%x) \r\n", i, count, count);
  }

  for (int i=0; i<10; i++){
    Xil_Out32(BASE+C_ADDR_ATC_COUNT_REQ, 0b01100000 + i);
    wait_atc_busy(C_ATC_BUSY_WAIT);
    count = Xil_In32(BASE+C_ADDR_ATC_COUNT);
    xil_printf("OUTPUT H(%d)-----------------%4d (0x%x) \r\n", i, count, count);
  }

}

void toggle_atc_destinations(){
  const unsigned BASE = AXIL_REGISTERS_BASEADDR+C_SCOPE_ATC;

  static int mode = 0;
  mode = (mode + 1) % 3;
  if (mode == 0) {
    xil_printf("INFO:  setting all destinations to zero (no output) \r\n");
    Xil_Out32(BASE+C_ADDR_ATC_DST_LEMO_A,  0x0);
    Xil_Out32(BASE+C_ADDR_ATC_DST_LEMO_B,  0x0);
    Xil_Out32(BASE+C_ADDR_ATC_DST_POKE_C,  0x0);
    Xil_Out32(BASE+C_ADDR_ATC_DST_POKE_D,  0x0);
    Xil_Out32(BASE+C_ADDR_ATC_DST_LOGIC_E, 0x0);
    Xil_Out32(BASE+C_ADDR_ATC_DST_LOGIC_F, 0x0);
    wait_atc_busy(C_ATC_BUSY_WAIT);
    Xil_Out32(BASE+C_ADDR_ATC_CONFIG_REQ, 0x0);
    wait_atc_busy(C_ATC_BUSY_WAIT);
  } else if (mode == 1) {
    xil_printf("configure timing for POKE C -> G POKE D -> H \r\n");
    Xil_Out32(BASE+C_ADDR_ATC_DST_LEMO_A,  0x0);
    Xil_Out32(BASE+C_ADDR_ATC_DST_LEMO_B,  0x0);
    Xil_Out32(BASE+C_ADDR_ATC_DST_POKE_C,  0x03FF0001);
    Xil_Out32(BASE+C_ADDR_ATC_DST_POKE_D,  0x03FF0002);
    Xil_Out32(BASE+C_ADDR_ATC_DST_LOGIC_E, 0x0);
    Xil_Out32(BASE+C_ADDR_ATC_DST_LOGIC_F, 0x0);
    wait_atc_busy(C_ATC_BUSY_WAIT);
    Xil_Out32(BASE+C_ADDR_ATC_CONFIG_REQ, 0x0);
    wait_atc_busy(C_ATC_BUSY_WAIT);
  } else {
    xil_printf("configure timing for LEMO A -> G LEMO B -> H \r\n");
    Xil_Out32(BASE+C_ADDR_ATC_DST_LEMO_A,  0x03FF0001);
    Xil_Out32(BASE+C_ADDR_ATC_DST_LEMO_B,  0x03FF0002);
    Xil_Out32(BASE+C_ADDR_ATC_DST_POKE_C,  0x0);
    Xil_Out32(BASE+C_ADDR_ATC_DST_POKE_D,  0x0);
    Xil_Out32(BASE+C_ADDR_ATC_DST_LOGIC_E, 0x0);
    Xil_Out32(BASE+C_ADDR_ATC_DST_LOGIC_F, 0x0);
    wait_atc_busy(C_ATC_BUSY_WAIT);
    Xil_Out32(BASE+C_ADDR_ATC_CONFIG_REQ, 0x0);
    wait_atc_busy(C_ATC_BUSY_WAIT);
  }
}

void send_poke_c(){
  const unsigned BASE = AXIL_REGISTERS_BASEADDR+C_SCOPE_ATC;
  wait_atc_busy(C_ATC_BUSY_WAIT);
  Xil_Out32(BASE+C_ADDR_ATC_POKE_C,0x3FF);
}

void send_poke_d(){
  const unsigned BASE = AXIL_REGISTERS_BASEADDR+C_SCOPE_ATC;
  wait_atc_busy(C_ATC_BUSY_WAIT);
  Xil_Out32(BASE+C_ADDR_ATC_POKE_D,0x3FF);
}

void timing_menu(){
  xil_printf("ASIC timing and control (ATC) signal menu:  \r\n");
  while(1){
    xil_printf("choose an option:\r\n");
    xil_printf("(0) Exit timing menu\r\n");
    xil_printf("(1) read ATC registers (2) read ATC counts (3) toggle ATC destinations \r\n");
    xil_printf("(4) poke C (5) poke D \r\n");

    unsigned char c=inbyte();
    xil_printf("pressed:  %c\n\r", c);
    switch(c){
    case '0':
      return;
    case '1':
      read_atc_registers();
      break;
    case '2':
      read_atc_counts();
      break;
    case '3':
      toggle_atc_destinations();
      break;
    case '4':
      send_poke_c();
      break;
    case '5':
      send_poke_d();
      break;
    default:
      xil_printf("invalid selection...\n\r");
    }
  }
}
