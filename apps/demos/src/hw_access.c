#include "xparameters.h"
#include "xil_io.h"
#include "xgpiops.h"
#include "xiicps.h"
#include "xstatus.h"
#include "xtime_l.h"
#include "hw_access.h"

void axil_platform_init(){}

void axil_platform_close(){}

hw_u32_t axil_platform_status(){ return HW_SUCCESS; }

void axil_platform_clear_status() {}

hw_val_t axil_read_register  (hw_addr_t offset){
  return Xil_In32(AXIL_REGISTERS_BASEADDR+offset);
}

void     axil_write_register (hw_addr_t offset, hw_val_t value){
  Xil_Out32(AXIL_REGISTERS_BASEADDR+offset, value);
}

//
// DMA Interface:
//

void dma_platform_init(){}

hw_u32_t dma_platform_status(){ return HW_SUCCESS; }

void dma_platform_clear_status() {}

hw_val_t dma_read_register  (hw_addr_t offset){
  return Xil_In32(DMA_REGISTERS_BASEADDR+offset);
}

void     dma_write_register (hw_addr_t offset, hw_val_t value){
  Xil_Out32(DMA_REGISTERS_BASEADDR+offset, value);
}

void dma_platform_init_buffer(hw_addr_t baseaddr, hw_addr_t size){
}

hw_ptr_t dma_ptr(hw_addr_t addr){
  return (hw_ptr_t) addr;
}

hw_ptr_t dma_safe_buffer(hw_addr_t addr, hw_addr_t size){
  return (hw_ptr_t) addr;
}

//
// I2C Interface:
//

// I2C device parameters
#define IIC_DEVICE_ID     XPAR_XIICPS_0_DEVICE_ID
#define IIC_SCLK_RATE     200000

static XIicPs iicps;
static int iicps_initialized = 0;

// Initialize the I2C interface
void iic_platform_init() {
  // do nothing if already initialized
  if (iicps_initialized)
    return;

  printf("Initializing I2C interface...\r\n");

  XIicPs_Config *cfg = XIicPs_LookupConfig(IIC_DEVICE_ID);
  if (cfg == NULL) {
    printf("FAILED: No config found.\r\n");
    return;
  }

  int status = XIicPs_CfgInitialize(&iicps, cfg, cfg->BaseAddress);
  if (status != XST_SUCCESS) {
    printf("FAILED: Config initialize.\r\n");
    return;
  }

  printf("Performing I2C self-test...\r\n");
  status = XIicPs_SelfTest(&iicps);
  if (status != XST_SUCCESS) {
    printf("FAILED: Self-test.\r\n");
    return;
  }

  XIicPs_SetSClk(&iicps, IIC_SCLK_RATE);
  iicps_initialized = 1;
  printf("I2C interface initialized successfully.\r\n");

}

void iic_platform_close() {
  // noting to release, just mark as not inialized:
  iicps_initialized = 0;
}

hw_u32_t iic_platform_status() {
  // No AXI-Lite status in bare-metal polling; return 0
  return 0;
}

void iic_platform_clear_status() {
  // Nothing to do
}

void iic_write(hw_u8_t addr, hw_u8_t reg, const hw_u8_t *data, hw_u32_t len) {
  hw_u32_t buf_len = 1 + len;
  hw_u8_t buf[buf_len];

  buf[0] = reg;
  for (hw_u32_t i = 0; i < len; i++) {
    buf[1 + i] = data[i];
  }

  int status = XIicPs_MasterSendPolled(&iicps, buf, buf_len, addr);
  if (status != XST_SUCCESS) {
    printf("I2C write failed to addr 0x%x reg 0x%x\r\n", addr, reg);
  }

  while (XIicPs_BusIsBusy(&iicps)) { /* wait */ }
}

void iic_read(hw_u8_t addr, hw_u8_t reg, hw_u8_t *data, hw_u32_t len,  bool use_repeated_read) {

  if (use_repeated_read)
    XIicPs_SetOptions(&iicps, XIICPS_REP_START_OPTION);


  // Send register first
  hw_u8_t reg_buf = reg;
  int status = XIicPs_MasterSendPolled(&iicps, &reg_buf, 1, addr);
  if (status != XST_SUCCESS) {
    printf("I2C read: failed to send register 0x%x\r\n", reg);

    if (use_repeated_read)
      XIicPs_ClearOptions(&iicps, XIICPS_REP_START_OPTION);

    return;
  }

  while (XIicPs_BusIsBusy(&iicps)) { /* wait */ }

  // Read data
  status = XIicPs_MasterRecvPolled(&iicps, data, len, addr);
  if (status != XST_SUCCESS) {
    printf("I2C read failed from addr 0x%x reg 0x%x\r\n", addr, reg);
  }

  while (XIicPs_BusIsBusy(&iicps)) { /* wait */ }

  if (use_repeated_read)
    XIicPs_ClearOptions(&iicps, XIICPS_REP_START_OPTION);

}


//
// PS GPIO (MIO) Interface:
//

#define GPIOPS_DEVICE_ID XPAR_XGPIOPS_0_DEVICE_ID
static XGpioPs gpiops;
static int gpio_initialized = 0;

void gpio_platform_init(){
  // do nothing if already initialized
  if (gpio_initialized)
    return;

  printf("initializing PS GPIO interface (MIO)...");
  XGpioPs_Config *cfg = XGpioPs_LookupConfig(GPIOPS_DEVICE_ID);
  if (cfg == NULL) {
    printf("FAILED.\r\n");
    return;
  }
  int status = XGpioPs_CfgInitialize(&gpiops, cfg, cfg->BaseAddr);
  if (status != XST_SUCCESS) {
    printf("FAILED.\r\n");
    return;
  }
  printf("SUCCESS.\r\n");
  gpio_initialized = 1;
}

void gpio_platform_close(){
  // nothing to release, just mark as not initialized:
  gpio_initialized = 0;
}

hw_u32_t gpio_platform_status(){ return HW_SUCCESS; }

void gpio_platform_clear_status(){}

void gpio_platform_configure_pin(hw_u32_t pin, gpio_dir_t dir, hw_u32_t value){
  XGpioPs_SetDirectionPin(&gpiops, pin, (dir==GPIO_DIR_OUTPUT));
  XGpioPs_SetOutputEnablePin(&gpiops, pin, (dir==GPIO_DIR_OUTPUT));
  if (dir==GPIO_DIR_OUTPUT)
    XGpioPs_WritePin(&gpiops, pin, value);
}

void gpio_write_pin(hw_u32_t pin, hw_u32_t value){
  XGpioPs_WritePin(&gpiops, pin, value);
}

hw_u32_t gpio_read_pin(hw_u32_t pin){
  return XGpioPs_ReadPin(&gpiops, pin);
}

//
// BRAM Interface:  (Currently Unused and Untested)
//

void        bram_platform_init(){}

void        bram_platform_close(){}

hw_u32_t    bram_platform_status(){ return HW_SUCCESS; }

void        bram_platform_clear_status(){}

void        bram_platform_write(hw_u32_t addr, hw_u32_t value){
  Xil_Out32(AXIL_REGISTERS_BASEADDR+addr, value);
}

hw_u32_t    bram_platform_read(hw_u32_t addr){
  return Xil_In32(AXIL_REGISTERS_BASEADDR+addr);
}





static XTime G_START_TIME;
static XTime G_STOP_TIME;

void start_hw_timer(){
  XTime_GetTime(&G_START_TIME);
}
void stop_hw_timer(){
  XTime_GetTime(&G_STOP_TIME);
}

hw_u32_t hw_timer_elapsed_us(){
  XTime elapsed_us = ((G_STOP_TIME - G_START_TIME) * 1000000ULL) / COUNTS_PER_SECOND ;
  return (unsigned) elapsed_us;
}



char input_choice(void) {
  char c = 0, last = 0;
  print("Enter choice and press return: ");

  while (1) {
    c = inbyte();   // blocking read from UART

    if (c == '\r' || c == '\n') {
      return last;
    }

    // echo so user sees what they typed
    outbyte(c);
    last = c;
  }
}
