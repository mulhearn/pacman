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

#include "gpiops.h"

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

void blink_mio_leds(){
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
}


void set_adc_sleep(){
  XGpioPs_WritePin(&gpiops, ADC_SLEEP, 1);
}
void set_adc_awake(){
  XGpioPs_WritePin(&gpiops, ADC_SLEEP, 0);
}
