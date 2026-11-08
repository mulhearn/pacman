#include <stdlib.h>

#include "hw_access.h"
#include "iic.h"
#include "iic_menu.h"


void iic_show_status(){
  printf("IIC status menu\n");
  printf("HW enum:  %u\n", (unsigned int) iic_get_hw_version());
  printf("platform status:   %u\n", (unsigned int) iic_platform_status());
}


void iic_toggle_hardware_version(){
  static int mode = 0;
  mode = (mode + 1) % 4;

  if (mode==0){
    printf("INFO: setting I2C HW version to latest (PACMAN 1V5)\r\n");
    iic_set_hw_version(1,5,0);
  } else if (mode==1){
    printf("INFO: setting I2C HW version to PACMAN 1V4 \r\n");
    iic_set_hw_version(1,4,0);
  } else if (mode==2){
    printf("INFO: setting I2C HW version to PACMAN 1V3 \r\n");
    iic_set_hw_version(1,3,0);
  } else {
    printf("INFO: setting I2C HW version to disabled \r\n");
    iic_set_hw_version(0,0,0);
  }
}

void iic_toggle_power(){
  unsigned vddd[] = {0x00, 0x2000, 0x4000, 0x8000, 0xFFFF};
  unsigned vdda[] = {0x00, 0x2000, 0x4000, 0x8000, 0xFFFF};
  static int mode = 0;
  mode = (mode + 1) % 5;

  printf("INFO: setting VDDD to 0x%x \r\n", vddd[mode]);
  for (int i=0; i<10; i++){
    iic_set_vddd_dn(i, vddd[mode]);
  }

  printf("INFO: setting VDDA to 0x%x \r\n", vdda[mode]);
  for (int i=0; i<10; i++){
    iic_set_vdda_dn(i, vdda[mode]);
  }
}

void iic_monitor_power(){
  for (int i=0; i<10; i++){
    printf("TILE %2d POWER SUMMARY:\r\n", i+1);
    unsigned vdda = iic_mon_vdda_mv(i);
    unsigned vddd = iic_mon_vddd_mv(i);
    unsigned idda = iic_mon_idda_ma(i);
    unsigned iddd = iic_mon_iddd_ma(i);

    printf("VDDA:  voltage:  %5d mV current: %5d mA\r\n", vdda, idda);
    printf("VDDD:  voltage:  %5d mV current: %5d mA\r\n", vddd, iddd);
  }

  printf("BOARD POWER SUMMARY:\r\n");

  unsigned vba = iic_mon_vboard_mv(0);
  unsigned vbb = iic_mon_vboard_mv(1);
  unsigned vbc = iic_mon_vboard_mv(2);
  unsigned vbd = iic_mon_vboard_mv(3);

  unsigned iba = iic_mon_iboard_ma(0);
  unsigned ibb = iic_mon_iboard_ma(1);
  unsigned ibc = iic_mon_iboard_ma(2);
  unsigned prb = iic_mon_probe_dn();
  printf("Board 3V6:  voltage:  %5d mV  current:  %5d mA\r\n",  vba, iba);
  printf("Board 3V3:  voltage:  %5d mV  current:  %5d mA\r\n",  vbb, ibb);
  printf("Board 3V0:  voltage:  %5d mV  current:  %5d mA\r\n",  vbc, ibc);
  printf("RTD Probe:  3V3:      %5d mV  current:  0x%04X DN\r\n",   vbd, prb);
}

void iic_menu(){
  printf("I2C menu:  \r\n");
  while(1){
    printf("choose an option:\r\n");
    printf("(x) Exit I2C menu (s) I2C status (v) toggle I2C HW version (c) check I2C (p) toggle power (m) monitor power \r\n");
    char input = input_choice();
    printf("INFO: selected %c\r\n", input);

    switch(input){
    case 'x':
      return;
    case 's':
      iic_show_status();
      break;
    case 'v':
      iic_toggle_hardware_version();
      break;
    case 'p':
      iic_toggle_power();
      break;
    case 'm':
      iic_monitor_power();
      break;
    default:
      printf("invalid selection...\r\n");
    }
  }

}
