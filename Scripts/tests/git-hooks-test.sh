#!/usr/bin/env bash
set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
commit_message_hook="$repository_root/Scripts/git-hooks/commit-msg"
message_file="$(mktemp)"
trap 'rm -f "$message_file"' EXIT
failures=0

check_message() {
    local expectation="$1"
    local message="$2"
    local outcome
    printf '%s\n' "$message" >"$message_file"
    if "$commit_message_hook" "$message_file" 2>/dev/null; then
        outcome=accepted
    else
        outcome=rejected
    fi
    if [[ "$outcome" != "$expectation" ]]; then
        printf 'FAIL: expected %s, got %s for message: %s\n' "$expectation" "$outcome" "$message" >&2
        failures=$((failures + 1))
    fi
}

check_message accepted "feat(TunnelConfiguration): parse multi-value AllowedIPs"
check_message accepted "fix: handle configurations without peers"
check_message accepted "build(SplitwayKit)!: require Swift 6.2"
check_message accepted "Merge branch 'feature/M0-05-splitwaykit-package'"
check_message accepted $'docs: describe the Co-Authored-By policy\n\nTask: M0-07'
check_message rejected "update stuff"
check_message rejected "Feat: capitalized type"
check_message rejected "feat:missing space"
check_message rejected $'feat: add parser\n\nCo-Authored-By: Claude <noreply@anthropic.com>'
check_message rejected $'fix: tidy imports\n\nCo-authored-by: GitHub Copilot <copilot@github.com>'
check_message rejected $'chore: bump version\n\nGenerated with [Claude Code](https://claude.com/claude-code)'

if ((failures > 0)); then
    printf '%d git hook checks failed\n' "$failures" >&2
    exit 1
fi
printf 'Git hook checks passed\n'
