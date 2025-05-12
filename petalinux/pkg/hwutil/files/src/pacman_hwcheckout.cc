#include <stdlib.h>
#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <cstring>
#include <stdint.h>
//#include "version.hh"
//#include "addr_conf.hh"
#include <sys/time.h>

#include "mio.hh"
#include "axil.hh"
#include "dma.hh"
#include "led.hh"
#include "i2c.hh"
#include "rxtx.hh"

void blink_leds(){
  blink_red_led();
}

void global_registers(){
  printf("fw major----------- %d   \n", read_axil(SCOPE_GLOBAL+C_ADDR_GLOBAL_FW_MAJOR));
  printf("fw minor----------- %d   \n", read_axil(SCOPE_GLOBAL+C_ADDR_GLOBAL_FW_MINOR));
  printf("fw build----------- 0x%x \n", read_axil(SCOPE_GLOBAL+C_ADDR_GLOBAL_FW_BUILD));
  printf("hw code------------ 0x%x \n", read_axil(SCOPE_GLOBAL+C_ADDR_GLOBAL_HW_CODE));
  printf("scratch a---------- 0x%x \n", read_axil(SCOPE_GLOBAL+C_ADDR_GLOBAL_SCRA));
  printf("scratch b---------- 0x%x \n", read_axil(SCOPE_GLOBAL+C_ADDR_GLOBAL_SCRB));
  printf("\n");
  printf("enables------------ 0x%x \n", read_axil(SCOPE_GLOBAL+C_ADDR_GLOBAL_ENABLES));
  printf("\n");
  printf("timing status-------0x%x \n", read_axil(SCOPE_TIMING+C_ADDR_TIMING_STATUS));
  printf("trig config---------0x%x \n", read_axil(SCOPE_TIMING+C_ADDR_TIMING_TRIG));
  printf("sync config---------0x%x \n", read_axil(SCOPE_TIMING+C_ADDR_TIMING_SYNC));
  printf("\n");
  printf("timestamp-----------0x%x \n", read_axil(SCOPE_TIMING+C_ADDR_TIMING_STAMP));
}

void toggle_scratch(){
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
  write_axil(SCOPE_GLOBAL+C_ADDR_GLOBAL_SCRA, scra);
  write_axil(SCOPE_GLOBAL+C_ADDR_GLOBAL_SCRB, scrb);
}

void toggle_enables(){
  unsigned enables[] = {0x00000000, 0x00010000, 0x00010001,  0x000103FF, 0x001103FF};
  static int mode = 0;
  mode = (mode + 1) % 5;
  printf("INFO: setting enables to 0x%08x \n", enables[mode]);
  write_axil(SCOPE_GLOBAL+C_ADDR_GLOBAL_ENABLES, enables[mode]);
}

void read_tx_status(){
  for (int i=0; i<40; i++){
    unsigned cshift = (i<<8);
    unsigned status = read_axil(SCOPE_TX+cshift+C_ADDR_TX_STATUS);
    unsigned config = read_axil(SCOPE_TX+cshift+C_ADDR_TX_CONFIG);
    unsigned starts = read_axil(SCOPE_TX+cshift+C_ADDR_TX_STARTS);
    unsigned nchan  = read_axil(SCOPE_TX+cshift+C_ADDR_TX_NCHAN);
    printf("%2d:  chan: %2d config: 0x%08x status: 0x%08x starts: %d\n",i, nchan, config, status, starts);
  }
  printf("gflags------------ 0x%x    \n", read_axil(SCOPE_TX+0x3F00+C_ADDR_TX_GFLAGS));
  printf("bstatus----------- 0x%x    \n", read_axil(SCOPE_TX+0x3F00+C_ADDR_TX_STATUS));
}

void read_tx_look(){
  for (int i=0; i<40; i++){
    unsigned cshift = (i<<8);
    unsigned d = read_axil(SCOPE_TX+cshift+C_ADDR_TX_LOOK_D);
    unsigned c = read_axil(SCOPE_TX+cshift+C_ADDR_TX_LOOK_C);
    printf("Channel %2d Look:  0x%08x %08x\n", i, d, c);
  }
}


void toggle_rx_config(){
  static int mode = 0;
  mode = (mode + 1) % 3;
  if (mode==0){
    unsigned config = 0x00001002;
    printf("INFO: No internal loopback.  Broadcasting rx config write 0x%08x \n", config);
    write_axil(SCOPE_RX+UART_BROADCAST+C_ADDR_RX_CONFIG, config);
  } else if (mode==1) {
    unsigned config = 0x00011002;
    printf("INFO: Full internal loopback.  Broadcasting rx configs write 0x%08x \n", config);
    write_axil(SCOPE_RX+UART_BROADCAST+C_ADDR_RX_CONFIG, config);
  } else if (mode==2) {
    unsigned config;
    config = 0x00011002;
    printf("INFO: Tiles 2-10 use internal loopback.  Broadcasting rx configs t 0x%08x \n", config);
    write_axil(SCOPE_RX+UART_BROADCAST+C_ADDR_RX_CONFIG, config);
    config = 0x00001002;
    printf("INFO: Tile 1 does not use internal loopback.  Setting Tile 1 rx config 0x%08x \n", config);
    write_axil(SCOPE_RX+(0<<8)+C_ADDR_RX_CONFIG, config);
    write_axil(SCOPE_RX+(1<<8)+C_ADDR_RX_CONFIG, config);
    write_axil(SCOPE_RX+(2<<8)+C_ADDR_RX_CONFIG, config);
    write_axil(SCOPE_RX+(3<<8)+C_ADDR_RX_CONFIG, config);    
  }

  printf("INFO: Disabling Trigger, Sync, and Heartbeat words in the RX unit... \n");
  printf("INFO: And setting cycles to 1... \n");
  write_axil(0x7FA4, 0x00000001);
}


void read_rx_status(){
  for (int i=0; i<40; i++){
    unsigned cshift  = (i<<8);
    unsigned status  = read_axil(SCOPE_RX+cshift+C_ADDR_RX_STATUS);
    unsigned config  = read_axil(SCOPE_RX+cshift+C_ADDR_RX_CONFIG);
    unsigned starts  = read_axil(SCOPE_RX+cshift+C_ADDR_RX_STARTS);
    unsigned beats   = read_axil(SCOPE_RX+cshift+C_ADDR_RX_BEATS);
    unsigned updates = read_axil(SCOPE_RX+cshift+C_ADDR_RX_UPDATES);
    unsigned lost    = read_axil(SCOPE_RX+cshift+C_ADDR_RX_LOST);
    unsigned nchan   = read_axil(SCOPE_RX+cshift+C_ADDR_RX_NCHAN);
    printf("%2d: ch: %2d cfg: 0x%08x status: 0x%08x s: %d b: %d u: %d l: %d\n",i, nchan, config, status, starts, beats, updates, lost);
  }
  printf("gstatus----------- 0x%x    \n", read_axil(SCOPE_RX+0x3F00+C_ADDR_RX_GSTATUS));
  printf("gflags------------ 0x%x    \n", read_axil(SCOPE_RX+0x3F00+C_ADDR_RX_GFLAGS));
  printf("FIFO R count-------%d      \n", read_axil(SCOPE_RX+0x3F00+C_ADDR_RX_FRCNT));
  printf("FIFO W count-------%d      \n", read_axil(SCOPE_RX+0x3F00+C_ADDR_RX_FWCNT));
  printf("DMA ITR------------0x%x    \n", read_axil(SCOPE_RX+0x3F00+C_ADDR_RX_DMAITR));
}

void read_rx_look(){
  for (int i=0; i<40; i++){
    unsigned cshift = (i<<8);
    unsigned a = read_axil(SCOPE_RX+cshift+C_ADDR_RX_LOOK_A);
    unsigned b = read_axil(SCOPE_RX+cshift+C_ADDR_RX_LOOK_B);
    unsigned c = read_axil(SCOPE_RX+cshift+C_ADDR_RX_LOOK_C);
    unsigned d = read_axil(SCOPE_RX+cshift+C_ADDR_RX_LOOK_D);
    printf("Channel %2d Look:  0x%08x %08x %08x %08x\n", i, d, c, b, a);
  }
}

void zero_counts(){
  write_axil(SCOPE_TX+UART_GLOBAL+C_ADDR_TX_STARTS, 0);
  write_axil(SCOPE_RX+UART_GLOBAL+C_ADDR_RX_ZERO_CNTS, 0);
}
















void vdda_vddd_checkout(){
  printf("INFO: Begin checkout of VDDA and VDDD setting and monitoring.\n");
  printf("INFO: setting tile 1 VDDD to full.\n");
  i2c_set_vddd(0, 0xab63);
  printf("INFO: reading VDDD.\n");
  uint32_t mv = i2c_mon_vddd(0);
  printf("INFO: monitored VDD:  %d mV", mv);
  printf("INFO: Done.\n");
}

void adc_look(){
  unsigned adc = read_axil(SCOPE_GLOBAL+C_ADDR_GLOBAL_ADC_LOOK);
  printf("INFO: ADC LOOK: 0x%08x \n", adc);
}


void toggle_adc_input(){
  i2c_set_vddd(0xa, 0x0);
  i2c_set_vdda(0xa, 0x0);
  i2c_set_muxa(11);
  i2c_set_muxb(11);
}


void config_menu(){
  while(1){
    printf("CONFIG MENU:  choose an option:\n");
    printf("(1) global registers (2) toggle enables (3) main menu \n");

    int input;
    scanf("%d", &input);
    printf("pressed:  %d\n", input);

    switch(input){
    case 1:
      global_registers();
      break;
    case 2:
      toggle_enables();
      break;
    case 3:
      return;
      break;
    default:
      printf("invalid selection...\n\r");
      return;
    }
  }
  return;
}


void power_menu(){
  while(1){
    printf("POWER MENU:  choose an option:\n");
    printf("(1) do nothing (2) main menu \n");

    int input;
    scanf("%d", &input);
    printf("pressed:  %d\n", input);

    switch(input){
    case 1:
      break;
    case 2:
      return;
      break;
    default:
      printf("invalid selection...\n\r");
      return;
    }
  }
  return;
}

void rxtx_menu(){
  while(1){
    printf("RX/TX MENU:  choose an option:\n");
    printf("(0) main menu (1) zero counts (2) toggle RX config\n");
    printf("(3) TX status  (4) TX look   (5) single TX  \n");
    printf("(6) RX status  (7) RX look   (8) single RX  \n");
    printf("(9) benchmark TX  (10) benchmark RX/TX loopback \n");
    printf("(11) DMA status (12) reset DMA \n");

    int input;
    scanf("%d", &input);
    printf("pressed:  %d\n", input);

    switch(input){
    case 0:
      return;
      break;      
    case 1:
      zero_counts();
      break;      
    case 2:
      toggle_rx_config();
      break;      
    case 3:
      read_tx_status();
      break;
    case 4:
      read_tx_look();
      break;
    case 5:
      single_tx();
      break;
    case 6:
      read_rx_status();
      break;
    case 7:
      read_rx_look();
      break;
    case 8:
      single_rx();
      break;
    case 9:
      benchmark_tx();
      break;      
    case 10:
      benchmark_rxtx_loopback();
      break;      
    case 11:
      dma_status();
      break;
    case 12:
      reset_dma();
      break;
    default:
      printf("invalid selection...\n\r");
      return;
    }
  }
  return;
}

void adc_menu(){
  while(1){
    printf("ADC MENU:  choose an option:\n");
    printf("(1) do nothing (2) main menu \n");

    int input;
    scanf("%d", &input);
    printf("pressed:  %d\n", input);

    switch(input){
    case 1:
      break;
    case 2:
      return;
      break;
    default:
      printf("invalid selection...\n\r");
      return;
    }
  }
  return;
}

void main_menu(){
  while(1){
    printf("MAIN MENU:  choose an option:\n");
    printf("(1) blink LEDs (2) global registers (3) toggle scratch registers \n");
    printf("(4) config menu (5) power menu (6) RX/TX menu (7) ADC menu \n");
    int input;
    scanf("%d", &input);
    printf("pressed:  %d\n", input);

    switch(input){
    case 1:
      blink_leds();
      break;
    case 2:
      global_registers();
      break;
    case 3:
      toggle_scratch();
      break;
    case 4:
      config_menu();
      break;
    case 5:
      power_menu();
      break;
    case 6:
      rxtx_menu();
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
  printf("PACMAN Linux-Based Hardware Checkout \n");
  printf("Random Max:  0x%x Random Number:  0x%x \n", RAND_MAX, rand());

  init_mio();
  init_axil();
  init_dma();
  init_led();
  init_i2c();
  main_menu();
}
