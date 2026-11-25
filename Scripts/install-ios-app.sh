#!/usr/bin/env bash
set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$repository_root/Scripts/lib/xcode-environment.sh"
source "$repository_root/Scripts/lib/build-directory.sh"
source "$repository_root/Scripts/lib/ios-devices.sh"
derived_data_directory="build/DerivedData-ios-device"
built_application="$derived_data_directory/Build/Products/Release-iphoneos/Splitway.app"
build_number="$(date +%s)"
device_list="$(mktemp)"
trap 'rm -f "$device_list"' EXIT

usage() {
    printf 'Usage: Scripts/install-ios-app.sh [device]\n' >&2
    printf '  device  name or UDID of the iPhone or iPad, needed only when several are connected\n' >&2
    exit 64
}

if [[ $# -gt 1 || "${1:-}" == -* ]]; then
    usage
fi

cd "$repository_root"
xcrun devicectl list devices --json-output "$device_list" >/dev/null
device="$(chosen_ios_device "$device_list" "${1:-}")"
IFS=$'\t' read -r device_udid device_name <<<"$device"

Packages/TunnelCore/Scripts/build-xcframework.sh
Scripts/generate-project.sh >/dev/null
printf 'Building Splitway %s for %s\n' "$build_number" "$device_name"
xcodebuild build -project Splitway.xcodeproj -scheme iOSApp -configuration Release \
    -destination "id=$device_udid" -derivedDataPath "$derived_data_directory" \
    -allowProvisioningUpdates -allowProvisioningDeviceRegistration -quiet \
    CURRENT_PROJECT_VERSION="$build_number"
xcrun devicectl device install app --device "$device_udid" "$built_application" >/dev/null
printf 'Splitway build %s is installed on %s\n' "$build_number" "$device_name"
