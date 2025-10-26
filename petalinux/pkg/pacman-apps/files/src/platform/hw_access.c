#include <stdio.h>
#include <fcntl.h>
#include <time.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <linux/i2c-dev.h>
#include <string.h>
#include "hw_access.h"  // for hw_u8_t, hw_u32_t

#include "hw_access.h"


// move to header?
#define DMA_REGISTERS_LEN      0x00010000
#define AXIL_REGISTERS_LEN     0x00010000

//
// AXI-Lite Registers:
//

static volatile uint32_t * G_AXIL  = NULL;

void init_axil_driver(){
  clear_axil_driver_status();

  printf("INFO:  Opening /dev/mem.\n");
  int dh = open("/dev/mem", O_RDWR|O_SYNC);
  if (dh < 0) {
    printf("ERROR:  Failed to open /dev/mem\r\n");
    return;
  }

  printf("INFO:  Initializing PACMAN AXI-Lite interface of size %d at 0x%X\n", AXIL_REGISTERS_LEN, AXIL_REGISTERS_BASEADDR);
  G_AXIL = (uint32_t*) mmap(NULL, AXIL_REGISTERS_LEN, PROT_READ|PROT_WRITE, MAP_SHARED, dh, AXIL_REGISTERS_BASEADDR);
  if (G_AXIL == MAP_FAILED) {
    printf("ERROR:  mmap failed");
    close(dh);
    return;
  }
  close(dh);

  unsigned fwmajor = G_AXIL[0XFF10>>2];
  unsigned fwminor = G_AXIL[0XFF14>>2];
  unsigned fwbuild = G_AXIL[0XFF18>>2];
  unsigned hwcode  = G_AXIL[0XFF1C>>2];

  printf("INFO:  Running pacman firmware version %d.%d (Build: 0x%x  HW Code:  0x%x)\n", fwmajor, fwminor, fwbuild, hwcode);
}

hw_u32_t axil_driver_status(){ return HW_SUCCESS; }

void clear_axil_driver_status() {}

hw_val_t axil_read_register  (hw_addr_t offset){
  return G_AXIL[offset>>2];
}

void     axil_write_register (hw_addr_t offset, hw_val_t value){
  G_AXIL[offset>>2] = value;
}

//
// DMA Registers (AXI-Lite Interface):
//

static volatile uint32_t * G_DMA  = NULL;

void init_dma_driver(){
  clear_dma_driver_status();
  printf("INFO:  Opening /dev/mem.\n");
  int dh = open("/dev/mem", O_RDWR|O_SYNC);
  if (dh < 0) {
    printf("ERROR:  Failed to open /dev/mem\r\n");
    return;
  }

  printf("INFO:  Initializing DMA AXI-Lite interface of size %d at 0x%X\n", DMA_REGISTERS_LEN, DMA_REGISTERS_BASEADDR);
  G_DMA = (uint32_t*)mmap(NULL, DMA_REGISTERS_LEN, PROT_READ|PROT_WRITE, MAP_SHARED, dh, DMA_REGISTERS_BASEADDR);
  if (G_DMA == MAP_FAILED) {
    printf("ERROR:  mmap failed");
    close(dh);
    return;
  }

  close(dh);
}

hw_u32_t dma_driver_status(){ return HW_SUCCESS; }

void clear_dma_driver_status() {}

hw_val_t dma_read_register  (hw_addr_t offset){
  return G_DMA[offset>>2];
}

void     dma_write_register (hw_addr_t offset, hw_val_t value){
  G_DMA[offset>>2] = value;
}

//
// DMA buffer:
//

static volatile uint32_t * G_BUF  = NULL;
static hw_addr_t G_BUF_BASEADDR = 0;
static hw_addr_t G_BUF_SIZE = 0;

void init_dma_buffer(hw_addr_t baseaddr, hw_addr_t size){
  G_BUF_BASEADDR = baseaddr;
  G_BUF_SIZE     = size;

  printf("INFO:  Opening /dev/mem.\n");
  int dh = open("/dev/mem", O_RDWR|O_SYNC);
    if (dh < 0) {
    printf("ERROR:  Failed to open /dev/mem\r\n");
    return;
  }

  printf("INFO:  Initializing DMA buffer of size %d at 0x%X\n", G_BUF_SIZE, G_BUF_BASEADDR);
  G_BUF = (uint32_t*) mmap(NULL, G_BUF_SIZE, PROT_READ|PROT_WRITE, MAP_SHARED, dh, G_BUF_BASEADDR);
  if (G_BUF == MAP_FAILED) {
    printf("ERROR:  mmap failed");
    close(dh);
    return;
  }
  close(dh);
}

hw_ptr_t dma_ptr(hw_addr_t addr){
  if (addr < G_BUF_BASEADDR)
    return NULL;
  hw_addr_t offset = addr - G_BUF_BASEADDR;
  if (offset > G_BUF_SIZE)
    return NULL;
  return &G_BUF[offset>>2];
}

//
// I2C Interface:
//

#define I2C_DEV "/dev/i2c-0"
#define I2C_DEBUG true

static int G_IIC_FH = -1;
static hw_u32_t G_IIC_STATUS = 0;

void init_iic_driver() {
    if (G_IIC_FH >= 0) {
        printf("**ERROR** I2C already initialized.\n");
        G_IIC_STATUS |= 1;
        return;
    }

    G_IIC_FH = open(I2C_DEV, O_RDWR);
    if (G_IIC_FH < 0) {
        printf("**ERROR** Failed to open I2C device");
        G_IIC_STATUS |= 2;
        return;
    }

    // clear status flags after successful open
    clear_iic_driver_status();
}

// report the status of the AXI-LITE interface:
hw_u32_t iic_driver_status(){
  return G_IIC_STATUS;
}

// report the status of the AXI-LITE interface:
void clear_iic_driver_status(){
  G_IIC_STATUS = 0;
}

// Write a sequence of bytes to an I2C device
void iic_write(hw_u8_t addr, hw_u8_t reg, const hw_u8_t *data, hw_u32_t len) {
    if (G_IIC_FH < 0) {
        printf("**ERROR** iic_write: I2C not initialized\n");
        G_IIC_STATUS |= 1;
        return;
    }

    if (ioctl(G_IIC_FH, I2C_SLAVE, addr) < 0) {
        printf("**ERROR** iic_write: Failed to set I2C address 0x%02x\n", addr);
        G_IIC_STATUS |= 2;
        return;
    }

    hw_u8_t buf[len + 1];
    buf[0] = reg;
    for (hw_u32_t i = 0; i < len; i++)
        buf[i + 1] = data[i];

    ssize_t wrote = write(G_IIC_FH, buf, len + 1);
    if (wrote != (ssize_t)(len + 1)) {
      printf("**ERROR** iic_write: Failed to write %u bytes to 0x%02x (return value:  %zd\n", len+1, addr, wrote);
      G_IIC_STATUS |= 4;
    }

#if I2C_DEBUG
    printf("iic_write: addr 0x%02x reg 0x%02x data:", addr, reg);
    for (hw_u32_t i = 0; i < len; i++) printf(" 0x%02x", data[i]);
    printf("\n");
#endif
}

// Read a sequence of bytes from an I2C device
void iic_read(hw_u8_t addr, hw_u8_t reg, hw_u8_t *data, hw_u32_t len) {
    if (G_IIC_FH < 0) {
        printf("**ERROR** iic_read: I2C not initialized\n");
        G_IIC_STATUS |= 1;
        return;
    }

    if (ioctl(G_IIC_FH, I2C_SLAVE, addr) < 0) {
        printf("**ERROR** iic_read: Failed to set I2C address 0x%02x\n", addr);
        G_IIC_STATUS |= 2;
        return;
    }

    if (write(G_IIC_FH, &reg, 1) != 1) {
        printf("**ERROR** iic_read: Failed to write register 0x%02x to 0x%02x\n", reg, addr);
        G_IIC_STATUS |= 4;
        return;
    }

    if (read(G_IIC_FH, data, len) != (ssize_t)len) {
        printf("**ERROR** iic_read: Failed to read %u bytes from 0x%02x\n", len, addr);
        G_IIC_STATUS |= 8;
    }

#if I2C_DEBUG
    printf("iic_read: addr 0x%02x reg 0x%02x data:", addr, reg);
    for (hw_u32_t i = 0; i < len; i++) printf(" 0x%02x", data[i]);
    printf("\n");
#endif

}

//
// Timer:
//

static struct timespec start;
static struct timespec stop;


void start_hw_timer(){
  clock_gettime(CLOCK_MONOTONIC, &start);
}
void stop_hw_timer(){
  clock_gettime(CLOCK_MONOTONIC, &stop);
}

hw_u32_t hw_timer_elapsed_us(){
  long seconds        = stop.tv_sec  - start.tv_sec;
  long nanoseconds    = stop.tv_nsec - start.tv_nsec;
  hw_u32_t elapsed_us = seconds * 1000000 + nanoseconds / 1000;
  return elapsed_us;
}
