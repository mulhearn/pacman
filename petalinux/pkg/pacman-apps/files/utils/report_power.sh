# checks VDDD/VDDA ADCs
# usage:
#    source report_power.sh
#
#PACMAN_UTIL=/home/root/pacman_util.py
PACMAN_UTIL=./pacman_util.py

READ_VDDA=0x24030 # base address to read ADC for VDDA
READ_VDDD=0x24040 # base address to read ADC for VDDA
READ_IDDA=0x24050 # base address to read ADC for IDDA
READ_IDDD=0x24060 # base address to read ADC for IDDA

for TILE in $(seq 1 10); do
    #echo $TILE
    REG_VDDA=$(( $READ_VDDA + $TILE - 1 ))
    REG_VDDD=$(( $READ_VDDD + $TILE - 1 ))
    REG_IDDA=$(( $READ_IDDA + $TILE - 1 ))
    REG_IDDD=$(( $READ_IDDD + $TILE - 1 ))

    python -c "print(\"TILE ${TILE}:\")"

    # EXAMPLE READ_RESPONSE:
    #READ_RESP="'READ' | '0x24031' | '0x578'"
    
    READ_RESP=$($PACMAN_UTIL --read $REG_VDDA | grep 'READ')
    python -c "adc=int(\"\"\"${READ_RESP}\"\"\".split()[-1].split('x')[-1].strip('\'L'),16); print('VDDA: %.0f mV ' % adc);"

    READ_RESP=$($PACMAN_UTIL --read $REG_VDDD | grep 'READ')
    python -c "adc=int(\"\"\"${READ_RESP}\"\"\".split()[-1].split('x')[-1].strip('\'L'),16); print('VDDD: %.0f mV ' % adc);"

    READ_RESP=$($PACMAN_UTIL --read $REG_IDDA | grep 'READ')
    python -c "adc=int(\"\"\"${READ_RESP}\"\"\".split()[-1].split('x')[-1].strip('\'L'),16); print('VDDA: %.0f mA ' % adc);"

    READ_RESP=$($PACMAN_UTIL --read $REG_IDDD | grep 'READ')
    python -c "adc=int(\"\"\"${READ_RESP}\"\"\".split()[-1].split('x')[-1].strip('\'L'),16); print('VDDD: %.0f mA ' % adc);"

done
    


        


