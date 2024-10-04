# sets nominal voltages on a tile and then powers on
# usage:
#   source power_up_tile.sh <tile number 1-10>
#
TILE=$1

#PACMAN_UTIL=/home/root/pacman_util.py
PACMAN_UTIL=./pacman_util.py

# set dacs
VDDD_DAC_VALUE=43875 # just a guess, should be a touch low (~1.75V) from nominal
VDDA_DAC_VALUE=43875

VDDA_DAC_WRITE_ADDR=$(( 0x24010 + $TILE-1 ))
VDDD_DAC_WRITE_ADDR=$(( 0x24020 + $TILE-1 ))

# enable larpix power
ANALOG_PWR_EN_ADDR=0x00000014
ANALOG_PWR_EN_VALUE=1 # enable larpix power

# set tile enable bit
TILE_EN_ADDR=0x00000010
TILE_EN_READ_RESP=$($PACMAN_UTIL --read $TILE_EN_ADDR | grep 'READ')
TILE_EN_VALUE=$(python -c "print(int(\
\"\"\"${TILE_EN_READ_RESP}\"\"\".split()[-1].split('x')[-1].strip('\''),16) \
| (1 << (${TILE}-1)))")

# write registers
$PACMAN_UTIL \
    --write $VDDA_DAC_WRITE_ADDR $VDDA_DAC_VALUE \
    --write $VDDD_DAC_WRITE_ADDR $VDDD_DAC_VALUE \
    --write $ANALOG_PWR_EN_ADDR $ANALOG_PWR_EN_VALUE \
    --write $TILE_EN_ADDR $TILE_EN_VALUE
