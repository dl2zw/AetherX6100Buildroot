#!/bin/sh

if [ ! -d /sys/class/bluetooth ] || [ -z "$(ls /sys/class/bluetooth/ 2>/dev/null)" ]; then
    exit 0
fi

# The GUI's Bluetooth window remembers its On/Off in /mnt/bt.conf. If the
# operator switched Bluetooth off there, keep it off across reboots (the
# window brings it up again with bt_up.sh). Without that file nothing
# changes: the adapter comes up as before, for CAT.
if grep -q '^enabled=0' /mnt/bt.conf 2>/dev/null; then
    /usr/bin/bluetoothctl power off >/dev/null 2>&1
    rfkill block bluetooth 2>/dev/null
    exit 0
fi

/usr/bin/bluetoothctl power on
/usr/bin/bluetoothctl discoverable on
/usr/bin/bt-agent --capability=NoInputNoOutput >/dev/null 2>&1 &

/usr/bin/sdptool add SP
