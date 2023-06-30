# mux_read.sh   use direct I2C access to read the MUX swiches
#
# In the output you will see 4 read replys, which are the current
# contents of the 0x00, 0x01, 0x02, and 0x03 registers of the MAX14661
# with contents:

# MUX is at I2C address 0b01001100 = 0x4C
# REG 0x00 is DIR0 direct r/w to MUX switches 8A-1A
# REG 0x01 is DIR1 direct r/w to MUX switches 16A-9A
# REG 0x02 is DIR2 direct r/w to MUX switches 8B-1B
# REG 0x03 is DIR3 direct r/w to MUX switches 16B-9B
# REG 0x14 is SET MUX A register
# REG 0x15 is SET MUX B register

PACMAN_UTIL=./pacman_util.py

# I2C direct access
MODE=0x24110
ENABLE=0x24111
ADDR=0x24112
REG=0x24113
BYTES=0x24114
DIRECT=0x24120

$PACMAN_UTIL --write $MODE 0 --write $ENABLE 1


$PACMAN_UTIL --write $ADDR 0x4C --write $REG 0x00 --write $BYTES 1
$PACMAN_UTIL --read $DIRECT

$PACMAN_UTIL --write $ADDR 0x4C --write $REG 0x01 --write $BYTES 1
$PACMAN_UTIL --read $DIRECT

$PACMAN_UTIL --write $ADDR 0x4C --write $REG 0x02 --write $BYTES 1
$PACMAN_UTIL --read $DIRECT

$PACMAN_UTIL --write $ADDR 0x4C --write $REG 0x03 --write $BYTES 1
$PACMAN_UTIL --read $DIRECT
