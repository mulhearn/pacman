#include <stdio.h>
#include <stdlib.h>

#include "axil.hh"
#include "dma.hh"

// *** RX and TX UNITs ***

void toggle_tx_config(){
  static int mode = 0;
  mode = (mode + 1) % 3;
  if (mode==0){
    unsigned config = 0x1602;
    printf("INFO: Default TX config.  Broadcasting tx config write 0x%08x \n", config);
    write_axil(SCOPE_TX+UART_BROADCAST+C_ADDR_TX_CONFIG, config);
  } else if (mode==1) {
    unsigned config = 0x1601;
    printf("INFO: Full-speed TX.  Broadcasting tx config write 0x%08x \n", config);
    write_axil(SCOPE_TX+UART_BROADCAST+C_ADDR_TX_CONFIG, config);
  } else if (mode==2) {
    unsigned config = 0x053c1602;
    printf("INFO: Default TX config plus delay.  Broadcasting tx config write 0x%08x \n", config);
    write_axil(SCOPE_TX+UART_BROADCAST+C_ADDR_TX_CONFIG, config);
  }

}

void read_tx_registers(){
  for (int i=0; i<40; i++){
    unsigned cshift = (i<<8);
    unsigned status = read_axil(SCOPE_TX+cshift+C_ADDR_TX_STATUS);
    unsigned config = read_axil(SCOPE_TX+cshift+C_ADDR_TX_CONFIG);
    unsigned starts = read_axil(SCOPE_TX+cshift+C_ADDR_TX_STARTS);
    unsigned nchan  = read_axil(SCOPE_TX+cshift+C_ADDR_TX_NCHAN);
    printf("%2d:  chan: %2d config: 0x%08x status: 0x%08x starts: %d\n",i, nchan, config, status, starts);
  }
  printf("gflags------------ 0x%x    \n", read_axil(SCOPE_TX+0x3F00+C_ADDR_TX_GFLAGS));
  printf("bstatus----------- 0x%x    \n", read_axil(SCOPE_TX+0x3F00+C_ADDR_TX_STATUS));
}

void read_tx_look(){
  for (int i=0; i<40; i++){
    unsigned cshift = (i<<8);
    unsigned d = read_axil(SCOPE_TX+cshift+C_ADDR_TX_LOOK_D);
    unsigned c = read_axil(SCOPE_TX+cshift+C_ADDR_TX_LOOK_C);
    printf("Channel %2d Look:  0x%08x %08x\n", i, d, c);
  }
}

void toggle_rx_config(){
  static int mode = 0;
  mode = (mode + 1) % 6;
  if (mode==0){
    unsigned config = 0x00001002;
    printf("INFO: No internal loopback.  Broadcasting rx config write 0x%08x \n", config);
    write_axil(SCOPE_RX+UART_BROADCAST+C_ADDR_RX_CONFIG, config);
  } else if (mode==1) {
    unsigned config = 0x00001001;
    printf("INFO: No internal loopback at full speed..  Broadcasting rx config write 0x%08x \n", config);
    write_axil(SCOPE_RX+UART_BROADCAST+C_ADDR_RX_CONFIG, config);
  } else if (mode==2) {
    unsigned config = 0x00011002;
    printf("INFO: Full internal loopback.  Broadcasting rx configs write 0x%08x \n", config);
    write_axil(SCOPE_RX+UART_BROADCAST+C_ADDR_RX_CONFIG, config);
  } else if (mode==3) {
    unsigned config;
    config = 0x00011002;
    printf("INFO: Tiles 2-10 use internal loopback.  Broadcasting rx configs t 0x%08x \n", config);
    write_axil(SCOPE_RX+UART_BROADCAST+C_ADDR_RX_CONFIG, config);
    config = 0x00001002;
    printf("INFO: Tile 1 does not use internal loopback.  Setting Tile 1 rx config 0x%08x \n", config);
    write_axil(SCOPE_RX+(0<<8)+C_ADDR_RX_CONFIG, config);
    write_axil(SCOPE_RX+(1<<8)+C_ADDR_RX_CONFIG, config);
    write_axil(SCOPE_RX+(2<<8)+C_ADDR_RX_CONFIG, config);
    write_axil(SCOPE_RX+(3<<8)+C_ADDR_RX_CONFIG, config);
  } else if (mode==4) {
    unsigned config = 0x00010002;
    printf("INFO: Disabling rx.  Broadcasting rx configs write 0x%08x \n", config);
    write_axil(SCOPE_RX+UART_BROADCAST+C_ADDR_RX_CONFIG, config);
  } else if (mode==5) {
    unsigned config = 0x00011001;
    printf("INFO: Full internal loopback at full speed.  Broadcasting rx configs write 0x%08x \n", config);
    write_axil(SCOPE_RX+UART_BROADCAST+C_ADDR_RX_CONFIG, config);
  }
}

void toggle_rx_global_config(){
  unsigned config[] = {0x00071FFF, 0x00000001, 0x00000100, 0x00000800, 0x00001000, 0x00001FFF};
  static int mode = 0;
  mode = (mode + 1) % 6;
  printf("INFO: setting rx global config to 0x%08x \n", config[mode]);
  write_axil(SCOPE_RX+UART_GLOBAL+C_ADDR_RX_GFLAGS, config[mode]);
}

void read_rx_registers(){
  for (int i=0; i<40; i++){
    unsigned cshift  = (i<<8);
    unsigned status  = read_axil(SCOPE_RX+cshift+C_ADDR_RX_STATUS);
    unsigned config  = read_axil(SCOPE_RX+cshift+C_ADDR_RX_CONFIG);
    unsigned starts  = read_axil(SCOPE_RX+cshift+C_ADDR_RX_STARTS);
    unsigned beats   = read_axil(SCOPE_RX+cshift+C_ADDR_RX_BEATS);
    unsigned updates = read_axil(SCOPE_RX+cshift+C_ADDR_RX_UPDATES);
    unsigned lost    = read_axil(SCOPE_RX+cshift+C_ADDR_RX_LOST);
    unsigned nchan   = read_axil(SCOPE_RX+cshift+C_ADDR_RX_NCHAN);
    printf("%2d: ch: %2d cfg: 0x%08x status: 0x%08x s: %d b: %d u: %d l: %d\n",i, nchan, config, status, starts, beats, updates, lost);
  }
  printf("gstatus----------- 0x%x    \n", read_axil(SCOPE_RX+0x3F00+C_ADDR_RX_GSTATUS));
  printf("gflags------------ 0x%x    \n", read_axil(SCOPE_RX+0x3F00+C_ADDR_RX_GFLAGS));
  printf("FIFO R count-------%d      \n", read_axil(SCOPE_RX+0x3F00+C_ADDR_RX_FRCNT));
  printf("FIFO W count-------%d      \n", read_axil(SCOPE_RX+0x3F00+C_ADDR_RX_FWCNT));
  printf("DMA ITR------------0x%x    \n", read_axil(SCOPE_RX+0x3F00+C_ADDR_RX_DMAITR));
}

void read_rx_look(){
  for (int i=0; i<40; i++){
    unsigned cshift = (i<<8);
    unsigned a = read_axil(SCOPE_RX+cshift+C_ADDR_RX_LOOK_A);
    unsigned b = read_axil(SCOPE_RX+cshift+C_ADDR_RX_LOOK_B);
    unsigned c = read_axil(SCOPE_RX+cshift+C_ADDR_RX_LOOK_C);
    unsigned d = read_axil(SCOPE_RX+cshift+C_ADDR_RX_LOOK_D);
    printf("Channel %2d Look:  0x%08x %08x %08x %08x\n", i, d, c, b, a);
  }
}

void rxtx_reset_counts(){
  write_axil(SCOPE_TX+UART_GLOBAL+C_ADDR_TX_STARTS, 0);
  write_axil(SCOPE_RX+UART_GLOBAL+C_ADDR_RX_ZERO_CNTS, 0);
}

u32 tx_mask_b = 0xFF;
u32 tx_mask_a = 0xFFFFFFFF;

#define TX_BD_BASEADDR     0x1200000
#define RX_BD_BASEADDR     0x1200040
#define TX_BUF_BASEADDR    0x1100000
#define RX_BUF_BASEADDR    0x2100000

#define TX_BUF_BYTES 0x150  // 40 uarts x 64 bits => 20 128 bit word plus 1 128 bit header => 21*4*4 = 336 bytes
#define RX_BUF_BYTES 0x400  // More than enough for now...

void init_bds(){
  printf("INFO:  initializing single TX BD:\r\n");
  dma_init_single_bd_tx((u32*) TX_BD_BASEADDR, (u32*) TX_BUF_BASEADDR, TX_BUF_BYTES);
  printf("INFO:  initializing single RX BD:\r\n");
  dma_init_single_bd_rx((u32*) RX_BD_BASEADDR, (u32*) RX_BUF_BASEADDR, RX_BUF_BYTES);
}


void init_rxtx(){
  init_bds();
}

void show_bds(){
  printf("INFO:  TX BD:\r\n");
  dma_show_bd((u32*) TX_BD_BASEADDR);
  printf("INFO:  RX BD:\r\n");
  dma_show_bd((u32*) RX_BD_BASEADDR);
}

void clear_bds(){
  printf("INFO:  clearing TX BD.\r\n");
  dma_clear_bd_status((u32*) TX_BD_BASEADDR);
  printf("INFO:  clearing RX BD\r\n");
  dma_clear_bd_status((u32*) RX_BD_BASEADDR);
}


void clear_ioc(){
  printf("INFO:  clearing DMA TX IOC flag.\r\n");
  dma_clear_tx_ioc(DMA_TIMEOUT);
  printf("INFO:  clearing DMA RX IOC flag\r\n");
  dma_clear_rx_ioc(DMA_TIMEOUT);
}


void single_tx(){
  // TX buffer is a 128 bit header plus 40 uarts allocated 64 bits each.
  // This is a total of 84 32-bit words (4 header words, 80 uart words)
  // The resulting AXI stream is 128 bits times 21 beats.

  static int count = 0;
  u32 *tx_buf = (u32 *) TX_BUF_BASEADDR;
  unsigned words = TX_BUF_BYTES/4;

  tx_buf[0]= tx_mask_a;
  tx_buf[1]= tx_mask_b;
  tx_buf[2]=0x00000000;
  tx_buf[3]=0x00000000;

  for (int i=0; i<(words-4); i++)
    tx_buf[i+4] = 0xB000F000 + i + (count<<16);
  count++;

  //Xil_DCacheFlushRange((UINTPTR)tx_buf, words*4);

  dma_single_tx((u32*) TX_BD_BASEADDR);

  if (dma_wait_tx_ioc(DMA_TIMEOUT) > 0){
    printf("INFO: single TX yielded TX IOC flag high (SUCCESS)\r\n");
  }

}

void show_tx_buffer(){
  printf("INFO:  TX Buffer:\r\n");
  dma_show_buffer((u32*) TX_BD_BASEADDR, 4, 1000);
}

void single_rx(){
  dma_single_rx((u32*) RX_BD_BASEADDR);

  if (dma_wait_rx_ioc(DMA_TIMEOUT) > 0){
    printf("INFO: single RX yielded RX IOC flag high (SUCCESS)\r\n");
  }

}

void show_rx_buffer(){
  printf("INFO:  RX Buffer:\r\n");
  dma_show_buffer((u32*) RX_BD_BASEADDR, 4, 1000);
}

void show_rx_transferred(){
  printf("INFO:  RX Buffer:\r\n");
  dma_show_transferred((u32*) RX_BD_BASEADDR, 4, 1000);
}

void rxtx_menu(){
  while(1){
    printf("RX/TX menu:  choose an option:\n");
    printf("(0) main menu (1) toggle RX global config (2) reset counts \n");
    printf("(10) read TX registers (11) read TX look (12) toggle TX config \n");
    printf("(20) read RX registers (21) read RX look (22) toggle RX config \n");
    printf("(30) TX DMA reset (31) TX DMA status (32) RX DMA reset (33) RX DMA status (34) long DMA status \n");
    printf("(35) init BDs (36) clear BDs (37) show BDs (38) clear IOC flags \n");
    int input;
    scanf("%d", &input);
    printf("INFO: selected %d\n", input);

    switch(input){
    case 0:
      return;
    case 1:
      toggle_rx_global_config();
      break;
    case 2:
      rxtx_reset_counts();
      break;
    case 10:
      read_tx_registers();
      break;
    case 11:
      read_tx_look();
      break;
    case 12:
      toggle_tx_config();
      break;
    case 20:
      read_rx_registers();
      break;
    case 21:
      read_rx_look();
      break;
    case 22:
      toggle_rx_config();
      break;
    case 30:
      dma_reset_tx(DMA_TIMEOUT);
      break;
    case 31:
      dma_show_tx_status();
      break;
    case 32:
      dma_reset_rx(DMA_TIMEOUT);
      break;
    case 33:
      dma_show_rx_status();
      break;
    case 34:
      dma_show_long_status();
      break;
    case 35:
      init_bds();
      break;
    case 36:
      clear_bds();
      break;
    case 37:
      show_bds();
      break;
    case 38:
      clear_ioc();
      break;
    default:
      printf("invalid selection...\n\r");
    }
  }
  return;
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
