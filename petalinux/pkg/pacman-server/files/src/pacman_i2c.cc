#ifndef pacman_i2c_cc
#define pacman_i2c_cc

#include <stdio.h>
#include <sys/ioctl.h>
#include <cstdint>
#include <linux/i2c-dev-user.h>
#include <unistd.h>
#include <fcntl.h>
#include <string.h>

#include "pacman_i2c.hh"

#define I2C_DEBUG_TAG     0xABCD

// I2C Address Space - PACMAN Rev 5

//0001100   AD5677        16-chan. 16-bit DAC for VDDA setup                
//0001101   AD5677        16-chan. 16-bit DAC for VDDD setup                
//0010000   PAC1944       4-chan. Power Monitor VDDA+VDDD Tile1 + Tile2     
//0010001   PAC1944       4-chan. Power Monitor VDDA+VDDD Tile3 + Tile4     
//0010010   PAC1944       4-chan. Power Monitor VDDA+VDDD Tile5 + Tile6     
//0010011   PAC1944       4-chan. Power Monitor VDDA+VDDD Tile7 + Tile8     
//0010100   PAC1944       4-chan. Power Monitor VDDA+VDDD Tile9 + Tile10    
//0010101   PAC1944       4-chan. Power Monitor T3V0 + D3V6 + D3V3          
//1001100   MAX14661      16:2 Positive-Side MUX                            
//1001101   MAX14661      16:2 Negative-Side MUX                            
//1010000   SFP           SFP Module for Timing (primary addr.)             
//1010001   SFP           SFP Module for Timing (secondary addr.)           
//1100000   ADN2814       Clock & Data Recovery (CDR) for Timing  

#define ADDR_BAD          0b0001110  // Non-existent address
#define ADDR_DAC_VDDA     0b0001100  // AD5677 DAC for VDDA TILES 1-10
#define ADDR_DAC_VDDD     0b0001101  // AD5677 DAC for VDDD TILES 1-10
#define ADDR_ADC_TILES    0b0010000  // PAC1944 for Tiles 1+2 (ADDR+0), Tiles 3+4 (ADDR+1), ...
#define ADDR_ADC_BOARD    0b0010101  // PAC 1944 for Board Power and Temp
#define ADDR_MUX_P        0b1001100  // MAX14661 for TILES 1-10
#define ADDR_MUX_N        0b1001101  // MAX14661 for TILES 1-10

#define VERBOSE true

int i2c_open(const char* dev) {
    // open i2c device
    int fh = open(dev, O_RDWR);
    if (fh < 0) {
        printf("**ERROR** i2c_open:  Failed to open I2C device!\n");
    }
    return fh;
}

int i2c_addr(int fh, uint8_t addr) {
    // set i2c addr
    int resp = ioctl(fh,I2C_SLAVE,addr);
    if (resp < 0) {
        printf("**ERROR** i2c_addr:  Failed to communicate with I2C secondary 0x%04x",addr);
    }
    return resp;
}

int i2c_set(int fh, uint8_t addr, uint8_t val) {
    // write 1 byte to i2c device at addr
    if (i2c_addr(fh, addr) < 0) return -1;
    uint8_t buf[1];
    buf[0] = val;
    #if VERBOSE
    printf("i2c_set: set single byte 0x%x (%d)\n", buf[0], buf[0]);
    #endif
    return write(fh,buf,1);
}

int i2c_set(int fh, uint8_t addr, uint8_t reg, uint32_t val, uint8_t nbytes) {
    // write n nbytes to register reg on i2c device at addr
    if (i2c_addr(fh, addr) < 0) return -1;
    uint8_t buf[nbytes+1];
    buf[0] = reg;
    #if VERBOSE
    printf("i2c_set:  buffer:   0x%x", buf[0]);
    #endif
    for (uint8_t i_byte = 1; i_byte < nbytes+1; i_byte++) {
        buf[i_byte] = (val >> (8 * (nbytes-i_byte))) & 0x000000FF;
        #if VERBOSE
        printf(" 0x%x", buf[i_byte]);
        #endif
    }
    #if VERBOSE
    printf("\n");
    #endif
    return write(fh,buf,nbytes+1);
}


int i2c_smbus_recv(int fh, uint8_t addr, uint8_t reg, uint8_t* buf, uint32_t nbytes) {
    // perform smbus read byte data
    if (i2c_addr(fh, addr) < 0) return -1;
    int rv = i2c_smbus_read_byte_data(fh, reg);
    if (rv < 0) {
        printf("***ERROR*** i2c_smbus_recv:  Failed to rw register!\n");
        return rv;
    }
    buf[0] = (uint8_t)(rv);
    #if VERBOSE
    printf("i2c_smbus_recv addr 0x%02x reg 0x%02x read: ",addr,reg);
    for (int i = 0; i < nbytes; i++) printf("0x%02x ",buf[i]);
    printf("\n");
    #endif
    return 1;
}
        
int i2c_rw(int fh, uint8_t addr, uint8_t reg, uint8_t* buf, uint32_t nbytes) {
    // perform read from register with repeated start
    if (i2c_addr(fh, addr) < 0) return -1;
    char reg_char = (char)reg;
    struct i2c_msg msgs[2];
    msgs[0].addr = addr;
    msgs[0].flags = 0;
    msgs[0].len = 1;
    msgs[0].buf = &reg_char;

    msgs[1].addr = addr;
    msgs[1].flags = I2C_M_RD | I2C_M_NOSTART;
    msgs[1].len = nbytes;
    msgs[1].buf = (char*)buf;
    
    struct i2c_rdwr_ioctl_data data;
    data.msgs = msgs;
    data.nmsgs = 2;

    memset(buf,0,nbytes);
    if (ioctl(fh, I2C_RDWR, data) < 0) {
        printf("***ERROR*** i2c_rw Failed to rw register!\n");
        return -1;
    }
    #if VERBOSE
    printf("i2c_rw: addr 0x%02x reg 0x%02x read: ",addr,reg);
    for (int i = 0; i < nbytes; i++) printf("0x%02x ",buf[i]);
    printf("\n");
    #endif
    return nbytes;
}

int i2c_recv(int fh, uint8_t addr, uint8_t reg, uint8_t* buf, uint32_t nbytes) {
    // read nbytes from register reg on i2c device at addr into buf
    if (i2c_addr(fh, addr) < 0) return -1;
    if (i2c_set(fh,addr,reg) != 1) {
        printf("***ERROR*** i2c_recv:  Failed to set register!\n");
        return -1;
    }
    memset(buf,0,nbytes);
    if (read(fh,buf,nbytes) != nbytes) {
        printf("***ERROR*** i2c_recv:  Failed to read register!\n");      
        return -1;
    }
    #if VERBOSE
    printf("i2c_recv: addr x%02x reg x%02x read: ",addr,reg);
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
        printf("***ERROR*** i2c_recv:  Failed to read!\n");
        return -1;
    }
    #if VERBOSE
    printf("i2c_recv: addr x%02x read: ",addr);
    for (int i = 0; i < nbytes; i++) printf("x%02x ",buf[i]);
    printf("\n");
    #endif
    return nbytes;
}

uint32_t i2c_scratch[0xF];

uint32_t i2c_expert[0xF];

uint32_t i2c_direct_read(int fh, uint32_t lower){
  uint32_t mode   = i2c_expert[0];
  uint32_t enable = i2c_expert[1];
  uint32_t addr   = i2c_expert[2];
  uint32_t reg    = i2c_expert[3];
  uint32_t nbytes = i2c_expert[4];
  #if VERBOSE
  printf("i2c_direct_read:  mode: %d enable: %d\n", mode, enable);
  printf("i2c_direct_read:  hw addr: 0x%x reg: 0x%x nbytes: %d\n", addr, reg, nbytes);
  #endif
  if (enable!=1) return 0;
  if (nbytes>4) return 0;
  uint8_t buf[nbytes];
  // Can enable other versions as needed via mode...
  if (i2c_recv(fh, addr, reg, buf, nbytes)!=nbytes){
    printf("**ERROR** i2c_direct_read:  Failed to direct read I2C register.\n");
    return 0;
  }
  uint32_t val = 0;
  for (int i=0 ; i< nbytes; i++){
    val = (val<<8) | buf[i];
  }  
  return val;
}

uint32_t i2c_direct_write(int fh, uint32_t lower, uint32_t val){
  uint32_t mode   = i2c_expert[0];
  uint32_t enable = i2c_expert[1];
  uint32_t addr   = i2c_expert[2];
  uint32_t reg    = i2c_expert[3];
  uint32_t nbytes  = i2c_expert[4];
  #if VERBOSE
  printf("i2c_direct_write:  value:  0x%x\n", val);
  printf("i2c_direct_write:  mode: %d enable: %d\n", mode, enable);
  printf("i2c_direct_write:  hw addr: 0x%x reg: 0x%x nbytes: %d\n", addr, reg, nbytes);
  #endif
  if (enable!=1) return 0;
  if (nbytes>4) return 0;
  uint8_t buf[nbytes];
  int ret = i2c_set(fh, addr, reg, val, nbytes);
  if (ret != nbytes+1){
    printf("**ERROR** i2c_direct_write: i2c_set returned %d when expecting %d\n", ret, nbytes+1);
    return 0;
  }
  return 1;
}

uint32_t i2c_set_vdda(int fh, uint32_t lower, uint32_t val){  
  uint8_t reg    = 0x30 + lower;
  const uint8_t nbytes = 2;
  if (lower > 0xa)
    return 0;
  #if VERBOSE
  printf("i2c_set_vdda:  tile: %d value: 0x%x\n", lower+1, val);
  printf("i2c_set_vdda:  reg: 0x%x\n", reg);
  #endif
  int ret = i2c_set(fh, ADDR_DAC_VDDA, reg, val, nbytes);
  
  if (ret != nbytes+1){
    printf("**ERROR** i2c_set_vdda: i2c_set returned %d when expecting %d\n", ret, nbytes+1);
    return 0;
  }
  return 1;
}

uint32_t i2c_set_vddd(int fh, uint32_t lower, uint32_t val){  
  uint8_t reg    = 0x30 + lower;
  const uint8_t nbytes = 2;
  if (lower > 0xa)
    return 0; 
  #if VERBOSE
  printf("i2c_set_vddd:  tile: %d value: 0x%x\n", lower+1, val);
  printf("i2c_set_vddd:  reg: 0x%x\n", reg);
  #endif
  int ret = i2c_set(fh, ADDR_DAC_VDDD, reg, val, nbytes);
  
  if (ret != nbytes+1){
    printf("**ERROR** i2c_set_vddd: i2c_set returned %d when expecting %d\n", ret, nbytes+1);
    return 0;
  }
  return 1;
}

uint32_t i2c_mon_vdda(int fh, uint32_t lower){
  const int full_scale = 9000; // 9 V = 9000 mV full scale
  const uint8_t addr   = 0x10+lower/2;
  const uint8_t reg    = 0x7 + 0x2*(lower%2);

  if (lower > 0xa) 
    return 0;
  
  const uint8_t nbytes = 2;
  uint8_t buf[nbytes];  

  int status = 0;
  // set config registers for single shot mode:
  status |= (i2c_set(fh, addr, 1, 0x8500, nbytes) != (nbytes+1));
  // send refresh to start conversions:
  status |= (i2c_set(fh, addr, 0) != 1);
  usleep(5000);
  // send second refresh to move most recent conversions into output registers:
  status |= (i2c_set(fh, addr, 0) != 1);
  usleep(5000);
  // read requested value:
  status |= (i2c_set(fh, addr, reg) != 1);
  status |= (i2c_recv(fh, addr, reg, buf, nbytes)!=nbytes);

  if (status){
    printf("**ERROR** i2c_mon_vdda:  I2C error.\n");
    return 0;
  }
  
  uint32_t val = 0;
  for (int i=0 ; i< nbytes; i++){
    val = (val<<8) | buf[i];
  }  
  return full_scale*val/0xFFFF;
}

uint32_t i2c_mon_vddd(int fh, uint32_t lower){
  const int full_scale = 9000; // 9 V = 9000 mV full scale
  const uint8_t addr   = 0x10+lower/2;
  const uint8_t reg    = 0x8 + 0x2*(lower%2);

  if (lower > 0xa) 
    return 0;

  const uint8_t nbytes = 2;
  uint8_t buf[nbytes];  

  int status = 0;
  // set config registers for single shot mode:
  status |= (i2c_set(fh, addr, 1, 0x8500, nbytes) != (nbytes+1));
  // send refresh to start conversions:
  status |= (i2c_set(fh, addr, 0) != 1);
  usleep(5000);
  // send second refresh to move most recent conversions into output registers:
  status |= (i2c_set(fh, addr, 0) != 1);
  usleep(5000);
  // read requested value:
  status |= (i2c_set(fh, addr, reg) != 1);
  status |= (i2c_recv(fh, addr, reg, buf, nbytes)!=nbytes);

  if (status){
    printf("**ERROR** i2c_mon_vddd:  I2C error.\n");
    return 0;
  }
  
  uint32_t val = 0;
  for (int i=0 ; i< nbytes; i++){
    val = (val<<8) | buf[i];
  }  
  return full_scale*val/0xFFFF;
}

uint32_t i2c_mon_idda(int fh, uint32_t lower){
  const int full_scale = 20000; // 20 A = 20000 mA full scale
  const uint8_t addr   = 0x10+lower/2;
  const uint8_t reg    = 0xB + 0x2*(lower%2);

  if (lower > 0xa) 
    return 0;
  
  const uint8_t nbytes = 2;
  uint8_t buf[nbytes];  

  int status = 0;
  // set config registers for single shot mode:
  status |= (i2c_set(fh, addr, 1, 0x8500, nbytes) != (nbytes+1));
  // send refresh to start conversions:
  status |= (i2c_set(fh, addr, 0) != 1);
  usleep(5000);
  // send second refresh to move most recent conversions into output registers:
  status |= (i2c_set(fh, addr, 0) != 1);
  usleep(5000);
  // read requested value:
  status |= (i2c_set(fh, addr, reg) != 1);
  status |= (i2c_recv(fh, addr, reg, buf, nbytes)!=nbytes);

  if (status){
    printf("**ERROR** i2c_mon_idda:  I2C error.\n");
    return 0;
  }
  
  uint32_t val = 0;
  for (int i=0 ; i< nbytes; i++){
    val = (val<<8) | buf[i];
  }  
  return full_scale*val/0xFFFF;

  
}

uint32_t i2c_mon_iddd(int fh, uint32_t lower){
  const int full_scale = 20000; // 20 A = 20000 mA full scale
  const uint8_t addr   = 0x10+lower/2;
  const uint8_t reg    = 0xC + 0x2*(lower%2);

  if (lower > 0xa) 
    return 0;
  
  const uint8_t nbytes = 2;
  uint8_t buf[nbytes];  

  int status = 0;
  // set config registers for single shot mode:
  status |= (i2c_set(fh, addr, 1, 0x8500, nbytes) != (nbytes+1));
  // send refresh to start conversions:
  status |= (i2c_set(fh, addr, 0) != 1);
  usleep(5000);
  // send second refresh to move most recent conversions into output registers:
  status |= (i2c_set(fh, addr, 0) != 1);
  usleep(5000);
  // read requested value:
  status |= (i2c_set(fh, addr, reg) != 1);
  status |= (i2c_recv(fh, addr, reg, buf, nbytes)!=nbytes);

  if (status){
    printf("**ERROR** i2c_mon_iddd:  I2C error.\n");
    return 0;
  }
  
  uint32_t val = 0;
  for (int i=0 ; i< nbytes; i++){
    val = (val<<8) | buf[i];
  }  
  return full_scale*val/0xFFFF;
  
}

uint32_t i2c_version(int fh, uint32_t lower){  
  if (lower == 0) return I2C_MAJOR_VERSION;
  if (lower == 1) return I2C_MINOR_VERSION;
  if (lower == 2) return I2C_DEBUG_TAG;
}
uint32_t get_mux_code(uint32_t val){
  uint32_t switch_disabled = 0x10;
  if (val == 0)
    return switch_disabled; // disable switch
  if ((val >= 1) && (val <= 10))
    return val - 1; // set to TILE val
  if (val == 11)
    return 0xb; // set to DAC
  printf("get_mux_code:  unsupported value:  0x%x (%d)\n", val, val);
  return switch_disabled;
}

uint32_t i2c_set_muxa(int fh, uint32_t lower, uint32_t val){  
  const uint8_t reg    = 0x14;
  const uint8_t nbytes = 1;

  uint32_t code = get_mux_code(val);

  printf("i2c_set_muxa:  value: %d  code: %d \n", val, code);
  int rep, status = 1;
  rep = i2c_set(fh, ADDR_MUX_P, reg, code, nbytes);  
  status *= (rep == nbytes+1);
  rep = i2c_set(fh, ADDR_MUX_N, reg, code, nbytes);  
  status *= (rep == nbytes+1);
  if (status!=1)
    printf("**ERROR** i2c_set_muxa:  i2c_set was not successful\n");
  return status;
}

uint32_t i2c_set_muxb(int fh, uint32_t lower, uint32_t val){
  const uint8_t reg    = 0x15;
  const uint8_t nbytes = 1;
  
  uint32_t code = get_mux_code(val);

  printf("i2c_set_muxb:  value: %d  code: %d \n", val, code);
  int rep, status = 1;
  rep = i2c_set(fh, ADDR_MUX_P, reg, code, nbytes);  
  status *= (rep == nbytes+1);
  rep = i2c_set(fh, ADDR_MUX_N, reg, code, nbytes);  
  status *= (rep == nbytes+1);
  if (status!=1)
    printf("**ERROR** i2c_set_muxb:  i2c_set was not successful\n");
  return status;
}

uint32_t i2c_read(int fh, uint32_t vreg_offset) {
  uint32_t upper = 0xFF0 & vreg_offset;
  uint32_t lower = 0x00F & vreg_offset;
  uint32_t val = 0;
  switch (upper){
  case I2C_VREG_OFFSET_SET_VDDA:
    return 0;
  case I2C_VREG_OFFSET_SET_VDDD:
    return 0;
  case I2C_VREG_OFFSET_MON_VDDA:
    return i2c_mon_vdda(fh, lower);
  case I2C_VREG_OFFSET_MON_VDDD:
    return i2c_mon_vddd(fh, lower);
  case I2C_VREG_OFFSET_MON_IDDA:
    return i2c_mon_idda(fh, lower);         
  case I2C_VREG_OFFSET_MON_IDDD:
    return i2c_mon_iddd(fh, lower);     
  case I2C_VREG_OFFSET_SET_MUXA:
    return 0;
  case I2C_VREG_OFFSET_SET_MUXB:
    return 0;
  case I2C_VREG_OFFSET_SCRATCH:
    val = i2c_scratch[lower];
    printf("i2c_read:  read  value 0x%x from scratch register %d\n", val, lower);
    return val;
  case I2C_VREG_OFFSET_EXPERT:    
    return i2c_expert[lower];
  case I2C_VREG_OFFSET_DIRECT:
    return i2c_direct_read(fh, lower);
  case I2C_VREG_OFFSET_I2C_VER:
    return i2c_version(fh, lower);    
  default:
    printf("i2c_read:  failed to read unimplemented register at offset:  0x%x\n", vreg_offset);
    break;
  }  
  return 0;
}


uint32_t i2c_devel(int fh, uint32_t lower, uint32_t val) {
  printf("i2c_devel:  ***Welcome to PACMAN I2C development code***\n");
  printf("i2c_devel:  lower = 0x%x, val = 0x%x\n", lower, val);
  // ...insert development code here...
  return 0;
}

uint32_t i2c_write(int fh, uint32_t vreg_offset, uint32_t val) {
  uint32_t upper = 0xFF0 & vreg_offset;
  uint32_t lower = 0x00F & vreg_offset;

  switch (upper){
  case I2C_VREG_OFFSET_SET_VDDA:
    return i2c_set_vdda(fh, lower, val);
  case I2C_VREG_OFFSET_SET_VDDD:
    return i2c_set_vddd(fh, lower, val);
  case I2C_VREG_OFFSET_MON_VDDA:
    return 0;
  case I2C_VREG_OFFSET_MON_VDDD:
    return 0;
  case I2C_VREG_OFFSET_MON_IDDA:
    return 0;        
  case I2C_VREG_OFFSET_MON_IDDD:
    return 0;    
  case I2C_VREG_OFFSET_SET_MUXA:
    return i2c_set_muxa(fh, lower, val);
  case I2C_VREG_OFFSET_SET_MUXB:
    return i2c_set_muxb(fh, lower, val);
  case I2C_VREG_OFFSET_SCRATCH:
    printf("i2c_write:  write  value 0x%x to scratch register %d\n", val, lower);
    i2c_scratch[lower]=val;
    return val;
  case I2C_VREG_OFFSET_EXPERT:
    i2c_expert[lower]=val;
    return val;
  case I2C_VREG_OFFSET_DIRECT:
    return i2c_direct_write(fh, lower, val);        
  case I2C_VREG_OFFSET_DEVEL:
    return i2c_devel(fh, lower, val);        
  default:
    printf("i2c_write:  failed to write unimplemented register at offset:  0x%x\n", vreg_offset);
    break;
  }  
  return 0;
}


#endif
