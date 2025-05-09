
// Modified from code of Antti Lukats (copyright 2015 Trenz Electronic GmbH)

#ifndef TRENZ_IDCODE_H_
#define TRENZ_IDCODE_H_

#include "xil_types.h"

#ifdef __cplusplus
extern "C" {
#endif

u32 te_read_IDCODE(void);

u32 TE_FsblHookBeforeHandoff_Custom(void);

#ifdef __cplusplus
}
#endif

#endif	/* end of protection macro */
