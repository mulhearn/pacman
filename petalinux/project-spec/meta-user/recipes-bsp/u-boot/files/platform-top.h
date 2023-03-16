#include <configs/zynq-common.h>
#include <configs/platform-auto.h>

#define CONFIG_PREBOOT    "echo U-BOOT for petalinux;echo importing env from FSBL shared area at 0xFFFFFC00; if itest *0xFFFFFC00 == 0xCAFEBABE; then echo Found valid magic; env import -t 0xFFFFFC04; fi;setenv preboot; echo; dhcp"
