#include "iic.h"

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

#define AD5677_BASE_REG   0x30
#define AD5677_NUM_CHAN   16

#define PAC1944_REG_VOLT_BASE   0x07  // Base register for voltage channels (VDDA/VDDD)
#define PAC1944_REG_CURR_BASE   0x0B  // Base register for current channels (IDDA/IDDD)




#define PAC1944_OFFSET_VDDA     0
#define PAC1944_OFFSET_VDDD     1
#define PAC1944_NUM_CHAN        4
#define PAC1944_SINGLE_SHOT_CFG 0x85

#define FULLSCALE_VSENSE_MV          9000  // 9 V full scale for TILE voltage sense
#define FULLSCALE_TILE_MA            5000  // 5 A full scale for TIle current sense (100 mV / 20 mR)
#define FULLSCALE_DIGITAL_MA        20000  // 20 A full scale for current sense (100 mV /  5 mR)
#define FULLSCALE_ALL_TILE_MA       50000  // 50 A full scale for current sense (100 mV /  2 mR)

void check_iic(){}

void iic_set_vdda(hw_u32_t chan, hw_u32_t val) {
    if (chan > 10) return; // Only 10 tile channels

    hw_u8_t reg = AD5677_BASE_REG + chan;
    hw_u8_t buf[2];
    buf[0] = (val >> 8) & 0xFF;
    buf[1] = val & 0xFF;

    iic_write(ADDR_DAC_VDDA, reg, buf, 2);
}

void iic_set_vddd(hw_u32_t chan, hw_u32_t val) {
    if (chan > 10) return; // Only 10 tile channels

    hw_u8_t reg = AD5677_BASE_REG + chan;
    hw_u8_t buf[2];
    buf[0] = (val >> 8) & 0xFF;
    buf[1] = val & 0xFF;

    iic_write(ADDR_DAC_VDDD, reg, buf, 2);
}

hw_u32_t iic_vsense_dn(hw_u32_t addr_offset, hw_u32_t reg_offset) {
  hw_u8_t addr = ADDR_ADC_TILES + addr_offset;
  hw_u8_t reg  = PAC1944_REG_VOLT_BASE + reg_offset;
  hw_u8_t buf[2];

  // Configure single-shot mode
  hw_u8_t cfg[2] = { PAC1944_SINGLE_SHOT_CFG, 0x00 };
  iic_write(addr, 1, cfg, 2);

  // Refresh twice
  iic_write(addr, 0, NULL, 0);
  usleep(5000);
  iic_write(addr, 0, NULL, 0);
  usleep(5000);

  // Read the output register
  iic_write(addr, reg, NULL, 0);
  iic_read(addr, reg, buf, 2);

  uint32_t val = (buf[0] << 8) | buf[1];
  return val;
}

hw_u32_t iic_isense_dn(hw_u32_t addr_offset, hw_u32_t reg_offset) {
  hw_u8_t addr = ADDR_ADC_TILES + addr_offset;
  hw_u8_t reg  = PAC1944_REG_CURR_BASE + reg_offset;
  hw_u8_t buf[2];

  // Configure single-shot mode
  hw_u8_t cfg[2] = { PAC1944_SINGLE_SHOT_CFG, 0x00 };
  iic_write(addr, 1, cfg, 2);

  // Refresh twice
  iic_write(addr, 0, NULL, 0);
  usleep(5000);
  iic_write(addr, 0, NULL, 0);
  usleep(5000);

  // Read the output register
  iic_write(addr, reg, NULL, 0);
  iic_read(addr, reg, buf, 2);

  uint32_t val = (buf[0] << 8) | buf[1];
  return val;
}


hw_u32_t iic_mon_vdda_mv(hw_u32_t chan){
  if (chan >= 10) return 0; // Report only for tiles 0-9

  const uint32_t full_scale = FULLSCALE_VSENSE_MV;
  uint32_t dn = iic_vsense_dn(chan/2, 2*(chan%2)+PAC1944_OFFSET_VDDA);
  return full_scale * dn / 0xFFFF;
}

hw_u32_t iic_mon_vddd_mv(hw_u32_t chan){
  if (chan >= 10) return 0; // Report only for tiles 0-9

  const uint32_t full_scale = FULLSCALE_VSENSE_MV; // 9 V full scale
  uint32_t dn = iic_vsense_dn(chan/2, 2*(chan%2)+PAC1944_OFFSET_VDDD);
  return full_scale * dn / 0xFFFF;
}

hw_u32_t iic_mon_idda_ma(hw_u32_t chan){
  if (chan >= 10) return 0; // Report only for tiles 0-9

  const uint32_t full_scale = FULLSCALE_TILE_MA;
  uint32_t dn = iic_isense_dn(chan/2, 2*(chan%2)+PAC1944_OFFSET_VDDA);
  return full_scale * dn / 0xFFFF;
}

hw_u32_t iic_mon_iddd_ma(hw_u32_t chan){
  if (chan >= 10) return 0; // Report only for tiles 0-9

  const uint32_t full_scale = FULLSCALE_TILE_MA;
  uint32_t dn = iic_isense_dn(chan/2, 2*(chan%2)+PAC1944_OFFSET_VDDD);
  return full_scale * dn / 0xFFFF;
}

// Gen monitored value of board voltage for chan <chan>
// chan:  0= 3V6, 1=3V3, 2=3V0, 3=3V3 (Probe)
hw_u32_t iic_mon_vboard_mv(hw_u32_t chan){
  if (chan >= 4) return 0; // Report only for channels 0-3

  const uint32_t full_scale = FULLSCALE_VSENSE_MV;
  uint32_t dn = iic_vsense_dn(5, chan);
  return full_scale * dn / 0xFFFF;
}

// Gen monitored value of board voltage for chan <chan>
// chan:  0= 3V6, 1=3V3, 2=3V0
hw_u32_t iic_mon_iboard_ma(hw_u32_t chan){
  if (chan >= 3) return 0; // Report only for channels 0-2

  uint32_t full_scale = FULLSCALE_DIGITAL_MA;
  if (chan == 2)
    full_scale = FULLSCALE_ALL_TILE_MA;

  uint32_t dn = iic_isense_dn(5, chan);
  return full_scale * dn / 0xFFFF;

}

// Get monitored value of votage drop across probe in raw counts:
hw_u32_t iic_mon_probe_dn(){
  uint32_t dn = iic_isense_dn(5, 3);
  return dn;
}





hw_u32_t iic_mon_vdda(hw_u32_t chan) {
    if (chan > 11) return 0; // Only 12 channels

    const uint32_t full_scale = 9000; // 9 V full scale

    hw_u8_t addr = ADDR_ADC_TILES + (chan / 2);
    hw_u8_t reg  = PAC1944_REG_VOLT_BASE + PAC1944_OFFSET_VDDA + 2 * (chan % 2);
    hw_u8_t buf[2];

    // Configure single-shot mode
    hw_u8_t cfg[2] = { PAC1944_SINGLE_SHOT_CFG, 0x00 };
    iic_write(addr, 1, cfg, 2);

    // Refresh twice
    iic_write(addr, 0, NULL, 0);
    usleep(5000);
    iic_write(addr, 0, NULL, 0);
    usleep(5000);

    // Read the output register
    iic_write(addr, reg, NULL, 0);
    iic_read(addr, reg, buf, 2);

    uint32_t val = (buf[0] << 8) | buf[1];
    return full_scale * val / 0xFFFF;
}

hw_u32_t iic_mon_vddd(hw_u32_t chan) {
    if (chan > 11) return 0; // Only 12 channels

    const uint32_t full_scale = 9000; // 9 V full scale
    hw_u8_t addr = ADDR_ADC_TILES + (chan / 2);
    hw_u8_t reg  = PAC1944_REG_VOLT_BASE + PAC1944_OFFSET_VDDD + 2 * (chan % 2);
    hw_u8_t buf[2];

    // Configure single-shot mode
    hw_u8_t cfg[2] = { PAC1944_SINGLE_SHOT_CFG, 0x00 };
    iic_write(addr, 1, cfg, 2);

    // Refresh twice
    iic_write(addr, 0, NULL, 0);
    usleep(5000);
    iic_write(addr, 0, NULL, 0);
    usleep(5000);

    // Read the output register
    iic_write(addr, reg, NULL, 0);
    iic_read(addr, reg, buf, 2);

    uint32_t val = (buf[0] << 8) | buf[1];
    return full_scale * val / 0xFFFF;
}

hw_u32_t iic_mon_idda(hw_u32_t chan) {
    if (chan > 11) return 0; // Only 12 channels

    const uint32_t full_scale = FULLSCALE_TILE_MA;

    hw_u8_t addr = ADDR_ADC_TILES + (chan / 2);
    hw_u8_t reg  = PAC1944_REG_CURR_BASE + PAC1944_OFFSET_VDDA + 2 * (chan % 2);
    hw_u8_t buf[2];

    // Configure single-shot mode
    hw_u8_t cfg[2] = { PAC1944_SINGLE_SHOT_CFG, 0x00 };
    iic_write(addr, 1, cfg, 2);

    // Refresh twice
    iic_write(addr, 0, NULL, 0);
    usleep(5000);
    iic_write(addr, 0, NULL, 0);
    usleep(5000);

    // Read the output register
    iic_write(addr, reg, NULL, 0);
    iic_read(addr, reg, buf, 2);

    uint32_t val = (buf[0] << 8) | buf[1];
    return full_scale * val / 0xFFFF;
}

hw_u32_t iic_mon_iddd(hw_u32_t chan) {
    if (chan > 11) return 0; // Only 12 channels

    const uint32_t full_scale = FULLSCALE_TILE_MA; // 100 mV / 20 mR = 5 A full scale
    hw_u8_t addr = ADDR_ADC_TILES + (chan / 2);
    hw_u8_t reg  = PAC1944_REG_CURR_BASE + PAC1944_OFFSET_VDDD + 2 * (chan % 2);
    hw_u8_t buf[2];

    // Configure single-shot mode
    hw_u8_t cfg[2] = { PAC1944_SINGLE_SHOT_CFG, 0x00 };
    iic_write(addr, 1, cfg, 2);

    // Refresh twice
    iic_write(addr, 0, NULL, 0);
    usleep(5000);
    iic_write(addr, 0, NULL, 0);
    usleep(5000);

    // Read the output register
    iic_write(addr, reg, NULL, 0);
    iic_read(addr, reg, buf, 2);

    uint32_t val = (buf[0] << 8) | buf[1];
    return full_scale * val / 0xFFFF;
}

hw_u32_t get_mux_code(hw_u32_t val){
  const hw_u32_t switch_disabled = 0x10;
  if (val == 0)
    return switch_disabled;       // disable switch
  if ((val >= 1) && (val <= 10))
    return val - 1;               // select TILE
  if (val == 11)
    return 0xb;                   // select DAC
  printf("get_mux_code: unsupported value: 0x%x (%d)\n", val, val);
  return switch_disabled;
}

void iic_set_muxa(hw_u32_t val){
  const hw_u8_t reg = 0x14;
  const hw_u8_t nbytes = 1;
  hw_u32_t code = get_mux_code(val);

  hw_u8_t buf[1] = { (hw_u8_t)code };

  // Write to positive MUX
  iic_write(ADDR_MUX_P, reg, buf, nbytes);

  // Write to negative MUX
  iic_write(ADDR_MUX_N, reg, buf, nbytes);

}

void iic_set_muxb(hw_u32_t val){
  const hw_u8_t reg = 0x15;
  const hw_u8_t nbytes = 1;
  hw_u32_t code = get_mux_code(val);

  hw_u8_t buf[1] = { (hw_u8_t)code };

  // Write to positive MUX
  iic_write(ADDR_MUX_P, reg, buf, nbytes);

  // Write to negative MUX
  iic_write(ADDR_MUX_N, reg, buf, nbytes);

}
