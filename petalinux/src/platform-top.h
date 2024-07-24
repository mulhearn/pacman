#include <configs/zynq-common.h>

#define CONFIG_PREBOOT      "echo U-BOOT for Pac-Man card; setenv preboot; echo"

/* boot from SD card */
#define CONFIG_BOOTCOMMAND  "fatload mmc 0 0x08000000 image.ub ; bootm 0x08000000"
