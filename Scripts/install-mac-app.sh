#!/usr/bin/env bash
set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$repository_root/Scripts/lib/xcode-environment.sh"
derived_data_directory="build/DerivedData-mac-local"
installed_application="/Applications/Splitway.app"
build_number="$(date +%s)"

cd "$repository_root"
Scripts/generate-project.sh >/dev/null
xcodebuild build -project Splitway.xcodeproj -scheme macOSApp -configuration Debug \
    -destination 'platform=macOS,arch=arm64' -derivedDataPath "$derived_data_directory" \
    -allowProvisioningUpdates -quiet CURRENT_PROJECT_VERSION="$build_number"
pkill -x Splitway || true
rm -rf "$installed_application"
ditto "$derived_data_directory/Build/Products/Debug/Splitway.app" "$installed_application"
printf 'Splitway build %s is installed in %s\n' "$build_number" "$installed_application"
