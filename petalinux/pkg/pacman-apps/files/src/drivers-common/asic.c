#include "hw_access.h"
#include "global.h"
#include "iic.h"

#include "asic.h"

void toggle_asic_power(){
  static int mode = 0;
  mode = (mode + 1) % 2;

  if (mode == 0) {
    printf("setting VDDA and VDDD to zero \r\n");
    //set_voltages(0, 0x00, 0x00, 0x00, 0x00);
    axil_write_register(SCOPE_GLOBAL+C_ADDR_GLOBAL_ENABLES, 0x0);
  } else {
    printf("setting VDDA and VDDD to nominal for ASIC \r\n");
    //set_voltages(0, 0xE2, 0xFF, 0x6D, 0xFF);
    axil_write_register(SCOPE_GLOBAL+C_ADDR_GLOBAL_ENABLES, 0x00010001);
  }
}

void asic_hello(){
}
