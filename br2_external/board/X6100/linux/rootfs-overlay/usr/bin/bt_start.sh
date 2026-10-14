#!/bin/sh

if [ ! -d /sys/class/bluetooth ] || [ -z "$(ls /sys/class/bluetooth/ 2>/dev/null)" ]; then
    exit 0
fi

# The GUI's Bluetooth window remembers its On/Off in /mnt/bt.conf. If the
# operator switched Bluetooth off there, keep it off across reboots (the
# window brings it up again with bt_up.sh). Otherwise the adapter comes up
# powered, hidden and not pairable (below), with the CAT Serial Port record.
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
#
# udev runs this as soon as hci0 appears, which can be before bluetoothd
# has the controller: bluetoothctl then only prints "No default controller
# available" and changes nothing. And bluetoothd restores Discoverable
# from /var/lib/bluetooth (kept across images by S39btstate), so a radio
# that ran the old bt_start.sh came back visible. So: repeat until
# bluetoothctl shows it powered, hidden and not pairable, at most 20 s.
# main.conf's DiscoverableTimeout / PairableTimeout are the safety net.
btctl() { /usr/bin/bluetoothctl "$@" >/dev/null 2>&1; }
bt_hidden() {
    s=$(/usr/bin/bluetoothctl show 2>/dev/null)
    echo "$s" | grep -q "Powered: yes" &&
        echo "$s" | grep -q "Discoverable: no" &&
        echo "$s" | grep -q "Pairable: no"
}
i=0
while :; do
    btctl power on
    btctl discoverable off
    btctl pairable off
    bt_hidden && break
    i=$((i + 1))
    if [ $i -ge 40 ]; then
        echo "bt_start: not hidden after 20 s:$(/usr/bin/bluetoothctl show 2>/dev/null |
            grep -E 'Powered|Discoverable|Pairable' | tr -s ' \t\n' ' ')" >&2
        break
    fi
    sleep 0.5
done

# The CAT Serial Port record (channel 1), only if it isn't there yet:
# bluetoothd keeps records across a new hci0 (WiFi off/on), so adding it
# every time piled up copies. The same check as bt_up.sh's.
if ! /usr/bin/sdptool browse local 2>/dev/null | awk '
        /^Service Name:/ { n = substr($0, 15) }
        /Channel:/       { if (n == "Serial Port" && $2 == 1) found = 1 }
        END              { exit !found }'; then
    /usr/bin/sdptool add SP
fi
