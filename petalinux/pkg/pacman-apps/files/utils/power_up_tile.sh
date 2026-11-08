# sets nominal voltages on a tile and then powers on
# usage:
#   source power_up_tile.sh <tile number 1-10>
#
TILE=$1

PACMAN_UTIL=/home/root/utils/pacman_util.py

# DAC values:
VDDD_DAC_VALUE=28000
VDDA_DAC_VALUE=58000

# Address for this TILE
VDDA_DAC_WRITE_ADDR=$(( 0x24010 + $TILE-1 ))
VDDD_DAC_WRITE_ADDR=$(( 0x24020 + $TILE-1 ))

# Write DAC registers
$PACMAN_UTIL \
    --write $VDDA_DAC_WRITE_ADDR $VDDA_DAC_VALUE \
    --write $VDDD_DAC_WRITE_ADDR $VDDD_DAC_VALUE

# enable tile power (global enable):
$PACMAN_UTIL  --string enable_tile_power

# set enable for this tile:
CMD="enable_tile tile="$TILE
$PACMAN_UTIL  --string "$CMD"
