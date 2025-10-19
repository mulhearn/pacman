#include <stdlib.h>
#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <string.h>
#include <stdint.h>
#include <sys/time.h>

#include "mio.h"

//static int G_I2C_FH = -1;
static uint32_t G_MIO_STATUS = 0;

static const uint32_t G_MIO_FIRST_PIN = 906;


uint32_t  get_mio_status(){
  return G_MIO_STATUS;
}

void      clear_mio_status(){
  G_MIO_STATUS = 0;
}

void      init_mio(){
  clear_mio_status();
  //write_mio(0, 1);
}

void      close_mio(){
}

void      write_mio(int pin, uint32_t value){
  char fbuf[100];
  char vbuf[100];
  snprintf(fbuf, 100, "/sys/class/gpio/gpio%d/value", G_MIO_FIRST_PIN + pin);
  snprintf(vbuf, 100, "%u", value);
  //printf("DEBUG: writing %s to %s\n", vbuf, fbuf);

  int fd = open(fbuf, O_WRONLY);
  if (fd < 0){
    G_MIO_STATUS |= 1;
    return;
  }
  int n = write(fd, vbuf, strlen(vbuf));
  if (n < 0){
    G_MIO_STATUS |= 2;
    close(fd);
    return;
  }
  close(fd);
}

uint32_t  read_mio(int pin){
  return 0;
}
