
PACMAN_UTIL=./pacman_util.py

# enable larpix power
ANALOG_PWR_EN_ADDR=0x00000014
ANALOG_PWR_EN_VALUE=1 # enable larpix power
$PACMAN_UTIL --write $ANALOG_PWR_EN_ADDR $ANALOG_PWR_EN_VALUE \

# set tile enable bit
TILE_EN_ADDR=0x00000010
TILE_EN_VALUE=0x00
$PACMAN_UTIL --write $TILE_EN_ADDR $TILE_EN_VALUE

# I2C direct access
MODE=0x24110
ENABLE=0x24111
ADDR=0x24112
REG=0x24113
BYTES=0x24114
DIRECT=0x24120
$PACMAN_UTIL --write $MODE 0 --write $ENABLE 1

SET_VDDA=0xFFFF
SET_VDDD=0x8000

# TILE 1 VDDA
$PACMAN_UTIL --write $ADDR 0x0C --write $REG  0x30 --write $BYTES  2
$PACMAN_UTIL --write $DIRECT 0
$PACMAN_UTIL --write $DIRECT $SET_VDDA

# TILE 1 VDDD
$PACMAN_UTIL --write $ADDR 0x0C --write $REG  0x31 --write $BYTES  2
$PACMAN_UTIL --write $DIRECT 0
$PACMAN_UTIL --write $DIRECT $SET_VDDD

# TILE 2 VDDA
#$PACMAN_UTIL --write $ADDR 0x0C --write $REG  0x32 --write $BYTES  2
#$PACMAN_UTIL --write $DIRECT 0
#$PACMAN_UTIL --write $DIRECT $SET_VDDA

# TILE 2 VDDD
#$PACMAN_UTIL --write $ADDR 0x0C --write $REG  0x33 --write $BYTES  2
#$PACMAN_UTIL --write $DIRECT 0
#$PACMAN_UTIL --write $DIRECT $SET_VDDD

# TILE 3 VDDA
#$PACMAN_UTIL --write $ADDR 0x0C --write $REG  0x34 --write $BYTES  2
#$PACMAN_UTIL --write $DIRECT 0
#$PACMAN_UTIL --write $DIRECT $SET_VDDA

# TILE 3 VDDD
#$PACMAN_UTIL --write $ADDR 0x0C --write $REG  0x35 --write $BYTES  2
#$PACMAN_UTIL --write $DIRECT 0
#$PACMAN_UTIL --write $DIRECT $SET_VDDD

# TILE 4 VDDA
#$PACMAN_UTIL --write $ADDR 0x0C --write $REG  0x36 --write $BYTES  2
#$PACMAN_UTIL --write $DIRECT 0
#$PACMAN_UTIL --write $DIRECT $SET_VDDA

# TILE 4 VDDD
#$PACMAN_UTIL --write $ADDR 0x0C --write $REG  0x37 --write $BYTES  2
#$PACMAN_UTIL --write $DIRECT 0
#$PACMAN_UTIL --write $DIRECT $SET_VDDD

# TILE 5 VDDA
#$PACMAN_UTIL --write $ADDR 0x0C --write $REG  0x38 --write $BYTES  2
#$PACMAN_UTIL --write $DIRECT 0
#$PACMAN_UTIL --write $DIRECT $SET_VDDA

# TILE 5 VDDD
#$PACMAN_UTIL --write $ADDR 0x0C --write $REG  0x39 --write $BYTES  2
#$PACMAN_UTIL --write $DIRECT 0
#$PACMAN_UTIL --write $DIRECT $SET_VDDD

# TILE 6 VDDA
#$PACMAN_UTIL --write $ADDR 0x0C --write $REG  0x3A --write $BYTES  2
#$PACMAN_UTIL --write $DIRECT 0
#$PACMAN_UTIL --write $DIRECT $SET_VDDA

# TILE 6 VDDD
#$PACMAN_UTIL --write $ADDR 0x0C --write $REG  0x3B --write $BYTES  2
#$PACMAN_UTIL --write $DIRECT 0
#$PACMAN_UTIL --write $DIRECT $SET_VDDD

# TILE 7 VDDA
#$PACMAN_UTIL --write $ADDR 0x0C --write $REG  0x3C --write $BYTES  2
#$PACMAN_UTIL --write $DIRECT 0
#$PACMAN_UTIL --write $DIRECT $SET_VDDA

# TILE 7 VDDD
#$PACMAN_UTIL --write $ADDR 0x0C --write $REG  0x3D --write $BYTES  2
#$PACMAN_UTIL --write $DIRECT 0
#$PACMAN_UTIL --write $DIRECT $SET_VDDD

# TILE 8 VDDA
#$PACMAN_UTIL --write $ADDR 0x0C --write $REG  0x3E --write $BYTES  2
#$PACMAN_UTIL --write $DIRECT 0
#$PACMAN_UTIL --write $DIRECT $SET_VDDA

# TILE 8 VDDD
#$PACMAN_UTIL --write $ADDR 0x0C --write $REG  0x3F --write $BYTES  2
#$PACMAN_UTIL --write $DIRECT 0
#$PACMAN_UTIL --write $DIRECT $SET_VDDD

# set tile enable bit
TILE_EN_ADDR=0x00000010
#TILE_EN_VALUE=0xFF
TILE_EN_VALUE=0x01
#TILE_EN_VALUE=0x02
$PACMAN_UTIL --write $TILE_EN_ADDR $TILE_EN_VALUE
