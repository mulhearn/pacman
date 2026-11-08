#ifndef ADC_H
#define ADC_H

#ifdef __cplusplus
extern "C" {
#endif

// GLOBAL REGISTERS:

#define SCOPE_ADC 0xD000
#define C_ADDR_ADC_STATUS  0x000
#define C_ADDR_ADC_CONFIG  0x004
#define C_ADDR_ADC_LOOK    0x010

// ADC driver initialization:
void adc_init();


// menu style hooks to ADC features:
void adc_read_registers();
void adc_toggle_sleep();
void adc_toggle_config();

#ifdef __cplusplus
}
#endif

#endif // ADC_H


