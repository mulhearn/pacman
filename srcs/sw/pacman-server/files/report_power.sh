# checks VDDD/VDDA ADCs
# usage:
#    source report_power.sh
#
#PACMAN_UTIL=/home/root/pacman_util.py
PACMAN_UTIL=./pacman_util.py

ADCS=( "VDDA" "IDDA" "VDDD" "IDDD" )
ADC_READ_ADDR=0x00024001 # base address to read for ADC channels
for TILE in $(seq 1 8); do
    echo $TILE
    for ADC in ${ADCS[@]}; do
        case $ADC in
            'VDDD')
                OFFSET=$(( ($TILE - 1) * 32 + 17 ))
            ;;
            'IDDD')
                OFFSET=$(( ($TILE - 1) * 32 + 16 ))
            ;;
            'VDDA')
                OFFSET=$(( ($TILE - 1) * 32 + 1 ))
            ;;
            'IDDA')
                OFFSET=$(( ($TILE - 1) * 32 ))
                ;;
        esac
        TILE_ADC_READ_ADDR=$(( $ADC_READ_ADDR + $OFFSET ))
        READ_RESP=$($PACMAN_UTIL \
                        --read $TILE_ADC_READ_ADDR | grep 'READ')
        case $ADC in
            'VDDD' | 'VDDA')
                python -c "adc=int(\"\"\"${READ_RESP}\"\"\".split()[-1].split('x')[-1].strip('\'L'),16); print('${ADC}: %f mV ' % (((adc >> 16) >> 3) * 4))"
                ;;
            'IDDD' | 'IDDA')
                python -c "adc=int(\"\"\"${READ_RESP}\"\"\".split()[-1].split('x')[-1].strip('\'L'),16); print('${ADC}: %f mA ' % (((adc >> 16) - (adc >> 31) * 65535) * 500 * 0.01))"
                ;;
        esac
    done
done

        


