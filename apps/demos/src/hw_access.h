#pragma once

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
// register access, DMA register access, memory mapped buffers for
// DMA, I2C, GPIO, and BRAM.
//
// Appropriate defines for cache management are included.  These are
// no-ops (removed at precompiler stage) under Linux.
//
// The interface provides basic utilities such as printf and sleep,
// via appropriate includes and defines.
//
// (BRAM support via this interface is untested, as current firmware
// does not include the controller)
//

#ifdef __cplusplus
extern "C" {
#endif

#include <stdint.h>
#include <stdbool.h>
#include <stdio.h>

// For baremetal, we depart from standard library for printf and sleep.
#ifdef _LINUX
  #include <unistd.h>
#else
  #include "xil_printf.h"
  #include "xil_cache.h"
  #include "sleep.h"
#endif

typedef uint8_t   hw_u8_t;
typedef uint16_t  hw_u16_t;
typedef uint32_t  hw_u32_t;
typedef uint64_t  hw_u64_t;

typedef hw_u32_t  hw_addr_t;
typedef hw_u32_t  hw_val_t;
typedef volatile hw_u32_t * hw_ptr_t;

// check sizes of typedefs:
#ifdef __cplusplus
  #define HW_STATIC_ASSERT static_assert
#else
  #define HW_STATIC_ASSERT _Static_assert
#endif
HW_STATIC_ASSERT(sizeof(hw_u8_t)  == 1,  "unexpected hw_u8_t size");
HW_STATIC_ASSERT(sizeof(hw_u16_t) == 2,  "unexpected hw_u16_t size");
HW_STATIC_ASSERT(sizeof(hw_u32_t) == 4,  "unexpected hw_u32_t size");

#define BRAM_BASEADDR           0x0

// Base addresses
#ifdef _LINUX
  #define AXIL_REGISTERS_BASEADDR 0x40000000
  #define DMA_REGISTERS_BASEADDR  0x40400000
  //#define BRAM_BASEADDR           TBD
#else
  #define AXIL_REGISTERS_BASEADDR XPAR_AXIL_TO_REGBUS_0_BASEADDR
  #define DMA_REGISTERS_BASEADDR  XPAR_AXI_DMA_0_BASEADDR
  //#define BRAM_BASEADDR           XPAR_BRAM_0_BASEADDR
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
//#ifndef _LINUX
//  #define printf xil_printf
//#endif

#define HW_SUCCESS 0

//
// AXI-LITE (general purpose) register access:
//

// initialize the AXI-LITE interface for register access:
void axil_platform_init();

// initialize the AXI-LITE interface for register access:
void axil_platform_close();

// report the status of the AXI-LITE interface:
hw_u32_t axil_platform_status();

// clear any errors in the AXI-LITE interface:
void axil_platform_clear_status();

// read the HW registers with offset <offset> relative to the AXI-LITE base address:
hw_val_t axil_read_register  (hw_addr_t offset);

// write <value> to the HW registers with offset <offset> relative to the AXI-LITE base address:
void     axil_write_register (hw_addr_t offset, hw_val_t value);

//
// DMA Registers:
//

// initialize the platform driver for the DMA interface:
void dma_platform_init();

// report the status of the DMA platform driver (not HW status!):
hw_u32_t dma_platform_status();

// clear any errors in the DMA platform driver (not a HW reset or clear!):
void dma_platform_clear_status();

// read the DMA registers with offset <offset> relative to the DMA base address:
hw_val_t dma_read_register  (hw_addr_t offset);

// write <value> to the DMA register with offset <offset> relative to the DMA base address:
void     dma_write_register (hw_addr_t offset, hw_val_t value);

//
// DMA Buffers:
//

// initialize the DMA buffer
void dma_platform_init_buffer(hw_addr_t baseaddr, hw_addr_t size);

// get a pointer to the hardware address addr
hw_ptr_t dma_ptr(hw_addr_t addr);

// get a pointer to the hardware address addr (asserts pointer is within allocation)
hw_ptr_t dma_ptr(hw_addr_t addr);

//get a pointer to the hardware address addr (asserts buffer is within allocation)
hw_ptr_t dma_safe_buffer(hw_addr_t addr, hw_addr_t size);

//
// I2C Interface:
//

// initialize the I2C interface:
void iic_platform_init();

// close the I2C interface:
void iic_platform_close();

// report the status of the AXI-LITE interface:
hw_u32_t iic_platform_status();

// report the status of the AXI-LITE interface:
void iic_platform_clear_status();

// Write a sequence of bytes to an I2C device.
// addr: 7-bit device address
// reg: first byte (typically the register)
// data: pointer to hw_u8 array
// len: number of additional bytes to write (may be zero)
void iic_write(hw_u8_t addr, hw_u8_t reg, const hw_u8_t *data, hw_u32_t len);

// Read a sequence of bytes from an I2C device.
// addr: 7-bit device address
// reg: register within device
// data: pointer to hw_u8 array to receive bytes
// len: number of bytes to read
// use_repeated_read: true to use repeated read (default behavior)
void iic_read(hw_u8_t addr, hw_u8_t reg, hw_u8_t *data, hw_u32_t len, bool use_repeated_read);

//
// PS GPIO (MIO) Interface:
//

typedef enum {
    GPIO_DIR_INPUT = 0,
    GPIO_DIR_OUTPUT = 1
} gpio_dir_t;

// initialize the GPIO platform
// (does nothing if driver is already initialized)
void gpio_platform_init();

// close the GPIO driver
void gpio_platform_close();

// report the status of the GPIO driver
hw_u32_t gpio_platform_status();

// clear the status of the GPIO driver
void gpio_platform_clear_status();

// configure direction and initial value for one pin
// pin: PS MIO pin index (platform-dependent numbering)
void gpio_platform_configure_pin(hw_u32_t pin, gpio_dir_t dir, hw_u32_t value);

// write to a pin
void gpio_write_pin(hw_u32_t pin, hw_u32_t value);

// read from a pin
hw_u32_t gpio_read_pin(hw_u32_t pin);

//
// BRAM Interface:  (Currently Unused and Untested)
//
void        bram_platform_init();
void        bram_platform_close();
hw_u32_t    bram_platform_status();
void        bram_platform_clear_status();
void        bram_platform_write(hw_u32_t addr, hw_u32_t value);
hw_u32_t    bram_platform_read(hw_u32_t addr);

//
// Timer utility:
//
// Simple microsecond timer for profiling; implemented separately per platform.
void start_hw_timer();
void stop_hw_timer();
hw_u32_t hw_timer_elapsed_us();

//
// Menu option utility:
//
// return last character pressed before enter:
char input_choice();

#ifdef __cplusplus
}
#endif

#endif // HW_ACCESS_H
