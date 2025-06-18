#include <stdlib.h>
#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <cstring>
#include <stdint.h>
#include <sys/time.h>

#include "mio.hh"
#include "axil.hh"
#include "bram.hh"
#include "dma.hh"
#include "led.hh"
#include "i2c.hh"
#include "rxtx.hh"

// *** LED ***

void blink_leds(){
  printf("INFO: starting LED blink test...\n");
  blink_red_led();
  blink_pacman_leds();
  printf("INFO: done with LED blink test.\n");
}

// *** GLOBAL UNIT ***

void read_global_registers(){
  printf("fw major----------- %d   \n", read_axil(C_SCOPE_GLOBAL+C_ADDR_GLOBAL_FW_MAJOR));
  printf("fw minor----------- %d   \n", read_axil(C_SCOPE_GLOBAL+C_ADDR_GLOBAL_FW_MINOR));
  printf("fw build----------- 0x%x \n", read_axil(C_SCOPE_GLOBAL+C_ADDR_GLOBAL_FW_BUILD));
  printf("hw code------------ 0x%x \n", read_axil(C_SCOPE_GLOBAL+C_ADDR_GLOBAL_HW_CODE));
  printf("scratch a---------- 0x%x \n", read_axil(C_SCOPE_GLOBAL+C_ADDR_GLOBAL_SCRA));
  printf("scratch b---------- 0x%x \n", read_axil(C_SCOPE_GLOBAL+C_ADDR_GLOBAL_SCRB));
  printf("\n");
  printf("enables------------ 0x%x \n", read_axil(C_SCOPE_GLOBAL+C_ADDR_GLOBAL_ENABLES));
  printf("\n");
  unsigned adc = read_axil(C_SCOPE_GLOBAL+C_ADDR_GLOBAL_ADC_LOOK);
  printf("adc look (deprecated) -- 0x%08x \n", adc);
}

void toggle_global_enables(){
  unsigned enables[] = {0x00000000, 0x00010000, 0x00010001,  0x000103FF, 0x001103FF};
  static int mode = 0;
  mode = (mode + 1) % 5;
  printf("INFO: setting enables to 0x%08x \n", enables[mode]);
  write_axil(C_SCOPE_GLOBAL+C_ADDR_GLOBAL_ENABLES, enables[mode]);
}

void toggle_global_scratch(){
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
  write_axil(C_SCOPE_GLOBAL+C_ADDR_GLOBAL_SCRA, scra);
  write_axil(C_SCOPE_GLOBAL+C_ADDR_GLOBAL_SCRB, scrb);
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

// *** RX and TX UNITs ***

void toggle_tx_config(){
  static int mode = 0;
  mode = (mode + 1) % 3;
  if (mode==0){
    unsigned config = 0x1602;
    printf("INFO: Default TX config.  Broadcasting tx config write 0x%08x \n", config);
    write_axil(SCOPE_TX+UART_BROADCAST+C_ADDR_TX_CONFIG, config);
  } else if (mode==1) {
    unsigned config = 0x1601;
    printf("INFO: Full-speed TX.  Broadcasting tx config write 0x%08x \n", config);
    write_axil(SCOPE_TX+UART_BROADCAST+C_ADDR_TX_CONFIG, config);
  } else if (mode==2) {
    unsigned config = 0x053c1602;
    printf("INFO: Default TX config plus delay.  Broadcasting tx config write 0x%08x \n", config);
    write_axil(SCOPE_TX+UART_BROADCAST+C_ADDR_TX_CONFIG, config);
  }

}

void read_tx_registers(){
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
  mode = (mode + 1) % 6;
  if (mode==0){
    unsigned config = 0x00001002;
    printf("INFO: No internal loopback.  Broadcasting rx config write 0x%08x \n", config);
    write_axil(SCOPE_RX+UART_BROADCAST+C_ADDR_RX_CONFIG, config);
  } else if (mode==1) {
    unsigned config = 0x00001001;
    printf("INFO: No internal loopback at full speed..  Broadcasting rx config write 0x%08x \n", config);
    write_axil(SCOPE_RX+UART_BROADCAST+C_ADDR_RX_CONFIG, config);
  } else if (mode==2) {
    unsigned config = 0x00011002;
    printf("INFO: Full internal loopback.  Broadcasting rx configs write 0x%08x \n", config);
    write_axil(SCOPE_RX+UART_BROADCAST+C_ADDR_RX_CONFIG, config);
  } else if (mode==3) {
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
  } else if (mode==4) {
    unsigned config = 0x00010002;
    printf("INFO: Disabling rx.  Broadcasting rx configs write 0x%08x \n", config);
    write_axil(SCOPE_RX+UART_BROADCAST+C_ADDR_RX_CONFIG, config);
  } else if (mode==5) {
    unsigned config = 0x00011001;
    printf("INFO: Full internal loopback at full speed.  Broadcasting rx configs write 0x%08x \n", config);
    write_axil(SCOPE_RX+UART_BROADCAST+C_ADDR_RX_CONFIG, config);
  }
}

void toggle_rx_global_config(){
  unsigned config[] = {0x00071FFF, 0x00000001, 0x00000100, 0x00000800, 0x00001000, 0x00001FFF};
  static int mode = 0;
  mode = (mode + 1) % 6;
  printf("INFO: setting rx global config to 0x%08x \n", config[mode]);
  write_axil(SCOPE_RX+UART_GLOBAL+C_ADDR_RX_GFLAGS, config[mode]);
}

void read_rx_registers(){
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

void rxtx_reset_counts(){
  write_axil(SCOPE_TX+UART_GLOBAL+C_ADDR_TX_STARTS, 0);
  write_axil(SCOPE_RX+UART_GLOBAL+C_ADDR_RX_ZERO_CNTS, 0);
}

// *** TIMING UNIT ***

void read_timing_registers(){
  printf("TIMING REGISTERS:\n");
  printf("timing status-------------0x%x \n", read_axil(C_SCOPE_TIMING+C_ADDR_TIMING_STATUS));
  printf("timestamp-----------------0x%x \n", read_axil(C_SCOPE_TIMING+C_ADDR_TIMING_STAMP));
  printf("config polarity-----------0x%x \n", read_axil(C_SCOPE_TIMING+C_ADDR_TIMING_CONFIG_POLARITY));
  printf("config timestamp sync-----0x%x \n", read_axil(C_SCOPE_TIMING+C_ADDR_TIMING_CONFIG_TS));
  for (int i=0; i<10; i++)
    printf("config tile %2d ATC G---0x%x \n", i+1, read_axil(C_SCOPE_TIMING+C_ADDR_TIMING_CONFIG_G_FIRST+4*i));
  for (int i=0; i<10; i++)
    printf("config tile %2d ATC H---0x%x \n", i+1, read_axil(C_SCOPE_TIMING+C_ADDR_TIMING_CONFIG_H_FIRST+4*i));
}

void read_timing_counts(){
  printf("TIMING SYSTEM COUNTERS:\n");
  printf("count LEMO A (fast) ------0x%x \n", read_axil(C_SCOPE_TIMING+C_ADDR_TIMING_COUNT_LEMO_A_F));
  printf("count LEMO B (fast) ------0x%x \n", read_axil(C_SCOPE_TIMING+C_ADDR_TIMING_COUNT_LEMO_B_F));
  printf("count LEMO A (slow) ------0x%x \n", read_axil(C_SCOPE_TIMING+C_ADDR_TIMING_COUNT_LEMO_A_S));
  printf("count LEMO B (slow) ------0x%x \n", read_axil(C_SCOPE_TIMING+C_ADDR_TIMING_COUNT_LEMO_B_S));
  printf("count POKE C (slow) ------0x%x \n", read_axil(C_SCOPE_TIMING+C_ADDR_TIMING_COUNT_POKE_C_S));
  printf("count POKE D (slow) ------0x%x \n", read_axil(C_SCOPE_TIMING+C_ADDR_TIMING_COUNT_POKE_D_S));

  printf("count timestamp sync-----0x%x \n", read_axil(C_SCOPE_TIMING+C_ADDR_TIMING_COUNT_TS));
  for (int i=0; i<10; i++)
    printf("count tile %2d ATC G---0x%x \n", i+1, read_axil(C_SCOPE_TIMING+C_ADDR_TIMING_COUNT_G_FIRST+4*i));
  for (int i=0; i<10; i++)
    printf("count tile %2d ATC H---0x%x \n", i+1, read_axil(C_SCOPE_TIMING+C_ADDR_TIMING_COUNT_H_FIRST+4*i));
}

void toggle_timing_input_polarity(){
  unsigned polarity[] = {0x0, 0x3};
  static int mode = 0;
  mode = (mode + 1) % 2;
  printf("INFO: setting input polarity to 0x%x \n", polarity[mode]);
  write_axil(C_SCOPE_TIMING + C_ADDR_TIMING_CONFIG_POLARITY, polarity[mode]);
}

void toggle_timing_ts_sync_config(){
  unsigned config[] = {0x00, 0x10};
  static int mode = 0;
  mode = (mode + 1) % 2;
  printf("INFO: setting timestamp sync config to 0x%x \n", config[mode]);
  write_axil(C_SCOPE_TIMING + C_ADDR_TIMING_CONFIG_TS, config[mode]);
}

void toggle_timing_g_config(){
  unsigned config[] = {0x0000, 0x00F14, 0x0F04};
  static int mode = 0;
  mode = (mode + 1) % 3;

  printf("INFO: setting all G config to 0x%x\n", config[mode]);
  for (int i=0; i<10; i++)
    write_axil(C_SCOPE_TIMING+C_ADDR_TIMING_CONFIG_G_FIRST+4*i, config[mode]);
}

void toggle_timing_h_config(){
  unsigned config[] = {0x0000, 0x1F18, 0x1F08};
  static int mode = 0;
  mode = (mode + 1) % 3;

  printf("INFO: setting all G config to 0x%x\n", config[mode]);
  for (int i=0; i<10; i++)
    write_axil(C_SCOPE_TIMING+C_ADDR_TIMING_CONFIG_H_FIRST+4*i, config[mode]);
}

void toggle_timing_counts(){
  static int mode = 0;
  mode = (mode + 1) % 2;
  if (mode == 0) {
    printf("INFO: stopping counts \n");
    write_axil(C_SCOPE_TIMING+C_ADDR_TIMING_STOP_COUNTS, 0x0);
  } else {
    printf("INFO: reseting and starting counts \r\n");
    write_axil(C_SCOPE_TIMING+C_ADDR_TIMING_STOP_COUNTS, 0x0);
    write_axil(C_SCOPE_TIMING+C_ADDR_TIMING_RESET_COUNTS, 0x0);
    write_axil(C_SCOPE_TIMING+C_ADDR_TIMING_START_COUNTS, 0x0);
  }
}

void poke_timing_input_c(){
  write_axil(C_SCOPE_TIMING+C_ADDR_TIMING_POKE_C, 0x0);
}

void poke_timing_input_d(){
  write_axil(C_SCOPE_TIMING+C_ADDR_TIMING_POKE_D, 0x0);
}


// *** ADC UNIT ***

static unsigned G_ADC_BUFFER_SIZE = 20;
static unsigned G_ADC_INPUT = 0;

void read_adc_registers(){
  printf("ADC REGISTERS: \n");
  printf("ADC status-------------0x%x \n", read_axil(C_SCOPE_ADC+C_ADDR_ADC_STATUS));
  printf("ADC look---------------0x%x \n", read_axil(C_SCOPE_ADC+C_ADDR_ADC_LOOK));
  printf("ADC last---------------0x%x \n", read_axil(C_SCOPE_ADC+C_ADDR_ADC_LAST));
  printf("ADC state--------------0x%x \n", read_axil(C_SCOPE_ADC+C_ADDR_ADC_STATE));
  printf("ADC config-------------0x%x \n", read_axil(C_SCOPE_ADC+C_ADDR_ADC_CONFIG));
  printf("ADC clkpar-------------0x%x \n", read_axil(C_SCOPE_ADC+C_ADDR_ADC_CLKPAR));
  printf("ADC scratch------------0x%x \n", read_axil(C_SCOPE_ADC+C_ADDR_ADC_SCRATCH));
  printf("ADC ROA----------------0x%x \n", read_axil(C_SCOPE_ADC+C_ADDR_ADC_ROA));
}

void toggle_adc_on_off(){
  static int mode = 0;
  mode = (mode + 1) % 2;

  if (mode == 0) {
    printf("INFO: setting ADC sleep to on and disabling inputs\n");
    write_mio(0,0x1);
    write_axil(C_SCOPE_GLOBAL+C_ADDR_GLOBAL_ENABLES, 0x00000000);
  } else {
    printf("INFO: setting ADC sleep to off and enabling inputs\n");
    write_mio(0,0x0);
    write_axil(C_SCOPE_GLOBAL+C_ADDR_GLOBAL_ENABLES, 0x00100000);
  }
}

void toggle_adc_daq_test_patterns(){
  G_ADC_BUFFER_SIZE = 20;
  unsigned config[] = {0x00000000, 0x000000A3, 0x000403B3, 0x00080FB3, 0x000CABC3, 0x001012C3, 0x004000D3};
  static int mode = 0;
  mode = (mode + 1) % 7;

  printf("INFO:  setting ADC config to %x \r\n", config[mode]);
  write_axil(C_SCOPE_ADC+C_ADDR_ADC_CONFIG, config[mode]);

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
  write_axil(C_SCOPE_ADC+C_ADDR_ADC_CONFIG, config);
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
  unsigned last_adr = 0x1FFF & read_axil(C_SCOPE_ADC+C_ADDR_ADC_STATUS);
  unsigned last_val = read_axil(C_SCOPE_ADC+C_ADDR_ADC_LAST);

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
  unsigned config   = read_axil(C_SCOPE_ADC+C_ADDR_ADC_CONFIG);
  unsigned last_adr = 0x1FFF & read_axil(C_SCOPE_ADC+C_ADDR_ADC_STATUS);
  unsigned last_val = read_axil(C_SCOPE_ADC+C_ADDR_ADC_LAST);

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
  write_axil(C_SCOPE_ADC+C_ADDR_ADC_CONFIG, config);
}

void set_adc_trigger(){
  G_ADC_BUFFER_SIZE = 1024;
  unsigned config = 0x10000033;
  printf("INFO:  setting ADC config to %x \r\n", config);
  write_axil(C_SCOPE_ADC+C_ADDR_ADC_CONFIG, config);
}

void set_adc_mode_to_run(){
  write_axil(C_SCOPE_ADC+C_ADDR_ADC_COMMAND, 0x2);
}

void poke_timing(){
  poke_timing_input_c();
  poke_timing_input_d();
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
    printf("RX/TX MENU:  choose an option:\n");
    printf("(0) main menu (1) zero counts (2) toggle TX config (3) toggle RX config (4) toggle RX global config\n");
    printf("(5) TX status  (6) TX look   (7) single TX  \n");
    printf("(8) RX status  (9) RX look   (10) single RX  \n");
    printf("(11) benchmark TX  (12) benchmark RX/TX loopback (13) random RX/TX loopback\n");
    printf("(14) DMA status (15) reset DMA \n");
    printf("(16) set DMA TX to RUN \n");
    printf("(17) set DMA RX to RUN (18) clear DMA RX (19) start DMA RX (20) resume RX\n");


    int input;
    scanf("%d", &input);
    printf("INFO: selected %d\n", input);

    switch(input){
    case 0:
      return;
      break;
    case 1:
      rxtx_reset_counts();
      break;
    case 2:
      toggle_tx_config();
      break;
    case 3:
      toggle_rx_config();
      break;
    case 4:
      toggle_rx_global_config();
      break;
    case 5:
      read_tx_registers();
      break;
    case 6:
      read_tx_look();
      break;
    case 7:
      single_tx();
      break;
    case 8:
      read_rx_registers();
      break;
    case 9:
      read_rx_look();
      break;
    case 10:
      single_rx();
      break;
    case 11:
      benchmark_tx();
      break;
    case 12:
      benchmark_rxtx_loopback();
      break;
    case 13:
      random_rxtx_loopback();
      break;
    case 14:
      dma_status();
      break;
    case 15:
      reset_dma();
      break;
    case 16:
      set_dma_tx_to_run();
      break;
    case 17:
      set_dma_rx_to_run();
      break;
    case 18:
      clear_dma_rx_buffer();
      break;
    case 19:
      start_dma_rx();
      break;
    case 20:
      resume_rx();
      break;
    default:
      printf("invalid selection...\n\r");
    }
  }
  return;
}

void timing_menu(){
  while(1){
    printf("TIMING MENU:  choose an option:\n");
    printf("(0) main menu (1) read timing registers (2) read counts \n");
    printf("(3) toggle input polarity (4) toggle ts sync config (5) toggle G config (6) toggle H config\n");
    printf("(7) toggle counts (8) poke C (9) poke D\n");
    int input;
    scanf("%d", &input);
    printf("INFO: selected %d\n", input);

    switch(input){
    case 0:
      return;
    case 1:
      read_timing_registers();
      break;
    case 2:
      read_timing_counts();
      break;
    case 3:
      toggle_timing_input_polarity();
      break;
    case 4:
      toggle_timing_ts_sync_config();
      break;
    case 5:
      toggle_timing_g_config();
      break;
    case 6:
      toggle_timing_h_config();
      break;
    case 7:
      toggle_timing_counts();
      break;
    case 8:
      poke_timing_input_c();
      break;
    case 9:
      poke_timing_input_d();
      break;
    default:
      printf("invalid selection...\n\r");
    }
  }
  return;
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
    printf("(4) power menu (5) RX/TX menu (6) timing menu (7) ADC menu \n");
    int input;
    scanf("%d", &input);
    printf("INFO: selected %d\n", input);

    switch(input){
    case 1:
      blink_leds();
      break;
    case 2:
      read_global_registers();
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
      timing_menu();
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
  init_axil();
  init_bram();
  init_dma();
  init_led();
  init_i2c();
  main_menu();
}
