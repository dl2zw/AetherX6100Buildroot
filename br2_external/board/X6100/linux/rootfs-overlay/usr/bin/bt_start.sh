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

# Hidden and not pairable, as bt_up.sh leaves it. Devices paired before
# (a phone for CAT, a headset, a keyboard) still connect. New ones pair
# through the GUI's Bluetooth window, which opens pairing for a few
# minutes on Scan. No bt-agent: it accepted every pairing request, from
# anyone in range, until the window was opened. The CAT server only
# accepts paired devices.
/usr/bin/bluetoothctl power on
/usr/bin/bluetoothctl discoverable off
/usr/bin/bluetoothctl pairable off

/usr/bin/sdptool add SP
