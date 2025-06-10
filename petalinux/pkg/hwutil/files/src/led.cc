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
#include "led.hh"

void init_led(){
}

void blink_red_led(){
  printf("Blinking RED LED on Trenz Module, via MIO.\n");
  for (int i=0; i<20; i++){
    write_mio(7, 1);
    usleep(50000);
    write_mio(7, 0);
    usleep(50000);
  }
  printf("Done...\n");
}
