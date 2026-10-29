#!/usr/bin/env bash

find_linter_suppressions() {
    grep -n -e 'swiftlint:' -- "$@"
}

find_wireguard_secrets() {
    local wireguard_key_assignment='(PrivateKey|PresharedKey)[[:space:]]*=[[:space:]]*[A-Za-z0-9+/]{42}[AEIMQUYcgkosw048]='
    grep -n -I -E "$wireguard_key_assignment" -- "$@" | cut -d : -f 1,2
}

is_fixture_path() {
    [[ "$1" == Scripts/LintFixtures/* || "$1" == */Fixtures/* ]]
}
