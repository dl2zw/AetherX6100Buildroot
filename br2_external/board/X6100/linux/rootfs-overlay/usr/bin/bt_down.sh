#!/bin/sh
#
# bt_down.sh [NAME] [CHANNEL]
#
# Powers the adapter down. Removes only our own SDP record (the frames
# channel, published as Dial-up Networking); the GUI's CAT record stays
# registered for the next power on. bluetoothd is left running.

log() { echo "bt_down: $*" >&2; }

if command -v sdptool >/dev/null 2>&1; then
    for h in $(sdptool browse local 2>/dev/null | awk '
            /^$/                  { n = "" }       # records end with a blank line
            /^Service Name:/      { n = substr($0, 15) }
            /^Service RecHandle:/ { if (n == "Dial-Up Networking") print $3 }'); do
        sdptool del "$h" >/dev/null 2>&1
    done
fi

bluetoothctl discoverable off >/dev/null 2>&1
bluetoothctl power off >/dev/null 2>&1
if [ -d /sys/class/bluetooth/hci0 ]; then
    hciconfig hci0 noscan >/dev/null 2>&1
    hciconfig hci0 down   >/dev/null 2>&1
fi

# The radio transmits enough RF of its own; do not leave a 2.4 GHz
# transmitter breathing next to the receiver when it is not in use.
rfkill block bluetooth >/dev/null 2>&1

log "down"
exit 0
