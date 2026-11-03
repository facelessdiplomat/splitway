#!/usr/bin/env bash

launch_services_registration_tool="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"

unregister_built_applications() {
    local directory="$1"
    local application
    while IFS= read -r -d '' application; do
        "$launch_services_registration_tool" -u "$application" 2>/dev/null || true
    done < <(find "$directory" -name '*.app' -type d -prune -print0 2>/dev/null)
}
