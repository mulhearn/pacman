#include "hw_access.h"
#include "dma.h"
#include "global.h"
#include "rxtx.h"

u32 tx_mask_b = 0xFF;
u32 tx_mask_a = 0xFFFFFFFF;

#define TX_BD_BASEADDR     0x1200000
#define RX_BD_BASEADDR     0x1200040
#define TX_BUF_BASEADDR    0x1100000
#define RX_BUF_BASEADDR    0x2100000

#define TX_BUF_BYTES 0x150  // 40 uarts x 64 bits => 20 128 bit word plus 1 128 bit header => 21*4*4 = 336 bytes
#define RX_BUF_BYTES 0x400  // More than enough for now...


void init_rxtx_bds(){
  printf("INFO:  initializing single TX BD:\r\n");
  dma_init_single_bd_tx(TX_BD_BASEADDR, TX_BUF_BASEADDR, TX_BUF_BYTES);
  printf("INFO:  initializing single RX BD:\r\n");
  dma_init_single_bd_rx(RX_BD_BASEADDR, RX_BUF_BASEADDR, RX_BUF_BYTES);
}

void init_rxtx(){
  init_rxtx_bds();
}

void show_rxtx_bds(){
  printf("INFO:  TX BD:\r\n");
  dma_show_bd(TX_BD_BASEADDR);
  printf("INFO:  RX BD:\r\n");
  dma_show_bd(RX_BD_BASEADDR);
}

void clear_rxtx_bds(){
  printf("INFO:  clearing TX BD.\r\n");
  dma_clear_bd_status(TX_BD_BASEADDR);
  printf("INFO:  clearing RX BD\r\n");
  dma_clear_bd_status(RX_BD_BASEADDR);
}

void clear_rxtx_ioc(){
  printf("INFO:  clearing DMA TX IOC flag.\r\n");
  dma_clear_tx_ioc(DMA_TIMEOUT);
  printf("INFO:  clearing DMA RX IOC flag\r\n");
  dma_clear_rx_ioc(DMA_TIMEOUT);
}

void show_tx_buffer(){
  printf("INFO:  TX Buffer:\r\n");
  dma_show_buffer(TX_BD_BASEADDR, 4, 1000);
}

void show_rx_buffer(){
  printf("INFO:  RX Buffer:\r\n");
  dma_show_buffer(RX_BD_BASEADDR, 4, 1000);
}

void show_rx_transferred(){
  printf("INFO:  RX Buffer:\r\n");
  dma_show_transferred(RX_BD_BASEADDR, 4, 1000);
}

void single_tx(){
  // TX buffer is a 128 bit header plus 40 uarts allocated 64 bits each.
  // This is a total of 84 32-bit words (4 header words, 80 uart words)
  // The resulting AXI stream is 128 bits times 21 beats.

  static int count = 0;
  hw_ptr_t tx_buf = dma_ptr(TX_BUF_BASEADDR);
  unsigned words = TX_BUF_BYTES/4;

  tx_buf[0]= tx_mask_a;
  tx_buf[1]= tx_mask_b;
  tx_buf[2]=0x00000000;
  tx_buf[3]=0x00000000;

  for (int i=0; i<(words-4); i++)
    tx_buf[i+4] = 0xB000F000 + i + (count<<16);
  count++;

  HW_FLUSH_DCACHE(tx_buf, words*4);

  dma_single_tx(TX_BD_BASEADDR);

  if (dma_wait_tx_ioc(DMA_TIMEOUT) > 0){
    printf("INFO: single TX yielded TX IOC flag high (SUCCESS)\r\n");
  }

}

void single_rx(){
  dma_single_rx(RX_BD_BASEADDR);

  if (dma_wait_rx_ioc(DMA_TIMEOUT) > 0){
    printf("INFO: single RX yielded RX IOC flag high (SUCCESS)\r\n");
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


/*

//
// Benchmarks:
//

void benchmark_dma_tx(){
  u32 *bd  = (u32 *) TX_BD_BASEADDR;
  u32 *buf = (u32 *) TX_BUF_BASEADDR;
  const unsigned words = TX_BUF_BYTES/4; // words in TX buffer (= 1 DMA packet)
  const unsigned packets = 10000;        // DMA packets to send

  buf[0]= tx_mask_a;
  buf[1]= tx_mask_b;
  buf[2]=0x00000000;
  buf[3]=0x00000000;

  for (int i=0; i<(words-4); i++)
    buf[i+4] = rand();

  Xil_DCacheFlushRange((UINTPTR)buf, words*4);

  dma_halt_tx(DMA_TIMEOUT);
  dma_clear_bd_status(bd);

  dma_clear_tx_ioc(DMA_TIMEOUT);

  dma_write_register(MM2S_CURDESC, (u32) bd);

  dma_run_tx(DMA_TIMEOUT);

  //dma_write_register(MM2S_TAILDESC, (u32) bd);
  //dma_wait_tx_ioc(DMA_TIMEOUT);

  XTime start_time;
  XTime stop_time;

  XTime_GetTime(&start_time);
  unsigned timeout = 0;
  for (int i=0;i<packets; i++){
    dma_clear_bd_status(bd);
    dma_clear_tx_ioc(DMA_TIMEOUT);
    //usleep(1);
    dma_write_register(MM2S_TAILDESC, (u32) bd);
    timeout = dma_wait_tx_ioc(DMA_TIMEOUT);
    if (timeout==0){
      printf("ERROR: timeout waiting on IOC flag at packet %d \r\n", i);
      return;
    } else if (timeout < 5){
      printf("INFO: timeout %d \r\n", timeout);
    }
  }
  XTime_GetTime(&stop_time);

  u32 delta = (u32) (stop_time - start_time);
  unsigned payloads = 40;
  printf("elapsed timer counts:      %d (0x%x)\r\n", delta, delta);
  printf("counts per second:         %d\r\n", COUNTS_PER_SECOND);
  printf("tx payloads per packet:    %d\r\n", payloads);
  printf("packets:                   %d\r\n", packets);

  unsigned r = (unsigned) (((float) COUNTS_PER_SECOND) * payloads * packets / delta / 1000);
  unsigned m = 40.0*10000/66;
  unsigned p = 40.0*10000/67;

  printf("INFO:  achieved throughput:  %d tx payloads per ms\r\n", r);
  printf("INFO:  maximum tx rate:      %d tx payloads (64-bit+2 @ 10 MHz) per ms\r\n", m);
  printf("INFO:  practical max:        %d tx payloads (64-bit+3 @ 10 MHz) per ms\r\n", p);
}


void benchmark_dma_rxtx_loopback(){
  // DISCLAIMER:  assumes 40 (larpix) packets per DMA TX packet

  const unsigned rx_header_bytes = 16;   // Each DMA TX packet includes a 128 bit header word
  const unsigned tx_packets = 10000;        // DMA TX packets to send
  const unsigned rx_expected = 16*40*tx_packets;   // Each DMA TX packet includes a 128 bit header word

  XTime start_time;
  XTime stop_time;

  u32 *tx_bd  = (u32 *) TX_BD_BASEADDR;
  u32 *tx_buf = (u32 *) TX_BUF_BASEADDR;
  u32 *rx_bd  = (u32 *) RX_BD_BASEADDR;

  // prepare the TX buffer with a random payload:
  const unsigned tx_words = TX_BUF_BYTES/4; // words in TX buffer (= 1 DMA packet)
  tx_buf[0]= tx_mask_a;
  tx_buf[1]= tx_mask_b;
  tx_buf[2]=0x00000000;
  tx_buf[3]=0x00000000;
  for (int i=0; i<(tx_words-4); i++)
    tx_buf[i+4] = rand();
  Xil_DCacheFlushRange((UINTPTR)tx_buf, tx_words*4);

  // Inititalize and run TX:
  dma_halt_tx(10*DMA_TIMEOUT);
  dma_clear_bd_status(tx_bd);
  dma_clear_tx_ioc(DMA_TIMEOUT);
  dma_write_register(MM2S_CURDESC, (u32) tx_bd);
  dma_run_tx(DMA_TIMEOUT);

  // Inititalize and run RX:
  dma_halt_rx(10*DMA_TIMEOUT);
  dma_clear_bd_status(rx_bd);
  dma_clear_rx_ioc(DMA_TIMEOUT);
  dma_write_register(S2MM_CURDESC, (u32) rx_bd);
  dma_run_rx(DMA_TIMEOUT);

  // Loop until done or a timeout occurs:
  unsigned timeout = 100;
  unsigned rx_timeout = timeout;
  unsigned tx_timeout = timeout;
  unsigned tx_sent = 0;
  unsigned rx_rcvd  = 0;
  unsigned rx_bytes = 0;

  XTime_GetTime(&start_time);

  // start first TX:
  dma_write_register(MM2S_TAILDESC, (u32) tx_bd);
  // start first RX:
  dma_write_register(S2MM_TAILDESC, (u32) rx_bd);

  while (tx_timeout && rx_timeout && (rx_bytes < rx_expected)){
    if (dma_poll_tx_ioc()){
      tx_sent++;
      tx_timeout = timeout;
      dma_clear_bd_status(tx_bd);
      dma_clear_tx_ioc(DMA_TIMEOUT);
      if (tx_sent < tx_packets)
	dma_write_register(MM2S_TAILDESC, (u32) tx_bd);
    }
    if (dma_poll_rx_ioc()){
      rx_rcvd++;
      unsigned bytes = rx_bd[DMA_BD_STATUS]&DMA_BD_STATUS_TRANSFERRED;
      if (bytes > rx_header_bytes)
	rx_bytes += bytes - rx_header_bytes;
      rx_timeout = timeout;
      dma_clear_bd_status(rx_bd);
      dma_clear_rx_ioc(DMA_TIMEOUT);
      dma_write_register(S2MM_TAILDESC, (u32) rx_bd);
    }
    rx_timeout--;
    if (tx_sent < tx_packets)
      tx_timeout--;
    usleep(1);
  }
  XTime_GetTime(&stop_time);

  printf("INFO:  tx packets sent:      %6d expecting: %6d \r\n", tx_sent, tx_packets);
  printf("INFO:  rx bytes received:    %6d expecting: %6d \r\n", rx_bytes, rx_expected);
  printf("INFO:  rx packets received:  %6d \r\n", rx_rcvd);

  if ((tx_timeout==0) || (rx_timeout==0)){
    printf("ERROR: a timeout occurred during benchmark.");
    printf("INFO:  rx_timeout:  ");
  }
  if (rx_timeout==0){
    printf("ERROR: benchmark not completed due to TX timeout");
    return;
  }

  u32 delta = (u32) (stop_time - start_time);
  unsigned payloads = 40;
  unsigned packets = tx_packets;
  printf("INFO:  elapsed timer counts:      %d (0x%x)\r\n", delta, delta);
  printf("INFO:  counts per second:         %d\r\n", COUNTS_PER_SECOND);
  printf("INFO:  tx payloads per packet:    %d\r\n", payloads);
  printf("INFO:  packets:                   %d\r\n", packets);

  unsigned r = (unsigned) (((float) COUNTS_PER_SECOND) * payloads * packets / delta / 1000);
  unsigned m = 40.0*10000/66;
  unsigned p = 40.0*10000/67;

  printf("INFO:  achieved throughput:  %d tx payloads per ms\r\n", r);
  printf("INFO:  maximum tx rate:      %d tx payloads (64-bit+2 @ 10 MHz) per ms\r\n", m);
  printf("INFO:  practical max:        %d tx payloads (64-bit+3 @ 10 MHz) per ms\r\n", p);

}



*/
