#!/usr/bin/env bash
set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repository_root"

xcodegen generate --spec project.yml --quiet
printf 'Generated %s/Splitway.xcodeproj\n' "$repository_root"
