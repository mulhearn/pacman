#!/bin/sh

start ()
{
    normal="\e[39m"
    lightgreen="\e[92m"
    yellow="\e[33m"

    echo -ne $yellow
    echo "Init Start"
    echo -ne $normal

    run_init_script() {
    local script_path="$1"
    if [ -f "$script_path" ]; then
        echo -ne $lightgreen
        echo "Run init.sh from SD card"
        echo -ne $normal
        tr -d '\r' < $script_path > /tmp/init.sh
        source /tmp/init.sh
        rm /tmp/init.sh
        #umount /media
    fi
    }

    # Check for init.sh in different locations
    locations=(
        "/media/sd-mmcblk1p1/init.sh"
        "/media/sd-mmcblk0p1/init.sh"
        "/run/media/mmcblk0p1/init.sh"
        "/run/media/mmcblk1p1/init.sh"
        "/run/media/SD-mmcblk0p1/init.sh"
        "/run/media/SD-mmcblk1p1/init.sh"
    )

    for location in "${locations[@]}"; do
        run_init_script "$location"
    done

    echo -ne $yellow
    echo "Init End"
    echo -ne $normal

}
stop ()
{
	echo " Stop."
}
restart()
{
	stop
	start
}
case "$1" in
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
