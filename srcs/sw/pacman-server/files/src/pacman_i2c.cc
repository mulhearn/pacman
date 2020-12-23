#ifndef pacman_i2c_cc
#define pacman_i2c_cc

#include <stdio.h>
#include <sys/ioctl.h>
#include <cstdint>
#include <linux/i2c-dev.h>
#include <unistd.h>
#include <fcntl.h>
#include <string.h>

#include "pacman_i2c.hh"

#define VERBOSE true

int i2c_open(char* dev) {
    // open i2c device
    int fh = open(dev, O_RDWR);
    if (fh < 0) {
        printf("Failed to open I2C device!\n");
    }
    return fh;
}

int i2c_addr(int fh, uint8_t addr) {
    // set i2c addr
    int resp = ioctl(fh,I2C_SLAVE,addr);
    if (resp < 0) {
        printf("Failed to communicate with slave 0x%04x",addr);
    }
    return resp;
}

int i2c_set(int fh, uint8_t addr, uint8_t val) {
    // write 1 byte to i2c device at addr
    if (i2c_addr(fh, addr) < 0) return -1;
    uint8_t buf[1];
    buf[0] = val;
    #if VERBOSE
    printf("i2c_set %d\n", buf[0]);
    #endif
    return write(fh,buf,1);
}

int i2c_set(int fh, uint8_t addr, uint8_t reg, uint32_t val, uint8_t bytes) {
    // write n bytes to register reg on i2c device at addr
    if (i2c_addr(fh, addr) < 0) return -1;
    uint8_t buf[bytes+1];
    buf[0] = reg;
    #if VERBOSE
    printf("i2c_set 0x%x", buf[0]);
    #endif
    for (uint8_t i_byte = 1; i_byte < bytes+1; i_byte++) {
        buf[i_byte] = (val >> (8 * (bytes-i_byte))) & 0x000000FF;
        #if VERBOSE
        printf(" 0x%x", buf[i_byte]);
        #endif
    }
    #if VERBOSE
    printf("\n");
    #endif
    return write(fh,buf,bytes+1);
}

int i2c_recv(int fh, uint8_t addr, uint8_t reg, uint8_t* buf, uint32_t nbytes) {
    // read nbytes from register reg on i2c device at addr into buf
    if (i2c_addr(fh, addr) < 0) return -1;
    if (i2c_set(fh,addr,reg) != 1) {
        printf("Failed to set register!\n");
        return -1;
    }
    memset(buf,0,nbytes);
    if (read(fh,buf,nbytes) != nbytes) {
        printf("Failed to read register!\n");
        return -1;
    }
    #if VERBOSE
    printf("i2c_recv addr x%02x reg x%02x read: ",addr,reg);
    for (int i = 0; i < nbytes; i++) printf("x%02x ",buf[i]);
    printf("\n");
    #endif
    return nbytes;
}

int i2c_recv(int fh, uint8_t addr, uint8_t* buf, uint32_t nbytes) {
    // read nbytes from i2c device at addr into buf
    if (i2c_addr(fh, addr) < 0) return -1;
    memset(buf,0,nbytes);
    if (read(fh,buf,nbytes) != nbytes) {
        printf("Failed to read register!\n");
        return -1;
    }
    #if VERBOSE
    printf("i2c_recv addr x%02x read: ",addr);
    for (int i = 0; i < nbytes; i++) printf("x%02x ",buf[i]);
    printf("\n");
    #endif
    return nbytes;
}

#define READ_BYTES 4
uint32_t i2c_read(int fh, uint32_t reg) {
    // read i2c devices as though they were a 32-bit register
    if (!((reg >= I2C_1_BASE_ADDR && reg < I2C_1_BASE_ADDR+I2C_1_BASE_LEN) ||
                    (reg >= I2C_2_BASE_ADDR && reg < I2C_2_BASE_ADDR+I2C_2_BASE_LEN))) {
        printf("Bad i2c address: 0x%08x\n", reg);
        return 0;
    }
    
    uint32_t i2c_dev_num = (reg < I2C_1_BASE_ADDR + I2C_1_BASE_LEN) && (reg >= I2C_1_BASE_ADDR) ? 1 : 2;
    uint32_t offset = i2c_dev_num == 1 ? (reg - I2C_1_BASE_ADDR) & 0x00000FF0 : (reg - I2C_2_BASE_ADDR) & 0x00000FF0;
    uint8_t i2c_addr = 0;
    uint8_t i2c_reg = i2c_dev_num == 1 ? (reg - I2C_1_BASE_ADDR) & 0x000000FF : (reg - I2C_2_BASE_ADDR) & 0x000000FF;
    uint8_t buf[READ_BYTES];
    bool use_reg = true;
    if (i2c_dev_num == 1) {
        if (offset == OFFSET_ADC_VDDA_1) {
            i2c_addr = ADDR_VDDA_TILE1;
            i2c_reg = i2c_reg & 0xF;
        }
        else if (offset == OFFSET_ADC_VDDD_1) {
            i2c_addr = ADDR_VDDD_TILE1;
            i2c_reg = i2c_reg & 0xF;            
        }
        else if (offset == OFFSET_ADC_VDDA_2) {
            i2c_addr = ADDR_VDDA_TILE2;
            i2c_reg = i2c_reg & 0xF;            
        }
        else if (offset == OFFSET_ADC_VDDD_2) {
            i2c_addr = ADDR_VDDD_TILE2;
            i2c_reg = i2c_reg & 0xF;            
        }
        else if (offset == OFFSET_ADC_VDDA_3) {
            i2c_addr = ADDR_VDDA_TILE3;
            i2c_reg = i2c_reg & 0xF;            
        }
        else if (offset == OFFSET_ADC_VDDD_3) {
            i2c_addr = ADDR_VDDD_TILE3;
            i2c_reg = i2c_reg & 0xF;            
        }
        else if (offset == OFFSET_ADC_VDDA_4) {
            i2c_addr = ADDR_VDDA_TILE4;
            i2c_reg = i2c_reg & 0xF;            
        }
        else if (offset == OFFSET_ADC_VDDD_4) {
            i2c_addr = ADDR_VDDD_TILE4;
            i2c_reg = i2c_reg & 0xF;            
        }
        else if (offset == OFFSET_ADC_VDDA_5) {
            i2c_addr = ADDR_VDDA_TILE5;
            i2c_reg = i2c_reg & 0xF;            
        }
        else if (offset == OFFSET_ADC_VDDD_5) {
            i2c_addr = ADDR_VDDD_TILE5;
            i2c_reg = i2c_reg & 0xF;            
        }
        else if (offset == OFFSET_ADC_VDDA_6) {
            i2c_addr = ADDR_VDDA_TILE6;
            i2c_reg = i2c_reg & 0xF;            
        }
        else if (offset == OFFSET_ADC_VDDD_6) {
            i2c_addr = ADDR_VDDD_TILE6;
            i2c_reg = i2c_reg & 0xF;            
        }
        else if (offset == OFFSET_ADC_VDDA_7) {
            i2c_addr = ADDR_VDDA_TILE7;
            i2c_reg = i2c_reg & 0xF;            
        }
        else if (offset == OFFSET_ADC_VDDD_7) {
            i2c_addr = ADDR_VDDD_TILE7;
            i2c_reg = i2c_reg & 0xF;            
        }
        else if (offset == OFFSET_ADC_VDDA_8) {
            i2c_addr = ADDR_VDDA_TILE8;
            i2c_reg = i2c_reg & 0xF;            
        }
        else if (offset == OFFSET_ADC_VDDD_8) {
            i2c_addr = ADDR_VDDD_TILE8;
            i2c_reg = i2c_reg & 0xF;            
        }
        else if ((offset & 0xF00) == OFFSET_V_DAC) {
            i2c_addr = ADDR_V_DAC;
        }
        else {
            printf("Access empty i2c-1 register: 0x%08x\n", reg);
            return 0;
        }
    }
    else {
        if ((offset & 0xF00) == OFFSET_TEST_MUX) {
            i2c_addr = ADDR_TEST_MUX;
        }
        else {
            printf("Access empty i2c-2 register: 0x%08x\n", reg);
            return 0;
        }        
    }

    uint32_t rv = 0;
    if (use_reg) {
        i2c_recv(fh, i2c_addr, i2c_reg, buf, READ_BYTES);
    } else {
        i2c_recv(fh, i2c_addr, buf, READ_BYTES);
    }
    for (int i = 0; i < READ_BYTES; i++) {
        rv = (rv << 8) + buf[i];
    }
    #if VERBOSE
    printf("Read %d\n", rv);
    #endif
    return rv;
}

uint32_t i2c_write(int fh, uint32_t reg, uint32_t val) {
    // write to i2c devices as through they were a 32-bit register
    if (!((reg >= I2C_1_BASE_ADDR && reg < I2C_1_BASE_ADDR+I2C_1_BASE_LEN) ||
                    (reg >= I2C_2_BASE_ADDR && reg < I2C_2_BASE_ADDR+I2C_2_BASE_LEN))) {
        printf("Bad i2c address: 0x%08x\n", reg);
        return 0;
    }    
    uint32_t i2c_dev_num = (reg < I2C_1_BASE_ADDR + I2C_1_BASE_LEN) && (reg >= I2C_1_BASE_ADDR) ? 1 : 2;
    uint32_t offset = i2c_dev_num == 1 ? (reg - I2C_1_BASE_ADDR) & 0x00000FF0 : (reg - I2C_2_BASE_ADDR) & 0x00000FF0;
    uint8_t i2c_addr = 0;
    uint8_t i2c_reg = i2c_dev_num == 1 ? (reg - I2C_1_BASE_ADDR) & 0x000000FF : (reg - I2C_2_BASE_ADDR) & 0x000000FF;
    uint8_t i2c_bytes = 2; // 2 data bytes, default
    bool use_reg = true;
    if (i2c_dev_num == 1) {
        if (offset == OFFSET_ADC_VDDA_1) {
            i2c_addr = ADDR_VDDA_TILE1;
            i2c_reg = i2c_reg & 0xF;            
        }
        else if (offset == OFFSET_ADC_VDDD_1) {
            i2c_addr = ADDR_VDDD_TILE1;
            i2c_reg = i2c_reg & 0xF;            
        }
        else if (offset == OFFSET_ADC_VDDA_2) {
            i2c_addr = ADDR_VDDA_TILE2;
            i2c_reg = i2c_reg & 0xF;            
        }
        else if (offset == OFFSET_ADC_VDDD_2) {
            i2c_addr = ADDR_VDDD_TILE2;
            i2c_reg = i2c_reg & 0xF;            
        }
        else if (offset == OFFSET_ADC_VDDA_3) {
            i2c_addr = ADDR_VDDA_TILE3;
            i2c_reg = i2c_reg & 0xF;            
        }
        else if (offset == OFFSET_ADC_VDDD_3) {
            i2c_addr = ADDR_VDDD_TILE3;
            i2c_reg = i2c_reg & 0xF;            
        }
        else if (offset == OFFSET_ADC_VDDA_4) {
            i2c_addr = ADDR_VDDA_TILE4;
            i2c_reg = i2c_reg & 0xF;            
        }
        else if (offset == OFFSET_ADC_VDDD_4) {
            i2c_addr = ADDR_VDDD_TILE4;
            i2c_reg = i2c_reg & 0xF;            
        }
        else if (offset == OFFSET_ADC_VDDA_5) {
            i2c_addr = ADDR_VDDA_TILE5;
            i2c_reg = i2c_reg & 0xF;            
        }
        else if (offset == OFFSET_ADC_VDDD_5) {
            i2c_addr = ADDR_VDDD_TILE5;
            i2c_reg = i2c_reg & 0xF;            
        }
        else if (offset == OFFSET_ADC_VDDA_6) {
            i2c_addr = ADDR_VDDA_TILE6;
            i2c_reg = i2c_reg & 0xF;            
        }
        else if (offset == OFFSET_ADC_VDDD_6) {
            i2c_addr = ADDR_VDDD_TILE6;
            i2c_reg = i2c_reg & 0xF;            
        }
        else if (offset == OFFSET_ADC_VDDA_7) {
            i2c_addr = ADDR_VDDA_TILE7;
            i2c_reg = i2c_reg & 0xF;            
        }
        else if (offset == OFFSET_ADC_VDDD_7) {
            i2c_addr = ADDR_VDDD_TILE7;
            i2c_reg = i2c_reg & 0xF;            
        }
        else if (offset == OFFSET_ADC_VDDA_8) {
            i2c_addr = ADDR_VDDA_TILE8;
            i2c_reg = i2c_reg & 0xF;            
        }
        else if (offset == OFFSET_ADC_VDDD_8) {
            i2c_addr = ADDR_VDDD_TILE8;
            i2c_reg = i2c_reg & 0xF;            
        }
        else if ((offset & 0xF00) == OFFSET_V_DAC) {
            i2c_addr = ADDR_V_DAC;
        }
        else {
            printf("Access empty i2c-1 register: 0x%08x\n", reg);
            return 0;
        }
    }
    else {
        if ((offset & 0xF00) == OFFSET_TEST_MUX) {
            i2c_addr = ADDR_TEST_MUX;
            i2c_bytes = 1; // 1 data byte
        }
        else {
            printf("Access empty i2c-2 register: 0x%08x\n", reg);
            return 0;
        }        
    }
    uint16_t i2c_val = (uint16_t)val;
    if (use_reg) {
        if (i2c_set(fh, i2c_addr, i2c_reg, i2c_val, i2c_bytes) != i2c_bytes+1) {
            printf("Could not write 0x%04x to reg 0x%02x on dev 0x%02x\n", i2c_val, i2c_reg, i2c_addr);
            return 0;            
        }
    } else {
        if (i2c_set(fh, i2c_addr, (uint8_t)(i2c_val & 0x00FF)) != 1) {
            printf("Could not write 0x%02x to dev 0x%02x\n", i2c_val, i2c_addr);
            return 0;
        }
    }
    return i2c_val;
}

#endif
