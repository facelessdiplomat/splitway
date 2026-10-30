#!/usr/bin/env bash
set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repository_root"

package_path="Scripts/RoutingProbe"
bundle="$repository_root/build/RoutingProbe/RoutingProbe.app"
bundle_identifier="${SPLITWAY_BUNDLE_ID_PREFIX:-com.facelessdiplomat}.splitway.routing-probe"

swift build -c release --package-path "$package_path" --product RoutingProbe --quiet
binary="$(swift build -c release --package-path "$package_path" --show-bin-path)/RoutingProbe"

rm -rf "$bundle"
mkdir -p "$bundle/Contents/MacOS"
cp "$binary" "$bundle/Contents/MacOS/RoutingProbe"
cat >"$bundle/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>RoutingProbe</string>
    <key>CFBundleIdentifier</key>
    <string>$bundle_identifier</string>
    <key>CFBundleName</key>
    <string>RoutingProbe</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>26.0</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
PLIST

identity="$(security find-identity -v -p codesigning | awk '/"Apple Development/ { print $2; exit }')"
if [[ -z "$identity" ]]; then
    printf 'No Apple Development signing identity in the keychain, sign in to Xcode with the team account\n' >&2
    exit 1
fi
codesign --force --sign "$identity" --identifier "$bundle_identifier" --options runtime --timestamp=none "$bundle" 2>&1 \
    | { grep -v 'replacing existing signature' || true; } >&2
codesign --verify --strict "$bundle"
team="$(codesign -dv "$bundle" 2>&1 | sed -n 's/^TeamIdentifier=//p')"
printf 'RoutingProbe: %s, team %s\n' "${bundle#"$repository_root"/}" "$team"
