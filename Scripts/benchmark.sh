#!/usr/bin/env bash
set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
go_module="$repository_root/Packages/TunnelCore/go"
benchmarked_packages=(usernet servicerouting)
benchmark_time=2s
repetitions=5
acknowledgement_tolerance=0.35

usage() {
    printf 'usage: Scripts/benchmark.sh [--write-baseline]\n' >&2
    exit 2
}

writes_baseline=false
case "${1-}" in
    "") ;;
    --write-baseline) writes_baseline=true ;;
    *) usage ;;
esac

output="$(mktemp)"
trap 'rm -f "$output"' EXIT
regressed_packages=0
for package in "${benchmarked_packages[@]}"; do
    compare_arguments=(-baseline "$go_module/$package/testdata/benchmark-baseline.txt"
        -unit-tolerance "acks/segment=$acknowledgement_tolerance")
    if [[ "$writes_baseline" == true ]]; then
        compare_arguments+=(-write)
    fi
    (cd "$go_module" && go test -run '^$' -bench . -benchtime "$benchmark_time" -count "$repetitions" "./$package/") |
        tee "$output"
    if ! (cd "$repository_root/Scripts/benchmark-check" && go run . "${compare_arguments[@]}") <"$output"; then
        regressed_packages=$((regressed_packages + 1))
    fi
done
((regressed_packages == 0))
