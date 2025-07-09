#include "hw_access.h"
#include "dma.h"

#define VERBOSE 0

//
// Local utility functions, not in header:
//

void print_dma_control(hw_val_t value);
void print_dma_status(hw_val_t value);
void print_dma_status_long(hw_val_t value);
void print_dma_control_long(hw_val_t value);

//
// Read and interpret the status and control registers:
//

void dma_show_tx_status(){
  hw_val_t cr = dma_read_register(MM2S_DMACR);
  hw_val_t sr = dma_read_register(MM2S_DMASR);
  print_dma_control(cr);
  print_dma_status(sr);
}

void dma_show_rx_status(){
  hw_val_t cr = dma_read_register(MM2S_DMACR);
  hw_val_t sr = dma_read_register(MM2S_DMASR);
  print_dma_control(cr);
  print_dma_status(sr);
}

void dma_show_long_status(){
  hw_val_t cr, sr;
  printf("INFO:  Long format of DMA TX status (MM2S): \r\n");
  cr = dma_read_register(MM2S_DMACR);
  sr = dma_read_register(MM2S_DMASR);
  print_dma_control_long(cr);
  print_dma_status_long(sr);
  printf("INFO:  Long format of DMA RX status (S2MM): \r\n");
  cr = dma_read_register(S2MM_DMACR);
  sr = dma_read_register(S2MM_DMASR);
  print_dma_control_long(cr);
  print_dma_status_long(sr);
}



void print_dma_control(hw_val_t value) {
    printf("DMA Control: 0x%08x [", value);
    if (value & DMACR_RUNSTOP)     printf(" RUN");
    if (value & DMACR_RESET)       printf(" RESET");
    if (value & DMACR_KEYHOLE)     printf(" KEYHOLE");
    if (value & DMACR_CYCLIC_BD)   printf(" CYCLIC");
    if (value & DMACR_IOC_IRQ_EN)  printf(" IOC_IRQ_EN");
    if (value & DMACR_DLY_IRQ_EN)  printf(" DLY_IRQ_EN");
    if (value & DMACR_ERR_IRQ_EN)  printf(" ERR_IRQ_EN");
    printf(" ]\r\n");
}

void print_dma_status(hw_val_t value) {
  printf("DMA Status: 0x%08x [", value);
  if (value & DMASR_HALTED)      printf(" HALTED");
  if (value & DMASR_IDLE)        printf(" IDLE");
  if (value & DMASR_SGINCLD)     printf(" SG");
  if (value & DMASR_DMA_INT_ERR) printf(" DMA_INT_ERR");
  if (value & DMASR_DMA_SEC_ERR) printf(" DMA_SEC_ERR");
  if (value & DMASR_DMA_DEC_ERR) printf(" DMA_DEC_ERR");
  if (value & DMASR_SG_INT_ERR)  printf(" SG_INT_ERR");
  if (value & DMASR_SG_SEC_ERR)  printf(" SG_SEC_ERR");
  if (value & DMASR_SG_DEC_ERR)  printf(" SG_DEC_ERR");
  if (value & DMASR_IOC_IRQ)     printf(" IOC_IRQ");
  if (value & DMASR_DLY_IRQ)     printf(" DLY_IRQ");
  if (value & DMASR_ERR_IRQ)     printf(" ERR_IRQ");
  printf(" ]\r\n");
}

void print_dma_status_long(hw_val_t value) {
    printf("DMA Status Register: 0x%08x\r\n", value);
    printf("  HALTED      : %s\r\n", (value & DMASR_HALTED) ? "Yes" : "No");
    printf("  IDLE        : %s\r\n", (value & DMASR_IDLE) ? "Yes" : "No");
    printf("  SG Included : %s\r\n", (value & DMASR_SGINCLD) ? "Yes" : "No");

    printf("  DMA Errors  : INT=%d, SEC=%d, DEC=%d\r\n",
        !!(value & DMASR_DMA_INT_ERR),
        !!(value & DMASR_DMA_SEC_ERR),
        !!(value & DMASR_DMA_DEC_ERR));

    printf("  SG Errors   : INT=%d, SEC=%d, DEC=%d\r\n",
        !!(value & DMASR_SG_INT_ERR),
        !!(value & DMASR_SG_SEC_ERR),
        !!(value & DMASR_SG_DEC_ERR));

    printf("  IRQ Flags   : IOC=%d, DLY=%d, ERR=%d\r\n",
        !!(value & DMASR_IOC_IRQ),
        !!(value & DMASR_DLY_IRQ),
        !!(value & DMASR_ERR_IRQ));
    printf("  IRQ Threshold Status: %d\r\n", (value & DMASR_IRQ_THRESHOLD_MASK) >> DMASR_IRQ_THRESHOLD_SHIFT);
    printf("  IRQ Delay Status    : %d\r\n", (value & DMASR_IRQ_DELAY_MASK) >> DMASR_IRQ_DELAY_SHIFT);
}

void print_dma_control_long(hw_val_t value) {
    printf("DMA Control Register: 0x%08x\r\n", value);
    printf("  RUN/STOP     : %s\r\n", (value & DMACR_RUNSTOP) ? "Running" : "Stopped");
    printf("  RESET        : %s\r\n", (value & DMACR_RESET) ? "Asserted" : "Inactive");
    printf("  KEYHOLE      : %s\r\n", (value & DMACR_KEYHOLE) ? "Enabled" : "Disabled");
    printf("  CYCLIC BD    : %s\r\n", (value & DMACR_CYCLIC_BD) ? "Enabled" : "Disabled");

    printf("  IRQ Enables  : IOC=%d, DLY=%d, ERR=%d\r\n",
        !!(value & DMACR_IOC_IRQ_EN),
        !!(value & DMACR_DLY_IRQ_EN),
        !!(value & DMACR_ERR_IRQ_EN));

    printf("  IRQ Threshold: %d\r\n", (value & DMACR_IRQ_THRESHOLD_MASK) >> DMACR_IRQ_THRESHOLD_SHIFT);
    printf("  IRQ Delay    : %d\r\n", (value & DMACR_IRQ_DELAY_MASK) >> DMACR_IRQ_DELAY_SHIFT);
}



//
// DMA states  RESET/HALT/IDLE:
//


// reset the TX
unsigned dma_reset_tx(unsigned timeout){

  dma_write_register(MM2S_DMACR, DMACR_RESET);

  if (timeout > 0){
    while (timeout && (dma_read_register(MM2S_DMACR) & DMACR_RESET)){ usleep(1); timeout--; }
    if (! timeout) {
      printf("ERROR:  timeout wating on RESET to clear.\r\n");
    } else if (VERBOSE) {
      printf("INFO:  DMA reset complete.  (timeout=%d) \r\n", timeout);
    }
  }

  return timeout;
}

// reset the RX
unsigned dma_reset_rx(unsigned timeout){
  dma_write_register(S2MM_DMACR, DMACR_RESET);

  if (timeout>0){
    while (timeout && (dma_read_register(S2MM_DMACR) & DMACR_RESET)){ usleep(1); timeout--; }

    if (! timeout) {
      printf("ERROR:  timeout wating on RESET to clear.\r\n");
    } else if (VERBOSE) {
      printf("INFO:  DMA reset complete.  (timeout=%d) \r\n", timeout);
    }
  }
  return timeout;
}

unsigned dma_halt_tx(unsigned timeout){

  dma_write_register(MM2S_DMACR, 0);

  if (timeout > 0){
    while (timeout && ((dma_read_register(MM2S_DMACR) & DMACR_RUNSTOP)||((dma_read_register(MM2S_DMASR) & DMASR_HALTED)==0))){
      usleep(1);
      timeout--;
    }
    if (! timeout) {
      printf("ERROR:  timeout wating on HALT state.\r\n");
    } else if (VERBOSE) {
      printf("INFO:  DMA halt complete.  (timeout=%d) \r\n", timeout);
    }
  }
  return timeout;
}

unsigned dma_halt_rx(unsigned timeout){

  dma_write_register(S2MM_DMACR, 0);

  if (timeout > 0){
    while (timeout && ((dma_read_register(S2MM_DMACR) & DMACR_RUNSTOP)||((dma_read_register(S2MM_DMASR) & DMASR_HALTED)==0))){
      usleep(1);
      timeout--;
    }
    if (! timeout) {
      printf("ERROR:  timeout wating on HALT state.\r\n");
    } else if (VERBOSE) {
      printf("INFO:  DMA is halted.  (timeout=%d) \r\n", timeout);
    }
  }
  return timeout;
}

unsigned dma_run_tx(unsigned timeout){

  dma_write_register(MM2S_DMACR, DMACR_RUNSTOP);

  if (timeout > 0){
    while (timeout && (((dma_read_register(MM2S_DMACR) & DMACR_RUNSTOP)==0)||(dma_read_register(MM2S_DMASR) & DMASR_HALTED))){
      usleep(1);
      timeout--;
    }
    if (! timeout) {
      printf("ERROR:  timeout wating on RUN state.\r\n");
    } else if (VERBOSE) {
      printf("INFO:  DMA is running.  (timeout=%d) \r\n", timeout);
    }
  }
  return timeout;
}

unsigned dma_run_rx(unsigned timeout){

  dma_write_register(S2MM_DMACR, DMACR_RUNSTOP);

  if (timeout > 0){
    while (timeout && (((dma_read_register(S2MM_DMACR) & DMACR_RUNSTOP)==0)||(dma_read_register(S2MM_DMASR) & DMASR_HALTED))){
      usleep(1);
      timeout--;
    }

    if (! timeout) {
      printf("ERROR:  timeout wating on RUN state.\r\n");
    } else if (VERBOSE){
      printf("INFO:  DMA is running.  (timeout=%d) \r\n", timeout);
    }
  }
  return timeout;
}

//
// IOC flags:
//

unsigned dma_clear_tx_ioc(unsigned timeout){

  dma_write_register(MM2S_DMASR, DMASR_IOC_IRQ);

  if (timeout > 0){
    while (timeout && (dma_read_register(MM2S_DMASR) & DMASR_IOC_IRQ)){
      usleep(1);
      timeout--;
    }
    if (! timeout) {
      printf("ERROR:  timeout wating for TX IOC to clear\r\n");
    } else if (VERBOSE) {
      printf("INFO:  DMA TX IOC flag is cleared  (timeout=%d) \r\n", timeout);
    }
  }
  return timeout;
}

unsigned dma_clear_rx_ioc(unsigned timeout){

  dma_write_register(S2MM_DMASR, DMASR_IOC_IRQ);

  if (timeout > 0){
    while (timeout && (dma_read_register(S2MM_DMASR) & DMASR_IOC_IRQ)){
      usleep(1);
      timeout--;
    }
    if (! timeout) {
      printf("ERROR:  timeout wating for TX IOC to clear\r\n");
    } else if (VERBOSE) {
      printf("INFO:  DMA TX IOC flag is cleared  (timeout=%d) \r\n", timeout);
    }
  }
  return timeout;
}


unsigned dma_wait_tx_ioc(unsigned timeout){
  if (timeout > 0){
    while (timeout && ((dma_read_register(MM2S_DMASR) & DMASR_IOC_IRQ)==0)){
      usleep(1);
      timeout--;
    }
    if (! timeout) {
      printf("ERROR:  timeout waiting for TX IOC.\r\n");
      return 0;
    } else if (VERBOSE) {
      printf("INFO:  DMA TX IOC flag was raised  (timeout=%d) \r\n", timeout);
    }
  }
  return timeout;
}

unsigned dma_wait_rx_ioc(unsigned timeout){

  if (timeout > 0){
    while (timeout && ((dma_read_register(S2MM_DMASR) & DMASR_IOC_IRQ)==0)){
      usleep(1);
      timeout--;
    }
    if (! timeout) {
      printf("ERROR:  timeout wating for RX IOC\r\n");
    } else if (VERBOSE) {
      printf("INFO:  DMA RX IOC flag was raised  (timeout=%d) \r\n", timeout);
    }
  }
  return timeout;
}

unsigned dma_poll_tx_ioc(){
  return (dma_read_register(MM2S_DMASR) & DMASR_IOC_IRQ) ? 1 : 0;
}

unsigned dma_poll_rx_ioc(){
  return (dma_read_register(S2MM_DMASR) & DMASR_IOC_IRQ) ? 1 : 0;
}

//
// Buffer Descriptor Utilities:
//

void dma_init_bd(hw_addr_t addr, hw_addr_t next_addr, hw_addr_t buf_addr, hw_val_t size_bytes, hw_val_t flags){
  if (size_bytes > DMA_BD_CONTROL_LEN)
    size_bytes = DMA_BD_CONTROL_LEN;

  hw_ptr_t bd = dma_ptr(addr);

  for (int i=0; i<16; i++){
    bd[i] = 0;
  }

  bd[DMA_BD_NXTDESC] = (hw_val_t) next_addr;
  bd[DMA_BD_BUFFER_ADDRESS] = (hw_val_t) buf_addr;
  bd[DMA_BD_CONTROL] = size_bytes | flags;

  HW_FLUSH_DCACHE(bd, DMA_BD_BYTES);

  dma_clear_buffer(addr);
}

// initialize a single BD with flags appropriate for TX (SOF / EOF)
void dma_init_single_bd_tx(hw_addr_t addr, hw_addr_t buf_addr, hw_val_t size_bytes){
  dma_init_bd(addr, addr, buf_addr, size_bytes, DMA_BD_CONTROL_SOF | DMA_BD_CONTROL_EOF );
}

// initialize a single BD with flags appropriate for RX
void dma_init_single_bd_rx(hw_addr_t addr, hw_addr_t buf_addr, hw_val_t size_bytes){
  dma_init_bd(addr, addr, buf_addr, size_bytes, 0 );
}

void dma_show_bd(hw_addr_t addr) {
  hw_ptr_t bd = dma_ptr(addr);

  HW_INVALIDATE_DCACHE(bd, DMA_BD_BYTES);

  hw_val_t next_desc   = bd[DMA_BD_NXTDESC];
  hw_val_t buffer_addr = bd[DMA_BD_BUFFER_ADDRESS];
  hw_val_t control     = bd[DMA_BD_CONTROL];
  hw_val_t status      = bd[DMA_BD_STATUS];

  printf("DMA Buffer Descriptor:\r\n");
  printf("  Next Descriptor : 0x%08x\r\n", next_desc);
  printf("  Buffer Address  : 0x%08x\r\n", buffer_addr);
  printf("  Control         : 0x%08x\r\n", control);
  printf("  Status          : 0x%08x\r\n", status);
}

void dma_clear_bd_status(hw_addr_t addr) {
  hw_ptr_t bd = dma_ptr(addr);
  bd[DMA_BD_STATUS] = 0;
  HW_FLUSH_DCACHE(bd, DMA_BD_BYTES);
}

void dma_clear_buffer(hw_addr_t addr) {
  hw_ptr_t bd = dma_ptr(addr);
  HW_INVALIDATE_DCACHE(bd, DMA_BD_BYTES);

  hw_ptr_t buf = dma_ptr(bd[DMA_BD_BUFFER_ADDRESS]);
  unsigned len = bd[DMA_BD_CONTROL]&DMA_BD_CONTROL_LEN;

  if (buf==NULL){
    printf("ERROR:  BD not initialized.\r\n");
    return;
  }

  if (VERBOSE)
    printf("INFO: clearing buffer of size 0x%x (%d)\r\n", len, len);
  for (int i=0; i<len/4; i++){
    buf[i]=0;
  }

  HW_FLUSH_DCACHE(buf, len);
}

void dma_print_buffer(hw_ptr_t buf, hw_val_t len, int ncol, int max_words) {
  if (buf==NULL){
    printf("ERROR:  BD not initialized.\r\n");
    return;
  }
  HW_INVALIDATE_DCACHE(buf, len);

  int words = len / DMA_BYTES_PER_WORD;
  if ((max_words > 0) && (words > max_words))
    words = max_words;

  for (int i=0; i<words; i++){
    if ((i%ncol)==0)
      printf("%4d: ", i/ncol);
    printf("0x%08x ", buf[i]);
    if (((i+1)%ncol)==0)
      printf("\r\n");
  }
  if (words%ncol)
    printf("\r\n");
}

void dma_show_buffer(hw_addr_t addr, int ncol, int max_words){
  hw_ptr_t bd = dma_ptr(addr);
  HW_INVALIDATE_DCACHE(bd, DMA_BD_BYTES);

  hw_ptr_t buf = dma_ptr(bd[DMA_BD_BUFFER_ADDRESS]);
  hw_val_t len = bd[DMA_BD_CONTROL] & DMA_BD_CONTROL_LEN;

  dma_print_buffer(buf, len, ncol, max_words);
}

void dma_show_transferred(hw_addr_t addr, int ncol, int max_words){
  hw_ptr_t bd = dma_ptr(addr);
  HW_INVALIDATE_DCACHE(bd, DMA_BD_BYTES);

  hw_ptr_t buf = dma_ptr(bd[DMA_BD_BUFFER_ADDRESS]);
  hw_val_t len = bd[DMA_BD_STATUS]&DMA_BD_STATUS_TRANSFERRED;

  dma_print_buffer(buf, len, ncol, max_words);
}

void dma_single_tx(hw_addr_t addr){

  dma_halt_tx(DMA_TIMEOUT);
  dma_clear_bd_status(addr);

  dma_clear_tx_ioc(DMA_TIMEOUT);

  if (VERBOSE)
    printf("INFO: setting TX current descriptor address to 0x%08x\r\n", addr);
  dma_write_register(MM2S_CURDESC, addr);

  dma_run_tx(DMA_TIMEOUT);

  if (VERBOSE)
    printf("INFO: setting TX tail address to 0x%08x\r\n", addr);
  dma_write_register(MM2S_TAILDESC, addr);

}

void dma_single_rx(hw_addr_t addr){

  dma_halt_rx(DMA_TIMEOUT);
  dma_clear_bd_status(addr);

  dma_clear_rx_ioc(DMA_TIMEOUT);

  if (VERBOSE)
    printf("INFO: setting RX current descriptor address to 0x%08x\r\n", addr);
  dma_write_register(S2MM_CURDESC, addr);

  dma_run_rx(DMA_TIMEOUT);

  if (VERBOSE)
    printf("INFO: setting TX tail address to 0x%08x\r\n", addr);

  dma_write_register(S2MM_TAILDESC, addr);

}




