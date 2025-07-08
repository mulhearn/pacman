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

#include "axil_hw.h"
#include "global.h"
#include "gpiops.h"
#include "timing.h"
#include "adc.h"

void toggle_adc_sleep(){
  static int mode = 0;
  mode = (mode + 1) % 2;

  if (mode == 0) {
    xil_printf("set ADC to sleep  \r\n");
    set_adc_sleep();
  } else {
    xil_printf("set ADC to awake \r\n");
    set_adc_awake();
  }
}

void toggle_adc_circular_buffer(){
  static int mode = 0;
  mode = (mode + 1) % 2;
  unsigned config = 0;
  if (mode == 0) {
    poke_timing();
    usleep(1);
    config = 0x00000000;
  } else {
    config = 0x10000013;
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
    config = 0x10000013;
  }
  xil_printf("setting ADC config to %x \r\n", config);
  Xil_Out32(ADDR_AXIL_REGS+0xD110, config);

  if (mode == 1){
    usleep(100000);
    config = 0x10000033;
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


void write_bram(){
  for (int i=0; i<30; i++){
    Xil_Out32(XPAR_BRAM_0_BASEADDR+4*i, i);
  }
}

void read_bram(){
  unsigned size = 1024;
  unsigned status = Xil_In32(ADDR_AXIL_REGS+0xD100);
  unsigned ladr = (status & 0xFFFF);
  xil_printf("BRAM status     -- 0x%x  \r\n", status);
  xil_printf("BRAM ladr       -- 0x%x  \r\n", ladr);
  xil_printf("BRAM size       -- 0x%x  \r\n", size);

  for (int i=0; i<size; i++){
    unsigned offset = 4*((ladr/4 + 1 + i) % size);
    xil_printf("0x%x, ", Xil_In32(XPAR_BRAM_0_BASEADDR+offset));
    if ((i+1)%10==0)
      xil_printf("\r\n");
  }
  xil_printf("\r\n");
}


void set_adc_mode_to_run(){
  Xil_Out32(ADDR_AXIL_REGS+0xD118, 0x2);
}

void adc_menu(){
  xil_printf("ADC Menu: \r\n");
  while(1){
    xil_printf("choose an option:\r\n");
    xil_printf("(0) exit ADC Menu \r\n");
    xil_printf("(1) toggle ADC sleep (2) toggle circular buffer (3) toggle trigger (4) run trigger\r\n");
    xil_printf("(5) toggle BRAM patterns (6) write BRAM (7) read BRAM \r\n");
    unsigned char c=inbyte();
    xil_printf("pressed:  %c\n\r", c);
    switch(c){
    case '0':
      return;
    case '1':
      toggle_adc_sleep();
      break;
    case '2':
      toggle_adc_circular_buffer();
      break;
    case '3':
      toggle_adc_trigger();
      break;
    case '4':
      set_adc_mode_to_run();
      break;
    case '5':
      toggle_adc_patterns();
      break;
    case '6':
      write_bram();
      break;
    case '7':
      read_bram();
      break;
    default:
      xil_printf("invalid selection...\n\r");
    }
  }
}
