#!/usr/bin/env bash
set -euo pipefail

package_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
repository_root="$(cd "$package_root/../.." && pwd)"
source "$repository_root/Scripts/lib/xcode-environment.sh"

go_module="$package_root/go"
interface_directory="$package_root/CInterface"
build_directory="$package_root/build"
framework="$package_root/Artifacts/TunnelCoreFramework.xcframework"
fingerprint_file="$build_directory/sources.sha256"
library_name="libtunnelcore.a"
minimum_ios_version="26.0"
minimum_macos_version="26.0"

sources_fingerprint() {
    {
        go version
        printf 'ios %s macos %s\n' "$minimum_ios_version" "$minimum_macos_version"
        find "$go_module" "$interface_directory" "$package_root/Scripts" -type f ! -path '*/testpeer/*' \
            \( \( -name '*.go' ! -name '*_test.go' \) -o -name 'go.mod' -o -name 'go.sum' \
            -o -name '*.h' -o -name '*.modulemap' -o -name '*.sh' \) -print0 \
            | sort -z \
            | xargs -0 shasum -a 256
    } | shasum -a 256 | cut -d ' ' -f 1
}

build_slice() {
    local sdk="$1"
    local target_os="$2"
    local target_architecture="$3"
    local clang_target="$4"
    local output_directory="$5"
    local sdk_path
    sdk_path="$(xcrun --sdk "$sdk" --show-sdk-path)"
    mkdir -p "$output_directory"
    (
        cd "$go_module"
        CGO_ENABLED=1 \
            GOOS="$target_os" \
            GOARCH="$target_architecture" \
            CC="$(xcrun --sdk "$sdk" --find clang)" \
            CGO_CFLAGS="-isysroot $sdk_path -target $clang_target" \
            CGO_LDFLAGS="-isysroot $sdk_path -target $clang_target" \
            go build -buildmode=c-archive -trimpath -o "$output_directory/$library_name" ./bridge
    )
    rm -f "$output_directory/${library_name%.a}.h"
}

fingerprint="$(sources_fingerprint)"
if [[ -d "$framework" && -f "$fingerprint_file" && "$(cat "$fingerprint_file")" == "$fingerprint" ]]; then
    printf 'TunnelCore xcframework is up to date\n'
    exit 0
fi

rm -rf "$build_directory" "$framework"
build_slice iphoneos ios arm64 "arm64-apple-ios$minimum_ios_version" "$build_directory/ios-arm64"
build_slice iphonesimulator ios arm64 "arm64-apple-ios$minimum_ios_version-simulator" "$build_directory/ios-arm64-simulator"
build_slice macosx darwin arm64 "arm64-apple-macos$minimum_macos_version" "$build_directory/macos-arm64"
build_slice macosx darwin amd64 "x86_64-apple-macos$minimum_macos_version" "$build_directory/macos-x86_64"

mkdir -p "$build_directory/macos"
lipo -create \
    "$build_directory/macos-arm64/$library_name" \
    "$build_directory/macos-x86_64/$library_name" \
    -output "$build_directory/macos/$library_name"

xcodebuild -create-xcframework \
    -library "$build_directory/ios-arm64/$library_name" -headers "$interface_directory" \
    -library "$build_directory/ios-arm64-simulator/$library_name" -headers "$interface_directory" \
    -library "$build_directory/macos/$library_name" -headers "$interface_directory" \
    -output "$framework" >/dev/null

printf '%s\n' "$fingerprint" >"$fingerprint_file"
printf 'TunnelCore xcframework built at %s\n' "$framework"
