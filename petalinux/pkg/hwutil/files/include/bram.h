#ifndef __BRAM_H__
#define __BRAM_H__

uint32_t  get_bram_status();
void      clear_bram_status();
void      init_bram();
void      close_bram();

void      write_bram(uint32_t addr, uint32_t value);
uint32_t  read_bram(uint32_t addr);

#endif // __BRAM_H__
