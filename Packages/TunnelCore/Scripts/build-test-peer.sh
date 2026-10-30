#!/usr/bin/env bash
set -euo pipefail

package_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
artifacts_directory="$package_root/Artifacts"
test_peer="$artifacts_directory/testpeer"

mkdir -p "$artifacts_directory"
(cd "$package_root/go" && go build -trimpath -o "$test_peer" ./testpeer)
printf 'Test peer built at %s\n' "$test_peer"
