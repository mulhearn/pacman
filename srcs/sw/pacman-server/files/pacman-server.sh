#!/bin/sh
VDDD_DAC_ADDR=0x1C
VDDA_DAC_ADDR=0x1D

dac_config() {
  echo "Configuring i2c DACs..."
  /usr/sbin/i2cset -y 0 $VDDD_DAC_ADDR 0x08 0x00 0x00 i
  /usr/sbin/i2cset -y 0 $VDDA_DAC_ADDR 0x08 0x00 0x00 i
}

launch_cmdserver () {
  echo "Launching pacman-cmdserver..."
  pacman-cmdserver >> /var/log/pacman-cmdlog &
}

stop_cmdserver () {
  echo "Stopping pacman-cmdserver..."
  killall pacman-cmdserver
}

launch_dataserver () {
  echo "Launching pacman-dataserver..."
  pacman-dataserver >> /var/log/pacman-datalog &
}

stop_dataserver () {
  echo "Stopping pacman-dataserver..."
  killall pacman-dataserver
}


start () {
  dac_config
  launch_cmdserver
  launch_dataserver
}

stop () {
  stop_cmdserver
  stop_dataserver  
}

restart () {
  stop
  start
}

case $1 in
  start)
    start; ;;
  stop)
    stop; ;;
  restart)
    restart; ;;
  *)
    echo "Usage: $0 {start|stop|restart}"
    exit 1
esac

exit $?
