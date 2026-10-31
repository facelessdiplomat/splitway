#!/usr/bin/env bash
set -euo pipefail

probe="${ROUTING_PROBE:-/Applications/RoutingProbe.app/Contents/MacOS/RoutingProbe}"
download_address="${RELAY_BENCHMARK_DOWNLOAD:-https://proof.ovh.net/files/100Mb.dat}"
latency_address="${RELAY_BENCHMARK_LATENCY:-https://proof.ovh.net/}"
echo_address="https://api.ipify.org"
extension_process="network-extension.systemextension/Contents/MacOS"
download_attempts=3
parallel_streams=2
latency_attempts=10
dns_attempts=5
idle_seconds=20
bytes_per_gigabyte=1000000000
results="$(mktemp -d)"
trap 'rm -rf "$results"' EXIT

usage() {
    printf 'usage: Scripts/relay-benchmark-macos.sh <label>\n' >&2
    exit 2
}

now() {
    perl -MTime::HiRes=time -e 'printf "%.3f\n", time'
}

extension_cpu_seconds() {
    if [[ -z "$extension_pid" ]]; then
        echo 0
        return
    fi
    ps -o cputime= -p "$extension_pid" | awk -F: '{ total = 0; for (i = 1; i <= NF; i++) total = total * 60 + $i; printf "%.2f\n", total }'
}

physical_packet_counts() {
    netstat -ib | awk '$1 ~ /^en[0-9]+$/ && $3 ~ /^<Link/ { inbound += $5; outbound += $8 } END { print inbound + 0, outbound + 0 }'
}

start_system_sampler() {
    printf 'run\n' >"$results/sampler-state"
    (
        while [[ "$(cat "$results/sampler-state")" == run ]]; do
            top -l 2 -s 1 -n 0 | grep "CPU usage" | tail -1
        done
    ) >"$results/top.txt" &
    sampler=$!
}

stop_system_sampler() {
    printf 'stop\n' >"$results/sampler-state"
    wait "$sampler"
    awk -v cores="$(sysctl -n hw.ncpu)" '{ gsub("%", ""); busy += $3 + $5; count++ } END { if (count) printf "%.2f", busy / count * cores / 100; else printf "none" }' "$results/top.txt"
}

successful_bytes() {
    cat "$@" | awk '$3 ~ /^bytes=/ && $0 ~ / status=200 / { split($3, field, "="); total += field[2] } END { print total + 0 }'
}

failed_attempts() {
    cat "$@" | awk '$1 ~ /^(download|upload)$/ && $2 != "median" && $0 !~ / status=200 / { count++ } END { print count + 0 }'
}

cost_fields() {
    awk -v before="$1" -v after="$2" -v started="$3" -v finished="$4" -v bytes="$5" -v gigabyte="$bytes_per_gigabyte" 'BEGIN {
        wall = finished - started
        printf "aggregate-mbps=%.1f extension-cpu-seconds-per-gb=%s", bytes * 8 / wall / 1e6, (bytes > 0 ? sprintf("%.1f", (after - before) / (bytes / gigabyte)) : "none")
    }'
}

measure_idle() {
    local before started
    before="$(extension_cpu_seconds)"
    started="$(now)"
    sleep "$idle_seconds"
    awk -v before="$before" -v after="$(extension_cpu_seconds)" -v started="$started" -v finished="$(now)" 'BEGIN { printf "idle extension-cpu-percent=%.1f\n", (after - before) / (finished - started) * 100 }'
}

check_route() {
    local probe_address curl_address
    probe_address="$("$probe" | awk '$1 == "address" && $2 == "ok" { print $3 }')"
    curl_address="$(curl -s --max-time 10 "$echo_address" || true)"
    if [[ -n "$probe_address" && "$probe_address" == "$curl_address" ]]; then
        printf 'route probe-and-curl=same\n'
    else
        printf 'route probe-and-curl=different\n'
    fi
}

measure_latency() {
    "$probe" latency "$latency_address" "$latency_attempts" | awk '$1 == "latency" && $2 == "median" { $1 = "latency"; $2 = ""; sub("  ", " "); print }'
}

measure_dns() {
    local attempt
    for ((attempt = 1; attempt <= dns_attempts; attempt++)); do
        "$probe" | awk '$1 == "resolver" && $2 == "ok" { sub("ms", "", $NF); print $NF }'
    done | sort -n | awk '{ value[NR] = $1 } END { if (NR) printf "dns median-ms=%s answers=%d\n", value[int((NR + 1) / 2)], NR; else print "dns median-ms=none answers=0" }'
}

measure_single_stream() {
    local before started finished after cores
    start_system_sampler
    before="$(extension_cpu_seconds)"
    started="$(now)"
    "$probe" download "$download_address" "$download_attempts" >"$results/single.txt"
    finished="$(now)"
    after="$(extension_cpu_seconds)"
    cores="$(stop_system_sampler)"
    printf 'single-stream median-mbps=%s %s system-cores=%s failed-attempts=%s\n' \
        "$(awk '$1 == "download" && $2 == "median" { sub("mbps=", "", $3); print $3 }' "$results/single.txt")" \
        "$(cost_fields "$before" "$after" "$started" "$finished" "$(successful_bytes "$results/single.txt")")" \
        "$cores" "$(failed_attempts "$results/single.txt")"
}

measure_parallel_streams() {
    local before started finished after cores stream downloads=()
    start_system_sampler
    before="$(extension_cpu_seconds)"
    started="$(now)"
    for ((stream = 1; stream <= parallel_streams; stream++)); do
        "$probe" download "$download_address" 1 >"$results/parallel-$stream.txt" &
        downloads+=("$!")
    done
    wait "${downloads[@]}"
    finished="$(now)"
    after="$(extension_cpu_seconds)"
    cores="$(stop_system_sampler)"
    printf 'parallel-streams streams=%d %s system-cores=%s failed-attempts=%s\n' "$parallel_streams" \
        "$(cost_fields "$before" "$after" "$started" "$finished" "$(successful_bytes "$results"/parallel-*.txt)")" \
        "$cores" "$(failed_attempts "$results"/parallel-*.txt)"
}

measure_packets() {
    local before after
    before="$(physical_packet_counts)"
    "$probe" download "$download_address" 1 >"$results/packets.txt"
    after="$(physical_packet_counts)"
    awk -v before="$before" -v after="$after" 'BEGIN {
        split(before, start, " "); split(after, end, " ")
        inbound = end[1] - start[1]; outbound = end[2] - start[2]
        printf "packets inbound=%d outbound=%d outbound-per-inbound=%.3f\n", inbound, outbound, (inbound > 0 ? outbound / inbound : 0)
    }'
}

if [[ $# -ne 1 ]]; then
    usage
fi
extension_pid="$(pgrep -f "$extension_process" | head -1 || true)"
printf 'label %s\n' "$1"
measure_idle
check_route
measure_latency
measure_dns
measure_single_stream
measure_parallel_streams
measure_packets
if [[ -n "$extension_pid" && "$(pgrep -f "$extension_process" | head -1 || true)" != "$extension_pid" ]]; then
    printf 'warning the extension restarted during the run, its CPU figures are wrong\n'
fi
