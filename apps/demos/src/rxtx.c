#include <stdlib.h>

#include "hw_access.h"
#include "dma.h"
#include "global.h"
#include "rxtx.h"

hw_val_t tx_mask_b = 0xFF;
hw_val_t tx_mask_a = 0xFFFFFFFF;


// this is reserved in system-user.dtsi and located within the HP AXI interface for DMA (0x00000000 - 0x3FFFFFFF):
#define DMA_BUFFER_BASEADDR  0x20000000
#define DMA_BUFFER_SIZE      0x10000000  // 256 MB

#define TX_BD_BASEADDR       0x20000000
#define RX_BD_BASEADDR       0x21000000
#define TX_BUF_BYTES 0x150  // 40 uarts x 64 bits => 20 128 bit word plus 1 128 bit header => 21*4*4 = 336 bytes
#define RX_BUF_BYTES 0x400  // More than enough for now...

void init_rxtx(){
  init_dma_driver();
  init_dma_buffer(DMA_BUFFER_BASEADDR, DMA_BUFFER_SIZE);
}

void init_rxtx_descriptor_ring_mode(){
  dma_reset_tx(DMA_TIMEOUT);
  dma_reset_rx(DMA_TIMEOUT);

  printf("INFO:  initializing TX BD ring:\r\n");
  dma_init_bd_ring(TX_BD_BASEADDR, 8, TX_BUF_BYTES, DMA_BD_CONTROL_SOF | DMA_BD_CONTROL_EOF, 0);
  printf("INFO:  initializing RX BD ring:\r\n");
  dma_init_bd_ring(RX_BD_BASEADDR, 8, RX_BUF_BYTES, 0, 0);

  dma_write_tx_curdesc(TX_BD_BASEADDR);
  dma_write_tx_taildesc(TX_BD_BASEADDR);
  dma_write_rx_curdesc(dma_get_next_bd_addr(RX_BD_BASEADDR));
  dma_write_rx_taildesc(RX_BD_BASEADDR);

  dma_run_tx(DMA_TIMEOUT);
  dma_run_rx(DMA_TIMEOUT);

  dma_write_rx_taildesc(RX_BD_BASEADDR);

  // send initial empty TX
  // writing the registers defeats the protection (hacky hacky ...)
  dma_write_register(MM2S_TAILDESC, TX_BD_BASEADDR);
}

void show_rxtx_bds(){
  printf("INFO:  TX BD:\r\n");
  dma_show_bd_ring(TX_BD_BASEADDR);
  printf("INFO:  RX BD:\r\n");
  dma_show_bd_ring(RX_BD_BASEADDR);
}

void show_rxtx_head_tail(){
  dma_show_tx_current_tail_addrs();
  dma_show_rx_current_tail_addrs();
}

void clear_rxtx_bds(){
  printf("INFO:  clearing TX BD.\r\n");
  dma_clear_bd_status_ring(TX_BD_BASEADDR);
  printf("INFO:  clearing RX BD\r\n");
  dma_clear_bd_status_ring(RX_BD_BASEADDR);
}

void clear_rxtx_ioc(){
  printf("INFO:  clearing DMA TX IOC flag.\r\n");
  dma_clear_tx_ioc();
  printf("INFO:  clearing DMA RX IOC flag\r\n");
  dma_clear_rx_ioc();
}

void show_tx_buffer(){
  printf("INFO:  TX Buffer:\r\n");
  dma_show_buffer_ring(TX_BD_BASEADDR, 4, 1000);
}

void show_rx_buffer(){
  printf("INFO:  RX Buffer:\r\n");
  dma_show_buffer_ring(RX_BD_BASEADDR, 4, 1000);
}

void show_rx_transferred(){
  printf("INFO:  RX Buffer:\r\n");
  dma_show_transferred_ring(RX_BD_BASEADDR, 4, 1000);
}

void single_tx(){
  // TX buffer is a 128 bit header plus 40 uarts allocated 64 bits each.
  // This is a total of 84 32-bit words (4 header words, 80 uart words)
  // The resulting AXI stream is 128 bits times 21 beats.

  hw_addr_t nxta = dma_get_next_bd_addr(dma_read_tx_taildesc());

  static int count = 0;
  hw_ptr_t tx_buf = dma_get_buffer(nxta);
  unsigned words = TX_BUF_BYTES/4;

  tx_buf[0]= tx_mask_a;
  tx_buf[1]= tx_mask_b;
  tx_buf[2]=0x00000000;
  tx_buf[3]=0x00000000;

  for (int i=0; i<(words-4); i++)
    tx_buf[i+4] = 0xB000F000 + i + (count<<16);
  count++;

  HW_FLUSH_DCACHE(tx_buf, words*4);

  dma_clear_bd_status(nxta);
  dma_write_tx_taildesc(nxta);

  if (dma_wait_tx_ioc(DMA_TIMEOUT) > 0){
    printf("INFO: single TX yielded TX IOC flag high (SUCCESS)\r\n");
  }
}

void single_rx(){
  hw_addr_t nxta = dma_get_next_bd_addr(dma_read_rx_taildesc());

  if (dma_read_bd_status(nxta) & DMA_BD_STATUS_COMPLETE){
    printf("INFO:  RX success.\r\n");
    dma_clear_bd_status(nxta);
    dma_write_rx_taildesc(nxta);
  } else {
    printf("INFO:  nothing RXed.\r\n");
  }
}

void benchmark_dma_tx();
void benchmark_dma_rxtx_loopback();


void toggle_tx_config(){
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

void toggle_rx_config(){
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

void toggle_rx_global_config(){
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

void read_rx_status(){
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

void read_rx_look(){
  for (int i=0; i<40; i++){
    unsigned cshift = (i<<8);
    unsigned a = axil_read_register(SCOPE_RX+cshift+C_ADDR_RX_LOOK_A);
    unsigned b = axil_read_register(SCOPE_RX+cshift+C_ADDR_RX_LOOK_B);
    unsigned c = axil_read_register(SCOPE_RX+cshift+C_ADDR_RX_LOOK_C);
    unsigned d = axil_read_register(SCOPE_RX+cshift+C_ADDR_RX_LOOK_D);
    printf("Channel %2d Look:  0x%08x %08x %08x %08x\r\n", i, d, c, b, a);
  }
}

void read_tx_status(){
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

void read_tx_look(){
  for (int i=0; i<40; i++){
    unsigned cshift = (i<<8);
    unsigned d = axil_read_register(SCOPE_TX+cshift+C_ADDR_TX_LOOK_D);
    unsigned c = axil_read_register(SCOPE_TX+cshift+C_ADDR_TX_LOOK_C);
    printf("Channel %2d Look:  0x%08x %08x\r\n", i, d, c);
  }
}

void toggle_tx_mask(){
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

void zero_rxtx_counts(){
  axil_write_register(SCOPE_TX+0x3F00+C_ADDR_TX_STARTS, 0x0);
  axil_write_register(SCOPE_RX+0x3F00+C_ADDR_RX_ZERO_CNTS, 0x0);
}


//
// Benchmarks:
//

void benchmark_tx(){
  const unsigned packets = 10000;        // DMA packets to send
  unsigned tx_chain_size = 10;
  unsigned chains = packets/tx_chain_size;
  unsigned tx_ring_size  = dma_count_bd_ring(TX_BD_BASEADDR);
  if (tx_ring_size < tx_chain_size){
    printf("ERROR: TX ring size %d is smaller than chain size %d\r\n", tx_ring_size, tx_chain_size);
    return;
  }

  hw_addr_t head_addr = TX_BD_BASEADDR;
  hw_addr_t tail_addr = TX_BD_BASEADDR;
  hw_addr_t cur_addr  = TX_BD_BASEADDR;

  unsigned words = TX_BUF_BYTES/4;
  for (int i=0; i<tx_chain_size; i++){
    hw_ptr_t tx_buf = dma_get_buffer(cur_addr);

    tx_buf[0]= tx_mask_a;
    tx_buf[1]= tx_mask_b;
    tx_buf[2]=0x00000000;
    tx_buf[3]=0x00000000;

    for (int i=0; i<(words-4); i++)
      tx_buf[i+4] = rand();

    HW_FLUSH_DCACHE(tx_buf, words*4);

    tail_addr = cur_addr;
    cur_addr  = dma_get_next_bd_addr(cur_addr);
  }

  start_hw_timer();
  //unsigned timeout = 0;
  for (int i=0;i<chains; i++){
    dma_chain_tx(head_addr, tail_addr);
    dma_wait_tx_ioc(DMA_TIMEOUT);
    dma_wait_tx_idle(DMA_TIMEOUT);
    //usleep(100);
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
}

void benchmark_rxtx_loopback(){
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

  const unsigned words = TX_BUF_BYTES/4; // words in TX buffer (= 1 DMA packet)
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

  if ((tx_timeout==0) || (rx_timeout==0)){
    printf("ERROR: a timeout occurred during RX/TX benchmark.");
    printf("INFO:  rx_timeout:  %d tx_timeout: %d \r\n", rx_timeout, tx_timeout);
  }
}


void benchmark_tx_single(){

  const unsigned words = TX_BUF_BYTES/4; // words in TX buffer (= 1 DMA packet)
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
}
