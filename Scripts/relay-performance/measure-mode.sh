#!/bin/sh
probe=/Applications/RoutingProbe.app/Contents/MacOS/RoutingProbe
label="$1"
results="/tmp/measure-$label-$(date +%s)"
mkdir -p "$results"
download_address="https://proof.ovh.net/files/100Mb.dat"
extension_pid="$(pgrep -f "network-extension.systemextension/Contents/MacOS" | head -1)"
core_count="$(sysctl -n hw.ncpu)"

now() {
    perl -MTime::HiRes=time -e 'printf "%.3f\n", time'
}

extension_cpu_seconds() {
    if [ -z "$extension_pid" ]; then
        echo 0
        return
    fi
    ps -o cputime= -p "$extension_pid" | awk -F: '{ total = 0; for (i = 1; i <= NF; i++) total = total * 60 + $i; printf "%.2f\n", total }'
}

total_bytes() {
    cat "$@" | awk '{ for (i = 1; i <= NF; i++) if ($i ~ /^bytes=/) { split($i, field, "="); total += field[2] } } END { print total + 0 }'
}

start_system_sampler() {
    echo run > "$results/$1-state"
    (while [ "$(cat "$results/$1-state")" = run ]; do top -l 2 -s 1 -n 0 | grep "CPU usage" | tail -1; done) > "$results/$1-top.txt" &
    sampler=$!
}

stop_system_sampler() {
    echo stop > "$results/$1-state"
    wait "$sampler"
    awk -v cores="$core_count" -v name="$1" '{ gsub("%", ""); busy = $3 + $5; sum += busy; count++ } END { if (count) printf "%s system busy=%.0f%% of %d cores (%.2f cores, %d samples)\n", name, sum / count, cores, sum / count * cores / 100, count }' "$results/$1-top.txt"
}

report_cost() {
    awk -v name="$1" -v before="$2" -v after="$3" -v started="$4" -v finished="$5" -v bytes="$6" 'BEGIN { cpu = after - before; wall = finished - started; printf "%s extension cpu-seconds=%.2f average-cpu=%.0f%% cpu-seconds-per-gb=%.1f aggregate-mbps=%.1f seconds=%.2f\n", name, cpu, cpu / wall * 100, (bytes > 0 ? cpu / (bytes / 1e9) : 0), bytes * 8 / wall / 1e6, wall }'
}

echo "== $label"
idle_before="$(extension_cpu_seconds)"
idle_started="$(now)"
sleep 20
report_cost idle "$idle_before" "$(extension_cpu_seconds)" "$idle_started" "$(now)" 0 | sed 's/ cpu-seconds-per-gb.*//'
probe_address="$("$probe" | awk '$1 == "address" && $2 == "ok" { print $3 }')"
curl_address="$(curl -s --max-time 10 https://api.ipify.org)"
if [ "$probe_address" = "$curl_address" ]; then echo "route: probe and curl share an address"; else echo "route: probe and curl use different addresses"; fi
"$probe" latency "https://proof.ovh.net/" 10 | tail -1
for attempt in 1 2 3 4 5; do "$probe" | awk '$1 == "resolver" && $2 == "ok" { print $NF }'; done | tr -d 'ms' | sort -n | awk '{ value[NR] = $1 } END { line = ""; for (i = 1; i <= NR; i++) line = line " " value[i]; printf "dns resolver-ms:%s median=%s\n", line, value[int((NR + 1) / 2)] }'

start_system_sampler single-stream
cpu_before="$(extension_cpu_seconds)"
started="$(now)"
"$probe" download "$download_address" 3 > "$results/single.txt"
finished="$(now)"
cpu_after="$(extension_cpu_seconds)"
stop_system_sampler single-stream
grep -v median "$results/single.txt" | awk '{ print $1, $2, $5 }' | tr '\n' ' '
echo
grep median "$results/single.txt"
report_cost single-stream "$cpu_before" "$cpu_after" "$started" "$finished" "$(total_bytes "$results/single.txt")"

start_system_sampler two-streams
cpu_before="$(extension_cpu_seconds)"
started="$(now)"
downloads=""
for stream in 1 2; do
    "$probe" download "$download_address" 1 > "$results/parallel-$stream.txt" &
    downloads="$downloads $!"
done
wait $downloads
finished="$(now)"
cpu_after="$(extension_cpu_seconds)"
stop_system_sampler two-streams
cat "$results"/parallel-*.txt | grep -v median | awk '{ print $5 }' | tr '\n' ' '
echo
report_cost two-streams "$cpu_before" "$cpu_after" "$started" "$finished" "$(total_bytes "$results"/parallel-*.txt)"

echo
