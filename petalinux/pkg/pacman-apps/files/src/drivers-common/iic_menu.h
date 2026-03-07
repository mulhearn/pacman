#ifndef IIC_MENU_H
#define IIC_MENU_H

#include "hw_access.h"
#include "iic.h"

#ifdef __cplusplus
extern "C" {
#endif

// menu interface to ASIC driver:
void iic_menu();

// menu options:
void iic_show_status();
void iic_toggle_hardware_version();
void iic_toggle_power();
void iic_monitor_power();

#ifdef __cplusplus
}
#endif

#endif // ASIC_MENU_H
