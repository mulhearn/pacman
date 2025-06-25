#include "xil_printf.h"
#include "xil_types.h"
#include "xil_io.h"
#include "xparameters.h"

#include "xtime_l.h"
#include "xaxidma.h"
#include "xstatus.h"
#include "xil_printf.h"
#include "sleep.h"

#include "dma.h"

#define VERBOSE 1

//
// Local utility functions, not in header:
//

void print_dma_control(u32 value);
void print_dma_status(u32 value);
void print_dma_status_long(u32 value);
void print_dma_control_long(u32 value);



//
// Read/Write DMA register via the AXI-LITE control intefrace
//

u32  dma_read_register(u32 addr){
  return Xil_In32(DMA_REGISTERS_BASEADDR+addr);
}

void dma_write_register(u32 addr, u32 value){
  Xil_Out32(DMA_REGISTERS_BASEADDR+addr, value);
}

//
// Read and interpret the status and control registers:
//

void dma_show_tx_status(){
  u32 cr = dma_read_register(MM2S_DMACR);
  u32 sr = dma_read_register(MM2S_DMASR);
  print_dma_control(cr);
  print_dma_status(sr);
}

void dma_show_rx_status(){
  u32 cr = dma_read_register(MM2S_DMACR);
  u32 sr = dma_read_register(MM2S_DMASR);
  print_dma_control(cr);
  print_dma_status(sr);
}

void dma_show_long_status(){
  u32 cr, sr;
  xil_printf("INFO:  Long format of DMA TX status (MM2S): \r\n");
  cr = dma_read_register(MM2S_DMACR);
  sr = dma_read_register(MM2S_DMASR);
  print_dma_control_long(cr);
  print_dma_status_long(sr);
  xil_printf("INFO:  Long format of DMA RX status (S2MM): \r\n");
  cr = dma_read_register(S2MM_DMACR);
  sr = dma_read_register(S2MM_DMASR);
  print_dma_control_long(cr);
  print_dma_status_long(sr);
}



void print_dma_control(u32 value) {
    xil_printf("DMA Control: 0x%08x [", value);
    if (value & DMACR_RUNSTOP)     xil_printf(" RUN");
    if (value & DMACR_RESET)       xil_printf(" RESET");
    if (value & DMACR_KEYHOLE)     xil_printf(" KEYHOLE");
    if (value & DMACR_CYCLIC_BD)   xil_printf(" CYCLIC");
    if (value & DMACR_IOC_IRQ_EN)  xil_printf(" IOC_IRQ_EN");
    if (value & DMACR_DLY_IRQ_EN)  xil_printf(" DLY_IRQ_EN");
    if (value & DMACR_ERR_IRQ_EN)  xil_printf(" ERR_IRQ_EN");
    xil_printf(" ]\r\n");
}

void print_dma_status(u32 value) {
  xil_printf("DMA Status: 0x%08x [", value);
  if (value & DMASR_HALTED)      xil_printf(" HALTED");
  if (value & DMASR_IDLE)        xil_printf(" IDLE");
  if (value & DMASR_SGINCLD)     xil_printf(" SG");
  if (value & DMASR_DMA_INT_ERR) xil_printf(" DMA_INT_ERR");
  if (value & DMASR_DMA_SEC_ERR) xil_printf(" DMA_SEC_ERR");
  if (value & DMASR_DMA_DEC_ERR) xil_printf(" DMA_DEC_ERR");
  if (value & DMASR_SG_INT_ERR)  xil_printf(" SG_INT_ERR");
  if (value & DMASR_SG_SEC_ERR)  xil_printf(" SG_SEC_ERR");
  if (value & DMASR_SG_DEC_ERR)  xil_printf(" SG_DEC_ERR");
  if (value & DMASR_IOC_IRQ)     xil_printf(" IOC_IRQ");
  if (value & DMASR_DLY_IRQ)     xil_printf(" DLY_IRQ");
  if (value & DMASR_ERR_IRQ)     xil_printf(" ERR_IRQ");
  xil_printf(" ]\r\n");
}

void print_dma_status_long(u32 value) {
    xil_printf("DMA Status Register: 0x%08x\r\n", value);
    xil_printf("  HALTED      : %s\r\n", (value & DMASR_HALTED) ? "Yes" : "No");
    xil_printf("  IDLE        : %s\r\n", (value & DMASR_IDLE) ? "Yes" : "No");
    xil_printf("  SG Included : %s\r\n", (value & DMASR_SGINCLD) ? "Yes" : "No");

    xil_printf("  DMA Errors  : INT=%d, SEC=%d, DEC=%d\r\n",
        !!(value & DMASR_DMA_INT_ERR),
        !!(value & DMASR_DMA_SEC_ERR),
        !!(value & DMASR_DMA_DEC_ERR));

    xil_printf("  SG Errors   : INT=%d, SEC=%d, DEC=%d\r\n",
        !!(value & DMASR_SG_INT_ERR),
        !!(value & DMASR_SG_SEC_ERR),
        !!(value & DMASR_SG_DEC_ERR));

    xil_printf("  IRQ Flags   : IOC=%d, DLY=%d, ERR=%d\r\n",
        !!(value & DMASR_IOC_IRQ),
        !!(value & DMASR_DLY_IRQ),
        !!(value & DMASR_ERR_IRQ));
    xil_printf("  IRQ Threshold Status: %d\r\n", (value & DMASR_IRQ_THRESHOLD_MASK) >> DMASR_IRQ_THRESHOLD_SHIFT);
    xil_printf("  IRQ Delay Status    : %d\r\n", (value & DMASR_IRQ_DELAY_MASK) >> DMASR_IRQ_DELAY_SHIFT);
}

void print_dma_control_long(u32 value) {
    xil_printf("DMA Control Register: 0x%08x\r\n", value);
    xil_printf("  RUN/STOP     : %s\r\n", (value & DMACR_RUNSTOP) ? "Running" : "Stopped");
    xil_printf("  RESET        : %s\r\n", (value & DMACR_RESET) ? "Asserted" : "Inactive");
    xil_printf("  KEYHOLE      : %s\r\n", (value & DMACR_KEYHOLE) ? "Enabled" : "Disabled");
    xil_printf("  CYCLIC BD    : %s\r\n", (value & DMACR_CYCLIC_BD) ? "Enabled" : "Disabled");

    xil_printf("  IRQ Enables  : IOC=%d, DLY=%d, ERR=%d\r\n",
        !!(value & DMACR_IOC_IRQ_EN),
        !!(value & DMACR_DLY_IRQ_EN),
        !!(value & DMACR_ERR_IRQ_EN));

    xil_printf("  IRQ Threshold: %d\r\n", (value & DMACR_IRQ_THRESHOLD_MASK) >> DMACR_IRQ_THRESHOLD_SHIFT);
    xil_printf("  IRQ Delay    : %d\r\n", (value & DMACR_IRQ_DELAY_MASK) >> DMACR_IRQ_DELAY_SHIFT);
}



//
// DMA states  RESET/HALT/IDLE:
//


// reset the TX
void dma_reset_tx(unsigned timeout){
  xil_printf("INFO:  Resetting DMA TX \r\n");
  dma_write_register(MM2S_DMACR, DMACR_RESET);

  if (timeout > 0){
    while (timeout && (dma_read_register(MM2S_DMACR) & DMACR_RESET)){ usleep(10); timeout--; }
    if (! timeout) {
      xil_printf("ERROR:  timeout wating on RESET to clear.\r\n");
      return;
    }
  }
  if (VERBOSE)
    xil_printf("INFO:  DMA reset complete.  (timeout=%d) \r\n", timeout);
}

// reset the RX
void dma_reset_rx(unsigned timeout){
  xil_printf("INFO:  Resetting DMA RX \r\n");
  dma_write_register(S2MM_DMACR, DMACR_RESET);

  if (timeout>0){
    while (timeout && (dma_read_register(S2MM_DMACR) & DMACR_RESET)){ usleep(10); timeout--; }

    if (! timeout) {
      xil_printf("ERROR:  timeout wating on RESET to clear.\r\n");
      return;
    }
  }
  if (VERBOSE)
    xil_printf("INFO:  DMA reset complete.  (timeout=%d) \r\n", timeout);
}

void dma_halt_tx(unsigned timeout){
  xil_printf("INFO:  Stopping DMA TX \r\n");
  dma_write_register(MM2S_DMACR, 0);

  if (timeout > 0){
    while (timeout && ((dma_read_register(MM2S_DMACR) & DMACR_RUNSTOP)||((dma_read_register(MM2S_DMASR) & DMASR_HALTED)==0))){
      usleep(10);
      timeout--;
    }
    if (! timeout) {
      xil_printf("ERROR:  timeout wating on HALT state.\r\n");
      return;
    }
  }
  if (VERBOSE)
    xil_printf("INFO:  DMA halt complete.  (timeout=%d) \r\n", timeout);
}

void dma_halt_rx(unsigned timeout){
  xil_printf("INFO:  Stopping DMA RX \r\n");
  dma_write_register(S2MM_DMACR, 0);

  if (timeout > 0){
    while (timeout && ((dma_read_register(S2MM_DMACR) & DMACR_RUNSTOP)||((dma_read_register(S2MM_DMASR) & DMASR_HALTED)==0))){
      usleep(10);
      timeout--;
    }
    if (! timeout) {
      xil_printf("ERROR:  timeout wating on HALT state.\r\n");
      return;
    }
  }
  if (VERBOSE)
    xil_printf("INFO:  DMA is halted.  (timeout=%d) \r\n", timeout);
}

void dma_run_tx(unsigned timeout){
  xil_printf("INFO:  Starting DMA TX \r\n");
  dma_write_register(MM2S_DMACR, DMACR_RUNSTOP);

  if (timeout > 0){
    while (timeout && (((dma_read_register(MM2S_DMACR) & DMACR_RUNSTOP)==0)||(dma_read_register(MM2S_DMASR) & DMASR_HALTED))){
      usleep(10);
      timeout--;
    }
    if (! timeout) {
      xil_printf("ERROR:  timeout wating on RUN state.\r\n");
      return;
    }
  }
  if (VERBOSE)
    xil_printf("INFO:  DMA is running.  (timeout=%d) \r\n", timeout);
}

void dma_run_rx(unsigned timeout){
  xil_printf("INFO:  Starting DMA RX \r\n");
  dma_write_register(S2MM_DMACR, DMACR_RUNSTOP);

  if (timeout > 0){
    while (timeout && (((dma_read_register(S2MM_DMACR) & DMACR_RUNSTOP)==0)||(dma_read_register(S2MM_DMASR) & DMASR_HALTED))){
      usleep(10);
      timeout--;
    }
    if (! timeout) {
      xil_printf("ERROR:  timeout wating on RUN state.\r\n");
      return;
    }
  }
  if (VERBOSE)
    xil_printf("INFO:  DMA is running.  (timeout=%d) \r\n", timeout);
}

//
// IOC flags:
//

void dma_clear_tx_ioc(unsigned timeout){
  if (VERBOSE)
    xil_printf("INFO:  clearing DMA TX IOC flag\r\n");
  dma_write_register(MM2S_DMASR, DMASR_IOC_IRQ);

  if (timeout > 0){
    while (timeout && (dma_read_register(MM2S_DMASR) & DMASR_IOC_IRQ)){
      usleep(10);
      timeout--;
    }
    if (! timeout) {
      xil_printf("ERROR:  timeout wating for TX IOC to clear\r\n");
      return;
    }
  }
  if (VERBOSE)
    xil_printf("INFO:  DMA TX IOC flag is cleared  (timeout=%d) \r\n", timeout);
}

void dma_clear_rx_ioc(unsigned timeout){
  if (VERBOSE)
    xil_printf("INFO:  clearing DMA RX IOC flag\r\n");
  dma_write_register(S2MM_DMASR, DMASR_IOC_IRQ);

  if (timeout > 0){
    while (timeout && (dma_read_register(S2MM_DMASR) & DMASR_IOC_IRQ)){
      usleep(10);
      timeout--;
    }
    if (! timeout) {
      xil_printf("ERROR:  timeout wating for RX IOC to clear\r\n");
      return;
    }
  }
  if (VERBOSE)
    xil_printf("INFO:  DMA TX IOC flag is cleared  (timeout=%d) \r\n", timeout);
}


void dma_wait_tx_ioc(unsigned timeout){
  if (VERBOSE)
    xil_printf("INFO:  waiting for DMA TX IOC flag\r\n");

  if (timeout > 0){
    while (timeout && ((dma_read_register(MM2S_DMASR) & DMASR_IOC_IRQ)==0)){
      usleep(10);
      timeout--;
    }
    if (! timeout) {
      xil_printf("ERROR:  timeout waiting for TX IOC.\r\n");
      return;
    }
  }
  if (VERBOSE)
    xil_printf("INFO:  DMA TX IOC flag was raised  (timeout=%d) \r\n", timeout);
}

void dma_wait_rx_ioc(unsigned timeout){
  if (VERBOSE)
    xil_printf("INFO:  waiting for DMA RX IOC flag\r\n");

  if (timeout > 0){
    while (timeout && ((dma_read_register(S2MM_DMASR) & DMASR_IOC_IRQ)==0)){
      usleep(10);
      timeout--;
    }
    if (! timeout) {
      xil_printf("ERROR:  timeout wating for RX IOC\r\n");
      return;
    }
  }
  if (VERBOSE)
    xil_printf("INFO:  DMA RX IOC flag was raised  (timeout=%d) \r\n", timeout);
}


//
// Buffer Descriptor Utilities:
//

void dma_init_bd(u32 *bd, u32 *nxt, u32 *buf, u32 size_bytes, u32 flags){
  if (size_bytes > DMA_BD_CONTROL_LEN)
    size_bytes = DMA_BD_CONTROL_LEN;

  for (int i=0; i<16; i++){
    bd[i] = 0;
  }

  bd[DMA_BD_NXTDESC] = (u32) nxt;
  bd[DMA_BD_BUFFER_ADDRESS] = (u32) buf;
  bd[DMA_BD_CONTROL] = size_bytes | flags;

  Xil_DCacheFlushRange((UINTPTR)bd, DMA_BD_BYTES);

  dma_clear_buffer(bd);
}

void dma_init_single_bd_tx(u32 *bd, u32 *buf, u32 size_bytes){
  dma_init_bd(bd, bd, buf, size_bytes, DMA_BD_CONTROL_SOF | DMA_BD_CONTROL_EOF );
}

void dma_init_single_bd_rx(u32 *bd, u32 *buf, u32 size_bytes){
  dma_init_bd(bd, bd, buf, size_bytes, 0);
}

void dma_show_bd(u32 *bd) {
  Xil_DCacheInvalidateRange((UINTPTR)bd, DMA_BD_BYTES);

  u32 next_desc   = bd[DMA_BD_NXTDESC];
  u32 buffer_addr = bd[DMA_BD_BUFFER_ADDRESS];
  u32 control     = bd[DMA_BD_CONTROL];
  u32 status      = bd[DMA_BD_STATUS];

  xil_printf("DMA Buffer Descriptor:\r\n");
  xil_printf("  Next Descriptor : 0x%08x\r\n", next_desc);
  xil_printf("  Buffer Address  : 0x%08x\r\n", buffer_addr);
  xil_printf("  Control         : 0x%08x\r\n", control);
  xil_printf("  Status          : 0x%08x\r\n", status);
}

void dma_clear_bd_status(u32 *bd) {
  bd[DMA_BD_STATUS] = 0;
  Xil_DCacheFlushRange((UINTPTR)bd, DMA_BD_BYTES);
}


void dma_clear_buffer(u32 *bd) {
  Xil_DCacheInvalidateRange((UINTPTR)bd, DMA_BD_BYTES);

  u32 *buf = (u32*) bd[DMA_BD_BUFFER_ADDRESS];
  unsigned len = bd[DMA_BD_CONTROL]&DMA_BD_CONTROL_LEN;

  if (buf==NULL){
    xil_printf("ERROR:  BD not initialized.\r\n");
    return;
  }

  xil_printf("INFO: clearing buffer of size 0x%x (%d)\r\n", len, len);
  for (int i=0; i<len/4; i++){
    buf[i]=0;
  }

  Xil_DCacheFlushRange((UINTPTR)buf, len);
}

void dma_print_buffer(u32 *buf, unsigned len, int ncol) {
  if (buf==NULL){
    xil_printf("ERROR:  BD not initialized.\r\n");
    return;
  }
  Xil_DCacheInvalidateRange((UINTPTR)buf, len);

  int words = len / DMA_BYTES_PER_WORD;
  for (int i=0; i<words; i++){
    if ((i%ncol)==0)
      xil_printf("%4d: ", i/ncol);
    xil_printf("0x%08x ", buf[i]);
    if (((i+1)%ncol)==0)
      xil_printf("\r\n");
  }
  if (words%ncol)
    xil_printf("\r\n");
}

void dma_show_buffer(u32* bd, int ncol){
  Xil_DCacheInvalidateRange((UINTPTR)bd, DMA_BD_BYTES);

  u32 *buf = (u32*) bd[DMA_BD_BUFFER_ADDRESS];
  unsigned len = bd[DMA_BD_CONTROL]&DMA_BD_CONTROL_LEN;

  dma_print_buffer(buf, len, ncol);
}

void dma_show_transferred(u32* bd, int ncol){
  Xil_DCacheInvalidateRange((UINTPTR)bd, DMA_BD_BYTES);

  u32 *buf = (u32*) bd[DMA_BD_BUFFER_ADDRESS];
  unsigned len = bd[DMA_BD_STATUS]&DMA_BD_STATUS_TRANSFERRED;

  dma_print_buffer(buf, len, ncol);
}


void dma_single_tx(u32* bd){

  dma_halt_tx(DMA_TIMEOUT);
  dma_clear_bd_status(bd);

  dma_clear_tx_ioc(DMA_TIMEOUT);

  xil_printf("INFO: setting current descriptor address to 0x%08x\r\n", bd);
  dma_write_register(MM2S_CURDESC, (u32) bd);

  dma_run_tx(DMA_TIMEOUT);

  xil_printf("INFO: setting tail address to 0x%08x\r\n", bd);
  dma_write_register(MM2S_TAILDESC, (u32) bd);

}

void dma_single_rx(u32* bd){

  dma_halt_rx(DMA_TIMEOUT);
  dma_clear_bd_status(bd);

  dma_clear_rx_ioc(DMA_TIMEOUT);

  xil_printf("INFO: setting current descriptor address\r\n");
  dma_write_register(S2MM_CURDESC, (u32) bd);

  dma_run_rx(DMA_TIMEOUT);

  xil_printf("INFO: setting tail address\r\n");
  dma_write_register(S2MM_TAILDESC, (u32) bd);

}




