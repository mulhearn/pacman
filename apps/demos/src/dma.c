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

void dma_show_tx_status(void){
  hw_val_t cr = dma_read_register(MM2S_DMACR);
  hw_val_t sr = dma_read_register(MM2S_DMASR);
  print_dma_control(cr);
  print_dma_status(sr);
}

void dma_show_rx_status(void){
  hw_val_t cr = dma_read_register(S2MM_DMACR);
  hw_val_t sr = dma_read_register(S2MM_DMASR);
  print_dma_control(cr);
  print_dma_status(sr);
}

void dma_show_long_status(void){
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
  printf("DMA Control: 0x%08x [", (unsigned int) value);
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
  printf("DMA Status: 0x%08x [", (unsigned int) value);
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
  printf("DMA Status Register: 0x%08x\r\n", (unsigned int) value);
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
  printf("  IRQ Threshold Status: %u\r\n", (unsigned int) (value & DMASR_IRQ_THRESHOLD_MASK) >> DMASR_IRQ_THRESHOLD_SHIFT);
  printf("  IRQ Delay Status    : %u\r\n", (unsigned int) (value & DMASR_IRQ_DELAY_MASK) >> DMASR_IRQ_DELAY_SHIFT);
}

void print_dma_control_long(hw_val_t value) {
  printf("DMA Control Register: 0x%08x\r\n", (unsigned int) value);
  printf("  RUN/STOP     : %s\r\n", (value & DMACR_RUNSTOP) ? "Running" : "Stopped");
  printf("  RESET        : %s\r\n", (value & DMACR_RESET) ? "Asserted" : "Inactive");
  printf("  KEYHOLE      : %s\r\n", (value & DMACR_KEYHOLE) ? "Enabled" : "Disabled");
  printf("  CYCLIC BD    : %s\r\n", (value & DMACR_CYCLIC_BD) ? "Enabled" : "Disabled");

  printf("  IRQ Enables  : IOC=%d, DLY=%d, ERR=%d\r\n",
	 !!(value & DMACR_IOC_IRQ_EN),
	 !!(value & DMACR_DLY_IRQ_EN),
	 !!(value & DMACR_ERR_IRQ_EN));

  printf("  IRQ Threshold: %u\r\n", (unsigned int) ((value & DMACR_IRQ_THRESHOLD_MASK) >> DMACR_IRQ_THRESHOLD_SHIFT));
  printf("  IRQ Delay    : %u\r\n", (unsigned int) ((value & DMACR_IRQ_DELAY_MASK) >> DMACR_IRQ_DELAY_SHIFT));
}



//
// DMA states  RESET/HALT/IDLE:
//


// reset the TX
unsigned dma_reset_tx(unsigned timeout){

  if (VERBOSE)
    printf("INFO:  resetting DMA TX (MM2S) \r\n");

  dma_write_register(MM2S_DMACR, DMACR_RESET);

  if (timeout > 0){
    while (timeout && (dma_read_register(MM2S_DMACR) & DMACR_RESET)){ usleep(1); timeout--; }
    if (! timeout) {
      printf("ERROR:  timeout waiting on RESET to clear.\r\n");
    } else if (VERBOSE) {
      printf("INFO:  TX DMA reset complete.  (timeout=%d) \r\n", timeout);
    }
  }

  return timeout;
}

// reset the RX
unsigned dma_reset_rx(unsigned timeout){

  if (VERBOSE)
    printf("INFO:  resetting DMA RX (S2MM) \r\n");

  dma_write_register(S2MM_DMACR, DMACR_RESET);

  if (timeout>0){
    while (timeout && (dma_read_register(S2MM_DMACR) & DMACR_RESET)){ usleep(1); timeout--; }

    if (! timeout) {
      printf("ERROR:  timeout waiting on RESET to clear.\r\n");
    } else if (VERBOSE) {
      printf("INFO:  RX DMA reset complete.  (timeout=%d) \r\n", timeout);
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
      printf("ERROR:  timeout waiting on HALT state.\r\n");
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
      printf("ERROR:  timeout waiting on HALT state.\r\n");
    } else if (VERBOSE) {
      printf("INFO:  DMA is halted.  (timeout=%d) \r\n", timeout);
    }
  }
  return timeout;
}

unsigned dma_run_tx(unsigned timeout){

  dma_write_register(MM2S_DMACR, DMACR_RUNSTOP);

  return dma_wait_tx_run(timeout);
}

unsigned dma_run_rx(unsigned timeout){

  dma_write_register(S2MM_DMACR, DMACR_RUNSTOP);

  return dma_wait_rx_run(timeout);
}

unsigned dma_poll_tx_run(){
  return (dma_read_register(MM2S_DMACR) & DMACR_RUNSTOP) ? 1 : 0;
}

unsigned dma_poll_rx_run(){
  return (dma_read_register(S2MM_DMACR) & DMACR_RUNSTOP) ? 1 : 0;
}

unsigned dma_wait_tx_run(unsigned timeout){
  if (timeout > 0){
    while (timeout && (((dma_read_register(MM2S_DMACR) & DMACR_RUNSTOP)==0)||(dma_read_register(MM2S_DMASR) & DMASR_HALTED))){
      usleep(1);
      timeout--;
    }
    if (! timeout) {
      printf("ERROR:  timeout waiting on RUN state.\r\n");
    } else if (VERBOSE) {
      printf("INFO:  DMA is running.  (timeout=%d) \r\n", timeout);
    }
  }
  return timeout;
}

unsigned dma_wait_rx_run(unsigned timeout){
  if (timeout > 0){
    while (timeout && (((dma_read_register(S2MM_DMACR) & DMACR_RUNSTOP)==0)||(dma_read_register(S2MM_DMASR) & DMASR_HALTED))){
      usleep(1);
      timeout--;
    }

    if (! timeout) {
      printf("ERROR:  timeout waiting on RUN state.\r\n");
    } else if (VERBOSE){
      printf("INFO:  DMA is running.  (timeout=%d) \r\n", timeout);
    }
  }
  return timeout;
}




unsigned dma_poll_tx_halt(){
  return (dma_read_register(MM2S_DMASR) & DMASR_HALTED) ? 1 : 0;
}

unsigned dma_poll_rx_halt(){
  return (dma_read_register(S2MM_DMASR) & DMASR_HALTED) ? 1 : 0;
}

//
// current/tail buffer descriptor HW addresses:
//

// read/write TX/RX current/tail buffer descriptor HW addresses:
hw_addr_t dma_read_tx_curdesc(void){
  return dma_read_register(MM2S_CURDESC);
}
hw_addr_t dma_read_rx_curdesc(void){
  return dma_read_register(S2MM_CURDESC);
}

hw_addr_t dma_read_tx_taildesc(void){
  return  dma_read_register(MM2S_TAILDESC);
}

hw_addr_t dma_read_rx_taildesc(void){
  return dma_read_register(S2MM_TAILDESC);
}

void dma_write_tx_curdesc(hw_addr_t bd_addr){
  if (! dma_poll_tx_halt()){
    printf("ERROR:  DMA must be in HALT state before setting TX current buffer descriptor HW address.\r\n");
    return;
  }

  if (VERBOSE)
    printf("INFO:  setting TX current buffer descriptor HW address to 0x%08x\r\n", (unsigned int) bd_addr);
  dma_write_register(MM2S_CURDESC, bd_addr);
}
void dma_write_rx_curdesc(hw_addr_t bd_addr){
  if (! dma_poll_rx_halt()){
    printf("ERROR:  DMA must be in HALT state before setting RX current buffer descriptor HW address.\r\n");
    return;
  }

  if (VERBOSE)
    printf("INFO:  setting RX current buffer descriptor HW address to 0x%08x\r\n",  (unsigned int) bd_addr);
  dma_write_register(S2MM_CURDESC, bd_addr);
}

void dma_write_tx_taildesc(hw_addr_t bd_addr){
  if (VERBOSE)
    printf("INFO:  setting TX tail buffer descriptor address to 0x%08x\r\n",  (unsigned int) bd_addr);

  dma_write_register(MM2S_TAILDESC, bd_addr);
}

void dma_write_rx_taildesc(hw_addr_t bd_addr){
  if (VERBOSE)
    printf("INFO:  setting RX tail buffer descriptor address to 0x%08x\r\n",  (unsigned int) bd_addr);

  dma_write_register(S2MM_TAILDESC, bd_addr);
}

//
// IOC flags:
//

unsigned dma_poll_tx_ioc(void){
  return (dma_read_register(MM2S_DMASR) & DMASR_IOC_IRQ) ? 1 : 0;
}

unsigned dma_poll_rx_ioc(void){
  return (dma_read_register(S2MM_DMASR) & DMASR_IOC_IRQ) ? 1 : 0;
}

unsigned dma_wait_tx_ioc(unsigned timeout){
  if (timeout > 0){
    while (timeout && (dma_poll_tx_ioc()==0)){
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
    while (timeout && (dma_poll_rx_ioc()==0)){
      usleep(1);
      timeout--;
    }
    if (! timeout) {
      printf("ERROR:  timeout waiting for RX IOC\r\n");
    } else if (VERBOSE) {
      printf("INFO:  DMA RX IOC flag was raised  (timeout=%d) \r\n", timeout);
    }
  }
  return timeout;
}

void dma_clear_tx_ioc(void){
  dma_write_register(MM2S_DMASR, DMASR_IOC_IRQ);
}

void dma_clear_rx_ioc(void){
  dma_write_register(S2MM_DMASR, DMASR_IOC_IRQ);
}


unsigned dma_poll_tx_idle(void){
  return (dma_read_register(MM2S_DMASR) & DMASR_IDLE) ? 1 : 0;
}

unsigned dma_poll_rx_idle(void){
  return (dma_read_register(S2MM_DMASR) & DMASR_IDLE) ? 1 : 0;
}

unsigned dma_wait_tx_idle(unsigned timeout){
  if (timeout > 0){
    while (timeout && (dma_poll_tx_idle()==0)){
      usleep(1);
      timeout--;
    }
    if (! timeout) {
      printf("ERROR:  timeout waiting for TX to reach IDLE.\r\n");
      return 0;
    } else if (VERBOSE) {
      printf("INFO:  DMA TX IDLE state reached  (timeout=%d) \r\n", timeout);
    }
  }
  return timeout;
}

unsigned dma_wait_rx_idle(unsigned timeout){

  if (timeout > 0){
    while (timeout && (dma_poll_rx_idle()==0)){
      usleep(1);
      timeout--;
    }
    if (! timeout) {
      printf("ERROR:  timeout waiting for RX to reach IDLE.\r\n");
      return 0;
    } else if (VERBOSE) {
      printf("INFO:  DMA RX IDLE state reached  (timeout=%d) \r\n", timeout);
    }
  }
  return timeout;
}





//
// Buffer Descriptor Utilities:
//

unsigned dma_valid_bd (hw_addr_t bd_addr){
  // check that bd_addr is a valid non-zero address pointing to properly initialized BD.

  if (bd_addr == 0){
    printf("ERROR:  bd_addr is 0, likely not initialized\r\n");
    return 0;
  }

  hw_ptr_t bd = dma_ptr(bd_addr);
  if (bd == NULL){
    printf("ERROR:  BD pointer is NULL.\r\n");
    return 0;
  }

  HW_INVALIDATE_DCACHE(bd, DMA_BD_BYTES);
  if (bd[DMA_BD_NXTDESC] == 0){
    printf("ERROR:  next BD addr is 0, BD not properly initialized\r\n");
    return 0;
  }
  if (bd[DMA_BD_BUFFER_ADDRESS] == 0) {
    printf("ERROR:  buffer address is 0, BD not properly initialized\r\n");
    return 0;
  }
  if ((bd[DMA_BD_CONTROL] & DMA_BD_CONTROL_LEN) == 0) {
    printf("ERROR:  buffer address length is 0, BD not properly initialized\r\n");
    return 0;
  }
  return 1;
}

hw_val_t dma_read_bd_status  (hw_addr_t bd_addr){
  hw_ptr_t bd = dma_ptr(bd_addr);
  HW_INVALIDATE_DCACHE(bd, DMA_BD_BYTES);
  return bd[DMA_BD_STATUS];
}
void dma_write_bd_status(hw_addr_t bd_addr, hw_val_t value){
  hw_ptr_t bd = dma_ptr(bd_addr);
  bd[DMA_BD_STATUS] = value;
  HW_FLUSH_DCACHE(bd, DMA_BD_BYTES);
}

void dma_clear_bd_status(hw_addr_t bd_addr) {
  dma_write_bd_status(bd_addr, 0);
}

hw_addr_t dma_get_next_bd_addr(hw_addr_t bd_addr){
  hw_ptr_t bd = dma_ptr(bd_addr);
  HW_INVALIDATE_DCACHE(bd, DMA_BD_BYTES);
  return bd[DMA_BD_NXTDESC];
}

hw_val_t dma_poll_bd_complete (hw_addr_t bd_addr){
  return ((dma_read_bd_status(bd_addr) & DMA_BD_STATUS_COMPLETE)==0)?0:1;
}

hw_val_t dma_poll_bd_transferred (hw_addr_t bd_addr){
  return (dma_read_bd_status(bd_addr) & DMA_BD_STATUS_TRANSFERRED);
}



unsigned dma_count_bd_ring(hw_addr_t bd_addr){
  unsigned count = 0;
  hw_addr_t cur_addr = bd_addr;

  do {
    if (!dma_valid_bd(cur_addr)){
      printf("ERROR: invalid BD detected at depth %d with HW address 0x%08X \r\n", count, (unsigned int) cur_addr);
      return 0;
    }
    if (count >= DMA_MAX_BD_RING_SIZE) {
      printf("ERROR: BD ring size exceeds max limit, possible corruption\r\n");
      return 0;
    }
    cur_addr = dma_get_next_bd_addr(cur_addr);
    count++;
  } while (cur_addr != bd_addr);

  return count;
}

void dma_init_bd(hw_addr_t bd_addr, hw_addr_t next_addr, hw_addr_t buf_addr, hw_val_t buf_size, hw_val_t bd_flags, hw_val_t bd_status){
  if (buf_size > DMA_BD_CONTROL_LEN){
    printf("ERROR:  requested buffer size is larger than DMA_BD_CONTROL_LEN");
    return;
  }

  hw_ptr_t bd = dma_ptr(bd_addr);

  for (int i=0; i<DMA_BD_WORDS; i++){
    bd[i] = 0;
  }
  bd[DMA_BD_NXTDESC]            = (hw_val_t) next_addr;
  bd[DMA_BD_BUFFER_ADDRESS]     = (hw_val_t) buf_addr;
  bd[DMA_BD_CONTROL] = buf_size | bd_flags;
  bd[DMA_BD_STATUS]  = bd_status;

  HW_FLUSH_DCACHE(bd, DMA_BD_BYTES);

  dma_clear_buffer(bd_addr);
}


void dma_init_bd_ring (hw_addr_t bd_addr, unsigned nring, hw_val_t buf_size, hw_val_t bd_flags,  hw_val_t bd_status){
  const hw_addr_t align_mask = DMA_BUFFER_ALIGN_BYTES-1;

  hw_addr_t aligned_size  = (align_mask + buf_size) & ~align_mask;
  printf("INFO:  size of each buffer: 0x%08X, aligned size:  0x%08X\r\n", (unsigned int) buf_size, (unsigned int) aligned_size);

  hw_addr_t buf_addr       = bd_addr + nring*DMA_BD_BYTES;
  printf("INFO:  first free address above BDs:     0x%08X\r\n", (unsigned int) buf_addr);
  buf_addr = (align_mask + buf_addr) & ~ align_mask; // this bit alignment using the 2^n - 1 trick
  printf("INFO:  aligned start of buffer:          0x%08X\r\n", (unsigned int) buf_addr);

  for (int i = 0; i < nring; i++) {
    int inxt = (i+1) % nring;
    hw_addr_t bda = bd_addr + i * DMA_BD_BYTES;

    hw_addr_t nxa = bd_addr + inxt * DMA_BD_BYTES;
    hw_addr_t bfa = buf_addr + i * aligned_size;

    dma_safe_buffer(bfa, buf_size);


    printf("INFO:  buffer descriptor %3d:  addr: 0x%08X nxt: 0x%08X buf: 0x%08X len:  0x%08X \r\n", i, (unsigned int) bda, (unsigned int) nxa, (unsigned int) bfa, (unsigned int) buf_size);
    dma_init_bd(bda, nxa, bfa, buf_size, bd_flags, bd_status);
  }
  printf("INFO:  first free address above buffer:  0x%08X\r\n", (unsigned int) (buf_addr + nring*aligned_size));
}

void dma_show_bd_ring(hw_addr_t bd_addr) {
  unsigned count = 0;
  hw_addr_t cur_addr = bd_addr;

  unsigned bd_ring_count = dma_count_bd_ring(bd_addr);
  if (bd_ring_count == 0){
    printf("ERROR: invalid ring detected with ring size zero.\r\n");
    return;
  }

  printf("INFO:  showing BD ring contents: \r\n");
  printf("   i:   addr         next         buf          control      status\r\n");
  do {
    hw_ptr_t bd = dma_ptr(cur_addr);
    HW_INVALIDATE_DCACHE(bd, DMA_BD_BYTES);
    hw_addr_t nxt_addr = bd[DMA_BD_NXTDESC];
    hw_addr_t buf_addr = bd[DMA_BD_BUFFER_ADDRESS];
    hw_val_t control   = bd[DMA_BD_CONTROL];
    hw_val_t status    = bd[DMA_BD_STATUS];
    printf("%4d:   0x%08X   0x%08X   0x%08X   0x%08X   0x%08X\r\n", count,
	   (unsigned int) cur_addr, (unsigned int) nxt_addr, (unsigned int) buf_addr,
	   (unsigned int) control, (unsigned int) status);

    cur_addr = nxt_addr;
    count++;
  } while (cur_addr != bd_addr);
  printf("INFO:  size of BD ring is %d \r\n", count);
  printf("INFO:  size as reported by dma_count_bd_ring() is %d \r\n", bd_ring_count);
}


//
// Buffer Descriptor Utilities:
//

hw_ptr_t dma_get_buffer(hw_addr_t bd_addr){
  hw_ptr_t bd = dma_ptr(bd_addr);
  HW_INVALIDATE_DCACHE(bd, DMA_BD_BYTES);
  return dma_ptr(bd[DMA_BD_BUFFER_ADDRESS]);
}

void dma_clear_buffer(hw_addr_t bd_addr) {
  hw_ptr_t bd = dma_ptr(bd_addr);
  HW_INVALIDATE_DCACHE(bd, DMA_BD_BYTES);

  hw_ptr_t buf = dma_ptr(bd[DMA_BD_BUFFER_ADDRESS]);
  unsigned len = bd[DMA_BD_CONTROL]&DMA_BD_CONTROL_LEN;

  if (buf==NULL){
    printf("ERROR:  BD not initialized.\r\n");
    return;
  }

  if (VERBOSE)
    printf("INFO:  clearing buffer of size 0x%x (%d)\r\n", (unsigned int) len, len);
  for (int i=0; i<len/4; i++){
    buf[i]=0;
  }

  HW_FLUSH_DCACHE(buf, len);
}

void dma_clear_buffer_ring(hw_addr_t bd_addr){
  hw_addr_t cur_addr = bd_addr;

  unsigned bd_ring_count = dma_count_bd_ring(bd_addr);
  if (bd_ring_count == 0){
    printf("ERROR: invalid ring detected with ring size zero.\r\n");
    return;
  }

  do {
    dma_clear_buffer(cur_addr);
    cur_addr = dma_get_next_bd_addr(cur_addr);
  } while (cur_addr != bd_addr);
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
    // putting LSBs to the right in each column:
    int ibuf = i + (ncol-1) - 2*(i%ncol);
    if ((i%ncol)==0)
      printf("%4d: ", i/ncol);
    printf("0x%08x ", (unsigned int) buf[ibuf]);
    if (((i+1)%ncol)==0)
      printf("\r\n");
  }
  if (words%ncol)
    printf("\r\n");
}

void dma_show_buffer(hw_addr_t bd_addr, int ncol, int max_words){
  hw_ptr_t bd = dma_ptr(bd_addr);
  HW_INVALIDATE_DCACHE(bd, DMA_BD_BYTES);

  hw_ptr_t buf = dma_ptr(bd[DMA_BD_BUFFER_ADDRESS]);
  hw_val_t len = bd[DMA_BD_CONTROL] & DMA_BD_CONTROL_LEN;

  dma_print_buffer(buf, len, ncol, max_words);
}

void dma_show_buffer_ring(hw_addr_t bd_addr, int ncol, int max_words){
  unsigned count = 0;
  hw_addr_t cur_addr = bd_addr;

  unsigned bd_ring_count = dma_count_bd_ring(bd_addr);
  if (bd_ring_count == 0){
    printf("ERROR: invalid ring detected with ring size zero.\r\n");
    return;
  }

  do {
    printf("INFO:  contents of buffer %d\r\n", count);
    dma_show_buffer(cur_addr, ncol, max_words);
    cur_addr = dma_get_next_bd_addr(cur_addr);
    count++;
  } while (cur_addr != bd_addr);
}


void dma_show_transferred(hw_addr_t bd_addr, int ncol, int max_words){
  if (! dma_poll_bd_complete(bd_addr))
    return;

  hw_ptr_t bd = dma_ptr(bd_addr);
  HW_INVALIDATE_DCACHE(bd, DMA_BD_BYTES);

  hw_ptr_t buf = dma_ptr(bd[DMA_BD_BUFFER_ADDRESS]);
  hw_val_t len = bd[DMA_BD_STATUS]&DMA_BD_STATUS_TRANSFERRED;

  dma_print_buffer(buf, len, ncol, max_words);
}

void dma_show_transferred_ring(hw_addr_t bd_addr, int ncol, int max_words){
  unsigned count = 0;
  hw_addr_t cur_addr = bd_addr;

  unsigned bd_ring_count = dma_count_bd_ring(bd_addr);
  if (bd_ring_count == 0){
    printf("ERROR: invalid ring detected with ring size zero.\r\n");
    return;
  }

  do {
    printf("INFO:  transferred contents of buffer %d\r\n", count);
    dma_show_transferred(cur_addr, ncol, max_words);
    cur_addr = dma_get_next_bd_addr(cur_addr);
    count++;
  } while (cur_addr != bd_addr);
}


// show the current and tail BD HW addresses for TX/RX:
void dma_show_tx_current_tail_addrs(){
  printf("INFO:  TX current 0x%08X tail 0x%08X batch tail 0x%08X \r\n",
	 (unsigned int) dma_read_tx_curdesc(), (unsigned int) dma_read_tx_taildesc(), (unsigned int) dma_read_batch_tx_taildesc());
}

void dma_show_rx_current_tail_addrs(){
  printf("INFO:  RX current 0x%08X tail 0x%08X batch tail 0x%08X \r\n",
	 (unsigned int) dma_read_rx_curdesc(), (unsigned int) dma_read_rx_taildesc(), (unsigned int) dma_read_batch_rx_taildesc());
}

//
// Batch TX / RX:
//

static hw_addr_t G_BATCH_TX_TAILDESC_ADDR = 0;
static hw_addr_t G_BATCH_RX_TAILDESC_ADDR = 0;

void dma_init_batch_tx_taildesc(hw_addr_t addr){
  printf("INFO:  setting address of TX batch tail field to 0x%08X \r\n", (unsigned int) addr);
  G_BATCH_TX_TAILDESC_ADDR = addr;
}

void dma_init_batch_rx_taildesc(hw_addr_t addr){
  printf("INFO:  setting address of RX batch tail field to 0x%08X \r\n", (unsigned int) addr);
  G_BATCH_RX_TAILDESC_ADDR = addr;
}

void dma_write_batch_tx_taildesc(hw_addr_t bd_addr){
  hw_ptr_t taildesc = dma_ptr(G_BATCH_TX_TAILDESC_ADDR);
  *taildesc = (hw_val_t) bd_addr;
  HW_FLUSH_DCACHE(taildesc, 4);
}

void dma_write_batch_rx_taildesc(hw_addr_t bd_addr){
  hw_ptr_t taildesc = dma_ptr(G_BATCH_RX_TAILDESC_ADDR);
  *taildesc = (hw_val_t) bd_addr;
  HW_FLUSH_DCACHE(taildesc, 4);
}

hw_addr_t dma_read_batch_tx_taildesc(){
  hw_ptr_t taildesc = dma_ptr(G_BATCH_TX_TAILDESC_ADDR);
  HW_INVALIDATE_DCACHE(taildesc, 4);
  return *taildesc;
}

hw_addr_t dma_read_batch_rx_taildesc(){
  hw_ptr_t taildesc = dma_ptr(G_BATCH_RX_TAILDESC_ADDR);
  HW_INVALIDATE_DCACHE(taildesc, 4);
  return *taildesc;
}

unsigned dma_next_available_tx_bd(hw_addr_t * bd_addr){
  hw_addr_t nxta = dma_get_next_bd_addr(dma_read_batch_tx_taildesc());
  if (nxta == dma_read_tx_curdesc())
    return 0;
  if (! dma_poll_bd_complete(nxta))
    return 0;
  *bd_addr = nxta;
  return 1;
}

unsigned dma_next_available_rx_bd(hw_addr_t * bd_addr){
  hw_addr_t nxta = dma_get_next_bd_addr(dma_read_batch_rx_taildesc());
  if (nxta == dma_read_rx_curdesc())
    return 0;
  if (! dma_poll_bd_complete(nxta))
    return 0;
  *bd_addr = nxta;
  return 1;
}

void dma_add_tx_bd(hw_addr_t bd_addr){
  dma_clear_bd_status(bd_addr);
  dma_write_batch_tx_taildesc(bd_addr);
}

void dma_add_rx_bd(hw_addr_t bd_addr){
  dma_clear_bd_status(bd_addr);
  dma_write_batch_rx_taildesc(bd_addr);
}

void dma_tx_batch(){
  dma_write_tx_taildesc(dma_read_batch_tx_taildesc());
}

void dma_rx_batch(){
  dma_write_rx_taildesc(dma_read_batch_rx_taildesc());
}
