#ifndef ASIC_MENU_H
#define ASIC_MENU_H

#include "hw_access.h"
#include "asic.h"

#ifdef __cplusplus
extern "C" {
#endif

// menu interface to ASIC driver:
void asic_menu();

// menu options:
void asic_full_reset();
void asic_internal_reset();
void asic_toggle_version();
void asic_toggle_rx_enables();
void asic_toggle_power();
void asic_config_root();
void asic_read_all();
void asic_hello();

#ifdef __cplusplus
}
#endif

#endif // ASIC_MENU_H
