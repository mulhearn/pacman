# disables tiles
PACMAN_UTIL=/home/root/pacman_util.py
TILE_EN_ADDR=0x10
$PACMAN_UTIL --write $TILE_EN_ADDR 0x00
