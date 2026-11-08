#include <stdlib.h>

#include "hw_access.h"
#include "atc.h"
#include "atc_menu.h"

void atc_menu(){
  printf("ASIC timing and control (ATC) signal menu:  \r\n");
  while(1){
    printf("choose an option:\r\n");
    printf("(x) Exit timing menu (s) set ATC default configuration\r\n");
    printf("(r) read ATC registers (n) read ATC counts (t) toggle ATC destinations \r\n");
    printf("(c) poke C (d) poke D \r\n");
    char input = input_choice();
    printf("INFO: selected %c\r\n", input);

    switch(input){
    case 'x':
      return;
    default:
      printf("invalid selection...\r\n");
    case 's':
      set_atc_default_config();
      break;      
    case 'r':
      read_atc_registers();
      break;
    case 'n':
      read_atc_counts();
      break;
    case 't':
      toggle_atc_destinations();
      break;
    case 'c':
      send_poke_c();
      break;
    case 'd':
      send_poke_d();
      break;
    }
  }
}
