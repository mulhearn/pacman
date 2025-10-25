#ifndef HW_ACCESS_H
#define HW_ACCESS_H

//
// Platform-dependent (Linux or Bare-Metal) access to the hardware.
//
// This interface is implemented separately for Bare-Metal and Linux
// applications.  Code written to this interface should compile and
// run unmodified on both Linux and bare-metal platforms.
//
// The HW interfaces that are currently supported are: AXI-Lite PACMAN
// register access, DMA register access, and memory mapped buffers for
// DMA.  (Soon: I2C)
//

#ifdef __cplusplus
extern "C" {
#endif

// Includes:
// For baremetal, we depart from standard library for types, printf, and sleep.
#ifdef _LINUX
  #include <stdint.h>
  #include <stdio.h>
  #include <unistd.h>
#else
  #include "xil_types.h"
  #include "xil_printf.h"
  #include "xil_cache.h"
  #include "sleep.h"
#endif

// Typedefs
#ifdef _LINUX
  typedef uint32_t hw_addr_t;
  typedef uint32_t hw_val_t;
  typedef volatile uint32_t * hw_ptr_t;
#else
  typedef u32 hw_addr_t;
  typedef u32 hw_val_t;
  typedef volatile u32 * hw_ptr_t;
#endif

// Base addresses
#ifdef _LINUX
  #define AXIL_REGISTERS_BASEADDR 0x40000000
  #define DMA_REGISTERS_BASEADDR  0x40400000
#else
  #define AXIL_REGISTERS_BASEADDR XPAR_AXIL_TO_REGBUS_0_BASEADDR
  #define DMA_REGISTERS_BASEADDR  XPAR_AXI_DMA_0_BASEADDR
#endif

// Cache management macros
#ifdef _LINUX
  #define HW_FLUSH_DCACHE(ptr, len)      ((void)0)
  #define HW_INVALIDATE_DCACHE(ptr, len) ((void)0)
#else
  #define HW_FLUSH_DCACHE(ptr, len)      Xil_DCacheFlushRange((UINTPTR)(ptr), (len))
  #define HW_INVALIDATE_DCACHE(ptr, len) Xil_DCacheInvalidateRange((UINTPTR)(ptr), (len))
#endif

// printf mapping
#ifndef _LINUX
  #define printf xil_printf
#endif


#define HW_SUCCESS 0

//
// AXI-LITE (general purpose) register access:
//

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

void init_dma_buffer(hw_addr_t baseaddr, hw_addr_t size);

hw_ptr_t dma_ptr(hw_addr_t addr);

//
// timer utility:
//
void start_hw_timer();
void stop_hw_timer();
unsigned hw_timer_elapsed_us();

#ifdef __cplusplus
}
#endif

#endif // __HW_ACCESS_H__


