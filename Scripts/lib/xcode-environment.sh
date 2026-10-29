#!/usr/bin/env bash

full_xcode_developer_directory="/Applications/Xcode.app/Contents/Developer"

if [[ -z "${DEVELOPER_DIR:-}" ]] \
    && [[ "$(xcode-select -p 2>/dev/null)" == "/Library/Developer/CommandLineTools" ]] \
    && [[ -d "$full_xcode_developer_directory" ]]; then
    export DEVELOPER_DIR="$full_xcode_developer_directory"
    printf 'xcode-select points to Command Line Tools, using %s for this run\n' "$DEVELOPER_DIR" >&2
fi
