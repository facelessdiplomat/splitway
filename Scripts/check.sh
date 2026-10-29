#!/usr/bin/env bash
set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$repository_root/Scripts/lib/xcode-environment.sh"
cd "$repository_root"

if (($# > 0)); then
    printf 'usage: Scripts/check.sh\n' >&2
    exit 2
fi

derived_data="$repository_root/build/DerivedData"
go_modules=(Packages/TunnelCore/go Scripts/go-comment-check)
started_at=$SECONDS

step() {
    printf '\n==> %s\n' "$1"
}

iphone_simulator_identifier() {
    xcrun simctl list devices available \
        | grep -m 1 -E '^[[:space:]]+iPhone' \
        | grep -oE '[0-9A-F]{8}(-[0-9A-F]{4}){3}-[0-9A-F]{12}' || true
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

printf '\nAll checks passed in %ds\n' "$((SECONDS - started_at))"
