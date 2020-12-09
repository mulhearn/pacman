# sets nominal voltages on all tiles and then powers on 
PACMAN_UTIL=/home/root/pacman_util.py

DAC_WRITE_ADDR=0x000241B0 # write to all DAC channels
DAC_VALUE=45875 # just a guess, should be a touch low (~1.75V) from nominal

ANALOG_PWR_EN_ADDR=0x00000014
ANALOG_PWR_EN_VALUE=1 # enable larpix power

TILE_EN_ADDR=0x00000010
TILE_EN_VALUE=0b11111111 # enable all tiles

$PACMAN_UTIL \
    --write $DAC_WRITE_ADDR $DAC_VALUE \
    --write $ANALOG_PWR_EN_ADDR $ANALOG_PWR_EN_VALUE \
    --write $TILE_EN_ADDR $TILE_EN_VALUE

