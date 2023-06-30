# mux_tile1.sh   use direct I2C access to set MUX switches for tile 1
#
# Sets registers 0x00, 0x01, 0x02, and 0x03 registers of the MAX14661
# so that:
#
# Front Panel ADC_TEST_OUTPUT <= TILE1_ANA_MON
# Front Panel DAC_TEST_INPUT  => TILE1_ADC_TEST
#
# MAX14661 register map:
# MUX is at I2C address 0b01001100 = 0x4C
# REG 0x00 is DIR0 direct r/w to MUX switches 8A-1A
# REG 0x01 is DIR1 direct r/w to MUX switches 16A-9A
# REG 0x02 is DIR2 direct r/w to MUX switches 8B-1B
# REG 0x03 is DIR3 direct r/w to MUX switches 16B-9B
# REG 0x14 is SET MUX A register
# REG 0x15 is SET MUX B register
#
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
# REG 0x00 is DIR0 direct r/w to MUX switches 8A-1A
# REG 0x01 is DIR1 direct r/w to MUX switches 16A-9A
# REG 0x02 is DIR2 direct r/w to MUX switches 8B-1B
# REG 0x03 is DIR3 direct r/w to MUX switches 16B-9B
# REG 0x14 is SET MUX A register
# REG 0x15 is SET MUX B register

$PACMAN_UTIL --write $ADDR 0x4C --write $REG 0x00 --write $BYTES 1
$PACMAN_UTIL --write $DIRECT 0x01

$PACMAN_UTIL --write $ADDR 0x4C --write $REG 0x01 --write $BYTES 1
$PACMAN_UTIL --write $DIRECT 0x00

$PACMAN_UTIL --write $ADDR 0x4C --write $REG 0x02 --write $BYTES 1
$PACMAN_UTIL --write $DIRECT 0x02

$PACMAN_UTIL --write $ADDR 0x4C --write $REG 0x03 --write $BYTES 1
$PACMAN_UTIL --write $DIRECT 0x00
