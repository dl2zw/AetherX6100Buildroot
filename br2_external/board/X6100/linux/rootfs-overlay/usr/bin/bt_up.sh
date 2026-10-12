#!/bin/sh
#
# bt_up.sh [NAME] [CHANNEL]
#
# Brings the Bluetooth adapter up for the GUI's Bluetooth window and the
# WSJT-X frames to the phone (x6100_gui bt_ctl.c runs this).
#
# - bluetoothd is started by S40bluetoothd with -nC (compat), so it is
#   never restarted here. Restarting it would drop every SDP record,
#   including the Serial Port record of the GUI's own CAT server.
# - The GUI listens for CAT (CI-V) on RFCOMM channel 1 and bt_start.sh
#   publishes that as Serial Port. Our frames use CHANNEL (2), published
#   as Dial-up Networking (UUID 0x1103), so the phone can look it up by
#   UUID: two Serial Port records could not be told apart.
# - If the adapter was off at boot, bt_start.sh stopped early and the CAT
#   record is missing; it is added here, so CAT works whenever BT is on.
# - No record is ever deleted except our own (bt_down.sh).

NAME="${1:-X6100}"
CHAN="${2:-2}"
BLUETOOTHD=/usr/libexec/bluetooth/bluetoothd

log() { echo "bt_up: $*" >&2; }
running() { ps | grep -v grep | grep -q "$1"; }
# One bluetoothctl run per command: in one-shot mode it waits for the
# adapter's reply. Piping several commands into one instance lost them.
btctl() { bluetoothctl "$@" >/dev/null 2>&1; }

bt_state_ok() {
    bluetoothctl show 2>/dev/null | grep -q "Powered: yes"
}

# Name of every SDP record and its channel, one "name|channel" per line.
sdp_records() {
    sdptool browse local 2>/dev/null | awk '
        /^$/             { if (n != "") print n "|" c; n = ""; c = "" }
        /^Service Name:/ { n = substr($0, 15); c = "" }
        /Channel:/       { c = $2 }
        END              { if (n != "") print n "|" c }'
}

# The Realtek firmware loads about 12 s into the boot; the GUI may ask
# before that.
rfkill unblock bluetooth 2>/dev/null
i=0
while [ ! -d /sys/class/bluetooth/hci0 ] && [ $i -lt 60 ]; do
    sleep 0.5
    i=$((i + 1))
done
[ -d /sys/class/bluetooth/hci0 ] || { log "no hci0 after 30 s"; exit 1; }

if ! running "bluetoothd"; then
    log "bluetoothd not running - starting it"
    /bin/sh -c "$BLUETOOTHD -nC >/dev/null 2>&1 &"
    i=0
    while [ $i -lt 10 ] && ! running "bluetoothd"; do
        sleep 0.5
        i=$((i + 1))
    done
    sleep 1
fi

# Hidden and not pairable. The GUI's Bluetooth window opens pairing for a
# few minutes when Scan is pressed, and its agent refuses pairing requests
# the rest of the time, so nobody in range can pair with the radio
# unasked. For the same reason no bt-agent (which accepts everything) is
# started, here or in bt_start.sh at boot.
btctl power on
btctl system-alias "$NAME"
btctl discoverable off
btctl pairable off
# The adapter can still be settling after power on: repeat until it is
# powered, at most 5 s.
i=0
while [ $i -lt 10 ] && ! bt_state_ok; do
    sleep 0.5
    btctl power on
    i=$((i + 1))
done
bt_state_ok || log "WARNING: $(bluetoothctl show 2>/dev/null | grep -E 'Powered' | tr -s ' \t' ' ')"

i=0
while [ $i -lt 10 ]; do
    hciconfig hci0 | grep -q "UP RUNNING" && break
    sleep 0.5
    i=$((i + 1))
done
if ! hciconfig hci0 | grep -q "UP RUNNING"; then
    log "adapter still DOWN"
    exit 1
fi

if command -v sdptool >/dev/null 2>&1; then
    recs=$(sdp_records)
    echo "$recs" | grep -q "^Serial Port|1$" || sdptool add --channel=1 SP >/dev/null 2>&1
    if echo "$recs" | grep -q "^Dial-Up Networking|$CHAN$"; then
        log "frames already published on channel $CHAN"
    elif sdptool add --channel="$CHAN" DUN >/dev/null 2>&1; then
        log "frames published on channel $CHAN (DUN)"
    else
        log "sdptool add failed"
    fi
fi

log "up as '$NAME'"
exit 0
