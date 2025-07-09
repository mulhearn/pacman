#ifndef __HW_ACCESS_H__
#define __HW_ACCESS_H__

#include "xil_types.h"
#include "xil_printf.h"
#include "xil_cache.h"
#include "sleep.h"
//#include "xtime_l.h"
//#include "xstatus.h"

//
// Platform-dependent (Linux or Bare-Metal) access to the hardware.
// *** This is the header for bare-metal applications ***
//
// This interface is implemented separately for Bare-Metal and Linux
// application.  Code written to this interface should compile and run
// unmodified on both Linux and bare-metal platforms.
//
// The HW interfaces that are currently supported are: AXI-Lite PACMAN
// register access, DMA register access, and memory mapped buffers for
// DMA.
//

// Hardware status is non-zero for any error:

#define HW_SUCCESS 0

// Typedefs for hardware addresses, values, and pointers:
typedef u32 hw_addr_t;
typedef u32 hw_val_t;
typedef volatile u32 * hw_ptr_t;

//
// AXI-Lite Registers:
//

// Base Hardware Address for the AXI-Lite Interface to PACMAN Registers
#define AXIL_REGISTERS_BASEADDR  XPAR_AXIL_TO_REGBUS_0_BASEADDR

// initialize the AXI-LITE interface for register access:
void init_axil_driver();

// report the status of the AXI-LITE interface:
int axil_driver_status();

// clear any errors in the AXI-LITE interface:
void clear_axil_driver_status();

// read the HW registers with offset <offset> relative to the AXI-LITE base address:
hw_val_t axil_read_register  (hw_addr_t offset);

// write <value> to the HW registers with offset <offset> relative to the AXI-LITE base address:
void     axil_write_register (hw_addr_t offset, hw_val_t value);

//
// DMA Registers:
//

// Base Hardware Address for the AXI-Lite Interface to DMA
#define DMA_REGISTERS_BASEADDR XPAR_AXI_DMA_0_BASEADDR

// initialize the software driver for the AXI-LITE interface providing register access:
void init_dma_driver();

// report the status of the AXI-LITE driver software (not HW status!):
int dma_driver_status();

// clear any errors in the AXI-LITE driver (not a HW reset or clear!):
void clear_dma_driver_status();

// read the HW registers with offset <offset> relative to the AXI-LITE base address:
hw_val_t dma_read_register  (hw_addr_t offset);

// write <value> to the HW registers with offset <offset> relative to the AXI-LITE base address:
void     dma_write_register (hw_addr_t offset, hw_val_t value);

//
// DMA Buffers:
//

// *** TODO needs a no-op init hook for when using mmap under linux... ***

#define HW_FLUSH_DCACHE(ptr, len)      Xil_DCacheFlushRange((UINTPTR)(ptr), (len))
#define HW_INVALIDATE_DCACHE(ptr, len) Xil_DCacheInvalidateRange((UINTPTR)(ptr), (len))

hw_ptr_t dma_ptr(hw_addr_t addr);


//
// printf utility: uses xil_printf
//
#define printf xil_printf

//
// timer utility:
//
void start_hw_timer();
void stop_hw_timer();
unsigned hw_timer_elapsed_us();

#endif // __HW_ACCESS_H__


