#ifndef __MIO_H__
#define __MIO_H__

uint32_t  get_mio_status();
void      clear_mio_status();
void      init_mio();
void      close_mio();

void      write_mio(int pin, uint32_t value);
uint32_t  read_mio(int pin);

#endif // __MIO_H__
