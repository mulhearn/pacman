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

void full_checkout(){
    printf("Running full checkout...\n");
    printf("Done...\n");
}

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




  usleep(10000);


  
}

void main_menu(){
  while(1){
    printf("choose an option:\n");
    printf("(1) run full checkout \n");
    printf("(2) LED \n");
	
    int input;
    scanf("%d", &input);
    printf("pressed:  %d\n", input);

    switch(input){
    case 1:
      full_checkout();
      break;
    case 2:
      led_checkout();
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

  printf("INFO:  Opening /dev/mem.\n");
  int dh = open("/dev/mem", O_RDWR|O_SYNC);

  init_led();
  
  main_menu();


  
  //printf("INFO:  Initializing PACMAN AXI-Lite interface.\n");
  //G_UTIL_AXIL = (uint32_t*)mmap(NULL, PACMAN_AXIL_LEN, PROT_READ|PROT_WRITE, MAP_SHARED, dh, PACMAN_AXIL_ADDR);


  //unsigned fwmajor = G_UTIL_AXIL[0XFF10>>2];
  //unsigned fwminor = G_UTIL_AXIL[0XFF14>>2];
  //unsigned fwbuild = G_UTIL_AXIL[0XFF18>>2];
  //unsigned hwcode  = G_UTIL_AXIL[0XFF1C>>2];

  //printf("INFO:  Running pacman-server version %d.%d\n", PACMAN_SERVER_MAJOR_VERSION, PACMAN_SERVER_MINOR_VERSION);
  //printf("INFO:  Running pacman firmware version %d.%d (Build: 0x%x  HW Code:  0x%x)\n", fwmajor, fwminor, fwbuild, hwcode);


}
