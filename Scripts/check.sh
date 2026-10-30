#!/usr/bin/env bash
set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$repository_root/Scripts/lib/xcode-environment.sh"
cd "$repository_root"

runs_ui_tests=false
case "${1-}" in
    "") ;;
    --ui) runs_ui_tests=true ;;
    *)
        printf 'usage: Scripts/check.sh [--ui]\n' >&2
        exit 2
        ;;
esac

derived_data="$repository_root/build/DerivedData"
ui_test_time_allowance=180
go_modules=(Packages/TunnelCore/go Scripts/go-comment-check)
started_at=$SECONDS

step() {
    printf '\n==> %s\n' "$1"
}

simulator_identifier() {
    xcrun simctl list devices available \
        | grep -m 1 -E "^[[:space:]]+$1" \
        | grep -oE '[0-9A-F]{8}(-[0-9A-F]{4}){3}-[0-9A-F]{12}' || true
}

iphone_simulator_identifier() {
    simulator_identifier iPhone
}

run_ui_tests() {
    local device="$1"
    local simulator
    simulator="$(simulator_identifier "$device")"
    if [[ -z "$simulator" ]]; then
        printf 'No available %s simulator, install one in Xcode\n' "$device" >&2
        exit 1
    fi
    xcrun simctl bootstatus "$simulator" -b >/dev/null
    xcodebuild -project Splitway.xcodeproj -scheme iOSUITests -destination "id=$simulator" \
        -derivedDataPath "$derived_data" -collect-test-diagnostics never \
        -test-timeouts-enabled YES -default-test-execution-time-allowance "$ui_test_time_allowance" test -quiet
}

build_scheme() {
    local scheme="$1"
    local destination="$2"
    xcodebuild -project Splitway.xcodeproj -scheme "$scheme" -destination "$destination" \
        -derivedDataPath "$derived_data" CODE_SIGNING_ALLOWED=NO build -quiet
}

step "TunnelCore xcframework"
Packages/TunnelCore/Scripts/build-xcframework.sh

step "Lint"
Scripts/lint.sh

step "Lint rule fixtures"
Scripts/tests/lint-rules-test.sh

step "Git hook checks"
Scripts/tests/git-hooks-test.sh

step "Go modules"
for module in "${go_modules[@]}"; do
    (cd "$module" && go vet ./... && go test ./...)
done

step "SplitwayKit tests"
swift test --package-path Packages/SplitwayKit --quiet

step "TunnelCore test peer"
Packages/TunnelCore/Scripts/build-test-peer.sh

step "TunnelCore adapter tests"
swift test --package-path Packages/TunnelCore --quiet

step "Xcode project"
Scripts/generate-project.sh

step "iOS build and integration tests"
iphone_simulator="$(iphone_simulator_identifier)"
if [[ -z "$iphone_simulator" ]]; then
    printf 'No available iPhone simulator, install an iOS simulator runtime in Xcode\n' >&2
    exit 1
fi
xcodebuild -project Splitway.xcodeproj -scheme iOSApp -destination "id=$iphone_simulator" \
    -derivedDataPath "$derived_data" test -quiet

step "macOS build"
build_scheme macOSApp 'generic/platform=macOS'

if [[ "$runs_ui_tests" == true ]]; then
    step "UI tests on iPhone"
    run_ui_tests iPhone
    step "UI tests on iPad"
    run_ui_tests iPad
fi

printf '\nAll checks passed in %ds\n' "$((SECONDS - started_at))"
