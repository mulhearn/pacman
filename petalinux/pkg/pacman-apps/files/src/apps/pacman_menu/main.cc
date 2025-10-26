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
#include "mio.h"
#include "bram.h"
#include "dma.h"
#include "led.h"
#include "iic.h"
#include "rxtx.h"
#include "atc.h"
#include "adc.h"

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
  unsigned vddd[] = {0x00, 0x2000, 0x4000, 0x8000, 0xFFFF};
  unsigned vdda[] = {0x00, 0x2000, 0x4000, 0x8000, 0xFFFF};
  static int mode = 0;
  mode = (mode + 1) % 5;

  printf("INFO: setting VDDD to 0x%x \n", vddd[mode]);
  for (int i=0; i<10; i++){
    iic_set_vddd(i, vddd[mode]);
  }

  printf("INFO: setting VDDA to 0x%x \n", vdda[mode]);
  for (int i=0; i<10; i++){
    iic_set_vdda(i, vdda[mode]);
  }
}

void toggle_test_dac(){
  // VDDA DAC is used for postive  end of differential test DAC output
  // VDDD DAC is used for negative end of differntial test DAC output

  unsigned vp[] = {0x00, 0x1000, 0x0000, 0x2000, 0x0000};
  unsigned vn[] = {0x00, 0x0000, 0x1000, 0x0000, 0x2000};
  static int mode = 0;
  mode = (mode + 1) % 5;

  printf("INFO: setting DAC test VP to 0x%x \n", vp[mode]);
  printf("INFO: setting DAC test VN to 0x%x \n", vn[mode]);
  iic_set_vdda(10, vp[mode]);
  iic_set_vddd(10, vn[mode]);

}

void monitor_power(){
  for (int i=0; i<10; i++){
    printf("TILE %2d POWER SUMMARY:\n", i+1);
    unsigned vdda = iic_mon_vdda(i);
    unsigned vddd = iic_mon_vddd(i);
    unsigned idda = iic_mon_idda(i);
    unsigned iddd = iic_mon_iddd(i);

    printf("VDDA:  voltage:  %5d mV current: %5d mA\n", vdda, idda);
    printf("VDDD:  voltage:  %5d mV current: %5d mV\n", vddd, iddd);
  }

  printf("BOARD POWER SUMMARY:\n");

  unsigned vxa = iic_mon_vdda(0xa);
  unsigned vya = iic_mon_vddd(0xa);
  unsigned ixa = iic_mon_idda(0xa);
  unsigned iya = iic_mon_iddd(0xa);

  unsigned vxb = iic_mon_vdda(0xb);
  unsigned vyb = iic_mon_vddd(0xb);
  unsigned ixb = iic_mon_idda(0xb);
  unsigned iyb = iic_mon_iddd(0xb);

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
    iic_set_vdda(i, 0);
    iic_set_vddd(i, 0);
  }

  for (int i=0; i<10; i++){
    fprintf(file, "TILE:   %d\n", i+1);
    printf("INFO:  VDDD/VDDA IV curves for Tile %d\n", i+1);
    for (unsigned vset = 0x0000; vset<=0xFFFF; vset+=0x1000){
      iic_set_vdda(i, vset);
      iic_set_vddd(i, vset);
      usleep(10);
      unsigned vdda = iic_mon_vdda(i);
      unsigned vddd = iic_mon_vddd(i);
      unsigned idda = iic_mon_idda(i);
      unsigned iddd = iic_mon_iddd(i);
      printf("INFO:  vset: 0x%04x vdda: %7d idda: %7d vddd: %7d iddd: %7d\n", vset, vdda, idda, vddd, iddd);
      fprintf(file, "vset: 0x%04x vdda: %7d idda: %7d vddd: %7d iddd: %7d\n", vset, vdda, idda, vddd, iddd);
    }
    iic_set_vdda(i, 0);
    iic_set_vddd(i, 0);
  }
  fclose(file);
}


void run_check_iic(){
  printf("INFO: running check I2C routine\n");
  check_iic();
}

void toggle_mux(){
  static int mode = 0;
  mode = (mode + 1) % 4;
  if (mode == 0) {
    printf("INFO: disabling all inputs to MUX A and B.\n");
    iic_set_muxa(0);
    iic_set_muxb(0);
  } else if (mode == 1) {
    printf("INFO: setting MUX A to DAC input and disabling MUX B inputs.\n");
    iic_set_muxa(11);
    iic_set_muxb(0);
  } else if (mode == 2) {
    printf("INFO: setting MUX B to DAC input and disabling MUX A inputs.\n");
    iic_set_muxa(0);
    iic_set_muxb(11);
  } else {
    printf("INFO: setting MUX A and B to DAC input.\n");
    iic_set_muxa(11);
    iic_set_muxb(11);
  }
}



void read_iic_status(){
  printf("INFO: I2C driver status:  0x%08x\n", iic_driver_status());
}

// *** MENUS ***

void adc_menu(){
  while(1){
    printf("ADC MENU:  choose an option:\n");
    printf("(0) main menu (1) read ADC registers (2) toggle ADC sleep (3) toggle ADC enable (4) toggle DAC (5) toggle MUX \n");

    int input;
    if (scanf("%d", &input) != 1){
      printf("ERROR: invalid input.\n");
      continue;
    }
    printf("INFO: selected %d\n", input);

    switch(input){
    case 0:
      return;
    case 1:
      read_adc_registers();
      break;
    case 2:
      toggle_adc_sleep();
      break;
    case 3:
      toggle_adc_config();
      break;
    case 4:
      toggle_test_dac();
      break;
    case 5:
      toggle_mux();
      break;
    default:
      printf("invalid selection...\n");
    }
  }
  return;
}




void iic_menu(){
  while(1){
    printf("I2C MENU:  choose an option:\n");
    printf("(0) main menu (1) check I2C (2) toggle MUX (3) read I2C status\n");

    int input;
    if (scanf("%d", &input) != 1){
      printf("ERROR: invalid input.\n");
      continue;
    }
    printf("INFO: selected %d\n", input);

    switch(input){
    case 0:
      return;
    case 1:
      run_check_iic();
      break;
    case 2:
      toggle_mux();
      break;
    case 3:
      read_iic_status();
      break;
    default:
      printf("invalid selection...\n");
    }
  }
  return;
}



void power_menu(){
  while(1){
    printf("POWER MENU:  choose an option:\n");
    printf("(0) main menu (1) toggle enables (2) toggle power (3) monitor power\n");
    printf("(4) write IV curves to file (5) check I2C (6) read I2C status\n");

    int input;
    if (scanf("%d", &input) != 1){
      printf("ERROR: invalid input.\n");
      continue;
    }
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
    case 5:
      check_iic();
      break;
    case 6:
      read_iic_status();
      break;
    default:
      printf("invalid selection...\n");
    }
  }
  return;
}

void rxtx_menu(){
  while(1){
    printf("RXTX MENU:  choose an option:\n");
    printf("choose an option:\n");
    printf("(0) exit RX/TX Menu \n");
    printf("(1) read tx status (2) read rx status (3) read tx look (4) read rx look\n");
    printf("(5) toggle tx UART configs (6) toggle rx UART configs (7) zero counts\n");
    printf("(8) toggle rx buffer config (9) toggle rx enables (10) toggle tx mask \n");
    printf("...\n");
    printf("(20) init descriptor ring mode (21) show BDs (22) show head/tail (23) clear IOC flags \n");
    printf("(24) single TX (25) single RX (26) batch TX (27) batch RX \n");
    printf("(28) show TX buffer (29) show RX buffer (30) show RX transferred \n");
    printf("...\n");
    printf("(40) reset TX DMA (41) TX DMA status (42) reset RX DMA (43) RX DMA status (44) long DMA status \n");
    printf("(45) benchmark TX (46) benchmark RX/TX loopback \n");

    int input;
    if (scanf("%d", &input) != 1){
      printf("ERROR: invalid input.\n");
      continue;
    }
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
      printf("invalid selection...\n");
    }
  }
  return;
}

void atc_menu(){
  printf("ASIC timing and control (ATC) signal menu:  \n");
  while(1){
    printf("choose an option:\n");
    printf("(0) Exit timing menu\n");
    printf("(1) read ATC registers (2) read ATC counts (3) toggle ATC destinations \n");
    printf("(4) poke C (5) poke D \n");

    int input;
    if (scanf("%d", &input) != 1){
      printf("ERROR: invalid input.\n");
      continue;
    }
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
      printf("invalid selection...\n");
    }
  }
}

void main_menu(){
  while(1){
    printf("MAIN MENU:  choose an option:\n");
    printf("(1) blink LEDs (2) global registers (3) toggle scratch registers\n");
    printf("(4) power menu (5) I2C menu (6) RX/TX menu (7) ATC menu (8) ADC menu \n");
    int input;
    if (scanf("%d", &input) != 1){
      printf("ERROR: invalid input.\n");
      continue;
    }

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
      iic_menu();
      break;
    case 6:
      rxtx_menu();
      break;
    case 7:
      atc_menu();
      break;
    case 8:
      adc_menu();
      break;
    default:
      printf("invalid selection...\n");
    }
  }
  return;
}

int main(){
  printf("pacman_menu:  PACMAN Linux driver access via menu, for diagnostics and hardware checkout.\n");
  //printf("Random Max:  0x%x Random Number:  0x%x \n", RAND_MAX, rand());

  init_mio();
  init_axil_driver();
  init_iic_driver();
  init_bram();
  init_rxtx();
  init_led();

  main_menu();
}
