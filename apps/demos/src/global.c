#include "hw_access.h"
#include "global.h"

void read_global_status(){
  printf("fw major----------- %d   \r\n", axil_read_register(SCOPE_GLOBAL+C_ADDR_GLOBAL_FW_MAJOR));
  printf("fw minor----------- %d   \r\n", axil_read_register(SCOPE_GLOBAL+C_ADDR_GLOBAL_FW_MINOR));
  printf("fw build----------- 0x%x \r\n", axil_read_register(SCOPE_GLOBAL+C_ADDR_GLOBAL_FW_BUILD));
  printf("hw code------------ 0x%x \r\n", axil_read_register(SCOPE_GLOBAL+C_ADDR_GLOBAL_HW_CODE));
  printf("scratch a---------- 0x%x \r\n", axil_read_register(SCOPE_GLOBAL+C_ADDR_GLOBAL_SCRA));
  printf("scratch b---------- 0x%x \r\n", axil_read_register(SCOPE_GLOBAL+C_ADDR_GLOBAL_SCRB));
  printf("\r\n");
  printf("enables------------ 0x%x \r\n", axil_read_register(SCOPE_GLOBAL+C_ADDR_GLOBAL_ENABLES));
  printf("\r\n");
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
  printf("INFO: setting scratch a to 0x%08x and scratch b to 0x%08x \r\n", scra, scrb);
  axil_write_register(SCOPE_GLOBAL+C_ADDR_GLOBAL_SCRA, scra);
  axil_write_register(SCOPE_GLOBAL+C_ADDR_GLOBAL_SCRB, scrb);
}

void toggle_global_enables(){
  unsigned enables[] = {0x00000000, 0x00010000, 0x00010001,  0x000103FF, 0x001103FF};
  static int mode = 0;
  mode = (mode + 1) % 5;
  printf("INFO: setting enables to 0x%08x \r\n", enables[mode]);
  axil_write_register(SCOPE_GLOBAL+C_ADDR_GLOBAL_ENABLES, enables[mode]);
}





