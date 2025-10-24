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

// *** MENUS ***

void power_menu(){
  while(1){
    printf("POWER MENU:  choose an option:\n");
    printf("(0) main menu (1) toggle enables (2) toggle power (3) monitor power\n");
    printf("(4) write IV curves to file\n");

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
      printf("invalid selection...\n\r");
    }
  }
}

void main_menu(){
  while(1){
    printf("MAIN MENU:  choose an option:\n");
    printf("(1) blink LEDs (2) global registers (3) toggle scratch registers\n");
    printf("(4) power menu (5) RX/TX menu (6) ATC menu \n");
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
      rxtx_menu();
      break;
    case 6:
      atc_menu();
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
