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

void init_led(){
  int fd;
  const char * str_a = "913";
  const char * str_b = "918";
  const char * str_c = "919";
  const char * out   = "out";
  const char * off   = "0";

  fd = open("/sys/class/gpio/export", O_WRONLY);
  if (fd < 0){
    printf("ERROR:  could not open GPIO export file handle;");
    return;
  }  
  write(fd, str_a, strlen(str_a));
  write(fd, str_b, strlen(str_b));
  write(fd, str_c, strlen(str_c));
  close(fd);
    
  fd = open("/sys/class/gpio/gpio913/direction", O_WRONLY);
  if (fd < 0){
    printf("ERROR:  could not export GPIO pin 913\n");
    return;
  }
  write(fd, out, strlen(out));
  close(fd);

  fd = open("/sys/class/gpio/gpio918/direction", O_WRONLY);
  if (fd < 0){
    printf("ERROR:  could not export GPIO pin 918\n");
    return;
  }
  write(fd, out, strlen(out));
  close(fd);

  fd = open("/sys/class/gpio/gpio919/direction", O_WRONLY);
  if (fd < 0){
    printf("ERROR:  could not export GPIO pin 919\n");
    return;
  }
  write(fd, out, strlen(out));
  close(fd);

  fd = open("/sys/class/gpio/gpio913/value", O_WRONLY);
  if (fd < 0){
    printf("ERROR:  could not set value for GPIO pin 913\n");
    return;
  }
  write(fd, off, strlen(off));
  close(fd);

  fd = open("/sys/class/gpio/gpio918/value", O_WRONLY);
  if (fd < 0){
    printf("ERROR:  could not set value for GPIO pin 918\n");
    return;
  }
  write(fd, off, strlen(off));
  close(fd);
  
  fd = open("/sys/class/gpio/gpio919/value", O_WRONLY);
  if (fd < 0){
    printf("ERROR:  could not set value for GPIO pin 919\n");
    return;
  }
  write(fd, off, strlen(off));
  close(fd);
   
  printf("INFO: Success initializing LEDs\n");
  
}

void led_checkout(){
  int fd;
  const char * off   = "0";
  const char * on    = "1";
  
  printf("Checking LEDs...\n");

  printf("Blinking RED LED on Trenz Module, via MIO.\n");
  fd = open("/sys/class/gpio/gpio913/value", O_WRONLY);
  if (fd>=0){
    for (int i=0; i<20; i++){
      write(fd, on, strlen(off));
      usleep(50000);
      write(fd, off, strlen(off));
      usleep(50000);
    }
  }
  close(fd);

  
  printf("Blinking PACMAN LED, via MIO.\n");
  fd = open("/sys/class/gpio/gpio918/value", O_WRONLY);
  if (fd>=0){
    for (int i=0; i<20; i++){
      write(fd, on, strlen(off));
      usleep(50000);
      write(fd, off, strlen(off));
      usleep(50000);
    }
  }
  close(fd);
  

  printf("Blinking PACMAN LED, via MIO.\n");
  fd = open("/sys/class/gpio/gpio919/value", O_WRONLY);
  if (fd>=0){
    for (int i=0; i<20; i++){
      write(fd, on, strlen(off));
      usleep(50000);
      write(fd, off, strlen(off));
      usleep(50000);
    }
  }
  close(fd);
  
  printf("Done...\n");
}
