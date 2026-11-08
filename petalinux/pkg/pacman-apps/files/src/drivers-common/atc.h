#ifndef __ATC_H__
#define __ATC_H__

#ifdef __cplusplus
extern "C" {
#endif

#include <stdint.h>

// ASIC Timing and Control Registers
#define C_SCOPE_ATC 0xE000

#define C_ADDR_ATC_STATUS          0x000 //read only
#define C_ADDR_ATC_TIMESTAMP       0x004 //read only

#define C_ADDR_ATC_POKE_C          0x0C0
#define C_ADDR_ATC_POKE_D          0x0D0

#define C_ADDR_ATC_CONFIG_REQ      0x100
#define C_ADDR_ATC_POLARITY        0x108
#define C_ADDR_ATC_LOGIC           0x10C
#define C_ADDR_ATC_DST_LEMO_A      0x110
#define C_ADDR_ATC_DST_LEMO_B      0x114
#define C_ADDR_ATC_DST_POKE_C      0x118
#define C_ADDR_ATC_DST_POKE_D      0x11C
#define C_ADDR_ATC_DST_LOGIC_E     0x120
#define C_ADDR_ATC_DST_LOGIC_F     0x124

#define C_ADDR_ATC_COUNT_REQ       0x200
#define C_ADDR_ATC_COUNT           0x204 //read only

void read_atc_registers();

void set_atc_default_config();

#define C_ATC_BUSY_WAIT 10
int wait_atc_busy(int timeout);

void read_atc_counts();

void toggle_atc_destinations();

void send_poke_c();

void send_poke_d();

#ifdef __cplusplus
}
#endif

#endif // __ATC_H__
