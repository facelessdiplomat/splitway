#!/bin/sh
probe=/Applications/RoutingProbe.app/Contents/MacOS/RoutingProbe
label="$1"
extension_pid="$(pgrep -f "network-extension.systemextension/Contents/MacOS" | head -1)"
"$probe" download "https://proof.ovh.net/files/100Mb.dat" 2 > "/tmp/profile-$label-download.txt" &
download=$!
sleep 1
sudo -n /usr/bin/sample "$extension_pid" 6 -mayDie -file "/tmp/sample-$label.txt" > /dev/null 2>&1
wait "$download"
cat "/tmp/profile-$label-download.txt"
wc -l < "/tmp/sample-$label.txt"
