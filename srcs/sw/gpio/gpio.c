/******************************************************************************
*
* Copyright (C) 2009 - 2014 Xilinx, Inc.  All rights reserved.
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* Use of the Software is limited solely to applications:
* (a) running on a Xilinx device, or
* (b) that interact with a Xilinx device through a bus or interconnect.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
* XILINX  BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
* WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
* OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*
* Except as contained in this notice, the name of the Xilinx shall not be used
* in advertising or otherwise to promote the sale, use or other dealings in
* this Software without prior written authorization from Xilinx.
*
******************************************************************************/

/*
 * helloworld.c: simple test application
 *
 * This application configures UART 16550 to baud rate 9600.
 * PS7 UART (Zynq) is not initialized by this application, since
 * bootrom/bsp configures it to baud rate 115200
 *
 * ------------------------------------------------
 * | UART TYPE   BAUD RATE                        |
 * ------------------------------------------------
 *   uartns550   9600
 *   uartlite    Configurable only in HW design
 *   ps7_uart    115200 (configured by bootrom/bsp)
 */

#include <stdio.h>
#include "xparameters.h"
#include "xgpio.h"
#include "xstatus.h"
#include "xil_printf.h"

#define LED_DELAY         100000000
#define LED_CHANNEL 1
#define LED_MAX_BLINK   2     /* Number of times the LED Blinks */
#define GPIO_BITWIDTH   16      /* This is the width of the GPIO */
#define printf xil_printf       /* A smaller footprint printf */
#define GPIO_OUTPUT_DEVICE_ID   XPAR_GPIO_0_DEVICE_ID

XGpio GpioOutput;

int GpioOutputExample(u16 DeviceId, u32 GpioWidth)
{
        volatile int Delay;
        u32 LedBit;
        u32 LedLoop;
        int Status;

        /*
         * Initialize the GPIO driver so that it's ready to use,
         * specify the device ID that is generated in xparameters.h
         */
         Status = XGpio_Initialize(&GpioOutput, DeviceId);
         if (Status != XST_SUCCESS)  {
                  return XST_FAILURE;
         }

         /* Set the direction for all signals to be outputs */
         XGpio_SetDataDirection(&GpioOutput, LED_CHANNEL, 0x0);

         /* Set the GPIO outputs to low */
         XGpio_DiscreteWrite(&GpioOutput, LED_CHANNEL, 0x0);

         for (LedBit = 0x0; LedBit < GpioWidth; LedBit++)  {

                for (LedLoop = 0; LedLoop < LED_MAX_BLINK; LedLoop++) {

                        /* Set the GPIO Output to High */
                        XGpio_DiscreteSet(&GpioOutput, LED_CHANNEL,
                                                1 << LedBit);

                        /* Wait a small amount of time so the LED is visible */
                        for (Delay = 0; Delay < LED_DELAY; Delay++);

                        /* Clear the GPIO Output */
                        XGpio_DiscreteClear(&GpioOutput, LED_CHANNEL,
                                              1 << LedBit);


                        /* Wait a small amount of time so the LED is visible */
                        for (Delay = 0; Delay < LED_DELAY; Delay++);

                  }

         }

         return XST_SUCCESS;

}




int main()
{
    print("Hello GPIO\n\r");
    u32 status;

    print("\r\nRunning GpioOutputExample() for axi_gpio_0...\r\n");

    status = GpioOutputExample(XPAR_AXI_GPIO_0_DEVICE_ID,2);

    if (status == 0) {
    	print("GpioOutputExample PASSED.\r\n");
   }
    return 0;
}
