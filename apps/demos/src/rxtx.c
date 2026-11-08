#include <stdlib.h>

#include "hw_access.h"
#include "dma.h"
#include "global.h"
#include "asic.h"
#include "rxtx.h"

hw_val_t tx_mask_b = 0xFF;
hw_val_t tx_mask_a = 0xFFFFFFFF;

static unsigned G_TX_COUNTER = 0;

void init_rxtx(void){
  dma_platform_init();
  dma_platform_init_buffer(DMA_BUFFER_BASEADDR, DMA_BUFFER_SIZE);
  dma_init_batch_tx_taildesc(TX_BATCH_NEXTDESC_ADDR);
  dma_init_batch_rx_taildesc(RX_BATCH_NEXTDESC_ADDR);
}

void init_tx_descriptor_ring_mode(int ring_size){
  printf("INFO:  initializing TX BD ring:\r\n");
  dma_init_bd_ring(TX_BD_BASEADDR, ring_size, TX_PACKET_BYTES, DMA_BD_CONTROL_SOF | DMA_BD_CONTROL_EOF, DMA_BD_STATUS_COMPLETE);

  dma_write_tx_curdesc(TX_BD_BASEADDR);
  dma_write_tx_taildesc(TX_BD_BASEADDR);

  dma_write_batch_tx_taildesc(TX_BD_BASEADDR);

  dma_run_tx(DMA_TIMEOUT);

  // send initial empty TX
  dma_clear_bd_status(TX_BD_BASEADDR);
  dma_write_tx_taildesc(TX_BD_BASEADDR);
}

void init_rx_descriptor_ring_mode(int ring_size){
  printf("INFO:  initializing RX BD ring:\r\n");
  dma_init_bd_ring(RX_BD_BASEADDR, ring_size, RX_BUF_BYTES, 0, 0);

  dma_write_rx_curdesc(dma_get_next_bd_addr(RX_BD_BASEADDR));
  dma_write_rx_taildesc(RX_BD_BASEADDR);

  dma_write_batch_rx_taildesc(RX_BD_BASEADDR);

  dma_run_rx(DMA_TIMEOUT);

  dma_write_rx_taildesc(RX_BD_BASEADDR);
}

void init_rxtx_descriptor_ring_mode(int ring_size){
  dma_reset_tx(DMA_TIMEOUT);
  dma_reset_rx(DMA_TIMEOUT);
  init_tx_descriptor_ring_mode(ring_size);
  init_rx_descriptor_ring_mode(ring_size);
}

void show_rxtx_bds(void){
  printf("INFO:  TX BD:\r\n");
  dma_show_bd_ring(TX_BD_BASEADDR);
  printf("INFO:  RX BD:\r\n");
  dma_show_bd_ring(RX_BD_BASEADDR);
}

void show_rxtx_head_tail(void){
  dma_show_tx_current_tail_addrs();
  dma_show_rx_current_tail_addrs();
}

void clear_rxtx_ioc(void){
  printf("INFO:  clearing DMA TX IOC flag.\r\n");
  dma_clear_tx_ioc();
  printf("INFO:  clearing DMA RX IOC flag\r\n");
  dma_clear_rx_ioc();
}

void show_tx_buffer(void){
  printf("INFO:  TX Buffer:\r\n");
  dma_show_buffer_ring(TX_BD_BASEADDR, 6, 1000);
}

void show_rx_buffer(void){
  printf("INFO:  RX Buffer:\r\n");
  dma_show_buffer_ring(RX_BD_BASEADDR, 6, 1000);
}

void show_rx_transferred(void){
  printf("INFO:  RX Buffer:\r\n");
  dma_show_transferred_ring(RX_BD_BASEADDR, 6, 1000);
}

void single_tx(void){
  // TX buffer is a 128 bit header plus 40 uarts allocated 64 bits each.
  // This is a total of 84 32-bit words (4 header words, 80 uart words)
  // The resulting AXI stream is 128 bits times 21 beats.

  hw_addr_t nxta = dma_get_next_bd_addr(dma_read_tx_taildesc());
  // keep batch tail synced even when doing single buffers:
  dma_write_batch_tx_taildesc(nxta);

  hw_ptr_t tx_buf = dma_get_buffer(nxta);

  tx_buf[0]= tx_mask_a;
  tx_buf[1]= tx_mask_b;

  for (int i=0; i<TX_PAYLOAD_U32_WORDS; i++)
    tx_buf[i+TX_HEADER_U32_WORDS] = 0xB000F000 + i + (G_TX_COUNTER<<16);
  G_TX_COUNTER++;

  HW_FLUSH_DCACHE(tx_buf, TX_PACKET_BYTES);
  dma_clear_tx_ioc();
  dma_clear_bd_status(nxta);
  dma_write_tx_taildesc(nxta);

  if (dma_wait_tx_ioc(DMA_TIMEOUT) > 0){
    printf("INFO: single TX yielded TX IOC flag high (SUCCESS)\r\n");
  }
}

void single_rx(void){
  hw_addr_t nxta = dma_get_next_bd_addr(dma_read_rx_taildesc());

  if (dma_read_bd_status(nxta) & DMA_BD_STATUS_COMPLETE){
    printf("INFO:  RX success.\r\n");
    // keep batch tail synced even when doing single buffers:
    dma_write_batch_rx_taildesc(nxta);
    dma_clear_bd_status(nxta);
    dma_write_rx_taildesc(nxta);
  } else {
    printf("INFO:  nothing RXed.\r\n");
  }
}

void batch_tx(void){
  unsigned count = 0;
  hw_addr_t nxta;

  while((count < 10) && (dma_next_available_tx_bd(&nxta))){
    printf("INFO:  working on buffer %d at HW addr 0x%08X \r\n", count, (unsigned int) nxta);
    hw_ptr_t tx_buf = dma_get_buffer(nxta);

    tx_buf[0]= tx_mask_a;
    tx_buf[1]= tx_mask_b;

    for (int i=0; i<TX_PAYLOAD_U32_WORDS; i++)
      tx_buf[i+TX_HEADER_U32_WORDS] = 0xB000F000 + i + (G_TX_COUNTER<<16);
    HW_FLUSH_DCACHE(tx_buf, TX_PACKET_BYTES);

    dma_add_tx_bd(nxta);
    count++;
    G_TX_COUNTER++;
  }

  dma_clear_tx_ioc();
  printf("INFO:  sending batch of %d TX buffers \r\n", count);
  dma_tx_batch();

  // NOTE: the IOC fires on the first complete transfer, so this only confirms one buffer was sent
  if (dma_wait_tx_ioc(DMA_TIMEOUT) > 0){
    printf("INFO:  batch TX yielded TX IOC flag high (SUCCESS)\r\n");
  }
}

void batch_rx(void){
  unsigned count = 0;
  hw_addr_t nxta;

  while((count < 10) && dma_next_available_rx_bd(&nxta)){
    // do work on buffer ...
    count++;
    dma_add_rx_bd(nxta);
  }

  printf("INFO:  sending batch of %d RX buffers \r\n", count);
  dma_rx_batch();
}


void benchmark_dma_tx();
void benchmark_dma_rxtx_loopback();


void toggle_tx_config(void){
  static int mode = 0;
  mode = (mode + 1) % 4;
  if (mode==0){
    unsigned config = 0x00001602;
    printf("INFO: Half speed.  Broadcasting tx config write 0x%08x \r\n", (unsigned int) config);
    axil_write_register(SCOPE_TX+UART_BROADCAST+C_ADDR_TX_UART_CONFIG, config);
  } else if (mode==1) {
    unsigned config = 0x05281602;
    printf("INFO: Half Speed with max 50 percent duty cycle (delay 0x528)  Broadcasting tx config write 0x%08x \r\n", (unsigned int) config);
    axil_write_register(SCOPE_TX+UART_BROADCAST+C_ADDR_TX_UART_CONFIG, config);
  } else if (mode==2) {
    unsigned config = 0x00001601;
    printf("INFO: Full speed.  Broadcasting tx config write 0x%08x \r\n", (unsigned int) config);
    axil_write_register(SCOPE_TX+UART_BROADCAST+C_ADDR_TX_UART_CONFIG, config);
  } else if (mode==3) {
    unsigned config = 0x05281601;
    printf("INFO: Full speed with max 33 percent duty (delay 0x528).  Broadcasting tx config write 0x%08x \r\n", (unsigned int) config);
    axil_write_register(SCOPE_TX+UART_BROADCAST+C_ADDR_TX_UART_CONFIG, config);
  }
  
}

void rx_disable_uart(unsigned chan){
  if (chan < 40){
    hw_u32_t cfg = axil_read_register(SCOPE_RX+(chan<<8)+C_ADDR_RX_UART_CONFIG);
    // for the particular config value of "11" the AND step could be skipped, but let's not:
    cfg &= (~0x00030000);
    cfg |=   0x00030000;
    axil_write_register(SCOPE_RX+(chan<<8)+C_ADDR_RX_UART_CONFIG, cfg);
  }
}

void rx_enable_uart(unsigned chan){
  if (chan < 40){
    hw_u32_t cfg = axil_read_register(SCOPE_RX+(chan<<8)+C_ADDR_RX_UART_CONFIG);
    // for the particular config value of "00" the OR step could be skipped, but let's not:
    cfg &= (~0x00030000);
    cfg |=   0x00000000;
    axil_write_register(SCOPE_RX+(chan<<8)+C_ADDR_RX_UART_CONFIG, cfg);
  }
}

bool rx_uart_is_enabled(unsigned chan){
  if (chan < 40){
    hw_u32_t cfg = axil_read_register(SCOPE_RX+(chan<<8)+C_ADDR_RX_UART_CONFIG);
    if ((cfg&0x00020000) == 0) {
      return true;
    }
  }
  return false;
}



void toggle_rx_config(void){
  static int mode = 0;
  mode = (mode + 1) % 6;
  if (mode==0){
    unsigned config = 0x00001002;
    printf("INFO: Half speed, no internal loopback.  Broadcasting rx config write 0x%08x \r\n", (unsigned int) config);
    axil_write_register(SCOPE_RX+UART_BROADCAST+C_ADDR_RX_UART_CONFIG, config);
  } else if (mode==1) {
    unsigned config = 0x00011002;
    printf("INFO: Half speed, full internal loopback.  Broadcasting rx configs write 0x%08x \r\n", config);
    axil_write_register(SCOPE_RX+UART_BROADCAST+C_ADDR_RX_UART_CONFIG, config);
  } else if (mode==2) {
    unsigned config = 0x00001001;
    printf("INFO: Full speed, no internal loopback.  Broadcasting rx configs write 0x%08x \r\n", (unsigned int) config);
    axil_write_register(SCOPE_RX+UART_BROADCAST+C_ADDR_RX_UART_CONFIG, config);
  } else if (mode==3) {
    unsigned config = 0x00011001;
    printf("INFO: Full speed, full internal loopback.  Broadcasting rx configs write 0x%08x \r\n", (unsigned int) config);
    axil_write_register(SCOPE_RX+UART_BROADCAST+C_ADDR_RX_UART_CONFIG, config);    
  } else if (mode==4) {
    unsigned config;
    config = 0x00011002;
    printf("INFO: Half speed, tiles 2-10 use internal loopback.  Broadcasting rx configs t 0x%08x \r\n", (unsigned int) config);
    axil_write_register(SCOPE_RX+UART_BROADCAST+C_ADDR_RX_UART_CONFIG, config);
    config = 0x00001002;
    printf("INFO: Tile 1 does not use internal loopback.  Setting Tile 1 rx config 0x%08x \r\n", (unsigned int) config);
    axil_write_register(SCOPE_RX+(0<<8)+C_ADDR_RX_UART_CONFIG, config);
    axil_write_register(SCOPE_RX+(1<<8)+C_ADDR_RX_UART_CONFIG, config);
    axil_write_register(SCOPE_RX+(2<<8)+C_ADDR_RX_UART_CONFIG, config);
    axil_write_register(SCOPE_RX+(3<<8)+C_ADDR_RX_UART_CONFIG, config);
  } else if (mode==5) {
    unsigned config;
    config = 0x00011001;
    printf("INFO: Full speed, tiles 2-10 use internal loopback.  Broadcasting rx configs t 0x%08x \r\n", (unsigned int) config);
    axil_write_register(SCOPE_RX+UART_BROADCAST+C_ADDR_RX_UART_CONFIG, config);
    config = 0x00001001;
    printf("INFO: Tile 1 does not use internal loopback.  Setting Tile 1 rx config 0x%08x \r\n", (unsigned int) config);
    axil_write_register(SCOPE_RX+(0<<8)+C_ADDR_RX_UART_CONFIG, config);
    axil_write_register(SCOPE_RX+(1<<8)+C_ADDR_RX_UART_CONFIG, config);
    axil_write_register(SCOPE_RX+(2<<8)+C_ADDR_RX_UART_CONFIG, config);
    axil_write_register(SCOPE_RX+(3<<8)+C_ADDR_RX_UART_CONFIG, config);
  }
}

void toggle_rx_buffer_config(void){
  static int mode = 0;
  mode = (mode + 1) % 4;

  unsigned config[] = {0x00000000, 0x00000001, 0x00000010, 0x00010000, 0x00100000};
  printf("INFO: Setting RX buffer config to 0x%08X \r\n", config[mode]);
  axil_write_register(SCOPE_RX+UART_GLOBAL+C_ADDR_RX_BUFFER_CONFIG, config[mode]);
}

void toggle_rx_buffer_enables(void){
  static int mode = 0;
  mode = (mode + 1) % 4;

  unsigned config[] = {0x3, 0x0, 0x1, 0x2};
  printf("INFO: Setting RX buffer enables to 0x%08X \r\n", config[mode]);
  axil_write_register(SCOPE_RX+UART_GLOBAL+C_ADDR_RX_BUFFER_ENABLES, config[mode]);
}

void read_rx_status(void){
  for (int i=0; i<40; i++){
    unsigned cshift  = (i<<8);
    unsigned status  = axil_read_register(SCOPE_RX+cshift+C_ADDR_RX_UART_STATUS);
    unsigned config  = axil_read_register(SCOPE_RX+cshift+C_ADDR_RX_UART_CONFIG);
    unsigned ichan   = axil_read_register(SCOPE_RX+cshift+C_ADDR_RX_UART_CHAN);
    unsigned starts  = axil_read_register(SCOPE_RX+cshift+C_ADDR_RX_UART_STARTS);
    unsigned beats   = axil_read_register(SCOPE_RX+cshift+C_ADDR_RX_UART_BEATS);
    unsigned updates = axil_read_register(SCOPE_RX+cshift+C_ADDR_RX_UART_UPDATES);
    unsigned lost    = axil_read_register(SCOPE_RX+cshift+C_ADDR_RX_UART_LOST);

    printf("%2d: ch: %2d cfg: 0x%08x status: 0x%08x s: %d b: %d u: %d l: %d\r\n",i, ichan, config, status, starts, beats, updates, lost);
  }
  printf("rx buffer status------------0x%x    \r\n", (unsigned int) axil_read_register(SCOPE_RX+0x3F00+C_ADDR_RX_BUFFER_STATUS));
  printf("rx buffer config------------0x%x    \r\n", (unsigned int) axil_read_register(SCOPE_RX+0x3F00+C_ADDR_RX_BUFFER_CONFIG));
  printf("rx buffer enables-----------0x%x    \r\n", (unsigned int) axil_read_register(SCOPE_RX+0x3F00+C_ADDR_RX_BUFFER_ENABLES));
  printf("rx pacman id----------------0x%x    \r\n", (unsigned int) axil_read_register(SCOPE_RX+0x3F00+C_ADDR_RX_PACMAN));
  printf("FIFO count------------------%d      \r\n", (unsigned int) axil_read_register(SCOPE_RX+0x3F00+C_ADDR_RX_FIFO_CNT));
  printf("FIFO max--------------------%d      \r\n", (unsigned int) axil_read_register(SCOPE_RX+0x3F00+C_ADDR_RX_FIFO_MAX));
  printf("heartbeat config------------0x%x    \r\n", (unsigned int) axil_read_register(SCOPE_RX+0x3F00+C_ADDR_RX_HEARTBEAT_CONFIG));
  printf("sync config-----------------0x%x    \r\n", (unsigned int) axil_read_register(SCOPE_RX+0x3F00+C_ADDR_RX_ROLLOVER_CONFIG));
  printf("word_type_lut---------------0x%x    \r\n", (unsigned int) axil_read_register(SCOPE_RX+0x3F00+C_ADDR_RX_WORD_TYPE_LUT));

  printf("heartbeat header------------0x%x    \r\n", (unsigned int) axil_read_register(SCOPE_RX+0x3F00+C_ADDR_RX_HEARTBEAT_HEADER));
  printf("rollover header-------------0x%x    \r\n", (unsigned int) axil_read_register(SCOPE_RX+0x3F00+C_ADDR_RX_ROLLOVER_HEADER));
  //printf("trigger header--------------0x%x    \r\n", (unsigned int) axil_read_register(SCOPE_RX+0x3F00+C_ADDR_RX_TRIG_HEADER));
  printf("end of packet header--------0x%x    \r\n", (unsigned int) axil_read_register(SCOPE_RX+0x3F00+C_ADDR_RX_EOP_HEADER));
}

void read_rx_look(void){
  hw_u32_t udata[2];
  for (int i=0; i<40; i++){
    axil_write_register(SCOPE_RX+UART_GLOBAL+C_ADDR_RX_LOOK_SELECT, i);
    udata[0] = axil_read_register(SCOPE_RX+UART_GLOBAL+C_ADDR_RX_LOOK_UA);
    udata[1] = axil_read_register(SCOPE_RX+UART_GLOBAL+C_ADDR_RX_LOOK_UB);
    printf("Channel %2d Look:  0x%08x %08x ", i, (unsigned int) udata[1], (unsigned int) udata[0]);
    asic_print_packet_summary(udata);
  }
}

void read_tx_status(void){
  for (int i=0; i<40; i++){
    unsigned cshift = (i<<8);
    unsigned status = axil_read_register(SCOPE_TX+cshift+C_ADDR_TX_UART_STATUS);
    unsigned config = axil_read_register(SCOPE_TX+cshift+C_ADDR_TX_UART_CONFIG);
    unsigned starts = axil_read_register(SCOPE_TX+cshift+C_ADDR_TX_UART_STARTS);
    unsigned beats = axil_read_register(SCOPE_TX+cshift+C_ADDR_TX_UART_BEATS);
    printf("%2d: config: 0x%08x status: 0x%08x starts: %d beats: %d\r\n",i,
	   (unsigned int) config, (unsigned int) status, starts, beats);
  }
  printf("rx buffer status----------- 0x%x    \r\n", (unsigned int) axil_read_register(SCOPE_TX+0x3F00+C_ADDR_TX_BUFFER_STATUS));
}

void read_tx_look(void){
  hw_u32_t udata[2];
  for (int i=0; i<40; i++){
    axil_write_register(SCOPE_TX+UART_GLOBAL+C_ADDR_TX_LOOK_SELECT, i);
    udata[0] = axil_read_register(SCOPE_TX+UART_GLOBAL+C_ADDR_TX_LOOK_UA);
    udata[1] = axil_read_register(SCOPE_TX+UART_GLOBAL+C_ADDR_TX_LOOK_UB);
    printf("Channel %2d Look:  0x%08x %08x ", i, (unsigned int) udata[1], (unsigned int) udata[0]);
    asic_print_packet_summary(udata);
  }
}

void toggle_tx_mask(void){
  static int mode = 0;
  mode = (mode + 1) % 4;
  switch(mode){
  case 1:
    tx_mask_b = 0x0;
    tx_mask_a = 0x0;
    break;
  case 2:
    tx_mask_b = 0x0;
    tx_mask_a = 0x1;
    break;
  case 3:
    tx_mask_b = 0x0;
    tx_mask_a = 0xFFFFFFFF;
    break;
  default:
    tx_mask_b = 0xFF;
    tx_mask_a = 0xFFFFFFFF;
  }
  printf("RX mask:  0x%08x %08x \r\n", (unsigned int) tx_mask_b, (unsigned int) tx_mask_a);
}

void zero_rxtx_counts(void){
  axil_write_register(SCOPE_TX+0x3F00+C_ADDR_TX_ZERO_CNTS, 0x0);
  axil_write_register(SCOPE_RX+0x3F00+C_ADDR_RX_ZERO_CNTS, 0x0);
}


//
// Benchmarks:
//

void benchmark_tx(void){
  // assuming 40 uarts
  const unsigned packets    = 10000; // DMA packets to send
  const unsigned uarts      = 40;
  const unsigned batch_size = 100;

  unsigned tx_sent = 0;

  init_rxtx_descriptor_ring_mode(128);

  start_hw_timer();
  while (tx_sent < packets) {
    unsigned batch_count = 0;
    hw_addr_t nxta = 0;
    while((batch_count < batch_size) && (dma_next_available_tx_bd(&nxta))){
      //printf("INFO:  working on buffer %d at HW addr 0x%08X \r\n", batch_count, nxta);
      hw_ptr_t tx_buf = dma_get_buffer(nxta);

      tx_buf[0]= tx_mask_a;
      tx_buf[1]= tx_mask_b;

      for (int i=0; i<TX_PAYLOAD_U32_WORDS; i++)
	tx_buf[i+TX_HEADER_U32_WORDS] = rand();

      HW_FLUSH_DCACHE(tx_buf, TX_PACKET_BYTES);

      dma_add_tx_bd(nxta);
      batch_count++;
    }
    if (batch_count > 0){
      tx_sent += batch_count;
      dma_tx_batch();
    }
  }
  dma_wait_tx_idle(100000);
  stop_hw_timer();

  unsigned elapsed_us = hw_timer_elapsed_us();

  printf("INFO:  elapsed microseconds:    %d (0x%x)\r\n", elapsed_us, (unsigned int) elapsed_us);
  printf("INFO:  tx payloads per packet:  %d\r\n", uarts);
  printf("INFO:  packets:                 %d\r\n", packets);

  if (elapsed_us == 0)
    return;

  unsigned a = 1000 * uarts * packets / elapsed_us;
  unsigned m = uarts*10000/66;
  unsigned p = uarts*10000/67;

  printf("INFO:  achieved throughput:     %d tx uart packets per ms\r\n", a);
  printf("INFO:  maximum tx rate:         %d tx uart packets (64-bit+2 @ 10 MHz) per ms\r\n", m);
  printf("INFO:  practical max:           %d tx uart packets (64-bit+3 @ 10 MHz) per ms\r\n", p);
}

void benchmark_rxtx_loopback(void){

  const unsigned tx_packets  = 10000; // DMA packets to send
  const unsigned uarts       = 40;    // *** assuming all 40 uarts enabled ***
  const unsigned uart_bytes  = 24;    // 192-bits per uart channel
  const unsigned batch_size  = 100;
  const unsigned rx_expected = uarts * uart_bytes * tx_packets;

  const unsigned timeout = 10000;
  unsigned rx_timeout = timeout;
  unsigned tx_timeout = timeout;
  unsigned tx_sent  = 0;
  unsigned rx_rcvd  = 0;
  unsigned rx_bytes = 0;

  init_rxtx_descriptor_ring_mode(128);

  start_hw_timer();
  while (tx_timeout && rx_timeout && (rx_bytes < rx_expected)){
    if (tx_sent < tx_packets) {
      tx_timeout--;
      unsigned batch_count = 0;
      hw_addr_t nxta = 0;
      while((batch_count < batch_size) && (batch_count < (tx_packets-tx_sent)) && (dma_next_available_tx_bd(&nxta))){
	//printf("INFO:  working on buffer %d at HW addr 0x%08X \r\n", batch_count, nxta);
	hw_ptr_t tx_buf = dma_get_buffer(nxta);

	tx_buf[0]= tx_mask_a;
	tx_buf[1]= tx_mask_b;

	//for (int i=0; i<TX_PAYLOAD_U32_WORDS; i++)
	//  tx_buf[i+TX_HEADER_U32_WORDS] = rand();

	HW_FLUSH_DCACHE(tx_buf, TX_PACKET_BYTES);

	dma_add_tx_bd(nxta);
	batch_count++;
      }
      if (batch_count > 0){
	tx_timeout = timeout;
	tx_sent += batch_count;
	dma_tx_batch();
      }
    }
    {
      rx_timeout--;
      unsigned batch_count = 0;
      hw_addr_t nxta = 0;
      while((batch_count < batch_size) && (dma_next_available_rx_bd(&nxta))){
	unsigned xbytes = dma_poll_bd_transferred(nxta);
	if (xbytes > RX_TRAILER_BYTES){
	  rx_bytes += xbytes - RX_TRAILER_BYTES;
	} else {
	  printf("ERROR: invalid RX packet of size %d bytes found \r\n", xbytes);
	  return;
	}
	batch_count++;
	dma_add_rx_bd(nxta);
      }
      if (batch_count > 0){
	rx_timeout = timeout;
	rx_rcvd += batch_count;
	dma_rx_batch();
      }
    }
  }
  stop_hw_timer();

  printf("INFO:  tx_sent: %d rx_rcvd: %d rx_bytes %d expected: %d \r\n", tx_sent, rx_rcvd, rx_bytes, rx_expected);

  if ((tx_timeout==0) || (rx_timeout==0)){
    printf("ERROR: a timeout occurred during RX/TX benchmark \r\n");
    printf("INFO:  rx_timeout:  %d tx_timeout: %d \r\n", rx_timeout, tx_timeout);
    return;
  }

  unsigned elapsed_us = hw_timer_elapsed_us();

  printf("INFO:  elapsed microseconds:    %d (0x%x)\r\n", elapsed_us, elapsed_us);
  printf("INFO:  tx payloads per packet:  %d\r\n", uarts);
  printf("INFO:  packets:                 %d\r\n", tx_packets);

  if (elapsed_us == 0)
    return;

  unsigned a = 1000 * uarts * tx_packets / elapsed_us;
  unsigned m = uarts*10000/66;
  unsigned p = uarts*10000/67;

  printf("INFO:  achieved throughput:     %d tx uart packets per ms\r\n", a);
  printf("INFO:  maximum tx rate:         %d tx uart packets (64-bit+2 @ 10 MHz) per ms\r\n", m);
  printf("INFO:  practical max:           %d tx uart packets (64-bit+3 @ 10 MHz) per ms\r\n", p);


}
