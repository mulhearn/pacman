#include <stdlib.h>

#include "hw_access.h"
#include "atc.h"

void read_atc_registers(){
  printf("timing status---------------0x%x \r\n", (unsigned int) axil_read_register(C_SCOPE_ATC + C_ADDR_ATC_STATUS));
  printf("timestamp-------------------0x%x \r\n", (unsigned int) axil_read_register(C_SCOPE_ATC + C_ADDR_ATC_TIMESTAMP));
  printf("polarity--------------------0x%x \r\n", (unsigned int) axil_read_register(C_SCOPE_ATC + C_ADDR_ATC_POLARITY));
  printf("destination LEMO A----------0x%x \r\n", (unsigned int) axil_read_register(C_SCOPE_ATC + C_ADDR_ATC_DST_LEMO_A));
  printf("destination LEMO B----------0x%x \r\n", (unsigned int) axil_read_register(C_SCOPE_ATC + C_ADDR_ATC_DST_LEMO_B));
  printf("destination poke C----------0x%x \r\n", (unsigned int) axil_read_register(C_SCOPE_ATC + C_ADDR_ATC_DST_POKE_C));
  printf("destination poke D----------0x%x \r\n", (unsigned int) axil_read_register(C_SCOPE_ATC + C_ADDR_ATC_DST_POKE_D));
  printf("destination logic E---------0x%x \r\n", (unsigned int) axil_read_register(C_SCOPE_ATC + C_ADDR_ATC_DST_LOGIC_E));
  printf("destination logic F---------0x%x \r\n", (unsigned int) axil_read_register(C_SCOPE_ATC + C_ADDR_ATC_DST_LOGIC_F));
}

#define C_ATC_BUSY_WAIT 10
int wait_atc_busy(int timeout){
  while (timeout && ( axil_read_register(C_SCOPE_ATC+C_ADDR_ATC_STATUS) & 0xF)){ usleep(1); timeout--; }
  return timeout;
}

void read_atc_counts(){
  unsigned count = 0;

  wait_atc_busy(C_ATC_BUSY_WAIT);

  axil_write_register(C_SCOPE_ATC+C_ADDR_ATC_COUNT_REQ, 0b01110000);
  wait_atc_busy(C_ATC_BUSY_WAIT);
  count = axil_read_register(C_SCOPE_ATC+C_ADDR_ATC_COUNT);
  printf("LEMO A----------------------%4d (0x%x) \r\n", count, (unsigned int) count);

  axil_write_register(C_SCOPE_ATC+C_ADDR_ATC_COUNT_REQ, 0b01110001);
  wait_atc_busy(C_ATC_BUSY_WAIT);
  count = axil_read_register(C_SCOPE_ATC+C_ADDR_ATC_COUNT);
  printf("LEMO B----------------------%4d (0x%x) \r\n", count, (unsigned int) count);

  axil_write_register(C_SCOPE_ATC+C_ADDR_ATC_COUNT_REQ, 0b01110010);
  wait_atc_busy(C_ATC_BUSY_WAIT);
  count = axil_read_register(C_SCOPE_ATC+C_ADDR_ATC_COUNT);
  printf("POKE C----------------------%4d (0x%x) \r\n", count, (unsigned int) count);

  axil_write_register(C_SCOPE_ATC+C_ADDR_ATC_COUNT_REQ, 0b01110011);
  wait_atc_busy(C_ATC_BUSY_WAIT);
  count = axil_read_register(C_SCOPE_ATC+C_ADDR_ATC_COUNT);
  printf("POKE D----------------------%4d (0x%x) \r\n", count, (unsigned int) count);

  for (int i=0; i<10; i++){
    axil_write_register(C_SCOPE_ATC+C_ADDR_ATC_COUNT_REQ, 0b01010000 + i);
    wait_atc_busy(C_ATC_BUSY_WAIT);
    count = axil_read_register(C_SCOPE_ATC+C_ADDR_ATC_COUNT);
    printf("OUTPUT G(%d)-----------------%4d (0x%x) \r\n", i, count, (unsigned int) count);
  }

  for (int i=0; i<10; i++){
    axil_write_register(C_SCOPE_ATC+C_ADDR_ATC_COUNT_REQ, 0b01100000 + i);
    wait_atc_busy(C_ATC_BUSY_WAIT);
    count = axil_read_register(C_SCOPE_ATC+C_ADDR_ATC_COUNT);
    printf("OUTPUT H(%d)-----------------%4d (0x%x) \r\n", i, count, (unsigned int) count);
  }
}

void toggle_atc_destinations(){

  static int mode = 0;
  mode = (mode + 1) % 4;
  if (mode == 0) {
    printf("INFO:  setting all destinations to zero (no output) \r\n");
    axil_write_register(C_SCOPE_ATC+C_ADDR_ATC_DST_LEMO_A,  0x0);
    axil_write_register(C_SCOPE_ATC+C_ADDR_ATC_DST_LEMO_B,  0x0);
    axil_write_register(C_SCOPE_ATC+C_ADDR_ATC_DST_POKE_C,  0x0);
    axil_write_register(C_SCOPE_ATC+C_ADDR_ATC_DST_POKE_D,  0x0);
    axil_write_register(C_SCOPE_ATC+C_ADDR_ATC_DST_LOGIC_E, 0x0);
    axil_write_register(C_SCOPE_ATC+C_ADDR_ATC_DST_LOGIC_F, 0x0);
    wait_atc_busy(C_ATC_BUSY_WAIT);
    axil_write_register(C_SCOPE_ATC+C_ADDR_ATC_CONFIG_REQ, 0x0);
    wait_atc_busy(C_ATC_BUSY_WAIT);
  } else if (mode == 1) {
    printf("configure timing for POKE C -> G POKE D -> H \r\n");
    axil_write_register(C_SCOPE_ATC+C_ADDR_ATC_DST_LEMO_A,  0x0);
    axil_write_register(C_SCOPE_ATC+C_ADDR_ATC_DST_LEMO_B,  0x0);
    axil_write_register(C_SCOPE_ATC+C_ADDR_ATC_DST_POKE_C,  0x03FF0011);
    axil_write_register(C_SCOPE_ATC+C_ADDR_ATC_DST_POKE_D,  0x03FF0012);
    axil_write_register(C_SCOPE_ATC+C_ADDR_ATC_DST_LOGIC_E, 0x0);
    axil_write_register(C_SCOPE_ATC+C_ADDR_ATC_DST_LOGIC_F, 0x0);
    wait_atc_busy(C_ATC_BUSY_WAIT);
    axil_write_register(C_SCOPE_ATC+C_ADDR_ATC_CONFIG_REQ, 0x0);
    wait_atc_busy(C_ATC_BUSY_WAIT);
  } else if (mode == 2) {
    printf("configure timing for POKE C -> G POKE D -> T \r\n");
    axil_write_register(C_SCOPE_ATC+C_ADDR_ATC_DST_LEMO_A,  0x0);
    axil_write_register(C_SCOPE_ATC+C_ADDR_ATC_DST_LEMO_B,  0x0);
    axil_write_register(C_SCOPE_ATC+C_ADDR_ATC_DST_POKE_C,  0x03FF0011);
    axil_write_register(C_SCOPE_ATC+C_ADDR_ATC_DST_POKE_D,  0x03FF0014);
    axil_write_register(C_SCOPE_ATC+C_ADDR_ATC_DST_LOGIC_E, 0x0);
    axil_write_register(C_SCOPE_ATC+C_ADDR_ATC_DST_LOGIC_F, 0x0);
    wait_atc_busy(C_ATC_BUSY_WAIT);
    axil_write_register(C_SCOPE_ATC+C_ADDR_ATC_CONFIG_REQ, 0x0);
    wait_atc_busy(C_ATC_BUSY_WAIT);
  } else {
    printf("configure timing for LEMO A -> G LEMO B -> H \r\n");
    axil_write_register(C_SCOPE_ATC+C_ADDR_ATC_DST_LEMO_A,  0x03FF0011);
    axil_write_register(C_SCOPE_ATC+C_ADDR_ATC_DST_LEMO_B,  0x03FF0012);
    axil_write_register(C_SCOPE_ATC+C_ADDR_ATC_DST_POKE_C,  0x0);
    axil_write_register(C_SCOPE_ATC+C_ADDR_ATC_DST_POKE_D,  0x0);
    axil_write_register(C_SCOPE_ATC+C_ADDR_ATC_DST_LOGIC_E, 0x0);
    axil_write_register(C_SCOPE_ATC+C_ADDR_ATC_DST_LOGIC_F, 0x0);
    wait_atc_busy(C_ATC_BUSY_WAIT);
    axil_write_register(C_SCOPE_ATC+C_ADDR_ATC_CONFIG_REQ, 0x0);
    wait_atc_busy(C_ATC_BUSY_WAIT);
  }
}

void send_poke_c(){
  wait_atc_busy(C_ATC_BUSY_WAIT);
  axil_write_register(C_SCOPE_ATC+C_ADDR_ATC_POKE_C,0x3FF);
}

void send_poke_d(){
  wait_atc_busy(C_ATC_BUSY_WAIT);
  axil_write_register(C_SCOPE_ATC+C_ADDR_ATC_POKE_D,0x3FF);
}
