#ifndef __HARDWARE_H__
#define __HARDWARE_H__

#include "xil_types.h"
#include "xil_printf.h"

#define printf xil_printf

// Top-Level Hardware Description:

// Hardware status is non-zero for any error:
#define HW_SUCCESS 0

#define ADDR_AXIL_REGS  XPAR_AXIL_TO_REGBUS_0_BASEADDR

typedef u32 hw_adr_t;
typedef u32 hw_val_t;

#define ADDR_AXIL_REGS  XPAR_AXIL_TO_REGBUS_0_BASEADDR

#endif // __HARDWARE_H__


