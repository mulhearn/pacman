#include <stdlib.h>
#include <stdio.h>
#include <sys/ioctl.h>
#include <cstdint>
#include <linux/i2c-dev.h>
#include <linux/i2c.h>
#include <unistd.h>
#include <fcntl.h>
#include <string.h>

#include "i2c.hh"


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

static int G_I2C_FH = -1;
static uint32_t G_I2C_STATUS = 0;

void init_i2c() {
    // open i2c device
    if (G_I2C_FH >= 0) {
        printf("**ERROR** init_i2C:  I2C FH already opened.\n");
	G_I2C_STATUS |= 1;
	return;
    }
    G_I2C_FH = open(I2C_DEV, O_RDWR);

    if (G_I2C_FH < 0) {
        printf("**ERROR** i2c_open:  Failed to open I2C device!\n");
	G_I2C_STATUS |= 2;
	return;
    }
    clear_i2c_status();
}

void close_i2c() {
    // open i2c device
    if (G_I2C_FH >= 0) {
      close(G_I2C_FH);
      G_I2C_FH = -1;
    }
}

uint32_t get_i2c_status(){
  if (G_I2C_FH < 0)
    return G_I2C_FH;
  return G_I2C_STATUS;
}

void clear_i2c_status(){
  G_I2C_STATUS = 0;
}

int i2c_addr(uint8_t addr) {
  // set i2c addr
  int resp = ioctl(G_I2C_FH,  I2C_SLAVE,addr);
  if (resp < 0) {
    printf("**ERROR** i2c_addr:  Failed to communicate with I2C secondary 0x%04x",addr);
  }
  return resp;
}

int i2c_set(uint8_t addr, uint8_t val) {
    // write 1 byte to i2c device at addr
    if (i2c_addr(addr) < 0) return -1;
    uint8_t buf[1];
    buf[0] = val;
    #if VERBOSE
    printf("i2c_set: set single byte 0x%x (%d)\n", buf[0], buf[0]);
    #endif
    return write(G_I2C_FH, buf,1);
}

int i2c_set(uint8_t addr, uint8_t reg, uint32_t val, uint8_t nbytes) {
    // write n nbytes to register reg on i2c device at addr
    if (i2c_addr(addr) < 0) return -1;
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
    return write(G_I2C_FH, buf,nbytes+1);
}

int i2c_rw(uint8_t addr, uint8_t reg, uint8_t* buf, uint32_t nbytes) {
    // perform read from register with repeated start
    if (i2c_addr(addr) < 0) return -1;
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
    if (ioctl(G_I2C_FH, I2C_RDWR, data) < 0) {
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

int i2c_recv(uint8_t addr, uint8_t reg, uint8_t* buf, uint32_t nbytes) {
    // read nbytes from register reg on i2c device at addr into buf
    if (i2c_addr(addr) < 0) return -1;
    if (i2c_set(addr,reg) != 1) {
        printf("***ERROR*** i2c_recv:  Failed to set register!\n");
        return -1;
    }
    memset(buf,0,nbytes);
    if (read(G_I2C_FH, buf,nbytes) != nbytes) {
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

int i2c_recv(uint8_t addr, uint8_t* buf, uint32_t nbytes) {
    // read nbytes from i2c device at addr into buf
    if (i2c_addr(addr) < 0) return -1;
    memset(buf,0,nbytes);
    if (read(G_I2C_FH, buf,nbytes) != nbytes) {
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

void i2c_set_vdda(uint32_t chan, uint32_t val){
  uint8_t reg    = 0x30 + chan;
  const uint8_t nbytes = 2;
  if (chan > 0xa)
    return;
  #if VERBOSE
  printf("i2c_set_vdda:  tile: %d value: 0x%x\n", chan+1, val);
  printf("i2c_set_vdda:  reg: 0x%x\n", reg);
  #endif
  int ret = i2c_set(ADDR_DAC_VDDA, reg, val, nbytes);

  if (ret != nbytes+1){
    printf("**ERROR** i2c_set_vdda: i2c_set returned %d when expecting %d\n", ret, nbytes+1);
    G_I2C_STATUS |= 4;
    return;
  }
}

void i2c_set_vddd(uint32_t chan, uint32_t val){
  uint8_t reg    = 0x30 + chan;
  const uint8_t nbytes = 2;
  if (chan > 0xa)
    return;
  #if VERBOSE
  printf("i2c_set_vddd:  tile: %d value: 0x%x\n", chan+1, val);
  printf("i2c_set_vddd:  reg: 0x%x\n", reg);
  #endif
  int ret = i2c_set(ADDR_DAC_VDDD, reg, val, nbytes);

  if (ret != nbytes+1){
    printf("**ERROR** i2c_set_vddd: i2c_set returned %d when expecting %d\n", ret, nbytes+1);
    G_I2C_STATUS |= 4;
    return;
  }
  return;
}

uint32_t i2c_mon_vdda(uint32_t chan){
  const int full_scale = 9000; // 9 V = 9000 mV full scale
  const uint8_t addr   = 0x10+chan/2;
  const uint8_t reg    = 0x7 + 0x2*(chan%2);

  if (chan > 0xb)
    return 0;

  const uint8_t nbytes = 2;
  uint8_t buf[nbytes];

  int status = 0;
  // set config registers for single shot mode:
  status |= (i2c_set(addr, 1, 0x8500, nbytes) != (nbytes+1));
  // send refresh to start conversions:
  status |= (i2c_set(addr, 0) != 1);
  usleep(5000);
  // send second refresh to move most recent conversions into output registers:
  status |= (i2c_set(addr, 0) != 1);
  usleep(5000);
  // read requested value:
  status |= (i2c_set(addr, reg) != 1);
  status |= (i2c_recv(addr, reg, buf, nbytes)!=nbytes);

  if (status){
    printf("**ERROR** i2c_mon_vdda:  I2C error.\n");
    G_I2C_STATUS |= 8;
    return 0;
  }

  uint32_t val = 0;
  for (int i=0 ; i< nbytes; i++){
    val = (val<<8) | buf[i];
  }
  return full_scale*val/0xFFFF;
}

uint32_t i2c_mon_vddd(uint32_t chan){
  const int full_scale = 9000; // 9 V = 9000 mV full scale
  const uint8_t addr   = 0x10+chan/2;
  const uint8_t reg    = 0x8 + 0x2*(chan%2);

  if (chan > 0xb)
    return 0;

  const uint8_t nbytes = 2;
  uint8_t buf[nbytes];

  int status = 0;
  // set config registers for single shot mode:
  status |= (i2c_set(addr, 1, 0x8500, nbytes) != (nbytes+1));
  // send refresh to start conversions:
  status |= (i2c_set(addr, 0) != 1);
  usleep(5000);
  // send second refresh to move most recent conversions into output registers:
  status |= (i2c_set(addr, 0) != 1);
  usleep(5000);
  // read requested value:
  status |= (i2c_set(addr, reg) != 1);
  status |= (i2c_recv(addr, reg, buf, nbytes)!=nbytes);

  if (status){
    printf("**ERROR** i2c_mon_vddd:  I2C error.\n");
    G_I2C_STATUS |= 8;
    return 0;
  }

  uint32_t val = 0;
  for (int i=0 ; i< nbytes; i++){
    val = (val<<8) | buf[i];
  }
  return full_scale*val/0xFFFF;
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

void i2c_set_muxa(uint32_t val){
  const uint8_t reg    = 0x14;
  const uint8_t nbytes = 1;

  uint32_t code = get_mux_code(val);

  printf("i2c_set_muxa:  value: %d  code: %d \n", val, code);
  int rep, status = 1;
  rep = i2c_set(ADDR_MUX_P, reg, code, nbytes);
  status *= (rep == nbytes+1);
  rep = i2c_set(ADDR_MUX_N, reg, code, nbytes);
  status *= (rep == nbytes+1);
  if (status!=1){
    printf("**ERROR** i2c_set_muxa:  i2c_set was not successful\n");
    G_I2C_STATUS |= 0x10;
  }
}

void i2c_set_muxb(uint32_t val){
  const uint8_t reg    = 0x15;
  const uint8_t nbytes = 1;

  uint32_t code = get_mux_code(val);

  printf("i2c_set_muxb:  value: %d  code: %d \n", val, code);
  int rep, status = 1;
  rep = i2c_set(ADDR_MUX_P, reg, code, nbytes);
  status *= (rep == nbytes+1);
  rep = i2c_set(ADDR_MUX_N, reg, code, nbytes);
  status *= (rep == nbytes+1);
  if (status!=1){
    printf("**ERROR** i2c_set_muxb:  i2c_set was not successful\n");
    G_I2C_STATUS |= 0x10;
  }
}





// NOT YET UPDATED TO USE GLOBAL STATUS...

uint32_t i2c_mon_idda(uint32_t lower){
  const int full_scale = 20000; // 20 A = 20000 mA full scale
  const uint8_t addr   = 0x10+lower/2;
  const uint8_t reg    = 0xB + 0x2*(lower%2);

  if (lower > 0xb)
    return 0;

  const uint8_t nbytes = 2;
  uint8_t buf[nbytes];

  int status = 0;
  // set config registers for single shot mode:
  status |= (i2c_set(addr, 1, 0x8500, nbytes) != (nbytes+1));
  // send refresh to start conversions:
  status |= (i2c_set(addr, 0) != 1);
  usleep(5000);
  // send second refresh to move most recent conversions into output registers:
  status |= (i2c_set(addr, 0) != 1);
  usleep(5000);
  // read requested value:
  status |= (i2c_set(addr, reg) != 1);
  status |= (i2c_recv(addr, reg, buf, nbytes)!=nbytes);

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

uint32_t i2c_mon_iddd(uint32_t lower){
  const int full_scale = 20000; // 20 A = 20000 mA full scale
  const uint8_t addr   = 0x10+lower/2;
  const uint8_t reg    = 0xC + 0x2*(lower%2);

  if (lower > 0xb)
    return 0;

  const uint8_t nbytes = 2;
  uint8_t buf[nbytes];

  int status = 0;
  // set config registers for single shot mode:
  status |= (i2c_set(addr, 1, 0x8500, nbytes) != (nbytes+1));
  // send refresh to start conversions:
  status |= (i2c_set(addr, 0) != 1);
  usleep(5000);
  // send second refresh to move most recent conversions into output registers:
  status |= (i2c_set(addr, 0) != 1);
  usleep(5000);
  // read requested value:
  status |= (i2c_set(addr, reg) != 1);
  status |= (i2c_recv(addr, reg, buf, nbytes)!=nbytes);

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

uint32_t i2c_version(uint32_t lower){
  if (lower == 0) return I2C_MAJOR_VERSION;
  if (lower == 1) return I2C_MINOR_VERSION;
  if (lower == 2) return I2C_DEBUG_TAG;
  return 0;
}
