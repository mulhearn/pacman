// iic_hw1v5.c
//
// I2C implementation specific to PACMAN 1V5
//

#include <assert.h>
#include "hw_access.h"
#include "iic_devices.h"

// I2C Address Space - PACMAN 1V5
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
//

#define MAX_TILE          10

#define ADDR_BAD          0b0001110  // Non-existent address
#define ADDR_DAC_VDDA     0b0001100  // AD5677 DAC for VDDA TILES 1-10
#define ADDR_DAC_VDDD     0b0001101  // AD5677 DAC for VDDD TILES 1-10
#define ADDR_ADC_TILES    0b0010000  // PAC1944 for Tiles 1+2 (ADDR+0), Tiles 3+4 (ADDR+1), ...
#define ADDR_ADC_BOARD    0b0010101  // PAC 1944 for Board Power and Temp
#define ADDR_MUX_P        0b1001100  // MAX14661 for TILES 1-10
#define ADDR_MUX_N        0b1001101  // MAX14661 for TILES 1-10

//#define AD5677_BASE_REG   0x30
//#define AD5677_NUM_CHAN   16

#define PAC1944_REG_VOLT_BASE   0x07  // Base register for voltage channels (VDDA/VDDD)
#define PAC1944_REG_CURR_BASE   0x0B  // Base register for current channels (IDDA/IDDD)

// Each PAC1944 has four channels, covering TILE N and N+1
// CHAN 0: VDDA N
// CHAN 1: VDDD N
// CHAN 2: VDDA N+1
// CHAN 3: VDDD N+1

#define PAC1944_OFFSET_VDDA     0
#define PAC1944_OFFSET_VDDD     1

#define FULLSCALE_VSENSE_MV          9000   // 9 V full scale for TILE voltage sense
#define FULLSCALE_TILE_MA            5000   // 5 A full scale for TIle current sense (100 mV / 20 mR)

static hw_val_t get_mv(hw_val_t dn){
  return FULLSCALE_VSENSE_MV * dn / 0xFFFF;
}

static hw_val_t get_ma(hw_val_t dn){
  return FULLSCALE_TILE_MA * dn / 0xFFFF;
}

void iic_hw1v5_set_vdda_dn(hw_val_t itile, hw_val_t val) {
  if (itile >= MAX_TILE) return; // Only 10 tile channels

  ad5677_set_voltage(ADDR_DAC_VDDA, itile, val);
}

void iic_hw1v5_set_vddd_dn(hw_val_t itile, hw_val_t val) {
  if (itile >= MAX_TILE) return; // Only 10 tile channels

  ad5677_set_voltage(ADDR_DAC_VDDD, itile, val);
}

void iic_hw1v5_set_vplus_dn( hw_val_t val) {
  ad5677_set_voltage(ADDR_DAC_VDDA, MAX_TILE, val);
}

void iic_hw1v5_set_vminus_dn( hw_val_t val) {
  ad5677_set_voltage(ADDR_DAC_VDDD, MAX_TILE, val);
}

hw_val_t iic_hw1v5_mon_vdda_mv(hw_val_t itile) {
  if (itile >= MAX_TILE) return 0;

  hw_u8_t addr = ADDR_ADC_TILES + (itile/2);
  hw_u8_t reg  = PAC1944_REG_VOLT_BASE + 2*(itile%2)+PAC1944_OFFSET_VDDA;

  return get_mv(pac1944_adc_dn(addr, reg));
}

hw_val_t iic_hw1v5_mon_vddd_mv(hw_val_t itile) {
  if (itile >= MAX_TILE) return 0;

  hw_u8_t addr = ADDR_ADC_TILES + (itile/2);
  hw_u8_t reg  = PAC1944_REG_VOLT_BASE + 2*(itile%2)+PAC1944_OFFSET_VDDD;

  return get_mv(pac1944_adc_dn(addr, reg));
}

hw_val_t iic_hw1v5_mon_idda_ma(hw_val_t itile) {
  if (itile >= MAX_TILE) return 0;

  hw_u8_t addr = ADDR_ADC_TILES + (itile/2);
  hw_u8_t reg  = PAC1944_REG_CURR_BASE + 2*(itile%2)+PAC1944_OFFSET_VDDA;

  return get_ma(pac1944_adc_dn(addr, reg));
}

hw_val_t iic_hw1v5_mon_iddd_ma(hw_val_t itile) {
  if (itile >= MAX_TILE) return 0;

  hw_u8_t addr = ADDR_ADC_TILES + (itile/2);
  hw_u8_t reg  = PAC1944_REG_CURR_BASE + 2*(itile%2)+PAC1944_OFFSET_VDDD;

  return get_ma(pac1944_adc_dn(addr, reg));
}

hw_val_t iic_hw1v5_mon_vboard_mv(hw_val_t chan) {
  if (chan >= 4) return 0; // 4 channels for board power voltage monitoring

  hw_u8_t addr = ADDR_ADC_TILES + 5;
  hw_u8_t reg  = PAC1944_REG_VOLT_BASE + chan;
  return get_mv(pac1944_adc_dn(addr, reg));
}

hw_val_t iic_hw1v5_mon_iboard_ma(hw_val_t chan) {
  hw_val_t iscale[] = {20/5,20/5, 50/5};

  if (chan >= 3) return 0; // 3 channels for board power current monitoring

  hw_u8_t addr = ADDR_ADC_TILES + 5;
  hw_u8_t reg  = PAC1944_REG_CURR_BASE + chan;

  return iscale[chan] * get_ma(pac1944_adc_dn(addr, reg));
}

hw_val_t iic_hw1v5_mon_probe_dn() {
  hw_u8_t addr = ADDR_ADC_TILES + 5;
  hw_u8_t reg  = PAC1944_REG_CURR_BASE + 3;

  return pac1944_adc_dn(addr, reg);
}

void iic_hw1v5_set_mux_front_panel(hw_val_t itile){
  hw_u8_t code = 0x10; // switch disabled

  if (itile < 10)
    code = itile;        // select TILE
  else if (itile == 10)
    code = 0xb;          // select DAC

  max14661_set_coma(ADDR_MUX_N, code);
  max14661_set_coma(ADDR_MUX_P, code);
}

void iic_hw1v5_set_mux_adc(hw_val_t itile){
  hw_u8_t code = 0x10; // switch disabled

  if (itile < 10)
    code = itile;        // select TILE
  else if (itile == 10)
    code = 0xb;          // select DAC

  max14661_set_comb(ADDR_MUX_N, code);
  max14661_set_comb(ADDR_MUX_P, code);
}




