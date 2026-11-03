#!/usr/bin/env bash

if [[ ! -e "$repository_root/build" ]]; then
    mkdir -p "$repository_root/build.noindex"
    ln -s build.noindex "$repository_root/build"
    printf 'Build products go to build.noindex, which Spotlight does not index\n' >&2
fi
