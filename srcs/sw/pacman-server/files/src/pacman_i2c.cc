#ifndef pacman_i2c_cc
#define pacman_i2c_cc

#include <stdio.h>
#include <sys/ioctl.h>
#include <cstdint>
extern "C" {
#include <linux/i2c-dev.h>
#include <i2c/smbus.h>
}
#include <unistd.h>
#include <fcntl.h>
#include <string.h>

#include "pacman_i2c.hh"

// I2C Addresses in I2C hardware address space:
#define ADDR_BAD          0b0001101  // Non-existent address
#define ADDR_DAC          0b0001100  // AD5677R for TILES 1-8
// One VDDA ADC per tile, incrementing address one per tile:
#define ADDR_ADC_VDDA_START 0b1000000  // INA220 for TILE 1
#define ADDR_ADC_VDDA_TILES 1
// Two VDDD ADC per tile, incrementing address one per two tiles:
#define ADDR_ADC_VDDD_START 0b1001000  // ADS1219 for TILES 1+2

#define ADDR_ADC_VDDD_TILES 2
#define ADDR_MUX          0b1001100  // MAX14661 for TILES 1-8

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
    struct i2c_msg msgs[2];
    msgs[0].addr = addr;
    msgs[0].flags = 0;
    msgs[0].len = 1;
    msgs[0].buf = &reg;

    msgs[1].addr = addr;
    msgs[1].flags = I2C_M_RD | I2C_M_NOSTART;
    msgs[1].len = nbytes;
    msgs[1].buf = buf;

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
  uint8_t addr   = 0x0C;
  uint8_t reg    = 0x30 + 2*lower;
  uint8_t nbytes = 2;
  #if VERBOSE
  printf("i2c_set_vdda:  tile: %d value: 0x%x\n", lower+1, val);
  printf("i2c_set_vdda:  addr: 0x%x reg: 0x%x\n", addr, reg);
  #endif
  int ret = i2c_set(fh, addr, reg, val, nbytes);

  if (ret != nbytes+1){
    printf("**ERROR** i2c_set_vdda: i2c_set returned %d when expecting %d\n", ret, nbytes+1);
    return 0;
  }
  return 1;
}

uint32_t i2c_set_vddd(int fh, uint32_t lower, uint32_t val){
  uint8_t addr   = 0x0C;
  uint8_t reg    = 0x31 + 2*lower;
  uint8_t nbytes = 2;
  #if VERBOSE
  printf("i2c_set_vddd:  tile: %d value: 0x%x\n", lower+1, val);
  printf("i2c_set_vddd:  addr: 0x%x reg: 0x%x\n", addr, reg);
  #endif
  int ret = i2c_set(fh, addr, reg, val, nbytes);

  if (ret != nbytes+1){
    printf("**ERROR** i2c_set_vddd: i2c_set returned %d when expecting %d\n", ret, nbytes+1);
    return 0;
  }
  return 1;
}

uint32_t i2c_mon_vdda(int fh, uint32_t lower){
  uint8_t addr   = 0x40 + lower;
  uint8_t reg    = 0x2;
  uint8_t nbytes = 2;
  #if VERBOSE
  printf("i2c_mon_vdda:  tile: %d\n", lower+1);
  printf("i2c_mon_vdda:  addr: 0x%x reg: 0x%x\n", addr, reg);
  #endif
  uint8_t buf[nbytes];
  if (i2c_recv(fh, addr, reg, buf, nbytes)!=nbytes){
    printf("**ERROR** i2c_mon_vdda:  Failed to read I2C register.\n");
    return 0;
  }
  uint32_t val = 0;
  for (int i=0 ; i< nbytes; i++){
    val = (val<<8) | buf[i];
  }

  uint32_t mv = 4*(val >> 3);
  printf("i2c_mon_vdda:  mv: %d\n", mv);
  return mv;
}

uint32_t i2c_mon_vddd(int fh, uint32_t lower){
  const uint8_t addr   = 0x48+lower/2;
  const uint8_t mux    = 0x80 + 0x40*(lower%2);
  const uint8_t reset  = 0x06;
  const uint8_t config = 0x40;
  const uint8_t start  = 0x08;
  const uint8_t ready  = 0x24;
  const uint8_t rdat   = 0x10;
  const uint8_t nbytes = 3;
  #if VERBOSE
  printf("i2c_mon_vddd:  tile: %d\n", lower+1);
  printf("i2c_mon_vddd:  addr: 0x%x mux: %x\n", addr, mux);
  #endif

  int fail = 0;
  fail |= (i2c_set(fh,addr,reset) != 1);
  fail |= (i2c_set(fh,addr,config,mux,1) != 2);
  fail |= (i2c_set(fh,addr,start) != 1);

  uint8_t buf[4];
  uint8_t rbit;
  fail |= (i2c_set(fh,addr,ready) != 1);
  fail |= (i2c_recv(fh,addr, ready, buf, 1)!=1);
  rbit = (buf[0]>>7)&1;
  printf("i2c_mon_vddd:  ready bit:  %d\n", rbit);

  // there are better solutions... note change in ready
  sleep(1);

  fail |= (i2c_set(fh,addr,ready) != 1);
  fail |= (i2c_recv(fh,addr, ready, buf, 1)!=1);
  rbit = (buf[0]>>7)&1;
  printf("i2c_mon_vddd:  ready bit:  %d\n", rbit);

  fail |= (i2c_set(fh,addr,rdat) != 1);
  fail |= (i2c_recv(fh,addr, rdat, buf, nbytes)!=nbytes);

  if (fail){
    printf("**ERROR** i2c_mon_vddd:  I2C failure.\n");
    return 0;
  }
  uint32_t val = 0;
  for (int i=0 ; i< nbytes; i++){
    val = (val<<8) | buf[i];
  }
  printf("i2c_mon_vddd:  value:  0x%x (%d)\n", val, val);
  uint32_t mv = val * 0.000476837;
  printf("i2c_mon_vddd:  mv:  %d\n", mv);
  return mv;
}

uint32_t i2c_mon_idda(int fh, uint32_t lower){
  uint8_t addr   = 0x40 + lower;
  uint8_t reg    = 0x1;
  uint8_t nbytes = 2;
  #if VERBOSE
  printf("i2c_mon_idda:  tile: %d\n", lower+1);
  printf("i2c_mon_idda:  addr: 0x%x reg: 0x%x\n", addr, reg);
  #endif
  uint8_t buf[nbytes];
  if (i2c_recv(fh, addr, reg, buf, nbytes)!=nbytes){
    printf("**ERROR** i2c_mon_idda:  Failed to read I2C register.\n");
    return 0;
  }
  uint32_t val = 0;
  for (int i=0 ; i< nbytes; i++){
    val = (val<<8) | buf[i];
  }
  return val;
}

uint32_t i2c_mon_iddd(int fh, uint32_t lower){
  const uint8_t addr   = 0x48+lower/2;
  const uint8_t mux    = 0x60 + 0x40*(lower%2);
  const uint8_t reset  = 0x06;
  const uint8_t config = 0x40;
  const uint8_t start  = 0x08;
  const uint8_t ready  = 0x24;
  const uint8_t rdat   = 0x10;
  const uint8_t nbytes = 3;
  #if VERBOSE
  printf("i2c_mon_iddd:  tile: %d\n", lower+1);
  printf("i2c_mon_iddd:  addr: 0x%x mux: %x\n", addr, mux);
  #endif

  int fail = 0;
  fail |= (i2c_set(fh,addr,reset) != 1);
  fail |= (i2c_set(fh,addr,config,mux,1) != 2);
  fail |= (i2c_set(fh,addr,start) != 1);

  uint8_t buf[4];
  uint8_t rbit;
  fail |= (i2c_set(fh,addr,ready) != 1);
  fail |= (i2c_recv(fh,addr, ready, buf, 1)!=1);
  rbit = (buf[0]>>7)&1;
  printf("i2c_mon_iddd:  ready bit:  %d\n", rbit);

  // there are better solutions... note change in ready
  sleep(1);

  fail |= (i2c_set(fh,addr,ready) != 1);
  fail |= (i2c_recv(fh,addr, ready, buf, 1)!=1);
  rbit = (buf[0]>>7)&1;
  printf("i2c_mon_iddd:  ready bit:  %d\n", rbit);

  fail |= (i2c_set(fh,addr,rdat) != 1);
  fail |= (i2c_recv(fh,addr, rdat, buf, nbytes)!=nbytes);

  if (fail){
    printf("**ERROR** i2c_mon_iddd:  I2C failure.\n");
    return 0;
  }
  uint32_t val = 0;
  for (int i=0 ; i< nbytes; i++){
    val = (val<<8) | buf[i];
  }
  printf("i2c_mon_iddd:  value:  0x%x (%d)\n", val, val);
  return val;
}

uint32_t i2c_set_muxa(int fh, uint32_t lower, uint32_t val){
  uint8_t addr   = 0x4C;
  uint8_t reglo  = 0x0;
  uint8_t reghi  = 0x1;
  uint8_t nbytes = 1;
  uint32_t lo = val & 0xFF;
  uint32_t hi = (val>>8) & 0xFF;
  int ret=0;

  printf("i2c_set_muxa:  value: %d\n", val);
  ret = i2c_set(fh, addr, reglo, lo, nbytes);
  if (ret != nbytes+1){
    printf("**ERROR** i2c_set_muxa: i2c_set returned %d when expecting %d\n", ret, nbytes+1);
    return 0;
  }
  ret = i2c_set(fh, addr, reghi, hi, nbytes);
  if (ret != nbytes+1){
    printf("**ERROR** i2c_set_muxa: i2c_set returned %d when expecting %d\n", ret, nbytes+1);
    return 0;
  }
  return 1;
}

uint32_t i2c_set_muxb(int fh, uint32_t lower, uint32_t val){
  uint8_t addr   = 0x4C;
  uint8_t reglo  = 0x2;
  uint8_t reghi  = 0x3;
  uint8_t nbytes = 1;
  uint32_t lo = val & 0xFF;
  uint32_t hi = (val>>8) & 0xFF;
  int ret=0;

  printf("i2c_set_muxa:  value: %d\n", val);
  ret = i2c_set(fh, addr, reglo, lo, nbytes);
  if (ret != nbytes+1){
    printf("**ERROR** i2c_set_muxb: i2c_set returned %d when expecting %d\n", ret, nbytes+1);
    return 0;
  }
  ret = i2c_set(fh, addr, reghi, hi, nbytes);
  if (ret != nbytes+1){
    printf("**ERROR** i2c_set_muxb: i2c_set returned %d when expecting %d\n", ret, nbytes+1);
    return 0;
  }
  return 1;
}

uint32_t i2c_read_muxa(int fh, uint32_t lower){
  uint8_t addr   = 0x4C;
  uint8_t reglo  = 0x0;
  uint8_t reghi  = 0x1;
  uint8_t nbytes = 1;
  uint8_t buf[4];
  int fail=0;
  uint32_t val = 0x0000;

  printf("i2c_read_muxa:\n");

  fail |= (i2c_set(fh,addr,reglo) != 1);
  fail |= (i2c_recv(fh,addr, reglo, buf, 1)!=1);
  val = val | buf[0];
  fail |= (i2c_set(fh,addr,reghi) != 1);
  fail |= (i2c_recv(fh,addr, reghi, buf, 1)!=1);
  val = val | (buf[0]<<8);

  if (fail){
    printf("**ERROR** i2c_read_muxa:  I2C failure.\n");
    return 0;
  }
  return val;
}

uint32_t i2c_read_muxb(int fh, uint32_t lower){
  uint8_t addr   = 0x4C;
  uint8_t reglo  = 0x2;
  uint8_t reghi  = 0x3;
  uint8_t nbytes = 1;
  uint8_t buf[4];
  int fail=0;
  uint32_t val = 0x0000;

  printf("i2c_read_muxb:\n");

  fail |= (i2c_set(fh,addr,reglo) != 1);
  fail |= (i2c_recv(fh,addr, reglo, buf, 1)!=1);
  val = val | buf[0];
  fail |= (i2c_set(fh,addr,reghi) != 1);
  fail |= (i2c_recv(fh,addr, reghi, buf, 1)!=1);
  val = val | (buf[0]<<8);

  if (fail){
    printf("**ERROR** i2c_read_muxb:  I2C failure.\n");
    return 0;
  }
  return val;
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
    return i2c_read_muxa(fh, lower);
  case I2C_VREG_OFFSET_SET_MUXB:
    return i2c_read_muxb(fh, lower);
  case I2C_VREG_OFFSET_SCRATCH:
    val = i2c_scratch[lower];
    printf("i2c_read:  read  value 0x%x from scratch register %d\n", val, lower);
    return val;
  case I2C_VREG_OFFSET_EXPERT:
    return i2c_expert[lower];
  case I2C_VREG_OFFSET_DIRECT:
    return i2c_direct_read(fh, lower);
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
