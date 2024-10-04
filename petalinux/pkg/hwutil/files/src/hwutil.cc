#ifndef hwutil_cc
#define hwutil_cc

#include <chrono>
#include <thread>

#include <time.h>
#include <stdio.h>
#include <fcntl.h>
#include <cstring>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/mman.h>
#include <cerrno>

#define BRAM_ADDR 0x40000000
#define BRAM_LEN      0x2000

#define AXIL_ADDR 0x43C10000
#define AXIL_LEN  0x00010000

int main(int argc, char* argv[]){
  const int LOOPS = 100000;
  int loop;
  const int SIZE  = BRAM_LEN/4;
  uint32_t buf[SIZE];
  
  time_t a,b;
  
  printf("Linux-based hardware utility - Version 1.0\n");

  printf("Configuring memory map for AXI BRAM...\n");
  int dh = open("/dev/mem", O_RDWR|O_SYNC);
  uint32_t* vbram = (uint32_t*)mmap(NULL, BRAM_LEN, PROT_READ|PROT_WRITE, MAP_SHARED, dh, BRAM_ADDR);
  printf("...DONE.\n");

  printf("Configuring memory map for AXIL REG...\n");
  volatile uint32_t* vaxil = (uint32_t*)mmap(NULL, AXIL_LEN, PROT_READ|PROT_WRITE, MAP_SHARED, dh, AXIL_ADDR);
  printf("...DONE.\n");


  printf("Filling local buffer...\n");
  time(&a);
  loop = LOOPS;
  while(loop--){
    for (int i=0;i<SIZE;i++){
      buf[i] = i;
    }
  }
  time(&b);
  printf("...DONE.\n");  
  printf("Start time:  %ld  End time:  %ld  Interval:  %ld\n", a,b,b-a);


  printf("Writing buffer contents to AXIL register repeadedly...\n");
  time(&a);
  loop = LOOPS;
  while(loop--){
    for (int i=0; i<SIZE; i++){
      vaxil[0] = buf[i];
    }    
  }
  time(&b);
  printf("...DONE.\n");  
  printf("Start time:  %ld  End time:  %ld  Interval:  %ld\n", a,b,b-a);  

  printf("Using memcpy to load BRAM...\n");
  time(&a);
  loop = LOOPS;
  while(loop--){
    memcpy(vbram,buf,BRAM_LEN);
  }
  time(&b);
  printf("...DONE.\n");  
  printf("Start time:  %ld  End time:  %ld  Interval:  %ld\n", a,b,b-a);


  printf("Using 32-bit writes to load BRAM...\n");
  time(&a);
  loop = LOOPS;
  volatile uint32_t * dst = vbram;
  while(loop--){
    for (int i=0; i<SIZE; i++){
      dst[i] = buf[i];
    }
  }
  time(&b);
  printf("...DONE.\n");  
  printf("Start time:  %ld  End time:  %ld  Interval:  %ld\n", a,b,b-a);

  printf("Using 64-bit writes to load BRAM...\n");
  time(&a);
  loop = LOOPS;
  volatile uint64_t * wdst = (volatile uint64_t *) vbram;
  while(loop--){
    for (int i=0; i<SIZE/2; i++){
      wdst[i] = ((uint64_t *) buf)[i];
    }
  }
  time(&b);
  printf("...DONE.\n");  
  printf("Start time:  %ld  End time:  %ld  Interval:  %ld\n", a,b,b-a);


  


  
  //uint32_t buf[100];
  //buf[0]=0xFFFFFFFF;
  //
}

#endif
