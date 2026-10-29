#!/usr/bin/env bash

find_linter_suppressions() {
    grep -n -e 'swiftlint:' -- "$@"
}
