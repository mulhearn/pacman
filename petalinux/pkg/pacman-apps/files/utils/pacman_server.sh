#!/bin/sh

### BEGIN INIT INFO
# Provides:          pacman_server
# Required-Start:    $remote_fs $syslog
# Required-Stop:     $remote_fs $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: PACMAN server daemon
### END INIT INFO

launch_cmdserver () {
  echo "Launching command server..."
  nohup /usr/bin/pacman_cmdserver >> /dev/null &
}

stop_cmdserver () {
  echo "Stopping command server..."
  killall pacman_cmdserver  
}

launch_dataserver () {
  echo "Launching data server..."
  nohup /usr/bin/pacman_dataserver >> /dev/null &
}

stop_dataserver () {
  echo "Stopping dataserver..."
  killall pacman_dataserver  
}


start () {
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
