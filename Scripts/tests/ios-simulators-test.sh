#!/usr/bin/env bash
set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$repository_root/Scripts/lib/ios-simulators.sh"
simulator_list="$(mktemp)"
trap 'rm -f "$simulator_list"' EXIT
failures=0

record_failure() {
    printf 'FAIL: %s\n' "$1" >&2
    failures=$((failures + 1))
}

runtime() {
    jq -n --arg version "$1" --arg platform "${2:-iOS}" --argjson isAvailable "${3:-true}" '{
        identifier: ("runtime-" + $platform + "-" + $version),
        version: $version,
        platform: $platform,
        isAvailable: $isAvailable
    }'
}

simulator() {
    jq -n --arg name "$1" --arg version "$2" --arg platform "${3:-iOS}" --arg state "${4:-Shutdown}" \
        --argjson isAvailable "${5:-true}" '{
            runtime: ("runtime-" + $platform + "-" + $version),
            name: $name,
            udid: ("udid " + $name),
            state: $state,
            isAvailable: $isAvailable,
            deviceTypeIdentifier: ("com.apple.CoreSimulator.SimDeviceType." + ($name | gsub(" "; "-")))
        }'
}

simulators_are() {
    jq -s '{
        runtimes: map(select(has("version"))),
        devices: (map(select(has("udid"))) | group_by(.runtime)
            | map({ key: .[0].runtime, value: map(del(.runtime)) }) | from_entries)
    }' >"$simulator_list"
}

expect_choice() {
    local description="$1"
    local expected="$2"
    local family="${3:-iPhone}"
    local chosen
    if ! chosen="$(chosen_simulator "$family" "$simulator_list")"; then
        record_failure "$description: no simulator was chosen"
    elif [[ "$chosen" != "$expected" ]]; then
        record_failure "$description: chose '$chosen' instead of '$expected'"
    fi
}

expect_no_choice() {
    local description="$1"
    local family="${2:-iPhone}"
    local chosen
    if chosen="$(chosen_simulator "$family" "$simulator_list")"; then
        record_failure "$description: chose '$chosen'"
    fi
}

{
    runtime 26.0
    runtime 27.2
    runtime 27.4 iOS false
    runtime 27.0 watchOS
    simulator "iPhone 16" 26.0
    simulator "iPhone 15" 27.2 iOS Shutdown false
    simulator "iPhone Air" 27.2
    simulator "iPhone 17" 27.2
    simulator "iPad Air" 27.2
    simulator "iPhone 19" 27.4
    simulator "Apple Watch" 27.0 watchOS
} | simulators_are
expect_choice "picks an available iPhone on the newest available iOS runtime" $'udid iPhone 17\tiPhone 17\t27.2\tShutdown'

{
    runtime 26.4
    runtime 26.10
    simulator "iPhone A" 26.4
    simulator "iPhone B" 26.10
} | simulators_are
expect_choice "compares runtime versions as numbers" $'udid iPhone B\tiPhone B\t26.10\tShutdown'

{
    runtime 26.0
    runtime 27.2
    simulator "iPhone 16" 26.0
    simulator "iPad Pro" 27.2
} | simulators_are
expect_choice "falls back to an older runtime when the newest has no iPhone" $'udid iPhone 16\tiPhone 16\t26.0\tShutdown'

{
    runtime 27.2
    simulator "iPhone 17" 27.2 iOS Booted
} | simulators_are
expect_choice "tells that the simulator is already booted" $'udid iPhone 17\tiPhone 17\t27.2\tBooted'

{
    runtime 27.2
    runtime 27.0 watchOS
    simulator "iPad Air" 27.2
    simulator "Apple Watch" 27.0 watchOS
} | simulators_are
expect_no_choice "chooses nothing without an iPhone simulator"

{
    runtime 26.0
    runtime 27.2
    simulator "iPad Air" 26.0
    simulator "iPad Pro" 27.2
    simulator "iPad mini" 27.2
    simulator "iPhone 17" 27.2
} | simulators_are
expect_choice "picks an iPad on the newest runtime for the iPad family" $'udid iPad Pro\tiPad Pro\t27.2\tShutdown' iPad

{
    runtime 27.2
    simulator "iPhone 17" 27.2
} | simulators_are
expect_no_choice "chooses nothing without a simulator of the family" iPad

printf '{}\n' >"$simulator_list"
expect_no_choice "chooses nothing when the simulator list is empty"

if ((failures > 0)); then
    printf '%d iOS simulator checks failed\n' "$failures" >&2
    exit 1
fi
printf 'iOS simulator checks passed\n'
