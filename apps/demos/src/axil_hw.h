#ifndef __AXIL_H_
#define __AXIL_H_

#include "hardware.h"

// initialize the AXI-LITE interface for register access:
void init_axil_hw();

// report the status of the AXI-LITE interface:
int axil_status();

// clear any errors in the AXI-LITE interface:
void axil_clear_status();

// read the HW registers with offset <offset> relative to the AXI-LITE base address:
hw_val_t axil_read_register  (hw_adr_t offset);

// write <value> to the HW registers with offset <offset> relative to the AXI-LITE base address:
void     axil_write_register (hw_adr_t offset, hw_val_t value);

#endif // __AXIL_H_


