#include <stdio.h>
#include <fcntl.h>
#include <time.h>
#include <unistd.h>
#include <sys/mman.h>
#include <linux/i2c.h>
#include <linux/i2c-dev.h>
#include <sys/ioctl.h>
#include <string.h>
#include <stdbool.h>
#include "hw_access.h"
#include "assert.h"


// move to header?
#define DMA_REGISTERS_LEN      0x00010000
#define AXIL_REGISTERS_LEN     0x00010000

//
// AXI-Lite Registers:
//

static volatile uint32_t * G_AXIL  = NULL;

void axil_platform_init(){
  // do nothing if already initialized:
  if (G_AXIL != NULL)
    return;

  axil_platform_clear_status();

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

void axil_platform_close(){ }

hw_u32_t axil_platform_status(){ return HW_SUCCESS; }

void axil_platform_clear_status() {}

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

void dma_platform_init(){
  // do nothing if already initialized:
  if (G_DMA != NULL)
    return;

  dma_platform_clear_status();


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

void dma_platform_close(){
}

hw_u32_t dma_platform_status(){ return HW_SUCCESS; }

void dma_platform_clear_status() {}

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

void dma_platform_init_buffer(hw_addr_t baseaddr, hw_addr_t size){
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
    assert(addr >= G_BUF_BASEADDR);
    hw_addr_t offset = addr - G_BUF_BASEADDR;
    assert(offset < G_BUF_SIZE);
    return &G_BUF[offset>>2];
}

hw_ptr_t dma_safe_buffer(hw_addr_t addr, hw_addr_t size){
  assert(addr >= G_BUF_BASEADDR);
  hw_addr_t offset = addr - G_BUF_BASEADDR;
  assert(size <= G_BUF_SIZE);
  assert(offset <= G_BUF_SIZE - size);
  return &G_BUF[offset>>2];
}

//
// I2C Interface:
//

#define I2C_DEV "/dev/i2c-0"
#define I2C_DEBUG false

static int G_IIC_FH = -1;
static hw_u32_t G_IIC_STATUS = 0;

void iic_platform_init() {
  // do nothing if already initialized:
  if (G_IIC_FH >= 0) {
    return;
  }

  iic_platform_clear_status();

  G_IIC_FH = open(I2C_DEV, O_RDWR);
  if (G_IIC_FH < 0) {
    printf("**ERROR** Failed to open I2C device");
    G_IIC_STATUS |= 2;
    return;
  }
}


void iic_platform_close() {
}

// report the status of the AXI-LITE interface:
hw_u32_t iic_platform_status(){
  return G_IIC_STATUS;
}

// report the status of the AXI-LITE interface:
void iic_platform_clear_status(){
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
void iic_read_prev(hw_u8_t addr, hw_u8_t reg, hw_u8_t *data, hw_u32_t len) {
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

void iic_read(hw_u8_t addr, hw_u8_t reg, hw_u8_t *data, hw_u32_t len, bool use_repeated_read)
{
    if (G_IIC_FH < 0) {
        printf("**ERROR** iic_read: I2C not initialized\n");
        G_IIC_STATUS |= 1;
        return;
    }

    if (!use_repeated_read) {
        // fallback: simple write() + read()
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
        return;
    }

    // repeated read via I2C_RDWR
    struct i2c_rdwr_ioctl_data msgset;
    struct i2c_msg msgs[2];

    msgs[0].addr  = addr;
    msgs[0].flags = 0;          // write
    msgs[0].len   = 1;
    msgs[0].buf   = &reg;

    msgs[1].addr  = addr;
    msgs[1].flags = I2C_M_RD;   // read
    msgs[1].len   = len;
    msgs[1].buf   = data;

    msgset.msgs  = msgs;
    msgset.nmsgs = 2;

    if (ioctl(G_IIC_FH, I2C_RDWR, &msgset) < 0) {
        printf("**ERROR** iic_read: repeated read failed from 0x%02x reg 0x%02x\n", addr, reg);
        G_IIC_STATUS |= 8;
    }

#if I2C_DEBUG
    printf("iic_read: addr 0x%02x reg 0x%02x data:", addr, reg);
    for (hw_u32_t i = 0; i < len; i++) printf(" 0x%02x", data[i]);
    printf("\n");
#endif
}



//
// GPIO
//

// Status flags
static hw_u32_t G_MIO_STATUS = 0;

// First MIO pin index (platform-dependent)
static const hw_u32_t G_MIO_FIRST_PIN = 906;

void gpio_platform_init() {
    G_MIO_STATUS = 0;
    // No extra initialization needed for sysfs GPIO
}

void gpio_platform_close() {
    // No cleanup needed for sysfs GPIO
}

hw_u32_t gpio_platform_status() {
    return G_MIO_STATUS;
}

void gpio_platform_clear_status() {
    G_MIO_STATUS = 0;
}

void gpio_platform_configure_pin(hw_u32_t pin, gpio_dir_t dir, hw_u32_t value) {
    char buf[64];
    int fd;

    // 1. Export the pin (ignore errors if already exported)
    fd = open("/sys/class/gpio/export", O_WRONLY);
    if (fd >= 0) {
        snprintf(buf, sizeof(buf), "%u", G_MIO_FIRST_PIN + pin);
	ssize_t n;
        n=write(fd, buf, strlen(buf));
	(void) n;
        close(fd);
    }

    // 2. Set direction
    snprintf(buf, sizeof(buf), "/sys/class/gpio/gpio%u/direction", G_MIO_FIRST_PIN + pin);
    fd = open(buf, O_WRONLY);
    if (fd < 0) {
        G_MIO_STATUS |= 1;  // direction open failed
        return;
    }
    const char *dir_str = (dir == GPIO_DIR_OUTPUT) ? "out" : "in";
    if (write(fd, dir_str, strlen(dir_str)) != (ssize_t)strlen(dir_str)) {
        G_MIO_STATUS |= 2;  // direction write failed
        close(fd);
        return;
    }
    close(fd);

    // 3. Set initial value if output
    if (dir == GPIO_DIR_OUTPUT) {
        snprintf(buf, sizeof(buf), "/sys/class/gpio/gpio%u/value", G_MIO_FIRST_PIN + pin);
        fd = open(buf, O_WRONLY);
        if (fd < 0) {
            G_MIO_STATUS |= 4;  // value open failed
            return;
        }
        char vbuf[2];
        snprintf(vbuf, sizeof(vbuf), "%u", value ? 1 : 0);
        if (write(fd, vbuf, 1) != 1) {
            G_MIO_STATUS |= 8;  // value write failed
        }
        close(fd);
    }
}

void gpio_write_pin(hw_u32_t pin, hw_u32_t value) {
    char fbuf[64];
    snprintf(fbuf, sizeof(fbuf), "/sys/class/gpio/gpio%u/value", G_MIO_FIRST_PIN + pin);
    int fd = open(fbuf, O_WRONLY);
    if (fd < 0) {
        G_MIO_STATUS |= 16;
        return;
    }
    char vbuf[2];
    snprintf(vbuf, sizeof(vbuf), "%u", value);
    if (write(fd, vbuf, 1) != 1) {
        G_MIO_STATUS |= 32;
    }
    close(fd);
}

hw_u32_t gpio_read_pin(hw_u32_t pin) {
    char fbuf[64];
    snprintf(fbuf, sizeof(fbuf), "/sys/class/gpio/gpio%u/value", G_MIO_FIRST_PIN + pin);
    int fd = open(fbuf, O_RDONLY);
    if (fd < 0) {
        G_MIO_STATUS |= 64;
        return 0;
    }
    char vbuf[2];
    if (read(fd, vbuf, 1) != 1) {
        G_MIO_STATUS |= 128;
        close(fd);
        return 0;
    }
    close(fd);
    return (vbuf[0] == '0') ? 0 : 1;
}

//
// BRAM:
//

// PACMAN AXI-Lite interface to BRAM
#define PACMAN_BRAM_ADDR 0x42000000
#define PACMAN_BRAM_HIGH 0x42001FFF
#define PACMAN_BRAM_LEN  (PACMAN_BRAM_HIGH - PACMAN_BRAM_ADDR + 1)

static uint32_t G_BRAM_STATUS = 0;
static volatile uint32_t *G_BRAM = NULL;
static int g_mem_fd = -1;

uint32_t bram_platform_status() {
    return G_BRAM_STATUS;
}

void bram_platform_clear_status() {
    G_BRAM_STATUS = 0;
}

void bram_platform_init() {
    if (G_BRAM != NULL) return; // already initialized

    G_BRAM_STATUS = 0;

    g_mem_fd = open("/dev/mem", O_RDWR | O_SYNC);
    if (g_mem_fd < 0) {
        perror("ERROR: opening /dev/mem for BRAM");
        G_BRAM_STATUS |= 1;
        return;
    }

    G_BRAM = (volatile uint32_t *)mmap(NULL, PACMAN_BRAM_LEN,
                                       PROT_READ | PROT_WRITE,
                                       MAP_SHARED, g_mem_fd,
                                       PACMAN_BRAM_ADDR);
    if (G_BRAM == MAP_FAILED) {
        perror("ERROR: mmap BRAM");
        G_BRAM = NULL;
        G_BRAM_STATUS |= 2;
        close(g_mem_fd);
        g_mem_fd = -1;
        return;
    }

    printf("INFO: BRAM platform initialized (0x%X bytes at 0x%X)\n", PACMAN_BRAM_LEN, PACMAN_BRAM_ADDR);
}

void bram_platform_close() {
    if (G_BRAM != NULL) {
        munmap((void *)G_BRAM, PACMAN_BRAM_LEN);
        G_BRAM = NULL;
    }
    if (g_mem_fd >= 0) {
        close(g_mem_fd);
        g_mem_fd = -1;
    }
}

void bram_platform_write(uint32_t addr, uint32_t value) {
    if (!G_BRAM || addr > PACMAN_BRAM_LEN) {
        G_BRAM_STATUS |= 4; // invalid write
        return;
    }
    G_BRAM[addr >> 2] = value;
}

uint32_t bram_platform_read(uint32_t addr) {
    if (!G_BRAM || addr > PACMAN_BRAM_LEN) {
        G_BRAM_STATUS |= 8; // invalid read
        return 0xDEADBEEF;
    }
    return G_BRAM[addr >> 2];
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

char input_choice(){
  char c = 0, last = 0;

  printf("Enter choice and press return: ");
  fflush(stdout);

  while (1) {
    c = getchar();
    if (c == '\n' || c == '\r')
      return last;
    last = c;
    usleep(1000);
  }
}
