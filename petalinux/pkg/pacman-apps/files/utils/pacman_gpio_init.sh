#!/bin/sh

echo "INFO: initializing MIO pins"

for pin in "906" "913" "918" "919"; do
    echo $pin > /sys/class/gpio/export || true
    echo out > /sys/class/gpio/gpio${pin}/direction
done

echo 1 > /sys/class/gpio/gpio906/value
echo 1 > /sys/class/gpio/gpio913/value
echo 0 > /sys/class/gpio/gpio918/value
echo 0 > /sys/class/gpio/gpio919/value
usleep 100000
echo 0 > /sys/class/gpio/gpio913/value

