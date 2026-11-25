#!/usr/bin/env bash
set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$repository_root/Scripts/lib/xcode-environment.sh"
source "$repository_root/Scripts/lib/build-directory.sh"
source "$repository_root/Scripts/lib/launch-services.sh"
source "$repository_root/Scripts/lib/ios-simulators.sh"
cd "$repository_root"

runs_ui_tests=false
runs_benchmarks=false
for argument in "$@"; do
    case "$argument" in
        --ui) runs_ui_tests=true ;;
        --bench) runs_benchmarks=true ;;
        *)
            printf 'usage: Scripts/check.sh [--ui] [--bench]\n' >&2
            exit 2
            ;;
    esac
done

derived_data="$repository_root/build/DerivedData"
integration_derived_data="$repository_root/build/DerivedData-integration"
ios_derived_data="$repository_root/build/DerivedData-ios"
go_modules=(Packages/TunnelCore/go Scripts/go-comment-check Scripts/benchmark-check)
ui_test_languages=(en ru)
ui_test_time_allowance=180
ios_checks_skipped=false
started_at=$SECONDS

step() {
    printf '\n==> %s\n' "$1"
}

run_ui_tests() {
    local simulator udid name version state language
    local status=0
    if ! simulator="$(chosen_simulator iPhone <(xcrun simctl list --json))"; then
        printf 'No iPhone simulator for the UI tests: add the iOS platform in Xcode › Settings › Components\n' >&2
        exit 1
    fi
    IFS=$'\t' read -r udid name version state <<<"$simulator"
    xcrun simctl bootstatus "$udid" -b >/dev/null
    for language in "${ui_test_languages[@]}"; do
        printf 'On the %s simulator with iOS %s, in %s\n' "$name" "$version" "$language"
        TEST_RUNNER_SPLITWAY_UI_TEST_LANGUAGE="$language" xcodebuild -project Splitway.xcodeproj \
            -scheme iOSUITests -destination "id=$udid" -derivedDataPath "$ios_derived_data" \
            -collect-test-diagnostics never -test-timeouts-enabled YES \
            -default-test-execution-time-allowance "$ui_test_time_allowance" test -quiet || status=$?
        [[ "$status" -eq 0 ]] || break
    done
    if [[ "$state" != Booted ]]; then
        xcrun simctl shutdown "$udid" 2>/dev/null || true
    fi
    [[ "$status" -eq 0 ]] || exit "$status"
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

step "iOS device choice"
Scripts/tests/ios-devices-test.sh

step "iOS simulator choice"
Scripts/tests/ios-simulators-test.sh

step "Site links"
Scripts/check-site.sh

step "Go modules"
for module in "${go_modules[@]}"; do
    (cd "$module" && go vet ./... && go test ./...)
done

step "SplitwayKit tests"
swift test --package-path Packages/SplitwayKit --quiet

step "RoutingProbe tests"
swift test --package-path Scripts/RoutingProbe --quiet

step "TunnelCore test peer"
Packages/TunnelCore/Scripts/build-test-peer.sh

step "TunnelCore adapter tests"
swift test --package-path Packages/TunnelCore --quiet

step "Xcode project"
Scripts/generate-project.sh

step "macOS build"
build_scheme macOSApp 'generic/platform=macOS'

step "macOS integration tests"
if security find-identity -v -p codesigning | grep -q 'Apple Development'; then
    integration_status=0
    xcodebuild -project Splitway.xcodeproj -scheme IntegrationTestHost -destination 'platform=macOS' \
        -derivedDataPath "$integration_derived_data" -allowProvisioningUpdates test -quiet || integration_status=$?
    unregister_built_applications "$integration_derived_data/Build/Products"
    [[ "$integration_status" -eq 0 ]] || exit "$integration_status"
else
    printf 'Skipped: no Apple Development certificate in the keychain to sign the test host\n'
fi

step "iOS build and integration tests"
if iphone_simulator="$(chosen_simulator iPhone <(xcrun simctl list --json))"; then
    IFS=$'\t' read -r simulator_udid simulator_name simulator_version simulator_state <<<"$iphone_simulator"
    printf 'On the %s simulator with iOS %s\n' "$simulator_name" "$simulator_version"
    ios_status=0
    xcodebuild -project Splitway.xcodeproj -scheme iOSApp -destination "id=$simulator_udid" \
        -derivedDataPath "$ios_derived_data" test -quiet || ios_status=$?
    if [[ "$simulator_state" != Booted ]]; then
        xcrun simctl shutdown "$simulator_udid" 2>/dev/null || true
    fi
    [[ "$ios_status" -eq 0 ]] || exit "$ios_status"
else
    ios_checks_skipped=true
    printf 'SKIPPED: no iPhone simulator, so the iOS app was neither built nor tested.\n'
    printf 'Add the iOS platform in Xcode › Settings › Components to check it.\n'
fi

if [[ "$runs_ui_tests" == true ]]; then
    step "iOS UI tests"
    run_ui_tests
fi

if [[ "$runs_benchmarks" == true ]]; then
    step "Benchmarks"
    Scripts/benchmark.sh
fi

if [[ "$ios_checks_skipped" == true ]]; then
    printf '\nAll checks passed in %ds, but the iOS checks were skipped: no iPhone simulator\n' \
        "$((SECONDS - started_at))"
else
    printf '\nAll checks passed in %ds\n' "$((SECONDS - started_at))"
fi
