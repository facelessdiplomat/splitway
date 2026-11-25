#!/usr/bin/env bash
set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$repository_root/Scripts/lib/ios-devices.sh"
device_list="$(mktemp)"
refusal="$(mktemp)"
trap 'rm -f "$device_list" "$refusal"' EXIT
failures=0

record_failure() {
    printf 'FAIL: %s\n' "$1" >&2
    failures=$((failures + 1))
}

device() {
    jq -n --arg name "$1" --arg udid "$2" --arg platform "$3" --arg reality "$4" \
        --arg tunnelState "$5" --arg developerMode "$6" '{
            identifier: ("core-" + $udid),
            deviceProperties: { name: $name, developerModeStatus: $developerMode },
            hardwareProperties: { platform: $platform, reality: $reality, udid: $udid },
            connectionProperties: { pairingState: "paired", tunnelState: $tunnelState }
        }'
}

work_iphone() { device "Work iPhone" 0001 iOS physical connected enabled; }
home_ipad() { device "Home iPad" 0002 iOS physical disconnected enabled; }
old_iphone() { device "Old iPhone" 0003 iOS physical unavailable enabled; }
apple_watch() { device "Watch" 0004 watchOS physical connected disabled; }
simulator() { device "iPhone 17 Pro" 0005 iOS simulated disconnected ""; }
locked_down_iphone() { device "Locked iPhone" 0006 iOS physical connected disabled; }

devices_are() {
    local device_kind
    for device_kind in "$@"; do
        "$device_kind"
    done | jq -s '{ result: { devices: . } }' >"$device_list"
}

expect_choice() {
    local description="$1"
    local requested="$2"
    local expected="$3"
    local chosen
    if ! chosen="$(chosen_ios_device "$device_list" "$requested" 2>/dev/null)"; then
        record_failure "$description: no device was chosen"
    elif [[ "$chosen" != "$expected" ]]; then
        record_failure "$description: chose '$chosen' instead of '$expected'"
    fi
}

expect_refusal() {
    local description="$1"
    local requested="$2"
    local expected_text="$3"
    if chosen_ios_device "$device_list" "$requested" >/dev/null 2>"$refusal"; then
        record_failure "$description: a device was chosen"
    elif ! grep -q -F -- "$expected_text" "$refusal"; then
        record_failure "$description: the refusal does not mention '$expected_text': $(cat "$refusal")"
    fi
}

devices_are work_iphone old_iphone apple_watch simulator
expect_choice "picks the only connected iPhone" "" $'0001\tWork iPhone'

devices_are home_ipad apple_watch simulator
expect_choice "picks an iPad that is reachable before its tunnel is up" "" $'0002\tHome iPad'

devices_are old_iphone apple_watch simulator
expect_refusal "refuses when no iPhone or iPad is connected" "" "No iPhone or iPad is connected"

devices_are work_iphone home_ipad
expect_refusal "asks which one when several are connected" "" "pass the name or UDID of one"
expect_refusal "lists the connected iPhone to choose from" "" "Work iPhone"
expect_refusal "lists the connected iPad to choose from" "" "Home iPad"
expect_choice "picks the requested device by name" "Home iPad" $'0002\tHome iPad'
expect_choice "picks the requested device by UDID" "0001" $'0001\tWork iPhone'
expect_choice "picks the requested device by CoreDevice identifier" "core-0002" $'0002\tHome iPad'

devices_are work_iphone old_iphone
expect_refusal "refuses a requested device that is not connected" "Old iPhone" "No connected iPhone or iPad matches Old iPhone"

devices_are locked_down_iphone
expect_refusal "asks to turn on Developer Mode" "" "Turn on Developer Mode on Locked iPhone"

if ((failures > 0)); then
    printf '%d iOS device checks failed\n' "$failures" >&2
    exit 1
fi
printf 'iOS device checks passed\n'
