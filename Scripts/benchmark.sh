#!/usr/bin/env bash
set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
baseline="$repository_root/Packages/TunnelCore/go/usernet/testdata/benchmark-baseline.txt"
benchmark_time=2s
repetitions=5
acknowledgement_tolerance=0.35

usage() {
    printf 'usage: Scripts/benchmark.sh [--write-baseline]\n' >&2
    exit 2
}

compare_arguments=(-baseline "$baseline" -unit-tolerance "acks/segment=$acknowledgement_tolerance")
case "${1-}" in
    "") ;;
    --write-baseline) compare_arguments+=(-write) ;;
    *) usage ;;
esac

output="$(mktemp)"
trap 'rm -f "$output"' EXIT
(
    cd "$repository_root/Packages/TunnelCore/go"
    go test -run '^$' -bench . -benchtime "$benchmark_time" -count "$repetitions" ./usernet/
) | tee "$output"
(cd "$repository_root/Scripts/benchmark-check" && go run . "${compare_arguments[@]}") <"$output"
