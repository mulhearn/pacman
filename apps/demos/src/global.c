#include "hw_access.h"
#include "global.h"
#include <stdint.h>
#include <time.h>

void get_synthesis_date_string(char * buffer, size_t buffer_size){
  hw_val_t synth_date = axil_read_register(SCOPE_GLOBAL+C_ADDR_GLOBAL_SYNTHESIS_DATE);
  time_t raw_time = (time_t) synth_date;
  struct tm *utc_time = gmtime(&raw_time);

  if (buffer_size > 0) {
    if (utc_time) {
      strftime(buffer, buffer_size, "%Y-%m-%d %H:%M:%S UTC", utc_time);
    } else {
      buffer[0] = '\0';  // Set empty string on failure
    }
  }
}

void get_git_hash_string(char * buffer, size_t buffer_size){
  hw_val_t hash[2];
  hash[0] = axil_read_register(SCOPE_GLOBAL+C_ADDR_GLOBAL_GIT_HASH_UPPER);
  hash[1] = axil_read_register(SCOPE_GLOBAL+C_ADDR_GLOBAL_GIT_HASH_LOWER);

  if (buffer_size >= 8) {  // 7 chars + null terminator
    for (int i = 0; i < 7; ++i) {
      int word_index = i / 4;
      int byte_shift = 24 - 8 * (i % 4);
      buffer[i] = (char)((hash[word_index] >> byte_shift) & 0xFF);
    }
    buffer[7] = '\0';
  } else if (buffer_size > 0) {
    buffer[0] = '\0';
  }
}



void read_global_status(){
  char synthesis_date_str[32];
  char git_hash_str[32];

  get_synthesis_date_string(synthesis_date_str, sizeof(synthesis_date_str));
  get_git_hash_string(git_hash_str, sizeof(git_hash_str));

  printf("firmware major----------- %u   \r\n", (unsigned int) axil_read_register(SCOPE_GLOBAL+C_ADDR_GLOBAL_FIRMWARE_MAJOR));
  printf("firmware minor----------- %u   \r\n", (unsigned int) axil_read_register(SCOPE_GLOBAL+C_ADDR_GLOBAL_FIRMWARE_MINOR));
  printf("firmware letter---------- 0x%x \r\n", (unsigned int) axil_read_register(SCOPE_GLOBAL+C_ADDR_GLOBAL_FIRMWARE_LETTER));
  printf("hardware major----------- %u   \r\n", (unsigned int) axil_read_register(SCOPE_GLOBAL+C_ADDR_GLOBAL_HARDWARE_MAJOR));
  printf("hardware minor----------- %u   \r\n", (unsigned int) axil_read_register(SCOPE_GLOBAL+C_ADDR_GLOBAL_HARDWARE_MINOR));
  printf("hardware letter---------- 0x%x \r\n", (unsigned int)axil_read_register(SCOPE_GLOBAL+C_ADDR_GLOBAL_HARDWARE_LETTER));
  printf("scratch a---------------- 0x%x \r\n", (unsigned int)axil_read_register(SCOPE_GLOBAL+C_ADDR_GLOBAL_SCRATCH_A));
  printf("scratch b---------------- 0x%x \r\n", (unsigned int)axil_read_register(SCOPE_GLOBAL+C_ADDR_GLOBAL_SCRATCH_B));
  printf("enables------------------ 0x%x \r\n", (unsigned int)axil_read_register(SCOPE_GLOBAL+C_ADDR_GLOBAL_ENABLES));
  printf("leds--------------------- 0x%x \r\n", (unsigned int)axil_read_register(SCOPE_GLOBAL+C_ADDR_GLOBAL_LEDS));
  printf("status------------------- 0x%x \r\n", (unsigned int)axil_read_register(SCOPE_GLOBAL+C_ADDR_GLOBAL_STATUS));
  printf("synthesis date----------- %s   \r\n", synthesis_date_str);
  printf("git hash----------------- %s   \r\n", git_hash_str);
  printf("vivado version----------- %u.%u \r\n",
	 (unsigned int) axil_read_register(SCOPE_GLOBAL+C_ADDR_GLOBAL_VIVADO_MAJOR),
	 (unsigned int) axil_read_register(SCOPE_GLOBAL+C_ADDR_GLOBAL_VIVADO_MINOR));
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
  printf("INFO: setting scratch a to 0x%08x and scratch b to 0x%08x \r\n", (unsigned int)scra, (unsigned int)scrb);
  axil_write_register(SCOPE_GLOBAL+C_ADDR_GLOBAL_SCRATCH_A, scra);
  axil_write_register(SCOPE_GLOBAL+C_ADDR_GLOBAL_SCRATCH_B, scrb);
}

void toggle_global_enables(){
  unsigned enables[] = {0x00000000, 0x00010000, 0x00010001,  0x000103FF, 0x001103FF};
  static int mode = 0;
  mode = (mode + 1) % 5;
  printf("INFO: setting enables to 0x%08x \r\n", (unsigned int)enables[mode]);
  axil_write_register(SCOPE_GLOBAL+C_ADDR_GLOBAL_ENABLES, enables[mode]);
}
