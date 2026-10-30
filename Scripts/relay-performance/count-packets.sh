#!/bin/sh
probe=/Applications/RoutingProbe.app/Contents/MacOS/RoutingProbe
label="$1"
counters() {
    netstat -I en0 -b | awk 'NR == 2 { print $5, $7, $8, $10 }'
}
before="$(counters)"
"$probe" download "https://proof.ovh.net/files/100Mb.dat" 1 | head -1 | awk '{ print $1, $2, $5, $6 }'
after="$(counters)"
echo "$before $after" | awk -v label="$label" '{ received = $5 - $1; sent = $7 - $3; printf "%s en0 packets in=%d out=%d out-per-in=%.3f bytes-in=%.1fMB bytes-out=%.1fMB\n", label, received, sent, sent / received, ($6 - $2) / 1e6, ($8 - $4) / 1e6 }'
