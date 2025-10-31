#include "hw_access.h"
#include "global.h"
#include "iic.h"
#include "dma.h"
#include "rxtx.h"
#include "asic.h"


void asic_full_reset(){
  const hw_u32_t mask = 0x3FF;
  printf("INFO: sending full reset \r\n");

  // update pulse duration for full reset (1023 cycles):
  axil_write_register(0xE118, 0x03FF3FF5);
  axil_write_register(0xE100, 0x00);
  usleep(10);

  // reset pulses triggered by poke C
  axil_write_register(0xE0C0, mask);
  usleep(100);

  // set pulse duration back to default (internal reset, 8 cycles):
  axil_write_register(0xE118, 0x03FF0085);
  axil_write_register(0xE100, 0x00);
  usleep(10);
}

void asic_internal_reset(){
  printf("INFO: sending internal reset \r\n");
  const hw_u32_t mask = 0x3FF;
  axil_write_register(0xE0C0, mask);

}


void asic_toggle_power(){
  static int mode = 0;
  mode = (mode + 1) % 2;

  if (mode == 0) {
    printf("setting VDDA and VDDD to zero \r\n");
    iic_set_vdda(0, 0x0);
    iic_set_vddd(0, 0x0);
    axil_write_register(SCOPE_GLOBAL+C_ADDR_GLOBAL_ENABLES, 0x0);
  } else {
    printf("setting VDDA and VDDD to nominal for ASIC \r\n");
    iic_set_vdda(0, 0xE2FF);
    //iic_set_vddd(0, 0x6DFF);
    iic_set_vddd(0, 0x75FF);
    axil_write_register(SCOPE_GLOBAL+C_ADDR_GLOBAL_ENABLES, 0x00010001);
  }
}

void asic_batch_tx(hw_u32_t * payload, hw_u32_t n){
  unsigned count = 0;
  hw_addr_t nxta;

  while((count < n) && (dma_next_available_tx_bd(&nxta))){
    printf("INFO:  working on buffer %d at HW addr 0x%08X \r\n", count, nxta);
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
  printf("INFO:  sending batch of %d TX buffers \r\n", count);
  dma_tx_batch();

  // NOTE: the IOC fires on the first complete transfer, so this only confirms one buffer was sent
  if (dma_wait_tx_ioc(DMA_TIMEOUT) > 0){
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

void asic_print(hw_u32_t * word){
  //printf("raw word: 0x%08X %08X\r\n", word[1], word[0]);

  unsigned wt = word[0]&0x3;
  if (wt == 2){
    printf("config write:  ");
  }else if (wt == 3){
    printf("config read:   ");
  }else{
    printf("skipping...\r\n");
    return;
  }
  hw_u8_t chip = (word[0]>>2)&0xFF;
  printf("chip: %03u ", chip);

  if ((wt == 2) || (wt == 3)) {
    hw_u8_t addr  = (word[0]>>10)&0xFF;
    printf("addr: 0x%02X (%03u) ", addr, addr);

    hw_u8_t value = (word[0]>>18)&0xFF;
    printf("value: 0x%02X (%03u) ", value, value);

    hw_u32_t magic = (word[0]>>26)&0x3F;
    magic |= ((word[1]&0x03FFFFFF)<<6);
    printf("magic: 0x%08X ", magic);

    if (magic == 0x89504E47) {
      printf("(valid) ");
    } else {
      printf("INVALID ");
    }

    if ((word[1]>>30)&1) {
      printf(" downstream ");
    } else {
      printf(" upstream   ");
    }

    hw_u32_t pbit = ((word[1]>>31)&1);
    printf(" parity bit: %u ", pbit);

    if (asic_calc_parity(word)) {
      printf("(valid) ");
    } else {
      printf("INVALID ");
    }
  }


  printf("\r\n");
}

void asic_root_chip_id(){
  printf("INFO:  setting root chip id to 11... \r\n");

  const unsigned MAX_NUM_WORDS = 20;
  unsigned NUM_WORDS;
  hw_u32_t payload[2*MAX_NUM_WORDS];

  NUM_WORDS = 1;
  // set chip id to 11:
  asic_config_write(&payload[0], 1,  122, 0xB);

  for (unsigned i=0; i< NUM_WORDS; i++){
    asic_print(&payload[2*i]);
  }

  printf("INFO sending... \n");
  asic_batch_tx(payload, NUM_WORDS);
}

void asic_config_root(){
  printf("INFO:  running ASIC config root chip... \r\n");

  const unsigned MAX_NUM_WORDS = 20;
  unsigned NUM_WORDS;
  hw_u32_t payload[2*MAX_NUM_WORDS];

  NUM_WORDS = 1;
  // set chip id to 4:
  asic_config_write(&payload[0], 1,  122, 0xB);

  for (unsigned i=0; i< NUM_WORDS; i++){
    asic_print(&payload[2*i]);
  }

  printf("INFO sending... \n");
  asic_batch_tx(payload, NUM_WORDS);

  usleep(10000);

  NUM_WORDS = 12;
  // set various enables:
  asic_config_write(&payload[0], 11, 123, 0xC0);
  // i_rx 0-1
  asic_config_write(&payload[2], 11, 243, 0x77);
  // r_term1
  asic_config_write(&payload[4], 11, 248, 0x07);
  // enable POSI
  asic_config_write(&payload[6], 11, 126, 0x2);
  // enable tx_slices 0-3
  asic_config_write(&payload[8], 11, 239, 0x77);
  asic_config_write(&payload[10], 11, 240, 0x77);
  // tx_diff 0-3
  asic_config_write(&payload[12], 11, 241, 0x77);
  asic_config_write(&payload[14], 11, 242, 0x77);
  //common mode
  asic_config_write(&payload[16], 11, 254, 0x55);
  asic_config_write(&payload[18], 11, 255, 0x55);
  //piso downstream:
  asic_config_write(&payload[20], 11, 125, 0xF);
  //piso upstream:
  asic_config_write(&payload[22], 11, 124, 0x0);

  for (unsigned i=0; i< NUM_WORDS; i++){
    asic_print(&payload[2*i]);
  }

  printf("INFO sending... \n");
  asic_batch_tx(payload, NUM_WORDS);
}

void asic_read_all(){
  printf("INFO:  reading all ASIC registers... \r\n");

  const unsigned MAX_NUM_WORDS = 512;
  hw_u32_t payload[2*MAX_NUM_WORDS];

  unsigned NUM_WORDS = 256;

  for (unsigned i=0; i<NUM_WORDS; i++){
    asic_config_read(&payload[2*i], 11, i);

    for (unsigned i=0; i< NUM_WORDS; i++){
      asic_print(&payload[2*i]);
    }

    printf("INFO sending... \n");
    asic_batch_tx(payload, NUM_WORDS);
  }
}

void asic_hello(){
  printf("INFO:  running ASIC hello... \r\n");

  const unsigned MAX_NUM_WORDS = 20;
  hw_u32_t payload[2*MAX_NUM_WORDS];

  unsigned NUM_WORDS = 1;

  //piso downstream:
  asic_config_read(&payload[0], 11, 122);

  for (unsigned i=0; i< NUM_WORDS; i++){
    asic_print(&payload[2*i]);
  }

  printf("INFO sending... \n");
  asic_batch_tx(payload, NUM_WORDS);

}
