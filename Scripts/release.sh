#!/usr/bin/env bash
set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$repository_root/Scripts/lib/xcode-environment.sh"
source "$repository_root/Scripts/lib/build-directory.sh"
cd "$repository_root"

usage() {
    printf 'Usage: Scripts/release.sh <version> [--publish]\n' >&2
    printf '  <version>  marketing version, for example 1.0 or 1.0.1\n' >&2
    printf '  --publish  create the GitHub release v<version> with Splitway.dmg and docs/releases/<version>.md\n' >&2
    printf 'Notarization uses the keychain profile named by SPLITWAY_NOTARY_PROFILE (splitway-notary by default).\n' >&2
    exit 64
}

[[ $# -ge 1 ]] || usage
version="$1"
shift
publishes=false
for argument in "$@"; do
    case "$argument" in
        --publish) publishes=true ;;
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

notary_profile="${SPLITWAY_NOTARY_PROFILE:-splitway-notary}"
build_number="$(git rev-list --count HEAD)"
team_identifier="$(awk '/DEVELOPMENT_TEAM:/ { print $2; exit }' project.yml)"
output_directory="$repository_root/build/release/$version-$build_number"
archive="$output_directory/Splitway.xcarchive"
export_directory="$output_directory/export"
application="$export_directory/Splitway.app"
image="$output_directory/Splitway.dmg"
checksum_file="$output_directory/Splitway.dmg.sha256"
release_tag="v$version"
release_notes="$repository_root/docs/releases/$version.md"

if [[ "$publishes" == true && ! -s "$release_notes" ]]; then
    printf 'Write the release notes to docs/releases/%s.md before publishing\n' "$version" >&2
    exit 1
fi

signing_identity="$(security find-identity -v -p codesigning |
    awk -v team="($team_identifier)" 'index($0, "Developer ID Application") && index($0, team) { print $2; exit }')"
if [[ -z "$signing_identity" ]]; then
    printf 'No Developer ID Application certificate of team %s in the keychain\n' "$team_identifier" >&2
    exit 1
fi

if ! xcrun notarytool history --keychain-profile "$notary_profile" >/dev/null 2>&1; then
    printf 'No notarization credentials in the keychain profile %s. Store them once with:\n' "$notary_profile" >&2
    printf '  xcrun notarytool store-credentials %s --key <AuthKey.p8> --key-id <Key ID> --issuer <Issuer ID>\n' \
        "$notary_profile" >&2
    exit 1
fi

if [[ "$publishes" == true ]] && gh release view "$release_tag" >/dev/null 2>&1; then
    printf 'The GitHub release %s already exists\n' "$release_tag" >&2
    exit 1
fi

write_export_options() {
    cat >"$1" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>developer-id</string>
    <key>teamID</key>
    <string>$team_identifier</string>
    <key>signingStyle</key>
    <string>automatic</string>
</dict>
</plist>
PLIST
}

notarize() {
    local artifact="$1"
    local result
    result="$(xcrun notarytool submit "$artifact" --keychain-profile "$notary_profile" --wait --output-format json)"
    local status
    status="$(printf '%s' "$result" | plutil -extract status raw -o - -)"
    if [[ "$status" != "Accepted" ]]; then
        local submission
        submission="$(printf '%s' "$result" | plutil -extract id raw -o - -)"
        printf 'Notarization of %s ended with %s:\n' "$(basename "$artifact")" "$status" >&2
        xcrun notarytool log "$submission" --keychain-profile "$notary_profile" >&2 || true
        exit 1
    fi
    printf 'Notarized %s\n' "$(basename "$artifact")"
}

require_system_extension_entitlements() {
    local bundle="$1"
    if ! codesign -d --entitlements - --xml "$bundle" 2>/dev/null | grep -q 'packet-tunnel-provider-systemextension'; then
        printf '%s lacks the Developer ID network extension entitlements\n' "$(basename "$bundle")" >&2
        exit 1
    fi
}

rm -rf "$output_directory"
mkdir -p "$output_directory"
Packages/TunnelCore/Scripts/build-xcframework.sh
Scripts/generate-project.sh >/dev/null

xcodebuild archive -project Splitway.xcodeproj -scheme macOSApp -configuration Release \
    -destination 'generic/platform=macOS' -archivePath "$archive" \
    -derivedDataPath "$output_directory/DerivedData" -allowProvisioningUpdates -quiet \
    MARKETING_VERSION="$version" CURRENT_PROJECT_VERSION="$build_number"
write_export_options "$output_directory/ExportOptions.plist"
xcodebuild -exportArchive -archivePath "$archive" -exportOptionsPlist "$output_directory/ExportOptions.plist" \
    -exportPath "$export_directory" -allowProvisioningUpdates -quiet
require_system_extension_entitlements "$application"
for extension in "$application"/Contents/Library/SystemExtensions/*.systemextension; do
    require_system_extension_entitlements "$extension"
done

ditto -c -k --keepParent "$application" "$output_directory/Splitway.zip"
notarize "$output_directory/Splitway.zip"
xcrun stapler staple -q "$application"
spctl --assess --type execute --verbose=2 "$application"

staging="$output_directory/image"
mkdir -p "$staging"
ditto "$application" "$staging/Splitway.app"
ln -s /Applications "$staging/Applications"
hdiutil create -quiet -volname Splitway -srcfolder "$staging" -fs HFS+ -format UDZO -ov "$image"
codesign --sign "$signing_identity" --timestamp "$image"
notarize "$image"
xcrun stapler staple -q "$image"
spctl --assess --type open --context context:primary-signature --verbose=2 "$image"

(cd "$output_directory" && shasum -a 256 Splitway.dmg >"$checksum_file")
printf 'Splitway %s (%s): %s\n' "$version" "$build_number" "$image"
cat "$checksum_file"

if [[ "$publishes" == true ]]; then
    gh release create "$release_tag" "$image" "$checksum_file" \
        --title "Splitway $version" --target "$(git rev-parse HEAD)" --notes-file "$release_notes" --generate-notes
    printf 'Published %s\n' "$release_tag"
fi
