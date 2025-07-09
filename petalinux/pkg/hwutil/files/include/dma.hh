#ifndef __DMA_HH_
#define __DMA_HH_

#include <stdint.h>

//
// Linux interface:
//

void init_dma();

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

// cleanup once working ...
#define DMA_REGISTERS_BASEADDR 0x40400000
#define DMA_REGISTERS_LEN      0x00010000
typedef uint32_t u32;

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
#define DMA_BD_WORDS        16   // 32-bit words
#define DMA_BD_BYTES        64

// From Table 25, converted to 32-bit array indices.
#define DMA_BD_NXTDESC               0  // 0x00: Next Descriptor Pointer (LSB)
#define DMA_BD_NXTDESC_MSB           1  // 0x04: Next Descriptor Pointer (MSB)
#define DMA_BD_BUFFER_ADDRESS        2  // 0x08: Buffer Address (LSB)
#define DMA_BD_BUFFER_ADDRESS_MSB    3  // 0x0C: Buffer Address (MSB)
#define DMA_BD_CONTROL               6  // 0x18: Control
#define DMA_BD_STATUS                7  // 0x1C: Status
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

// read/write DMA registers via the dedicated AXI-LITE control interface
u32  dma_read_register(u32 addr);
void dma_write_register(u32 addr, u32 value);

// read and display the status and control registers for TX/RX
void dma_show_tx_status();
void dma_show_rx_status();

// read and display a long format version the TX and RX status and control registers
void dma_show_long_status();

// reset/halt/run the  TX/RX DMA engines (waits <timeout> for completion unless timeout=0)
// suggested default timeout:
#define DMA_TIMEOUT 100 // timeout=1 ==> 100 us maximum wait
// returns 0 for all errors and non-zero timeout remaining otherwise
unsigned dma_reset_tx(unsigned timeout);
unsigned dma_reset_rx(unsigned timeout);
unsigned dma_halt_tx(unsigned timeout);
unsigned dma_halt_rx(unsigned timeout);
unsigned dma_run_tx(unsigned timeout);
unsigned dma_run_rx(unsigned timeout);

// clear IOC flags (waits <timeout> for completion unless timeout=0)
// (IOC flag is set even whem the corresponding HW interrupt is disable)
unsigned dma_clear_tx_ioc(unsigned timeout);
unsigned dma_clear_rx_ioc(unsigned timeout);
// wait on IOC flag to be raised (waits <timeout> unless timeout=0)
unsigned dma_wait_tx_ioc(unsigned timeout);
unsigned dma_wait_rx_ioc(unsigned timeout);

// poll IOC flag for tx/rx (single read, no timeout)
unsigned dma_poll_tx_ioc();
unsigned dma_poll_rx_ioc();



// scatter/gather buffer descriptors
// initialize a BD located at <bd>, with next BD at <nxt>, buffer at <buf> of size <size_bytes>.
// control flags <flags> are the defines DMA_BD_CONTROL_X
void dma_init_bd(u32 *bd, u32 *nxt, u32 *buf, u32 size_bytes, u32 flags);
// initialize a single BD with flags appropriate for TX (SOF / EOF)
void dma_init_single_bd_tx(u32 *bd, u32 *buf, u32 size_bytes);
// initialize a single BD with flags appropriate for RX
void dma_init_single_bd_rx(u32 *bd, u32 *buf, u32 size_bytes);
// show a BD:
void dma_show_bd(u32 *bd);
// clear the status field of a BD
void dma_clear_bd_status(u32* bd);
// print the contents of the buffer associated with the BD <bd>, in <ncol> column format.
// (i.e. length of buffer taken from control register)
void dma_show_buffer(u32* bd, int ncol, int max_words);
// print the *transferred* contents of the buffer associated with the BD, in <ncol> column format.
// (i.e. length of buffer taken from status register)
void dma_show_transferred(u32* bd, int ncol, int max_words);

// set the contents of the buffer associated with the BD <bd> to zero.
void dma_clear_buffer(u32* bd);

// single TX/RX request:
void dma_single_tx(u32* bd);
void dma_single_rx(u32* bd);













#endif // __RXTX_H_


