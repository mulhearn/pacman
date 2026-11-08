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
#include "led.h"
#include "mio.h"

void init_led(){
}

void blink_red_led(){
  printf("Blinking RED LED on Trenz Module, via MIO...\n");
  for (int i=0; i<20; i++){
    write_mio(7, 1);
    usleep(50000);
    write_mio(7, 0);
    usleep(50000);
  }
}

void blink_pacman_leds(){
  printf("Blinking PACMAN LED-0, via MIO...\n");
  for (int i=0; i<20; i++){
    write_mio(12, 1);
    usleep(50000);
    write_mio(12, 0);
    usleep(50000);
  }
  printf("Blinking PACMAN LED-1, via MIO...\n");
  for (int i=0; i<20; i++){
    write_mio(13, 1);
    usleep(50000);
    write_mio(13, 0);
    usleep(50000);
  }
  printf("Blinking PACMAN LED-2, via AXIL register...\n");
  for (int i=0; i<20; i++){
    axil_write_register(SCOPE_GLOBAL + C_ADDR_GLOBAL_LEDS, 0x1);
    usleep(50000);
    axil_write_register(SCOPE_GLOBAL + C_ADDR_GLOBAL_LEDS, 0x0);
    usleep(50000);
  }
  printf("Blinking PACMAN LED-3, via AXIL register...\n");
  for (int i=0; i<20; i++){
    axil_write_register(SCOPE_GLOBAL + C_ADDR_GLOBAL_LEDS, 0x2);
    usleep(50000);
    axil_write_register(SCOPE_GLOBAL + C_ADDR_GLOBAL_LEDS, 0x0);
    usleep(50000);
  }
}
