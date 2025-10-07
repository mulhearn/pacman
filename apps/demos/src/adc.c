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

void toggle_adc_enable(){
}

void read_adc_look(){
}

void adc_menu(){
  xil_printf("ADC Menu: \r\n");
  while(1){
    xil_printf("choose an option:\r\n");
    xil_printf("(0) exit ADC Menu \r\n");
    xil_printf("(1) toggle ADC sleep (2) toggle ADC enable (3) read ADC look \r\n");
    unsigned char c=inbyte();
    xil_printf("pressed:  %c\n\r", c);
    switch(c){
    case '0':
      return;
    case '1':
      toggle_adc_sleep();
      break;
    case '2':
      toggle_adc_enable();
      break;
    case '3':
      read_adc_look();
      break;
    default:
      xil_printf("invalid selection...\n\r");
    }
  }
}
