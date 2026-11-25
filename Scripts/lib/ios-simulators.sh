#!/usr/bin/env bash

chosen_simulator() {
    local family="$1"
    local simulator_list="$2"
    local chosen
    chosen="$(jq -r --arg family "$family" '
        (.devices // {}) as $devices
        | [ (.runtimes // [])[]
            | select(.platform == "iOS" and .isAvailable)
            | . as $runtime
            | ($devices[$runtime.identifier] // [])[]
            | select(.isAvailable and (.deviceTypeIdentifier | test("\\." + $family + "-")))
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
