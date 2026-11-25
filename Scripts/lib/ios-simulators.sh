#!/usr/bin/env bash

chosen_iphone_simulator() {
    local simulator_list="$1"
    local chosen
    chosen="$(jq -r '
        (.devices // {}) as $devices
        | [ (.runtimes // [])[]
            | select(.platform == "iOS" and .isAvailable)
            | . as $runtime
            | ($devices[$runtime.identifier] // [])[]
            | select(.isAvailable and (.deviceTypeIdentifier | test("\\.iPhone")))
            | {
                udid,
                name,
                state,
                version: $runtime.version,
                newestFirst: ((($runtime.version | split(".") | map(tonumber)) + [0, 0, 0])[:3] | map(-.))
            } ]
        | sort_by(.newestFirst, .name)
        | first
        | select(. != null)
        | [.udid, .name, .version, .state]
        | @tsv
    ' "$simulator_list")" || return 1
    [[ -n "$chosen" ]] || return 1
    printf '%s\n' "$chosen"
}
