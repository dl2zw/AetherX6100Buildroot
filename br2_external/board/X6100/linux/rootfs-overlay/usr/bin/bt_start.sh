#!/bin/sh

if [ ! -d /sys/class/bluetooth ] || [ -z "$(ls /sys/class/bluetooth/ 2>/dev/null)" ]; then
    exit 0
fi

if pidof rfcomm > /dev/null; then
    exit 0
fi

/usr/bin/bluetoothctl power on
/usr/bin/bluetoothctl discoverable on

/usr/bin/bt-agent --capability=NoInputNoOutput >/dev/null 2>&1 &

/usr/bin/sdptool add SP

/usr/bin/rfcomm watch rfcomm0 1 >/dev/null 2>&1 &
