#!/usr/bin/env bash
set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repository_root"

required_tools=(git swiftlint xcodegen go)
for tool in "${required_tools[@]}"; do
    if ! command -v "$tool" >/dev/null; then
        printf 'Missing required tool: %s\n' "$tool" >&2
        exit 1
    fi
done

chmod +x Scripts/*.sh Scripts/git-hooks/* Scripts/tests/*.sh Packages/TunnelCore/Scripts/*.sh
source "$repository_root/Scripts/lib/build-directory.sh"
git config core.hooksPath Scripts/git-hooks
printf 'Git hooks installed from Scripts/git-hooks\n'

Packages/TunnelCore/Scripts/build-xcframework.sh
Scripts/generate-project.sh
