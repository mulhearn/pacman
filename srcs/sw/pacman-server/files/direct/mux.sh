PACMAN_UTIL=./pacman_util.py

# I2C direct access
MODE=0x24110
ENABLE=0x24111
ADDR=0x24112
REG=0x24113
BYTES=0x24114
DIRECT=0x24120

$PACMAN_UTIL --write $MODE 0 --write $ENABLE 1

# MUX is at I2C address 0b01001100 = 0x4C
# REG 0x14 is SET MUX A register
# REG 0x15 is SET MUX B register

# ***TODO*** CHECK FOR CORRECT I vs O ASSIGNMENT (NOT DONE...)
# SET MUX TO TILE 1:
$PACMAN_UTIL --write $ADDR 0x4C --write $REG  0x14 --write $BYTES  1
$PACMAN_UTIL --write $DIRECT 0x0

$PACMAN_UTIL --write $ADDR 0x4C --write $REG  0x15 --write $BYTES  1
$PACMAN_UTIL --write $DIRECT 0x1

# SET MUX TO TILE 2:
#$PACMAN_UTIL --write $ADDR 0x4C --write $REG  0x14 --write $BYTES  1
#$PACMAN_UTIL --write $DIRECT 0x2

#$PACMAN_UTIL --write $ADDR 0x4C --write $REG  0x15 --write $BYTES  1
#$PACMAN_UTIL --write $DIRECT 0x3

