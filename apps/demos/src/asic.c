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
#include "iic.h"

#include "asic.h"

void toggle_asic_power(){
  static int mode = 0;
  mode = (mode + 1) % 2;

  if (mode == 0) {
    xil_printf("setting VDDA and VDDD to zero \r\n");
    set_voltages(0, 0x00, 0x00, 0x00, 0x00);
    axil_write_register(SCOPE_GLOBAL+C_ADDR_GLOBAL_ENABLES, 0x0);
  } else {
    xil_printf("setting VDDA and VDDD to nominal for ASIC \r\n");
    set_voltages(0, 0xE2, 0xFF, 0x6D, 0xFF);
    axil_write_register(SCOPE_GLOBAL+C_ADDR_GLOBAL_ENABLES, 0x00010001);
  }
}

void asic_hello(){
}

void asic_menu(){
  xil_printf("ASIC Menu: \r\n");
  while(1){
    xil_printf("choose an option:\r\n");
    xil_printf("(0) exit ASIC Menu \r\n");
    xil_printf("(1) toggle ASIC power (2) ASIC hello \r\n");
    unsigned char c=inbyte();
    xil_printf("pressed:  %c\n\r", c);
    switch(c){
    case '0':
      return;
    case '1':
      toggle_asic_power();
      break;
    case '2':
      asic_hello();
      break;
    default:
      xil_printf("invalid selection...\n\r");
    }
  }
}
