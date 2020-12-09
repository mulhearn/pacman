# disable all tiles and then power off
PACMAN_UTIL=/home/root/pacman_util.py

TILE_EN_ADDR=0x00000010
TILE_EN_VALUE=0b00000000 # disable all tiles

ANALOG_PWR_EN_ADDR=0x00000014
ANALOG_PWR_EN_VALUE=0 # disable larpix power

$PACMAN_UTIL \
    --write $TILE_EN_ADDR $TILE_EN_VALUE \
    --write $ANALOG_PWR_EN_ADDR $ANALOG_PWR_EN_VALUE
