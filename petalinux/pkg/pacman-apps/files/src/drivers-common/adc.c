#include <stdint.h>

#include "hw_access.h"
#include "adc.h"

void read_adc_registers(){
  printf("ADC status--------------- 0x%x \r\n", axil_read_register(SCOPE_ADC+C_ADDR_ADC_STATUS));
  printf("ADC config--------------- 0x%x \r\n", axil_read_register(SCOPE_ADC+C_ADDR_ADC_CONFIG));
  printf("ADC look----------------- 0x%x \r\n", axil_read_register(SCOPE_ADC+C_ADDR_ADC_LOOK));
}

void toggle_adc_sleep(){
}

void toggle_adc_config(){
  static int mode = 0;
  mode = (mode + 1) % 2;
  if (mode == 0) {
    printf("INFO: disabling ADC \r\n");
    axil_write_register(SCOPE_ADC+C_ADDR_ADC_CONFIG,0x00000000);
  } else {
    printf("INFO: enabling ADC \r\n");
    axil_write_register(SCOPE_ADC+C_ADDR_ADC_CONFIG,0x00000001);
  }
}

