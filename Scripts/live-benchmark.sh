#!/usr/bin/env bash
set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$repository_root/Scripts/lib/xcode-environment.sh"
source "$repository_root/Scripts/lib/build-directory.sh"
source "$repository_root/Scripts/lib/ios-devices.sh"
derived_data_directory="build/DerivedData-ios-device"
device_list="$(mktemp)"
trap 'rm -f "$device_list"' EXIT

usage() {
    printf 'Usage: Scripts/live-benchmark.sh [device [tunnel]]\n' >&2
    printf '  device  name or UDID of the iPhone, needed only when several are connected\n' >&2
    printf '  tunnel  name of the test tunnel in Splitway and in the WireGuard app, cz-prg by default\n' >&2
    exit 64
}

if [[ $# -gt 2 || "${1:-}" == -* ]]; then
    usage
fi

cd "$repository_root"
xcrun devicectl list devices --json-output "$device_list" >/dev/null
device="$(chosen_ios_device "$device_list" "${1:-}")"
IFS=$'\t' read -r device_udid device_name <<<"$device"

Packages/TunnelCore/Scripts/build-xcframework.sh
Scripts/generate-project.sh >/dev/null
printf 'Live benchmark on %s\n' "$device_name"
TEST_RUNNER_SPLITWAY_LIVE_BENCHMARK=YES TEST_RUNNER_SPLITWAY_LIVE_TUNNEL_NAME="${2:-cz-prg}" \
    xcodebuild test -project Splitway.xcodeproj -scheme iOSUITests -destination "id=$device_udid" \
    -derivedDataPath "$derived_data_directory" -allowProvisioningUpdates -allowProvisioningDeviceRegistration \
    -only-testing:iOSUITests/LiveBenchmarkTests \
    -collect-test-diagnostics never -quiet
