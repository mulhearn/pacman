#include <stdlib.h>

#include "hw_access.h"
#include "global.h"
#include "iic.h"
#include "dma.h"
#include "rxtx.h"
#include "asic.h"
#include "asic_menu.h"


static int CHIP_ID = 11;

void asic_toggle_chip_id(){
  static int mode = 0;
  mode = (mode + 1) % 5;

  int chip_id_vals[] = {11,12,13,14,255};

  printf("INFO:  setting chip ID to %d\r\n", chip_id_vals[mode]);
  CHIP_ID = chip_id_vals[mode];
}

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

void asic_toggle_version(){
  static int mode = 0;
  mode = (mode + 1) % 2;

  if (mode == 0) {
    printf("setting ASIC version to unknown \r\n");
    asic_set_version(UNKNOWN);
  } else {
    printf("setting ASIC version to LArPix v3 \r\n");
    asic_set_version(LARPIX_V3);
  }
}

void asic_toggle_power(){
  static int mode = 0;
  mode = (mode + 1) % 2;

  if (mode == 0) {
    printf("setting VDDA and VDDD to zero \r\n");
    iic_set_vdda_dn(0, 0x0);
    iic_set_vddd_dn(0, 0x0);
    axil_write_register(SCOPE_GLOBAL+C_ADDR_GLOBAL_ENABLES, 0x0);
  } else {
    printf("setting VDDA and VDDD to nominal for ASIC \r\n");
    iic_set_vdda_dn(0, 0xE2FF);
    //iic_set_vddd_dn(0, 0x6DFF);
    iic_set_vddd_dn(0, 0x75FF);
    axil_write_register(SCOPE_GLOBAL+C_ADDR_GLOBAL_ENABLES, 0x00010001);
  }
}

void asic_toggle_rx_uart_enables(){
  static int mode = 0;
  mode = (mode + 1) % 5;

  if (mode == 0) {
    printf("INFO: enabling all RX UARTS\r\n");
    for (unsigned chan=0; chan<40; chan++){
      rx_enable_uart(chan);
    }
  } else if (mode == 1) {
    printf("INFO: disabling all RX UARTS\r\n");
    for (unsigned chan=0; chan<40; chan++){
      rx_disable_uart(chan);
    }
  } else if (mode == 2) {
    printf("INFO: enabling only UART chan=0\r\n");
    rx_enable_uart(0);
    for (unsigned chan=1; chan<40; chan++){
      rx_disable_uart(chan);
    }
  } else if (mode == 3) {
    printf("INFO: enabling only UART channels 0 and 1\r\n");
    rx_enable_uart(0);
    rx_enable_uart(1);
    for (unsigned chan=2; chan<40; chan++){
      rx_disable_uart(chan);
    }
  } else {
    printf("INFO: enabling only UART channels 0-3\r\n");
    rx_enable_uart(0);
    rx_enable_uart(1);
    rx_enable_uart(2);
    rx_enable_uart(3);
    for (unsigned chan=4; chan<40; chan++){
      rx_disable_uart(chan);
    }
  }
}

void asic_config_root(){
  printf("INFO:  running ASIC config root chip... \r\n");

  const unsigned MAX_NUM_WORDS = 20;
  unsigned NUM_WORDS;
  hw_u32_t payload[2*MAX_NUM_WORDS];

  NUM_WORDS = 1;
  // set chip id to 11:
  asic_config_write(&payload[0], 1,  122, CHIP_ID);

  for (unsigned i=0; i< NUM_WORDS; i++){
    asic_print_packet_summary(&payload[2*i]);
  }

  printf("INFO sending... \n");
  asic_batch_tx(payload, NUM_WORDS);

  usleep(10000);

  NUM_WORDS = 12;
  // set various enables:
  asic_config_write(&payload[0], CHIP_ID, 123, 0xC0);
  // i_rx 0-1
  asic_config_write(&payload[2], CHIP_ID, 243, 0x77);
  // r_term1
  asic_config_write(&payload[4], CHIP_ID, 248, 0x07);
  // enable POSI
  asic_config_write(&payload[6], CHIP_ID, 126, 0x2);
  // enable tx_slices 0-3
  asic_config_write(&payload[8], CHIP_ID, 239, 0x77);
  asic_config_write(&payload[10], CHIP_ID, 240, 0x77);
  // tx_diff 0-3
  asic_config_write(&payload[12], CHIP_ID, 241, 0x77);
  asic_config_write(&payload[14], CHIP_ID, 242, 0x77);
  //common mode
  asic_config_write(&payload[16], CHIP_ID, 254, 0x55);
  asic_config_write(&payload[18], CHIP_ID, 255, 0x55);
  //piso downstream:
  asic_config_write(&payload[20], CHIP_ID, 125, 0xF);
  //piso upstream:
  asic_config_write(&payload[22], CHIP_ID, 124, 0x0);

  for (unsigned i=0; i< NUM_WORDS; i++){
    asic_print_packet_summary(&payload[2*i]);
  }

  printf("INFO sending... \n");
  asic_batch_tx(payload, NUM_WORDS);
}

void asic_request_read_all(){

  printf("INFO:  requesting read of all ASIC registers... \r\n");

  const unsigned MAX_NUM_WORDS = 512;
  hw_u32_t payload[2*MAX_NUM_WORDS];

  unsigned NUM_WORDS = 256;

  for (unsigned i=0; i<NUM_WORDS; i++){
    asic_config_read(&payload[2*i], CHIP_ID, i);
  }

  for (unsigned i=0; i< NUM_WORDS; i++){
    asic_print_packet_summary(&payload[2*i]);
  }

  printf("INFO sending... \n");
  asic_batch_tx(payload, NUM_WORDS);

}

void asic_hello(){
  printf("INFO:  running ASIC hello... \r\n");

  const unsigned MAX_NUM_WORDS = 20;
  hw_u32_t payload[2*MAX_NUM_WORDS];

  unsigned NUM_WORDS = 1;

  //piso downstream:
  asic_config_read(&payload[0], CHIP_ID, 122);

  for (unsigned i=0; i< NUM_WORDS; i++){
    asic_print_packet_summary(&payload[2*i]);
  }

  printf("INFO sending... \n");
  asic_batch_tx(payload, NUM_WORDS);
}

void asic_read_rx(){
  unsigned verbose = 0;
  unsigned count = 0;
  hw_addr_t nxta;
  hw_u64_t start = 0;
  (void) start;

  while(dma_next_available_rx_bd(&nxta)){
    unsigned xbytes = dma_poll_bd_transferred(nxta);
    if ( (xbytes < RX_TRAILER_BYTES) || (! dma_poll_bd_complete(nxta))){
      printf("ERROR: incomplete buffer encountered... skipping.\r\n");
      dma_add_rx_bd(nxta);
      continue;
    }
    unsigned words = (xbytes - RX_TRAILER_BYTES) / RX_WORD_BYTES;
    if (verbose)
      printf("INFO: received packet with %d RX 192-bit words\r\n", words);
    hw_ptr_t buf = dma_get_buffer(nxta);

    // check DMA packet trailer:
    hw_u32_t * trailer = (hw_u32_t *) &buf[6*words];

    if (((trailer[0]&0xFF) != 0x4C) || (trailer[2] != words)){
      printf("ERROR: invalid trailer detected in DMA packet... skipping.\r\n");
      printf("DMA packet tailer: 0x%x %x 0x%x %x 0x%x %x\r\n",
	     (unsigned int) trailer[5], (unsigned int) trailer[4], (unsigned int) trailer[3],
	     (unsigned int) trailer[2], (unsigned int) trailer[1], (unsigned int) trailer[0]);
      dma_add_rx_bd(nxta);
      continue;
    } else if (verbose) {
      printf("DMA packet tailer: 0x%x %x 0x%x %x 0x%x %x\r\n",
	     (unsigned int) trailer[5], (unsigned int) trailer[4], (unsigned int) trailer[3],
	     (unsigned int) trailer[2], (unsigned int) trailer[1], (unsigned int) trailer[0]);
    }

    for (unsigned i=0; i<words; i++){
      hw_u32_t * word = (hw_u32_t *) &buf[6*i];
      hw_u64_t timestamp = (((hw_u64_t) word[3])<<32) | word[2];
      if (start == 0)
	start = timestamp;
      if (verbose)
	printf("asic packet: 0x%x %x timestamp: 0x%x %x header: 0x%x %x\r\n",
	       (unsigned int) word[5], (unsigned int) word[4], (unsigned int) word[3],
	       (unsigned int) word[2], (unsigned int) word[1], (unsigned int) word[0]);
      printf("elapsed t: 0x%08lx ", (unsigned long) (timestamp - start));
      asic_print_packet_summary(&word[4]);
    }
    count++;
    dma_add_rx_bd(nxta);
  }

  printf("INFO:  sending batch of %d RX buffers \r\n", count);
  dma_rx_batch();
}

void asic_loopback(){
  const unsigned MAX_REGISTERS = 8;
  const unsigned NUM_TESTS     = 10;
  const unsigned NUM_READS     = 10;

  hw_u32_t payload[2*NUM_READS*MAX_REGISTERS];
  hw_u8_t  values[MAX_REGISTERS];

  unsigned addr_chan_mask = 131;
  unsigned num_chan_mask = 8;

  unsigned asic_packets  = 0;
  unsigned dma_packets   = 0;
  unsigned count_errors  = 0;

  start_hw_timer();
  for (unsigned test=0; test<NUM_TESTS; test++){

    for (unsigned i=0; i<num_chan_mask; i++){
      values[i] = rand() & 0xFF;
      asic_config_write(&payload[2*i], CHIP_ID, addr_chan_mask+i, values[i]);
    }
    asic_batch_tx(payload, num_chan_mask);

    for (unsigned o=0; o<NUM_READS; o++){
      for (unsigned i=0; i<num_chan_mask; i++){
	asic_config_read(&payload[2*num_chan_mask*o+2*i], CHIP_ID, addr_chan_mask+i);
      }
    }
    asic_batch_tx(payload, NUM_READS*num_chan_mask);

    unsigned timeout = 100000;
    unsigned reps    = 0;

    while((timeout>0) && (reps < NUM_READS*num_chan_mask)){
      hw_addr_t nxta;
      while(dma_next_available_rx_bd(&nxta)){
	unsigned xbytes = dma_poll_bd_transferred(nxta);
	if ( (xbytes < RX_TRAILER_BYTES) || (! dma_poll_bd_complete(nxta))){
	  printf("ERROR: incomplete buffer encountered... skipping.\r\n");
	  dma_add_rx_bd(nxta);
	  continue;
	}
	unsigned words = (xbytes - RX_TRAILER_BYTES) / RX_WORD_BYTES;
	hw_ptr_t buf = dma_get_buffer(nxta);

	// check DMA packet trailer:
	hw_u32_t * trailer = (hw_u32_t *) &buf[6*words];
	if (((trailer[0]&0xFF) != 0x4C) || (trailer[2] != words)){
	  printf("ERROR: invalid trailer detected in DMA packet... skipping.\r\n");
	  printf("DMA packet tailer: 0x%x %x 0x%x %x 0x%x %x\r\n",
		 (unsigned int) trailer[5], (unsigned int) trailer[4], (unsigned int) trailer[3],
		 (unsigned int) trailer[2], (unsigned int) trailer[1], (unsigned int) trailer[0]);
	  dma_add_rx_bd(nxta);
	  continue;
	}
	for (unsigned i=0; i<words; i++){
	  hw_u32_t * word = (hw_u32_t *) &buf[6*i];
	  unsigned wt   = buf[0] & 0xFF;
	  unsigned chan = (buf[0] >> 16) & 0xFFFF;

	  if ( (wt != 0x44) && (wt != 0x43)){
	    continue;
	  }
	  if ( chan != 1 ){
	    continue;
	  }
	  //printf("expecting:  0x%02X ", values[reps]);
	  //asic_print_packet_summary(&word[4]);
	  if (values[reps%num_chan_mask] != asic_config_get_value(&word[4]))
	    count_errors++;
	  reps++;
	}
	dma_packets++;
	dma_add_rx_bd(nxta);
      }
      dma_rx_batch();
      usleep(1);
      timeout--;
    }
    if (timeout == 0) {
      printf("ERROR: timeout waiting on read back.  Replies:  %d \r\n", reps);
      stop_hw_timer();
      return;
    }
    asic_packets += reps;
  }
  stop_hw_timer();
  unsigned elapsed_us = hw_timer_elapsed_us();
  printf("RESULTS:  dma_packets: %u asic_packets: %u errors: %u time: %u us\r\n", dma_packets, asic_packets, count_errors, elapsed_us);
}


void asic_menu(){
  printf("ASIC menu:  \r\n");
  while(1){
    printf("choose an option:\r\n");
    printf("(x) Exit ASIC menu\r\n");
    printf("(v) toggle ASIC version (u) toggle RX UART enables (p) toggle ASIC power\r\n");
    printf("(f) send full reset (i) send internal reset (c) config root chip \r\n");
    printf("(a) request all registers (h) hello ASIC (r) read RX \r\n");
    printf("(l) run ASIC loopback test (d) toggle chip id \r\n");
    char input = input_choice();
    printf("INFO: selected %c\r\n", input);

    switch(input){
    case 'x':
      return;
    case 'v':
      asic_toggle_version();
      break;
    case 'u':
      asic_toggle_rx_uart_enables();
      break;
    case 'p':
      asic_toggle_power();
      break;
    case 'f':
      asic_full_reset();
      break;
    case 'i':
      asic_internal_reset();
      break;
    case 'c':
      asic_config_root();
      break;
    case 'a':
      asic_request_read_all();
      break;
    case 'h':
      asic_hello();
      break;
    case 'd':
      asic_toggle_chip_id();
      break;
    case 'r':
      asic_read_rx();
      break;
    case 'l':
      asic_loopback();
      break;
    default:
      printf("invalid selection...\r\n");
    }
  }

}
