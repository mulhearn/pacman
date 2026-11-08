#include "hw_access.h"
#include "global.h"
#include "iic.h"
#include "dma.h"
#include "rxtx.h"
#include "asic.h"

static asic_version_t G_ASIC_VER = UNKNOWN;

void asic_set_version(asic_version_t ver){
  G_ASIC_VER = ver;
}

asic_version_t asic_get_version(){
  return G_ASIC_VER;
}



//print a summary of a 64-bit ASIC packet:
void asic_print_packet_summary(hw_u32_t * word){
  if (G_ASIC_VER == LARPIX_V3) {
    unsigned wt = word[0]&0x3;
    unsigned chip = (word[0]>>2)&0xFF;
    if ((wt == 2) || (wt == 3)) {
      unsigned addr   = (word[0]>>10)&0xFF;
      unsigned value  = (word[0]>>18)&0xFF;
      unsigned magic  = (word[0]>>26)&0x3F;
      magic |= ((word[1]&0x03FFFFFF)<<6);
      unsigned valid  = 1;
      valid &= (magic == 0x89504E47);
      unsigned downstream = (word[1]>>30)&1;
      valid &= asic_calc_parity(word);

      if (valid){
	printf("valid ");
	if (wt == 2)
	  printf(" cfg write ");
	else
	  printf(" cfg read  ");
	if (downstream)
	  printf("downstream ");
	else
	  printf("upstream   ");
	printf("chip: 0x%02X (%03d) ", (unsigned int) chip, chip);
	printf("addr: 0x%02X (%03d) ", (unsigned int) addr, addr);
	printf("value: 0x%02X", (unsigned int) value);
      } else {
	printf("*** invalid *** ");
      }
    }
  }
  printf("\r\n");
}

hw_u8_t asic_config_get_chip  (hw_u32_t * word){
  if (G_ASIC_VER == LARPIX_V3) {
    return (word[0]>>2)&0xFF;
  }
  return 0;
}

hw_u8_t asic_config_get_addr  (hw_u32_t * word){
  if (G_ASIC_VER == LARPIX_V3) {
    unsigned wt = word[0]&0x3;
    if ((wt == 2) || (wt == 3)) {
      return (word[0]>>10)&0xFF;
    }
  }
  return 0;
}

hw_u8_t asic_config_get_value (hw_u32_t * word){
  if (G_ASIC_VER == LARPIX_V3) {
    unsigned wt = word[0]&0x3;
    if ((wt == 2) || (wt == 3)) {
      return (word[0]>>18)&0xFF;
    }
  }
  return 0;
}




void asic_batch_tx(hw_u32_t * payload, hw_u32_t n){
  int verbose = 0;
  unsigned count = 0;
  hw_addr_t nxta;

  while((count < n) && (dma_next_available_tx_bd(&nxta))){
    if (verbose)
      printf("INFO:  working on buffer %d at HW addr 0x%08X \r\n", count, (unsigned int) nxta);
    hw_ptr_t tx_buf = dma_get_buffer(nxta);

    // UART 0 only:
    tx_buf[0]= 0x1;
    tx_buf[1]= 0x0;
    for (int i=0; i<TX_PAYLOAD_U32_WORDS; i++)
      tx_buf[i+TX_HEADER_U32_WORDS] = 0;

    tx_buf[TX_HEADER_U32_WORDS]   = payload[2*count];
    tx_buf[TX_HEADER_U32_WORDS+1] = payload[2*count+1];

    HW_FLUSH_DCACHE(tx_buf, TX_PACKET_BYTES);

    dma_add_tx_bd(nxta);
    count++;
  }

  dma_clear_tx_ioc();
  if (verbose)
    printf("INFO:  sending batch of %d TX buffers \r\n", count);
  dma_tx_batch();

  // NOTE: the IOC fires on the first complete transfer, so this only confirms one buffer was sent
  if (dma_wait_tx_ioc(DMA_TIMEOUT) > 0){
    if (verbose)
      printf("INFO:  batch TX yielded TX IOC flag high (SUCCESS)\r\n");
  }
}

hw_u32_t asic_calc_parity(hw_u32_t * word){
  hw_u32_t x = word[0] ^ word[1];
  x ^= (x >> 16);
  x ^= (x >> 8);
  x ^= (x >> 4);
  x ^= (x >> 2);
  x ^= (x >> 1);
  return x & 1;
}

void asic_config_write(hw_u32_t * word, hw_u8_t chip, hw_u8_t addr, hw_u8_t data){
  word[0]  = 0x1c000002;
  word[1]  = 0x02254139;
  word[0] |= (chip << 2);
  word[0] |= (addr << 10);
  word[0] |= (data << 18);

  hw_u32_t parity = asic_calc_parity(word);
  if (parity == 0){
    word[1] |= (1<<31);
  }
}

void asic_config_read(hw_u32_t * word, hw_u8_t chip, hw_u8_t addr){
  word[0]  = 0x1c000003;
  word[1]  = 0x02254139;
  word[0] |= (chip << 2);
  word[0] |= (addr << 10);

  hw_u32_t parity = asic_calc_parity(word);
  if (parity == 0){
    word[1] |= (1<<31);
  }
}
