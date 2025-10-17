#include <stdlib.h>
#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <string.h>
#include <stdint.h>
#include <sys/time.h>

#include "hw_access.h"
#include "global.h"
#include "registers.h"
#include "mio.h"
#include "bram.h"
#include "dma.h"
#include "led.h"
#include "i2c.h"
#include "rxtx.h"
#include "atc.h"

// *** LED ***

void blink_leds(){
  printf("INFO: starting LED blink test...\n");
  blink_red_led();
  blink_pacman_leds();
  printf("INFO: done with LED blink test.\n");
}

// *** GLOBAL UNIT ***


void toggle_global_enables_obsolete(){
  unsigned enables[] = {0x00000000, 0x00010000, 0x00010001,  0x000103FF, 0x001103FF};
  static int mode = 0;
  mode = (mode + 1) % 5;
  printf("INFO: setting enables to 0x%08x \n", enables[mode]);
  axil_write_register(SCOPE_GLOBAL+C_ADDR_GLOBAL_ENABLES, enables[mode]);
}

void toggle_global_scratch_obsolete(){
  unsigned scra, scrb;
  static int mode = 0;
  mode = (mode + 1) % 3;
  switch(mode){
    case 1:
      scra = 0xAAAAAAAA;
      scrb = 0xBBBBBBBB;
      break;
    case 2:
      scra = 0x12341234;
      scrb = 0x7777FFFF;
      break;
    default:
      scra = 0x0;
      scrb = 0x0;
  }
  printf("INFO: setting scratch a to 0x%08x and scratch b to 0x%08x \n", scra, scrb);
  axil_write_register(SCOPE_GLOBAL+C_ADDR_GLOBAL_SCRATCH_A, scra);
  axil_write_register(SCOPE_GLOBAL+C_ADDR_GLOBAL_SCRATCH_B, scrb);
}

// *** POWER UNIT ***

void toggle_power(){
  unsigned vddd[] = {0x00, 0xFFFF, 0,8000, 0x4000};
  unsigned vdda[] = {0x00, 0xFFFF, 0x8000, 0x4000};
  static int mode = 0;
  mode = (mode + 1) % 4;

  printf("INFO: setting VDDD to 0x%x \n", vddd[mode]);
  for (int i=0; i<10; i++){
    i2c_set_vddd(i, vddd[mode]);
  }

  printf("INFO: setting VDDA to 0x%x \n", vdda[mode]);
  for (int i=0; i<10; i++){
    i2c_set_vdda(i, vdda[mode]);
  }
}

void monitor_power(){
  for (int i=0; i<10; i++){
    printf("TILE %2d POWER SUMMARY:\n", i+1);
    unsigned vdda = i2c_mon_vdda(i);
    unsigned vddd = i2c_mon_vddd(i);
    unsigned idda = i2c_mon_idda(i);
    unsigned iddd = i2c_mon_iddd(i);

    printf("VDDA:  voltage:  %5d mV current: %5d mA\n", vdda, idda);
    printf("VDDD:  voltage:  %5d mV current: %5d mV\n", vddd, iddd);
  }

  printf("BOARD POWER SUMMARY:\n");

  unsigned vxa = i2c_mon_vdda(0xa);
  unsigned vya = i2c_mon_vddd(0xa);
  unsigned ixa = i2c_mon_idda(0xa);
  unsigned iya = i2c_mon_iddd(0xa);

  unsigned vxb = i2c_mon_vdda(0xb);
  unsigned vyb = i2c_mon_vddd(0xb);
  unsigned ixb = i2c_mon_idda(0xb);
  unsigned iyb = i2c_mon_iddd(0xb);

  float cyb = 4.5*iyb/20000.;

  printf("Board 3V6:  voltage:  %5d mV  current:  %5d mA\n",  vxa, ixa);
  printf("Board 3V3:  voltage:  %5d mV  current:  %5d mA\n",  vya, iya);
  printf("Board 3V0:  voltage:  %5d mV  current:  %5d mA\n",  vxb, ixb);
  printf("RTD Probe:  3V3:      %5d mV  current:  %.1f mA\n", vyb, cyb);

}

void record_iv_curves(){
  FILE *file;
  file = fopen("iv.txt", "w");
  if (file == NULL) {
    printf("ERROR: could not open file ");
    return;
  }

  printf("INFO: first setting all voltages to zero.\n");
  for (int i=0; i<10; i++){
    i2c_set_vdda(i, 0);
    i2c_set_vddd(i, 0);
  }

  for (int i=0; i<10; i++){
    fprintf(file, "TILE:   %d\n", i+1);
    printf("INFO:  VDDD/VDDA IV curves for Tile %d\n", i+1);
    for (unsigned vset = 0x0000; vset<=0xFFFF; vset+=0x1000){
      i2c_set_vdda(i, vset);
      i2c_set_vddd(i, vset);
      usleep(10);
      unsigned vdda = i2c_mon_vdda(i);
      unsigned vddd = i2c_mon_vddd(i);
      unsigned idda = i2c_mon_idda(i);
      unsigned iddd = i2c_mon_iddd(i);
      printf("INFO:  vset: 0x%04x vdda: %7d idda: %7d vddd: %7d iddd: %7d\n", vset, vdda, idda, vddd, iddd);
      fprintf(file, "vset: 0x%04x vdda: %7d idda: %7d vddd: %7d iddd: %7d\n", vset, vdda, idda, vddd, iddd);
    }
    i2c_set_vdda(i, 0);
    i2c_set_vddd(i, 0);
  }
  fclose(file);
}





// *** ADC UNIT ***

static unsigned G_ADC_BUFFER_SIZE = 20;
static unsigned G_ADC_INPUT = 0;

void read_adc_registers(){
  printf("ADC REGISTERS: \n");
  printf("ADC status-------------0x%x \n", axil_read_register(C_SCOPE_ADC+C_ADDR_ADC_STATUS));
  printf("ADC look---------------0x%x \n", axil_read_register(C_SCOPE_ADC+C_ADDR_ADC_LOOK));
  printf("ADC last---------------0x%x \n", axil_read_register(C_SCOPE_ADC+C_ADDR_ADC_LAST));
  printf("ADC state--------------0x%x \n", axil_read_register(C_SCOPE_ADC+C_ADDR_ADC_STATE));
  printf("ADC config-------------0x%x \n", axil_read_register(C_SCOPE_ADC+C_ADDR_ADC_CONFIG));
  printf("ADC clkpar-------------0x%x \n", axil_read_register(C_SCOPE_ADC+C_ADDR_ADC_CLKPAR));
  printf("ADC scratch------------0x%x \n", axil_read_register(C_SCOPE_ADC+C_ADDR_ADC_SCRATCH));
  printf("ADC ROA----------------0x%x \n", axil_read_register(C_SCOPE_ADC+C_ADDR_ADC_ROA));
}

void toggle_adc_on_off(){
  static int mode = 0;
  mode = (mode + 1) % 2;

  if (mode == 0) {
    printf("INFO: setting ADC sleep to on and disabling inputs\n");
    write_mio(0,0x1);
    axil_write_register(SCOPE_GLOBAL+C_ADDR_GLOBAL_ENABLES, 0x00000000);
  } else {
    printf("INFO: setting ADC sleep to off and enabling inputs\n");
    write_mio(0,0x0);
    axil_write_register(SCOPE_GLOBAL+C_ADDR_GLOBAL_ENABLES, 0x00100000);
  }
}

void toggle_adc_daq_test_patterns(){
  G_ADC_BUFFER_SIZE = 20;
  unsigned config[] = {0x00000000, 0x000000A3, 0x000403B3, 0x00080FB3, 0x000CABC3, 0x001012C3, 0x004000D3};
  static int mode = 0;
  mode = (mode + 1) % 7;

  printf("INFO:  setting ADC config to %x \r\n", config[mode]);
  axil_write_register(C_SCOPE_ADC+C_ADDR_ADC_CONFIG, config[mode]);

  if (mode==0){
    for (unsigned i=0; i<G_ADC_BUFFER_SIZE; i++){
      unsigned addr = 4*i;
      write_bram(addr, 0);
    }
  }
}

void set_adc_daq_off(){
  unsigned config = 0x0;
  printf("INFO:  setting ADC config to %x \r\n", config);
  axil_write_register(C_SCOPE_ADC+C_ADDR_ADC_CONFIG, config);
}

void clear_bram(){
  G_ADC_BUFFER_SIZE = 20;

  for (unsigned i=0; i<G_ADC_BUFFER_SIZE; i++){
    unsigned addr = 4*i;
    write_bram(addr,0);
  }
}

void toggle_bram_test_patterns(){
  G_ADC_BUFFER_SIZE = 20;

  static int mode = 0;
  mode = (mode + 1) % 3;
  if (mode==0){
    for (unsigned i=0; i<G_ADC_BUFFER_SIZE; i++){
      unsigned addr = 4*i;
      write_bram(addr,0);
    }
  } else if (mode==1){
    for (unsigned i=0; i<G_ADC_BUFFER_SIZE; i++){
      unsigned addr = 4*i;
      write_bram(addr,0x0ADC0000 + i);
    }
  } else {
    for (unsigned i=0; i<G_ADC_BUFFER_SIZE; i++){
      unsigned addr = 4*i;
      write_bram(addr,0x12340000 + 2*i);
    }
  }
}

void read_bram_by_address(){
  for (unsigned i=0; i<G_ADC_BUFFER_SIZE; i++){
    unsigned addr = 4*i;
    printf("%2d 0x%03x: 0x%08x\n", i, addr, read_bram(addr));
  }
}

void read_bram_time_ordered(){
  unsigned last_adr = 0x1FFF & axil_read_register(C_SCOPE_ADC+C_ADDR_ADC_STATUS);
  unsigned last_val = axil_read_register(C_SCOPE_ADC+C_ADDR_ADC_LAST);

  printf("LAST ADDRESS:  0x%x\n", last_adr);
  printf("LAST VALUE:    0x%x\n", last_val);
  printf("ADC INPUT:     0x%x\n", G_ADC_INPUT);
  printf("BUFFER SIZE:   %d\n", G_ADC_BUFFER_SIZE);

  if (G_ADC_BUFFER_SIZE == 0)
    return;

  for (int i=1; i<G_ADC_BUFFER_SIZE; i++){
    unsigned addr = (last_adr + 4*i)%(4*G_ADC_BUFFER_SIZE);
    printf("0x%x, ", read_bram(addr));
    if (i%10 == 0)
      printf("\n");
  }
  printf("0x%x\n", read_bram(last_adr%(4*G_ADC_BUFFER_SIZE)));
}




void copy_adc_buffer_to_file(){
  FILE *file;
  unsigned config   = axil_read_register(C_SCOPE_ADC+C_ADDR_ADC_CONFIG);
  unsigned last_adr = 0x1FFF & axil_read_register(C_SCOPE_ADC+C_ADDR_ADC_STATUS);
  unsigned last_val = axil_read_register(C_SCOPE_ADC+C_ADDR_ADC_LAST);

  file = fopen("adc.txt", "a");
  if (file == NULL) {
    printf("ERROR: could not open file ");
    return;
  }

  fprintf(file, "CONFIG:        0x%x\n", config);
  fprintf(file, "LAST ADDRESS:  0x%x\n", last_adr);
  fprintf(file, "LAST VALUE:    0x%x\n", last_val);
  fprintf(file, "ADC INPUT:     0x%x\n", G_ADC_INPUT);
  fprintf(file, "BUFFER SIZE:   %d\n", G_ADC_BUFFER_SIZE);

  if (G_ADC_BUFFER_SIZE == 0)
    return;

  for (int i=1; i<G_ADC_BUFFER_SIZE; i++){
    unsigned addr = (last_adr + 4*i)%(4*G_ADC_BUFFER_SIZE);
    fprintf(file, "0x%x, ", read_bram(addr));
    if (i%10 == 0)
    fprintf(file, "\n");
  }
  fprintf(file, "0x%x\n", read_bram(last_adr%(4*G_ADC_BUFFER_SIZE)));
  fclose(file);
}

void set_adc_input_to_dac(){
  printf("INFO: setting ADC input to DAC\n");
  i2c_set_vddd(0xa, 0x0);
  i2c_set_vdda(0xa, 0x0);
  i2c_set_muxa(11);
  i2c_set_muxb(11);
  G_ADC_INPUT = 11;
}

void toggle_adc_dac_constant_value(){
  unsigned vp[] = {0x00, 0x4000, 0x2000, 0x0000, 0x0000};
  unsigned vn[] = {0x00, 0x0000, 0x0000, 0x4000, 0x2000};
  static int mode = 0;
  mode = (mode + 1) % 5;

  printf("INFO: setting ADC DAC input to +0x%x -0x%x\n", vp[mode], vn[mode]);
  i2c_set_vdda(0xa, vp[mode]);
  i2c_set_vddd(0xa, vn[mode]);
}

void toggle_adc_input_tile(){
  static int tile = 9;
  tile = (tile + 1) % 10;

  printf("INFO: setting ADC input to TILE %d monitoring\n", tile+1);
  i2c_set_muxa(tile);
  i2c_set_muxb(tile);
  G_ADC_INPUT = tile;
}

void set_adc_circular_buffer(){
  G_ADC_BUFFER_SIZE = 1024;
  unsigned config = 0x10000013;
  printf("INFO:  setting ADC config to %x \r\n", config);
  axil_write_register(C_SCOPE_ADC+C_ADDR_ADC_CONFIG, config);
}

void set_adc_trigger(){
  G_ADC_BUFFER_SIZE = 1024;
  unsigned config = 0x10000033;
  printf("INFO:  setting ADC config to %x \r\n", config);
  axil_write_register(C_SCOPE_ADC+C_ADDR_ADC_CONFIG, config);
}

void set_adc_mode_to_run(){
  axil_write_register(C_SCOPE_ADC+C_ADDR_ADC_COMMAND, 0x2);
}

void poke_timing(){
  send_poke_c();
  send_poke_d();
}

// *** MENUS ***

void power_menu(){
  while(1){
    printf("POWER MENU:  choose an option:\n");
    printf("(0) main menu (1) toggle enables (2) toggle power (3) monitor power\n");
    printf("(4) write IV curves to file\n");

    int input;
    scanf("%d", &input);
    printf("INFO: selected %d\n", input);

    switch(input){
    case 0:
      return;
    case 1:
      toggle_global_enables();
      break;
    case 2:
      toggle_power();
      break;
    case 3:
      monitor_power();
      break;
    case 4:
      record_iv_curves();
      break;
    default:
      printf("invalid selection...\n\r");
    }
  }
  return;
}

void rxtx_menu(){
  while(1){
    printf("RXTX MENU:  choose an option:\n");
    printf("choose an option:\r\n");
    printf("(0) exit RX/TX Menu \r\n");
    printf("(1) read tx status (2) read rx status (3) read tx look (4) read rx look\r\n");
    printf("(5) toggle tx UART configs (6) toggle rx UART configs (7) zero counts\r\n");
    printf("(8) toggle rx buffer config (9) toggle rx enables (10) toggle tx mask \r\n");
    printf("...\r\n");
    printf("(20) init descriptor ring mode (21) show BDs (22) show head/tail (23) clear IOC flags \r\n");
    printf("(24) single TX (25) single RX (26) batch TX (27) batch RX \r\n");
    printf("(28) show TX buffer (29) show RX buffer (30) show RX transferred \r\n");
    printf("...\r\n");
    printf("(40) reset TX DMA (41) TX DMA status (42) reset RX DMA (43) RX DMA status (44) long DMA status \r\n");
    printf("(45) benchmark TX (46) benchmark RX/TX loopback \r\n");

    int input;
    scanf("%d", &input);
    printf("INFO: selected %d\n", input);

    switch(input){
    case 0:
      return;
    case 1:
      read_tx_status();
      break;
    case 2:
      read_rx_status();
      break;
    case 3:
      read_tx_look();
      break;
    case 4:
      read_rx_look();
      break;
    case 5:
      toggle_tx_config();
      break;
    case 6:
      toggle_rx_config();
      break;
    case 7:
      zero_rxtx_counts();
      break;
    case 8:
      toggle_rx_buffer_config();
      break;
    case 9:
      toggle_rx_buffer_enables();
      break;
    case 10:
      toggle_tx_mask();
      break;
    case 20:
      init_rxtx_descriptor_ring_mode(8);
      break;
    case 21:
      show_rxtx_bds();
      break;
    case 22:
      show_rxtx_head_tail();
      break;
    case 23:
      clear_rxtx_ioc();
      break;
    case 24:
      single_tx();
      break;
    case 25:
      single_rx();
      break;
    case 26:
      batch_tx();
      break;
    case 27:
      batch_rx();
      break;
    case 28:
      show_tx_buffer();
      break;
    case 29:
      show_rx_buffer();
      break;
    case 30:
      show_rx_transferred();
      break;
    case 40:
      dma_reset_tx(DMA_TIMEOUT);
      break;
    case 41:
      dma_show_tx_status();
      break;
    case 42:
      dma_reset_rx(DMA_TIMEOUT);
      break;
    case 43:
      dma_show_rx_status();
      break;
    case 44:
      dma_show_long_status();
      break;
    case 45:
      benchmark_tx();
      break;
    case 46:
      benchmark_rxtx_loopback();
      break;
    default:
      printf("invalid selection...\n\r");
    }
  }
  return;
}

void atc_menu(){
  printf("ASIC timing and control (ATC) signal menu:  \r\n");
  while(1){
    printf("choose an option:\r\n");
    printf("(0) Exit timing menu\r\n");
    printf("(1) read ATC registers (2) read ATC counts (3) toggle ATC destinations \r\n");
    printf("(4) poke C (5) poke D \r\n");

    int input;
    scanf("%d", &input);
    printf("INFO: selected %d\n", input);

    switch(input){
    case 0:
      return;
    case 1:
      read_atc_registers();
      break;
    case 2:
      read_atc_counts();
      break;
    case 3:
      toggle_atc_destinations();
      break;
    case 4:
      send_poke_c();
      break;
    case 5:
      send_poke_d();
      break;
    default:
      printf("invalid selection...\n\r");
    }
  }
}



void adc_menu(){
  while(1){
    printf("ADC MENU:  choose an option:\n");
    printf("(0) main menu (1) read ADC registers (2) toggle ADC on/off (3) toggle ADC DAQ test patterns (4) turn ADC DAQ off\n");
    printf("(5) clear BRAM (6) toggle BRAM test patterns (7) read BRAM by address (8) read BRAM time ordered (9) copy ADC buffer to file\n");
    printf("(10) set ADC input to DAC (11) toggle DAC constant value (12) toggle TILE input\n");
    printf("(13) set ADC DAQ to circular buffer (14) set ADC DAQ to trigger (15) set trigger mode to RUN\n");
    printf("(16) poke timing\n");

    int input;
    scanf("%d", &input);
    printf("INFO: selected %d\n", input);

    switch(input){
    case 0:
      return;
    case 1:
      read_adc_registers();
      break;
    case 2:
      toggle_adc_on_off();
      break;
    case 3:
      toggle_adc_daq_test_patterns();
      break;
    case 4:
      set_adc_daq_off();
      break;
    case 5:
      clear_bram();
      break;
    case 6:
      toggle_bram_test_patterns();
      break;
    case 7:
      read_bram_by_address();
      break;
    case 8:
      read_bram_time_ordered();
      break;
    case 9:
      copy_adc_buffer_to_file();
      break;
    case 10:
      set_adc_input_to_dac();
      break;
    case 11:
      toggle_adc_dac_constant_value();
      break;
    case 12:
      toggle_adc_input_tile();
      break;
    case 13:
      set_adc_circular_buffer();
      break;
    case 14:
      set_adc_trigger();
      break;
    case 15:
      set_adc_mode_to_run();
      break;
    case 16:
      poke_timing();
      break;
    default:
      printf("invalid selection...\n\r");
    }
  }
  return;
}

void main_menu(){
  while(1){
    printf("MAIN MENU:  choose an option:\n");
    printf("(1) blink LEDs (2) global registers (3) toggle scratch registers\n");
    printf("(4) power menu (5) RX/TX menu (6) ATC menu (7) ADC menu \n");
    int input;
    scanf("%d", &input);
    printf("INFO: selected %d\n", input);

    switch(input){
    case 1:
      blink_leds();
      break;
    case 2:
      read_global_status();
      break;
    case 3:
      toggle_global_scratch();
      break;
    case 4:
      power_menu();
      break;
    case 5:
      rxtx_menu();
      break;
    case 6:
      atc_menu();
      break;
    case 7:
      adc_menu();
      break;
    default:
      printf("invalid selection...\n\r");
    }
  }
  return;
}

int main(){
  printf("pacman_menu:  PACMAN Linux driver access via menu, for diagnostics and hardware checkout.\n");
  //printf("Random Max:  0x%x Random Number:  0x%x \n", RAND_MAX, rand());

  init_mio();
  init_axil_driver();
  init_bram();
  init_rxtx();
  init_led();
  init_i2c();
  main_menu();
}
