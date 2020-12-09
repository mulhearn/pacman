#!/bin/sh
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
