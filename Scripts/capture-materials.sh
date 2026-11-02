#!/usr/bin/env bash
set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$repository_root/Scripts/lib/xcode-environment.sh"
cd "$repository_root"

output="$repository_root/build/materials"
derived_data="$repository_root/build/DerivedData"
results="$output/results"
if [[ $# -gt 0 ]]; then
    screens=("$@")
else
    screens=(iphone ipad)
fi
languages=(en ru)

device_name() {
    case "$1" in
        iphone) printf 'iPhone 18 Pro Max' ;;
        ipad) printf 'iPad Pro 13-inch (M5)' ;;
    esac
}

simulator_identifier() {
    xcrun simctl list devices available \
        | grep -F "    $1 (" \
        | head -1 \
        | grep -oE '[0-9A-F]{8}(-[0-9A-F]{4}){3}-[0-9A-F]{12}' || true
}

prepare_simulator() {
    xcrun simctl boot "$1" 2>/dev/null || true
    xcrun simctl bootstatus "$1" -b >/dev/null
    xcrun simctl ui "$1" appearance light
    xcrun simctl status_bar "$1" override --time 9:41 --dataNetwork wifi --wifiMode active --wifiBars 3 \
        --cellularMode active --cellularBars 4 --batteryState charged --batteryLevel 100
}

run_materials_test() {
    local simulator="$1" language="$2" test_name="$3" result="$4"
    rm -rf "$result"
    TEST_RUNNER_SPLITWAY_MATERIALS=YES TEST_RUNNER_SPLITWAY_UI_TEST_LANGUAGE="$language" \
        xcodebuild test-without-building -project Splitway.xcodeproj -scheme iOSUITests -destination "id=$simulator" \
        -derivedDataPath "$derived_data" -only-testing:"iOSUITests/StoreMaterialsTests/$test_name" \
        -resultBundlePath "$result" -collect-test-diagnostics never -quiet
}

export_screenshots() {
    local result="$1" target="$2" attachments
    attachments="$(mktemp -d)"
    xcrun xcresulttool export attachments --path "$result" --output-path "$attachments" >/dev/null
    mkdir -p "$target"
    python3 -I -c '
import json, os, shutil, sys
attachments, target = sys.argv[1], sys.argv[2]
for test in json.load(open(os.path.join(attachments, "manifest.json"))):
    for attachment in test.get("attachments", []):
        name = attachment.get("suggestedHumanReadableName", "").split("_")[0]
        if name[:2].isdigit():
            extension = os.path.splitext(attachment["exportedFileName"])[1]
            shutil.copy(os.path.join(attachments, attachment["exportedFileName"]), os.path.join(target, name + extension))
' "$attachments" "$target"
    rm -rf "$attachments"
}

record_video() {
    local simulator="$1" language="$2" recorder
    xcrun simctl io "$simulator" recordVideo --codec=h264 --force "$output/iphone-$language.mp4" >/dev/null 2>&1 &
    recorder=$!
    run_materials_test "$simulator" "$language" testShowsHowToChooseServices "$results/video-$language.xcresult"
    kill -INT "$recorder"
    wait "$recorder" || true
}

mkdir -p "$results"
Scripts/generate-project.sh >/dev/null
first_simulator="$(simulator_identifier "$(device_name "${screens[0]}")")"
if [[ -z "$first_simulator" ]]; then
    printf 'No %s simulator, install it in Xcode\n' "$(device_name "${screens[0]}")" >&2
    exit 1
fi
xcodebuild build-for-testing -project Splitway.xcodeproj -scheme iOSUITests -destination "id=$first_simulator" \
    -derivedDataPath "$derived_data" -quiet

for screen in "${screens[@]}"; do
    simulator="$(simulator_identifier "$(device_name "$screen")")"
    if [[ -z "$simulator" ]]; then
        printf 'No %s simulator, install it in Xcode\n' "$(device_name "$screen")" >&2
        exit 1
    fi
    prepare_simulator "$simulator"
    for language in "${languages[@]}"; do
        result="$results/$screen-$language.xcresult"
        run_materials_test "$simulator" "$language" testCapturesTheMainScreens "$result"
        export_screenshots "$result" "$output/$screen/$language"
        if [[ "$screen" == iphone ]]; then
            record_video "$simulator" "$language"
        fi
    done
    xcrun simctl status_bar "$simulator" clear
done
printf 'Materials are in %s\n' "$output"
