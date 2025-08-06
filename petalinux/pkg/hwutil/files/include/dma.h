#ifndef __DMA_H_
#define __DMA_H_

#include "hw_access.h"

#ifdef __cplusplus
extern "C" {
#endif

// DMA driver for AXI DMA (See PG021, as of June 24, 2025)
//
// All defines start with either DMA, MM2S, or S2MM and attempt to remain as close as possible to PG021.
//
// This is not a general purpose DMA driver.  It is specialized to the following AXI DMA IP Configuration:
// - Single AXI DMA Core for MM2S and S2MM (DMA 0)
// - Scatter Gather (GS) engine enabled
// - Configuration Stream disabled
// - Micro mode disabled
//
// Notation:
// - We refer to MM2S as transmitter (TX) and S2MM as receiver (RX)
// - We refer to buffer descriptors as BDs.

// 32-bit addressing
#define DMA_BYTES_PER_WORD 4

// From Table 4:  Scatter/Gather Mode Register Address Map:
#define MM2S_DMACR             0x00  // MM2S DMA Control Register
#define MM2S_DMASR             0x04  // MM2S DMA Status Register
#define MM2S_CURDESC           0x08  // MM2S Current Descriptor Pointer
#define MM2S_CURDESC_MSB       0x0C  // MM2S Current Descriptor Pointer (MSB)
#define MM2S_TAILDESC          0x10  // MM2S Tail Descriptor Pointer
#define MM2S_TAILDESC_MSB      0x14  // MM2S Tail Descriptor Pointer (MSB)
#define S2MM_DMACR             0x30  // S2MM DMA Control Register
#define S2MM_DMASR             0x34  // S2MM DMA Status Register
#define S2MM_CURDESC           0x38  // S2MM Current Descriptor Pointer
#define S2MM_CURDESC_MSB       0x3C  // S2MM Current Descriptor Pointer (MSB)
#define S2MM_TAILDESC          0x40  // S2MM Tail Descriptor Pointer
#define S2MM_TAILDESC_MSB      0x44  // S2MM Tail Descriptor Pointer (MSB)
// Note: SG_CTL at 0x2C is not used in this driver

// From Tables 6 and 16, with same bit layout for MM2S and S2M control registers:
#define DMACR_RUNSTOP             0x00000001  // Bit 0: Start/Stop DMA
#define DMACR_ALWAYS_ONE          0x00000002  // Bit 1: Reserved (always reads as 1)
#define DMACR_RESET               0x00000004  // Bit 2: Reset DMA engine (self-clearing)
#define DMACR_KEYHOLE             0x00000008  // Bit 3: Keyhole mode enable
#define DMACR_CYCLIC_BD           0x00000010  // Bit 4: Cyclic buffer descriptor enable
#define DMACR_IOC_IRQ_EN          0x00001000  // Bit 12: Interrupt On Complete Enable
#define DMACR_DLY_IRQ_EN          0x00002000  // Bit 13: Delay Interrupt Enable
#define DMACR_ERR_IRQ_EN          0x00004000  // Bit 14: Error Interrupt Enable
#define DMACR_IRQ_THRESHOLD_SHIFT 16          // Bits 16-23: Interrupt Threshold (8 bits)
#define DMACR_IRQ_THRESHOLD_MASK  0x00FF0000  // Bits 16-23 mask
#define DMACR_IRQ_DELAY_SHIFT     24          // Bits 24-31: Interrupt Delay (8 bits)
#define DMACR_IRQ_DELAY_MASK      0xFF000000  // Bits 24-31 mask
// Unlisted bits are reserved and are always read as zero.

// From Tables 7 and 17, with same bit layout for MM2S and S2M status registers:
#define DMASR_HALTED              0x00000001  // Bit 0: DMA channel halted
#define DMASR_IDLE                0x00000002  // Bit 1: DMA channel idle
#define DMASR_SGINCLD             0x00000008  // Bit 3: Scatter Gather Engine included
#define DMASR_DMA_INT_ERR         0x00000010  // Bit 4: Internal Error
#define DMASR_DMA_SEC_ERR         0x00000020  // Bit 5: Secondary Error (PG021 uses term "Slave")
#define DMASR_DMA_DEC_ERR         0x00000040  // Bit 6: Decode Error
#define DMASR_SG_INT_ERR          0x00000100  // Bit 8: SG Internal Error
#define DMASR_SG_SEC_ERR          0x00000200  // Bit 9: SG Secondary Error (PG021 uses term "Slave")
#define DMASR_SG_DEC_ERR          0x00000400  // Bit 10: SG Decode Error
#define DMASR_IOC_IRQ             0x00001000  // Bit 12: Interrupt On Complete
#define DMASR_DLY_IRQ             0x00002000  // Bit 13: Delay Interrupt
#define DMASR_ERR_IRQ             0x00004000  // Bit 14: Error Interrupt
#define DMASR_IRQ_THRESHOLD_SHIFT 16          // Bits 16-23: Interrupt Threshold (8 bits)
#define DMASR_IRQ_THRESHOLD_MASK  0x00FF0000  // Bits 16-23 mask
#define DMASR_IRQ_DELAY_SHIFT     24          // Bits 24-31: Interrupt Delay (8 bits)
#define DMASR_IRQ_DELAY_MASK      0xFF000000  // Bits 24-31 mask
// Unlisted bits are reserved and are always read as zero.

// Scatter Gather Descriptor Fields:

// Each BD is 16 32-bit words, for a total of 0x40 (64) bytes:
#define DMA_BD_WORDS 16   // 32-bit words
#define DMA_BD_BYTES 64

// From Table 25, converted to 32-bit array indices.
#define DMA_BD_NXTDESC            0  // 0x00: Next Descriptor Pointer (LSB)
#define DMA_BD_NXTDESC_MSB        1  // 0x04: Next Descriptor Pointer (MSB)
#define DMA_BD_BUFFER_ADDRESS     2  // 0x08: Buffer Address (LSB)
#define DMA_BD_BUFFER_ADDRESS_MSB 3  // 0x0C: Buffer Address (MSB)
#define DMA_BD_CONTROL            6  // 0x18: Control
#define DMA_BD_STATUS             7  // 0x1C: Status
// Note that the status field has a different interpretation for MM2S and S2MM (see below)

// Scatter Gather Descriptor Control Field bit layout for MM2S:
// From Tables 30 and 37,  with same bit layout for MM2S and S2M status registers.
// But note that SOF and EOF do not apply to S2MM CONTROL field with Micro mode disabled (our configuration).
#define DMA_BD_CONTROL_SOF        0x08000000
#define DMA_BD_CONTROL_EOF        0x04000000
#define DMA_BD_CONTROL_LEN        0x03FFFFFF

// Scatter Gather Descriptor Status Field bit layout for MM2S:
// From Tables 31 and 38, with same bit layout for MM2S and S2MM.
// But note that SOF and EOF only apply to S2MM in the BD CONTROL fireld.
#define DMA_BD_STATUS_COMPLETE    0x80000000
#define DMA_BD_STATUS_DECERR      0x40000000
#define DMA_BD_STATUS_SECERR      0x20000000
#define DMA_BD_STATUS_INTERR      0x10000000
#define DMA_BD_STATUS_SOF         0x08000000
#define DMA_BD_STATUS_EOF         0x04000000
#define DMA_BD_STATUS_TRANSFERRED 0x03FFFFFF

// suggested default timeout for DMA: (parameter timeout below)
#define DMA_TIMEOUT 100 // timeout=100 ==> 100 us maximum wait

// byte alignment for DMA buffers
# define DMA_BUFFER_ALIGN_BYTES 16

// the maximum number of BDs allowed in a ring (for sanity):
#define DMA_MAX_BD_RING_SIZE 1024

// read and display the status and control registers for TX/RX
void dma_show_tx_status (void);
void dma_show_rx_status (void);

// read and display a long format version the TX and RX status and control registers
void dma_show_long_status (void);

// RESET/HALT/RUN the TX/RX DMA engines (waits <timeout> for completion unless timeout=0)
// returns 0 for all errors and non-zero timeout remaining otherwise
unsigned dma_reset_tx (unsigned timeout);
unsigned dma_reset_rx (unsigned timeout);
unsigned dma_halt_tx  (unsigned timeout);
unsigned dma_halt_rx  (unsigned timeout);
unsigned dma_run_tx   (unsigned timeout);
unsigned dma_run_rx   (unsigned timeout);

// poll for RUN state of TX/RX
unsigned dma_poll_tx_run (void);
unsigned dma_poll_rx_run (void);
// wait for RUN state (waits <timeout> unless timeout=0)
unsigned dma_wait_tx_run (unsigned timeout);
unsigned dma_wait_rx_run (unsigned timeout);

// poll for HALT:
unsigned dma_poll_tx_halt();
unsigned dma_poll_rx_halt();

// read/write TX/RX current/tail buffer descriptor HW addresses:
// NOTE: checks for HALT state before writing current buffer descriptor.
hw_addr_t dma_read_tx_curdesc   (void);
hw_addr_t dma_read_rx_curdesc   (void);
hw_addr_t dma_read_tx_taildesc  (void);
hw_addr_t dma_read_rx_taildesc  (void);
void      dma_write_tx_curdesc  (hw_addr_t bd_addr); // DMA must be at HALT=1
void      dma_write_rx_curdesc  (hw_addr_t bd_addr); // DMA must be at HALT=1
void      dma_write_tx_taildesc (hw_addr_t bd_addr);
void      dma_write_rx_taildesc (hw_addr_t bd_addr);

// show the HW addresses for the current and tail BDs for TX and RX
void dma_show_tx_current_tail_addrs();
void dma_show_rx_current_tail_addrs();

// poll/clear the IOC flag for TX/RX
// NOTE: IOC flag is set even when the corresponding HW interrupt is disabled.
unsigned dma_poll_tx_ioc  (void);
unsigned dma_poll_rx_ioc  (void);
void     dma_clear_tx_ioc (void);
void     dma_clear_rx_ioc (void);

// wait on IOC flag to be raised (waits <timeout> unless timeout=0)
unsigned dma_wait_tx_ioc (unsigned timeout);
unsigned dma_wait_rx_ioc (unsigned timeout);

// poll for IDLE state of TX/RX
unsigned dma_poll_tx_idle (void);
unsigned dma_poll_rx_idle (void);

// wait for IDLE state (waits <timeout> unless timeout=0)
unsigned dma_wait_tx_idle (unsigned timeout);
unsigned dma_wait_rx_idle (unsigned timeout);



// Buffer Descriptor (BD) utitilies:

// sanity check that bd_addr points to a properly initialized BD (nonzero addresses and lengths)
unsigned dma_valid_bd (hw_addr_t bd_addr);

// read/write/clear the status field of BD at HW address bd_addr:
hw_val_t dma_read_bd_status   (hw_addr_t bd_addr);
void     dma_write_bd_status  (hw_addr_t bd_addr, hw_val_t value);
void     dma_clear_bd_status  (hw_addr_t bd_addr);

// poll if this BD has complete bit set in status field:
hw_val_t dma_poll_bd_complete (hw_addr_t bd_addr);

// poll length of transfer in this status field of this BD:
hw_val_t dma_poll_bd_transferred (hw_addr_t bd_addr);


// get the HW address of the next BD after the one at HW address <bd_addr>.
hw_addr_t dma_get_next_bd_addr (hw_addr_t bd_addr);

// count the number of valid BDs in the ring starting at HW address <bd_addr>:
// returns 0 if any invalid BD is detected, so checking dma_count_bd_ring() > 0 is a good sanity check on the ring.
unsigned dma_count_bd_ring (hw_addr_t bd_addr);

// initialize a BD located at HW address <bd_addr>, with next BD at HW address <nxt_addr>,
// buffer at HW address <buf_addr> of size <buf_size> in bytes,
// with BD flags set to <bd_flags> and status initialized to <bd_status>:
void dma_init_bd (hw_addr_t bd_addr, hw_addr_t next_addr, hw_addr_t buf_addr, hw_val_t buf_size, hw_val_t bd_flags,  hw_val_t bd_status);

// initialize a ring of <nring> consecutive BDs, with each BD initialized as above.
// buffers begin immediately above the ring of BDs, byte aligned to DMA_BUFFER_ALIGN_BYTES
void dma_init_bd_ring (hw_addr_t bd_addr, unsigned nring, hw_val_t buf_size, hw_val_t bd_flags,  hw_val_t bd_status);

// show ring of BDs starting at HW address <bd_addr>:
void dma_show_bd_ring (hw_addr_t bd_addr);

// Buffer utilities:

// get a pointer to the buffer associated with the BD at address <bd_addr>.
hw_ptr_t dma_get_buffer (hw_addr_t bd_addr);

// set to zero the contents of the buffer associated with the BD at address <bd_addr>.
void dma_clear_buffer (hw_addr_t bd_addr);
// as above but for the ring of buffers starting at HW addr <bd_addr>
void dma_clear_buffer_ring(hw_addr_t bd_addr);

// print the contents of the buffer associated with the BD at address <bd_addr>, in <ncol> column format
// the length of buffer is taken from control register, but show at most <max_words>
void dma_show_buffer (hw_addr_t bd_addr, int ncol, int max_words);
// as above but for the ring of buffers starting at HW addr <bd_addr>
void dma_show_buffer_ring (hw_addr_t bd_addr, int ncol, int max_words);

// print the *transferred* contents of the buffer associated with the BD at address <bd_addr>, in <ncol> column format
// the length of buffer is taken from status register, but show at most <max_words>
// CAREFUL: the address refers to BD, not the buffer associated with BD!
void dma_show_transferred (hw_addr_t bd_addr, int ncol, int max_words);
// as above but for the ring of buffers starting at HW addr <bd_addr>
void dma_show_transferred_ring (hw_addr_t bd_addr, int ncol, int max_words);


// Batch TX/RX support:

// Note: this sets the HW address where the tail HW address will be stored (pointer to pointer)
void dma_init_batch_tx_taildesc(hw_addr_t addr);
void dma_init_batch_rx_taildesc(hw_addr_t addr);

void dma_write_batch_tx_taildesc(hw_addr_t bd_addr);
void dma_write_batch_rx_taildesc(hw_addr_t bd_addr);

hw_addr_t dma_read_batch_tx_taildesc();
hw_addr_t dma_read_batch_rx_taildesc();

unsigned dma_next_available_tx_bd(hw_addr_t * bd_addr);
unsigned dma_next_available_rx_bd(hw_addr_t * bd_addr);

void dma_add_tx_bd(hw_addr_t bd_addr);
void dma_add_rx_bd(hw_addr_t bd_addr);

void dma_tx_batch();
void dma_rx_batch();

#ifdef __cplusplus
}
#endif

#endif // __DMA_H_
