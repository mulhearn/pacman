#include <stdlib.h>

#include "hw_access.h"
#include "dma.h"
#include "global.h"
#include "rxtx.h"

hw_val_t tx_mask_b = 0xFF;
hw_val_t tx_mask_a = 0xFFFFFFFF;

static unsigned G_TX_COUNTER = 0;

// this is reserved in system-user.dtsi and located within the HP AXI interface for DMA (0x00000000 - 0x3FFFFFFF):
#define DMA_BUFFER_BASEADDR  0x20000000
#define DMA_BUFFER_SIZE      0x10000000  // 256 MB

#define TX_BD_BASEADDR       0x20000000
#define RX_BD_BASEADDR       0x21000000
#define TX_BUF_BYTES 0x150  // 40 uarts x 64 bits => 20 128 bit word plus 1 128 bit header => 21*4*4 = 336 bytes
#define RX_BUF_BYTES 0x400  // More than enough for now...

#define TX_BUF_WORDS TX_BUF_BYTES/4


void init_rxtx(void){
  init_dma_driver();
  init_dma_buffer(DMA_BUFFER_BASEADDR, DMA_BUFFER_SIZE);
}

void init_tx_descriptor_ring_mode(int ring_size){
  dma_reset_tx(DMA_TIMEOUT);

  printf("INFO:  initializing TX BD ring:\r\n");
  dma_init_bd_ring(TX_BD_BASEADDR, ring_size, TX_BUF_BYTES, DMA_BD_CONTROL_SOF | DMA_BD_CONTROL_EOF, DMA_BD_STATUS_COMPLETE);

  dma_write_tx_curdesc(TX_BD_BASEADDR);
  dma_write_tx_taildesc(TX_BD_BASEADDR);
  dma_init_batch_tx_tail(TX_BD_BASEADDR);

  dma_run_tx(DMA_TIMEOUT);

  // send initial empty TX
  dma_clear_bd_status(TX_BD_BASEADDR);
  dma_write_tx_taildesc(TX_BD_BASEADDR);
}

void init_rx_descriptor_ring_mode(int ring_size){
  dma_reset_rx(DMA_TIMEOUT);

  printf("INFO:  initializing RX BD ring:\r\n");
  dma_init_bd_ring(RX_BD_BASEADDR, ring_size, RX_BUF_BYTES, 0, 0);

  dma_write_rx_curdesc(dma_get_next_bd_addr(RX_BD_BASEADDR));
  dma_write_rx_taildesc(RX_BD_BASEADDR);
  dma_init_batch_rx_tail(RX_BD_BASEADDR);

  dma_run_rx(DMA_TIMEOUT);

  dma_write_rx_taildesc(RX_BD_BASEADDR);
}

void init_rxtx_descriptor_ring_mode(int ring_size){
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
  dma_show_buffer_ring(TX_BD_BASEADDR, 4, 1000);
}

void show_rx_buffer(void){
  printf("INFO:  RX Buffer:\r\n");
  dma_show_buffer_ring(RX_BD_BASEADDR, 4, 1000);
}

void show_rx_transferred(void){
  printf("INFO:  RX Buffer:\r\n");
  dma_show_transferred_ring(RX_BD_BASEADDR, 4, 1000);
}

void single_tx(void){
  // TX buffer is a 128 bit header plus 40 uarts allocated 64 bits each.
  // This is a total of 84 32-bit words (4 header words, 80 uart words)
  // The resulting AXI stream is 128 bits times 21 beats.

  hw_addr_t nxta = dma_get_next_bd_addr(dma_read_tx_taildesc());
  // keep batch tail synced even when doing single buffers:
  dma_init_batch_tx_tail(nxta);

  hw_ptr_t tx_buf = dma_get_buffer(nxta);
  unsigned words = TX_BUF_WORDS;

  tx_buf[0]= tx_mask_a;
  tx_buf[1]= tx_mask_b;
  tx_buf[2]=0x00000000;
  tx_buf[3]=0x00000000;

  for (int i=0; i<(words-4); i++)
    tx_buf[i+4] = 0xB000F000 + i + (G_TX_COUNTER<<16);
  G_TX_COUNTER++;

  HW_FLUSH_DCACHE(tx_buf, words*4);
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
    dma_init_batch_rx_tail(nxta);
    dma_clear_bd_status(nxta);
    dma_write_rx_taildesc(nxta);
  } else {
    printf("INFO:  nothing RXed.\r\n");
  }
}

void batch_tx(void){
  unsigned words = TX_BUF_WORDS;
  unsigned count = 0;
  hw_addr_t nxta;

  while((count < 10) && (dma_next_available_tx_bd(&nxta))){
    printf("INFO:  working on buffer %d at HW addr 0x%08X \r\n", count, nxta);
    hw_ptr_t tx_buf = dma_get_buffer(nxta);

    tx_buf[0]= tx_mask_a;
    tx_buf[1]= tx_mask_b;
    tx_buf[2]=0x00000000;
    tx_buf[3]=0x00000000;

    for (int i=0; i<(words-4); i++)
      tx_buf[i+4] = 0xB000F000 + i + (G_TX_COUNTER<<16);
    HW_FLUSH_DCACHE(tx_buf, words*4);

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
  mode = (mode + 1) % 3;
  if (mode==0){
    unsigned config = 0x00001602;
    printf("INFO: No Delay.  Broadcasting tx config write 0x%08x \r\n", config);
    axil_write_register(SCOPE_TX+UART_BROADCAST+C_ADDR_TX_CONFIG, config);
  } else if (mode==1) {
    unsigned config = 0x05281602;
    printf("INFO: Half Speed.  Broadcasting tx config write 0x%08x \r\n", config);
    axil_write_register(SCOPE_TX+UART_BROADCAST+C_ADDR_TX_CONFIG, config);
  } else if (mode==2) {
    unsigned config = 0x00001601;
    printf("INFO: Double speed.  Broadcasting tx config write 0x%08x \r\n", config);
    axil_write_register(SCOPE_TX+UART_BROADCAST+C_ADDR_TX_CONFIG, config);
  }
}

void toggle_rx_config(void){
  static int mode = 0;
  mode = (mode + 1) % 4;
  if (mode==0){
    unsigned config = 0x00001002;
    printf("INFO: No internal loopback.  Broadcasting rx config write 0x%08x \r\n", config);
    axil_write_register(SCOPE_RX+UART_BROADCAST+C_ADDR_RX_CONFIG, config);
  } else if (mode==1) {
    unsigned config = 0x00011002;
    printf("INFO: Full internal loopback.  Broadcasting rx configs write 0x%08x \r\n", config);
    axil_write_register(SCOPE_RX+UART_BROADCAST+C_ADDR_RX_CONFIG, config);
  } else if (mode==2) {
    unsigned config = 0x00011001;
    printf("INFO: Full internal loopback at full speed.  Broadcasting rx configs write 0x%08x \r\n", config);
    axil_write_register(SCOPE_RX+UART_BROADCAST+C_ADDR_RX_CONFIG, config);
  } else if (mode==3) {
    unsigned config;
    config = 0x00011002;
    printf("INFO: Tiles 2-10 use internal loopback.  Broadcasting rx configs t 0x%08x \r\n", config);
    axil_write_register(SCOPE_RX+UART_BROADCAST+C_ADDR_RX_CONFIG, config);
    config = 0x00001002;
    printf("INFO: Tile 1 does not use internal loopback.  Setting Tile 1 rx config 0x%08x \r\n", config);
    axil_write_register(SCOPE_RX+(0<<8)+C_ADDR_RX_CONFIG, config);
    axil_write_register(SCOPE_RX+(1<<8)+C_ADDR_RX_CONFIG, config);
    axil_write_register(SCOPE_RX+(2<<8)+C_ADDR_RX_CONFIG, config);
    axil_write_register(SCOPE_RX+(3<<8)+C_ADDR_RX_CONFIG, config);
  }
}

void toggle_rx_global_config(void){
  static int mode = 0;
  mode = (mode + 1) % 2;
  if (mode==0){
    unsigned config = 0x00000000;
    printf("INFO: Setting RX global config to 0x%08X \r\n", config);
    axil_write_register(SCOPE_RX+UART_GLOBAL+C_ADDR_RX_GFLAGS, config);
  } else if (mode==1) {
    unsigned config = 0x00000001;
    printf("INFO: Setting RX global config to 0x%08X \r\n", config);
    axil_write_register(SCOPE_RX+UART_GLOBAL+C_ADDR_RX_GFLAGS, config);
  }
}

void read_rx_status(void){
  for (int i=0; i<40; i++){
    unsigned cshift = (i<<8);
    unsigned status = axil_read_register(SCOPE_RX+cshift+C_ADDR_RX_STATUS);
    unsigned config = axil_read_register(SCOPE_RX+cshift+C_ADDR_RX_CONFIG);
    unsigned starts  = axil_read_register(SCOPE_RX+cshift+C_ADDR_RX_STARTS);
    unsigned beats   = axil_read_register(SCOPE_RX+cshift+C_ADDR_RX_BEATS);
    unsigned updates = axil_read_register(SCOPE_RX+cshift+C_ADDR_RX_UPDATES);
    unsigned lost    = axil_read_register(SCOPE_RX+cshift+C_ADDR_RX_LOST);
    unsigned nchan  = axil_read_register(SCOPE_RX+cshift+C_ADDR_RX_NCHAN);
    printf("%2d: ch: %2d cfg: 0x%08x status: 0x%08x s: %d b: %d u: %d l: %d\r\n",i, nchan, config, status, starts, beats, updates, lost);
  }
  printf("gstatus----------- 0x%x    \r\n", axil_read_register(SCOPE_RX+0x3F00+C_ADDR_RX_GSTATUS));
  printf("gflags------------ 0x%x    \r\n", axil_read_register(SCOPE_RX+0x3F00+C_ADDR_RX_GFLAGS));
  printf("FIFO R count-------%d      \r\n", axil_read_register(SCOPE_RX+0x3F00+C_ADDR_RX_FRCNT));
  printf("FIFO W count-------%d      \r\n", axil_read_register(SCOPE_RX+0x3F00+C_ADDR_RX_FWCNT));
  printf("DMA ITR------------0x%x    \r\n", axil_read_register(SCOPE_RX+0x3F00+C_ADDR_RX_DMAITR));
}

void read_rx_look(void){
  for (int i=0; i<40; i++){
    unsigned cshift = (i<<8);
    unsigned a = axil_read_register(SCOPE_RX+cshift+C_ADDR_RX_LOOK_A);
    unsigned b = axil_read_register(SCOPE_RX+cshift+C_ADDR_RX_LOOK_B);
    unsigned c = axil_read_register(SCOPE_RX+cshift+C_ADDR_RX_LOOK_C);
    unsigned d = axil_read_register(SCOPE_RX+cshift+C_ADDR_RX_LOOK_D);
    printf("Channel %2d Look:  0x%08x %08x %08x %08x\r\n", i, d, c, b, a);
  }
}

void read_tx_status(void){
  for (int i=0; i<40; i++){
    unsigned cshift = (i<<8);
    unsigned status = axil_read_register(SCOPE_TX+cshift+C_ADDR_TX_STATUS);
    unsigned config = axil_read_register(SCOPE_TX+cshift+C_ADDR_TX_CONFIG);
    unsigned starts = axil_read_register(SCOPE_TX+cshift+C_ADDR_TX_STARTS);
    unsigned nchan  = axil_read_register(SCOPE_TX+cshift+C_ADDR_TX_NCHAN);
    printf("%2d:  chan: %2d config: 0x%08x status: 0x%08x starts: %d\r\n",i, nchan, config, status, starts);
  }
  printf("gflags------------ 0x%x    \r\n", axil_read_register(SCOPE_TX+0x3F00+C_ADDR_TX_GFLAGS));
  printf("bstatus----------- 0x%x    \r\n", axil_read_register(SCOPE_TX+0x3F00+C_ADDR_TX_STATUS));
}

void read_tx_look(void){
  for (int i=0; i<40; i++){
    unsigned cshift = (i<<8);
    unsigned d = axil_read_register(SCOPE_TX+cshift+C_ADDR_TX_LOOK_D);
    unsigned c = axil_read_register(SCOPE_TX+cshift+C_ADDR_TX_LOOK_C);
    printf("Channel %2d Look:  0x%08x %08x\r\n", i, d, c);
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
  printf("RX mask:  0x%08x %08x \r\n", tx_mask_b, tx_mask_a);
}

void zero_rxtx_counts(void){
  axil_write_register(SCOPE_TX+0x3F00+C_ADDR_TX_STARTS, 0x0);
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
  const unsigned words      = TX_BUF_WORDS; // words in TX buffer (= 1 DMA packet)

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
      tx_buf[2]=0x00000000;
      tx_buf[3]=0x00000000;

      //for (int i=0; i<(words-4); i++)
      //tx_buf[i+4] = rand();

      HW_FLUSH_DCACHE(tx_buf, words*4);

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

  printf("INFO:  elapsed microseconds:    %d (0x%x)\r\n", elapsed_us, elapsed_us);
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
  const unsigned uart_bytes  = 16;    // 128-bits per uart channel
  const unsigned batch_size  = 100;
  const unsigned words       = TX_BUF_WORDS; // words in TX buffer (= 1 DMA packet)
  const unsigned rx_expected = uarts * uart_bytes * tx_packets;
  const unsigned rx_trailer_bytes = 16; // Each DMA RX packet has a 128-bit trailer

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
      while((batch_count < batch_size) && (dma_next_available_tx_bd(&nxta))){
	//printf("INFO:  working on buffer %d at HW addr 0x%08X \r\n", batch_count, nxta);
	hw_ptr_t tx_buf = dma_get_buffer(nxta);

	tx_buf[0]= tx_mask_a;
	tx_buf[1]= tx_mask_b;
	tx_buf[2]=0x00000000;
	tx_buf[3]=0x00000000;

	//for (int i=0; i<(words-4); i++)
	//tx_buf[i+4] = rand();

	HW_FLUSH_DCACHE(tx_buf, words*4);

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
	if (xbytes > rx_trailer_bytes){
	  rx_bytes += xbytes - rx_trailer_bytes;
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


  /*

  // DISCLAIMER:  assumes 40 (larpix) packets per DMA TX packet

  const unsigned uarts            = 40;
  const unsigned uart_bytes       = 16;           // 128-bits per uart channel
  const unsigned tx_packets       = 10000;        // DMA TX packets to send
  const unsigned rx_trailer_bytes = 16;           // Each DMA RX packet has a 128-bit trailer
  const unsigned rx_expected = uarts * uart_bytes * tx_packets;


  // prepare the TX buffer with a random payload:
  hw_ptr_t tx_buf = dma_get_buffer(TX_BD_BASEADDR);
  tx_buf[0]= tx_mask_a;
  tx_buf[1]= tx_mask_b;
  tx_buf[2]=0x00000000;
  tx_buf[3]=0x00000000;

  const unsigned words = TX_BUF_WORDS; // words in TX buffer (= 1 DMA packet)
  for (int i=0; i<(words-4); i++)
    tx_buf[i+4] = rand();

  HW_FLUSH_DCACHE(tx_buf, words*4);

  // get pointer to the RX buffer descriptor
  hw_ptr_t rx_bd = dma_ptr(RX_BD_BASEADDR);

  // Inititalize and run TX:
  dma_halt_tx(10*DMA_TIMEOUT);
  dma_clear_bd_status_ring(TX_BD_BASEADDR);
  dma_clear_tx_ioc();
  dma_write_register(MM2S_CURDESC, TX_BD_BASEADDR);
  dma_run_tx(DMA_TIMEOUT);

  // Inititalize and run RX:
  dma_halt_rx(10*DMA_TIMEOUT);
  dma_clear_bd_status_ring(RX_BD_BASEADDR);
  dma_clear_rx_ioc();
  dma_write_register(S2MM_CURDESC, RX_BD_BASEADDR);
  dma_run_rx(DMA_TIMEOUT);

  // Loop until done or a timeout occurs:
  unsigned timeout = 100;
  unsigned rx_timeout = timeout;
  unsigned tx_timeout = timeout;
  unsigned tx_sent = 0;
  unsigned rx_rcvd  = 0;
  unsigned rx_bytes = 0;

  start_hw_timer();

  // start first TX:
  dma_write_register(MM2S_TAILDESC, TX_BD_BASEADDR);
  // start first RX:
  dma_write_register(S2MM_TAILDESC, RX_BD_BASEADDR);

  while (tx_timeout && rx_timeout && (rx_bytes < rx_expected)){
    if (dma_poll_tx_ioc()){
      tx_sent++;
      tx_timeout = timeout;
      dma_clear_bd_status(TX_BD_BASEADDR);
      dma_clear_tx_ioc();
      if (tx_sent < tx_packets)
	dma_write_register(MM2S_TAILDESC, TX_BD_BASEADDR);
    }
    if (dma_poll_rx_ioc()){
      rx_rcvd++;
      unsigned bytes = rx_bd[DMA_BD_STATUS]&DMA_BD_STATUS_TRANSFERRED;
      if (bytes > rx_trailer_bytes)
	rx_bytes += bytes - rx_trailer_bytes;
      rx_timeout = timeout;
      dma_clear_bd_status(RX_BD_BASEADDR);
      dma_clear_rx_ioc();
      // TODO: add condition here that rx_bytes < rx_expected before:
      dma_write_register(S2MM_TAILDESC, RX_BD_BASEADDR);
    }
    rx_timeout--;
    if (tx_sent < tx_packets)
      tx_timeout--;
    usleep(1);
  }
  stop_hw_timer();

  unsigned elapsed_us = hw_timer_elapsed_us();
  printf("INFO:  elapsed microseconds:        %d (0x%x)\r\n", elapsed_us, elapsed_us);
  printf("INFO:  uart payloads per tx packet: %d\r\n", uarts);
  printf("INFO:  tx packets:                  %d\r\n", tx_packets);

  if (elapsed_us == 0)
    return;

  unsigned a = 1000 * uarts * tx_packets / elapsed_us;
  unsigned m = 40.0*10000/66;
  unsigned p = 40.0*10000/67;

  printf("INFO:  achieved throughput:     %d uart packets per ms\r\n", a);
  printf("INFO:  maximum tx rate:         %d uart packets (64-bit+2 @ 10 MHz) per ms\r\n", m);
  printf("INFO:  practical max:           %d uart packets (64-bit+3 @ 10 MHz) per ms\r\n", p);

  */
}


void benchmark_tx_single(void){
  /*
  const unsigned words = TX_BUF_WORDS; // words in TX buffer (= 1 DMA packet)
  const unsigned packets = 10000;        // DMA packets to send

  hw_ptr_t tx_buf = dma_get_buffer(TX_BD_BASEADDR);
  tx_buf[0]= tx_mask_a;
  tx_buf[1]= tx_mask_b;
  tx_buf[2]=0x00000000;
  tx_buf[3]=0x00000000;

  for (int i=0; i<(words-4); i++)
    tx_buf[i+4] = rand();

  HW_FLUSH_DCACHE(tx_buf, words*4);

  dma_halt_tx(DMA_TIMEOUT);
  dma_clear_bd_status(TX_BD_BASEADDR);

  dma_clear_tx_ioc();

  dma_write_register(MM2S_CURDESC, TX_BD_BASEADDR);

  dma_run_tx(DMA_TIMEOUT);

  start_hw_timer();
  unsigned timeout = 0;
  for (int i=0;i<packets; i++){
    dma_clear_bd_status(TX_BD_BASEADDR);
    dma_clear_tx_ioc();
    //usleep(1);
    dma_write_register(MM2S_TAILDESC, TX_BD_BASEADDR);
    timeout = dma_wait_tx_ioc(DMA_TIMEOUT);
    if (timeout==0){
      printf("ERROR: timeout waiting on IOC flag at packet %d \r\n", i);
      return;
    } else if (timeout < 5){
      printf("INFO: timeout %d \r\n", timeout);
    }
  }
  stop_hw_timer();

  unsigned elapsed_us = hw_timer_elapsed_us();
  unsigned uarts = 40;

  printf("INFO:  elapsed microseconds:    %d (0x%x)\r\n", elapsed_us, elapsed_us);
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
  */
}
