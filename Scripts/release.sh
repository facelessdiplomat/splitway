#!/usr/bin/env bash
set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$repository_root/Scripts/lib/xcode-environment.sh"
cd "$repository_root"

usage() {
    printf 'Usage: Scripts/release.sh <version> [--upload]\n' >&2
    printf '  <version>  marketing version, for example 1.0 or 1.0.1\n' >&2
    printf '  --upload   upload to App Store Connect with the key from SPLITWAY_ASC_KEY_ID and SPLITWAY_ASC_ISSUER_ID\n' >&2
    printf 'Without --upload the archives appear in Xcode Organizer, ready for Distribute App.\n' >&2
    exit 64
}

[[ $# -ge 1 ]] || usage
version="$1"
shift
uploads=false
for argument in "$@"; do
    case "$argument" in
        --upload) uploads=true ;;
        *) usage ;;
    esac
done

if [[ ! "$version" =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?$ ]]; then
    printf 'The version must look like 1.0 or 1.0.1, not %s\n' "$version" >&2
    exit 64
fi

if [[ -n "$(git status --porcelain)" ]]; then
    printf 'The working tree has uncommitted changes: release from a clean checkout of master\n' >&2
    exit 1
fi

key_identifier="${SPLITWAY_ASC_KEY_ID:-}"
issuer_identifier="${SPLITWAY_ASC_ISSUER_ID:-}"
key_file="${SPLITWAY_ASC_KEY_FILE:-$HOME/.appstoreconnect/private_keys/AuthKey_$key_identifier.p8}"
if [[ "$uploads" == true ]]; then
    if [[ -z "$key_identifier" || -z "$issuer_identifier" ]]; then
        printf 'Set SPLITWAY_ASC_KEY_ID and SPLITWAY_ASC_ISSUER_ID to upload\n' >&2
        exit 1
    fi
    if [[ ! -f "$key_file" ]]; then
        printf 'No App Store Connect key at %s\n' "$key_file" >&2
        exit 1
    fi
fi

build_number="$(git rev-list --count HEAD)"
team_identifier="$(awk '/DEVELOPMENT_TEAM:/ { print $2; exit }' project.yml)"
archive_directory="$HOME/Library/Developer/Xcode/Archives/$(date +%Y-%m-%d)"
export_directory="$repository_root/build/release/$version-$build_number"

scheme_for() {
    case "$1" in
        iOS) printf 'iOSApp' ;;
        macOS) printf 'macOSApp' ;;
    esac
}

write_export_options() {
    local options="$1"
    cat >"$options" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store-connect</string>
    <key>destination</key>
    <string>upload</string>
    <key>teamID</key>
    <string>$team_identifier</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>uploadSymbols</key>
    <true/>
    <key>manageAppVersionAndBuildNumber</key>
    <false/>
</dict>
</plist>
PLIST
}

upload() {
    local archive="$1"
    local platform="$2"
    local options="$export_directory/ExportOptions.plist"
    mkdir -p "$export_directory"
    write_export_options "$options"
    xcodebuild -exportArchive -archivePath "$archive" -exportOptionsPlist "$options" \
        -exportPath "$export_directory/$platform" -allowProvisioningUpdates \
        -authenticationKeyPath "$key_file" -authenticationKeyID "$key_identifier" \
        -authenticationKeyIssuerID "$issuer_identifier"
    printf 'Uploaded Splitway %s %s (%s) to App Store Connect\n' "$platform" "$version" "$build_number"
}

Packages/TunnelCore/Scripts/build-xcframework.sh
Scripts/generate-project.sh >/dev/null
mkdir -p "$archive_directory"

for platform in iOS macOS; do
    archive="$archive_directory/Splitway $platform $version ($build_number).xcarchive"
    xcodebuild archive -project Splitway.xcodeproj -scheme "$(scheme_for "$platform")" -configuration Release \
        -destination "generic/platform=$platform" -archivePath "$archive" -allowProvisioningUpdates -quiet \
        MARKETING_VERSION="$version" CURRENT_PROJECT_VERSION="$build_number"
    printf 'Archived %s\n' "$archive"
    if [[ "$uploads" == true ]]; then
        upload "$archive" "$platform"
    fi
done
