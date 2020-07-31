# sets VDDD to ~1.8V, VDDA to 1.8V, and brings up tile power
PACMAN_UTIL=/home/root/pacman_util.py
VDDD_DAC_ADDR=0x24001
VDDA_DAC_ADDR=0x24011
DAC_VALUE=0xdee4
TILE_EN_ADDR=0x10
$PACMAN_UTIL --write $VDDD_DAC_ADDR $DAC_VALUE --write $VDDA_DAC_ADDR $DAC_VALUE --write $TILE_EN_ADDR 0xFF
