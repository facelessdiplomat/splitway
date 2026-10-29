#!/usr/bin/env bash
set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$repository_root/Scripts/lib/lint-checks.sh"
fixtures="$repository_root/Scripts/LintFixtures"
failures=0

swiftlint_output() {
    swiftlint lint --quiet --config "$repository_root/.swiftlint.yml" "$fixtures/$1" 2>/dev/null || true
}

record_failure() {
    printf 'FAIL: %s\n' "$1" >&2
    failures=$((failures + 1))
}

expect_rule_violation() {
    local rule="$1"
    local fixture="$2"
    if ! swiftlint_output "$fixture" | grep -q "($rule)"; then
        record_failure "expected $rule in $fixture"
    fi
}

expect_no_violations() {
    local fixture="$1"
    local output
    output="$(swiftlint_output "$fixture")"
    if [[ -n "$output" ]]; then
        record_failure "expected $fixture to be clean, got: $output"
    fi
}

expect_suppression_found() {
    local fixture="$1"
    if ! find_linter_suppressions "$fixtures/$fixture" >/dev/null; then
        record_failure "expected a linter suppression to be found in $fixture"
    fi
}

expect_rule_violation no_comments LineComment.swift
expect_rule_violation no_comments DocumentationComment.swift
expect_rule_violation no_comments BlockComment.swift
expect_rule_violation no_comments MarkComment.swift
expect_rule_violation no_comments TrailingComment.swift
expect_rule_violation core_layer_imports Core/FrameworkImport.swift
expect_rule_violation no_print Print.swift
expect_no_violations UrlInString.swift
expect_no_violations PackageManifest/Package.swift
expect_no_violations Infrastructure/FrameworkImport.swift
expect_suppression_found LinterSuppression.swift

if ((failures > 0)); then
    printf '%d lint rule checks failed\n' "$failures" >&2
    exit 1
fi
printf 'Lint rule checks passed\n'
