#ifndef pacman_i2c_cc
#define pacman_i2c_cc

#include <stdio.h>
#include <sys/ioctl.h>
#include <cstdint>
#include <linux/i2c-dev.h>
#include <unistd.h>
#include <fcntl.h>
#include <string.h>

#include "pacman-i2c.hh"

int i2c_open(char* dev) {
    int fh = open(dev, O_RDWR);
    if (fh < 0) {
        printf("Failed to open I2C device!\n");
    }
    return fh;
}

int i2c_addr(int fh, uint8_t addr) {
    int resp = ioctl(fh,I2C_SLAVE,addr);
    if (resp < 0) {
        printf("Failed to communicate with slave 0x%04x",addr);
    }
    return resp;
}

int i2c_send(int fh, uint8_t addr, uint8_t reg) {
    if (i2c_addr(fh, addr) < 0) return -1;
    uint8_t buf[1];
    buf[0] = reg;
    //printf("i2c_send %d\n", buf[0]);    
    return write(fh,buf,1);
}

int i2c_set(int fh, uint32_t addr, uint8_t reg, uint16_t val) {
    if (i2c_addr(fh, addr) < 0) return -1;
    uint8_t buf[3];
    buf[0] = reg;
    buf[1] = (val & 0xFF00) >> 8;
    buf[2] = val & 0x00FF;
    //printf("i2c_set %d %d %d\n", buf[0], buf[1], buf[2]);
    return write(fh,buf,3);
}

int i2c_recv(int fh, uint32_t addr, uint8_t reg, uint8_t* buf, uint32_t nbytes) {
    if (i2c_addr(fh, addr) < 0) return -1;
    if (i2c_send(fh,addr,reg) != 1) {
        printf("Failed to set register!\n");
        return -1;
    }
    memset(buf,0,nbytes);
    if (read(fh,buf,nbytes) != nbytes) {
        printf("Failed to read register!\n");
        return -1;
    }
    //printf("i2c_recv addr x%02x reg x%02x read: ",addr,reg);
    //for (int i = 0; i < nbytes; i++) printf("x%02x ",buf[i]);
    //printf("\n");
    return nbytes;
}

#define READ_BYTES 4
uint32_t i2c_read(int fh, uint32_t reg) {
    if (reg < I2C_BASE_ADDR || reg >= I2C_BASE_ADDR+I2C_BASE_LEN) {
        printf("Bad i2c address: 0x%08x\n", reg);
        return 0;
    }
    uint32_t offset = (reg - I2C_BASE_ADDR) & 0xFFFFFFF0;
    uint8_t i2c_addr = 0;
    uint8_t i2c_reg = (reg - I2C_BASE_ADDR) & 0x0000000F;
    uint8_t buf[READ_BYTES];
    if (offset == OFFSET_DAC_VDDD) {
        //printf("Read from VDDD DAC\n");
        i2c_addr = ADDR_DAC_VDDD;
    } else if (offset == OFFSET_DAC_VDDA) {
        //printf("Read from VDDA DAC\n");
        i2c_addr = ADDR_DAC_VDDA;
    } else if (offset == OFFSET_ADC_VPLUS) {
        //printf("Read from V+ ADC\n");
        i2c_addr = ADDR_ADC_VPLUS;
    } else if (offset == OFFSET_ADC_VDDD) {
        //printf("Read from VDDD ADC\n");
        i2c_addr = ADDR_ADC_VDDD;
    } else if (offset == OFFSET_ADC_VDDA) {
        //printf("Read from VDDA ADC\n");
        i2c_addr = ADDR_ADC_VDDA;
    } else {
        printf("Access empty i2c register: 0x%08x\n", reg);
        return 0;
    }
    uint32_t rv = 0;
    i2c_recv(fh, i2c_addr, i2c_reg, buf, READ_BYTES);
    for (int i = 0; i < READ_BYTES; i++) {
        rv = (rv << 8) + buf[i];
    }
    //printf("Read %d\n", rv);
    return rv;
}

uint32_t i2c_write(int fh, uint32_t reg, uint32_t val) {
    if (reg < I2C_BASE_ADDR || reg >= I2C_BASE_ADDR+I2C_BASE_LEN) {
        printf("Bad i2c address: 0x%08x\n", reg);
        return 0;
    }
    uint32_t offset = (reg - I2C_BASE_ADDR) & 0xFFFFFFF0;
    uint8_t i2c_reg = (reg - I2C_BASE_ADDR) & 0x0000000F;
    uint8_t i2c_addr = 0;
    uint16_t i2c_val = val & 0x0000FFFF;
    if (offset == OFFSET_DAC_VDDD) {
        i2c_addr = ADDR_DAC_VDDD;
    } else if (offset == OFFSET_DAC_VDDA) {
        i2c_addr = ADDR_DAC_VDDA;
    } else if (offset == OFFSET_ADC_VPLUS) {
        i2c_addr = ADDR_ADC_VPLUS;
    } else if (offset == OFFSET_ADC_VDDD) {
        i2c_addr = ADDR_ADC_VDDD;
    } else if (offset == OFFSET_ADC_VDDA) {
        i2c_addr = ADDR_ADC_VDDA;
    } else {
        printf("Access empty i2c register: 0x%08x\n",reg);
        return 0;
    }
    if (i2c_set(fh, i2c_addr, i2c_reg, i2c_val) != 3) {
        printf("Could not write 0x%04x to reg 0x%02x on dev 0x%02x\n", i2c_val, i2c_reg, i2c_addr);
        return 0;
    }
    return i2c_val;
}

#endif
