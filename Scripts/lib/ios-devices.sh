#!/usr/bin/env bash

connected_ios_devices() {
    local device_list="$1"
    local requested="$2"
    jq -r --arg requested "$requested" '
        .result.devices[]
        | select(.hardwareProperties.platform == "iOS" and .hardwareProperties.reality == "physical")
        | select(.connectionProperties.pairingState == "paired")
        | select(.connectionProperties.tunnelState != "unavailable")
        | select($requested == "" or $requested == .deviceProperties.name
            or $requested == .hardwareProperties.udid or $requested == .identifier)
        | [.hardwareProperties.udid, .deviceProperties.name, (.deviceProperties.developerModeStatus // "")]
        | @tsv
    ' "$device_list"
}

chosen_ios_device() {
    local device_list="$1"
    local requested="${2:-}"
    local devices udid name developer_mode
    devices="$(connected_ios_devices "$device_list" "$requested")" || return 1
    if [[ -z "$devices" && -n "$requested" ]]; then
        printf 'No connected iPhone or iPad matches %s\n' "$requested" >&2
        return 1
    fi
    if [[ -z "$devices" ]]; then
        printf 'No iPhone or iPad is connected: connect one with a cable, unlock it and trust this Mac\n' >&2
        return 1
    fi
    if [[ "$devices" == *$'\n'* ]]; then
        printf 'Several iPhones and iPads are connected, pass the name or UDID of one:\n' >&2
        awk -F '\t' '{ printf "  %s  %s\n", $2, $1 }' <<<"$devices" >&2
        return 1
    fi
    IFS=$'\t' read -r udid name developer_mode <<<"$devices"
    if [[ "$developer_mode" == disabled ]]; then
        printf 'Turn on Developer Mode on %s: Settings › Privacy & Security › Developer Mode, then restart it\n' \
            "$name" >&2
        return 1
    fi
    printf '%s\t%s\n' "$udid" "$name"
}
