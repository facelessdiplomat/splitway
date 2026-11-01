#!/usr/bin/env bash
set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$repository_root/Scripts/lib/xcode-environment.sh"
cd "$repository_root"

if [[ $# -lt 1 ]]; then
    printf 'usage: Scripts/live-tunnel-test.sh <device identifier> [tunnel name]\n' >&2
    exit 2
fi

Scripts/generate-project.sh >/dev/null
TEST_RUNNER_SPLITWAY_LIVE_TUNNEL=YES TEST_RUNNER_SPLITWAY_LIVE_TUNNEL_NAME="${2:-cz-prg}" \
    xcodebuild test -project Splitway.xcodeproj -scheme iOSUITests -destination "id=$1" \
    -derivedDataPath build/DerivedData-signed -allowProvisioningUpdates \
    -only-testing:iOSUITests/LiveTunnelTests -only-testing:iOSUITests/LiveServiceRoutingTests \
    -collect-test-diagnostics never -quiet
