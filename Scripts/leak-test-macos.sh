#!/usr/bin/env bash
set -euo pipefail

probe="${ROUTING_PROBE:-/Applications/RoutingProbe.app/Contents/MacOS/RoutingProbe}"
echo_address="https://api.ipify.org"
resolver_identity="whoami.akamai.net"
ipv6_destination="2606:4700:4700::1111"
blocking_budget_milliseconds=5000
background_delay_seconds=5
background_wait_seconds=15
background_collection_seconds=30
background_address=""
failures=0

usage() {
    printf 'usage: Scripts/leak-test-macos.sh <selected|unavailable|background> [--show-addresses]\n' >&2
    exit 2
}

report() {
    printf '%-4s %s\n' "$1" "$2"
    if [[ "$1" == FAIL ]]; then
        failures=$((failures + 1))
    fi
}

check() {
    local description="$1"
    shift
    if "$@"; then
        report PASS "$description"
    else
        report FAIL "$description"
    fi
}

probe_field() {
    awk -v check="$1" -v index_="$2" '$1 == check { print $index_ }' <<<"$probe_output"
}

probe_elapsed() {
    awk -v check="$1" '$1 == check { sub("ms", "", $NF); print $NF }' <<<"$probe_output"
}

is_true() {
    [[ "$1" == true ]]
}

measure() {
    probe_output="$("$probe")"
    system_resolver="$(awk '/^nameserver/ { print $2; exit }' /etc/resolv.conf)"
    direct_address="$(curl -s --max-time 10 "$echo_address" || true)"
    direct_resolver="$(dig +short +time=3 +tries=1 "@$system_resolver" "$resolver_identity" A 2>/dev/null | tail -1 || true)"
    direct_ipv6="$(curl -6 -s -o /dev/null -w '%{http_code}' --max-time 5 "https://[$ipv6_destination]/" || true)"
}

show_addresses() {
    printf '\nRoutingProbe:\n%s\n' "$probe_output"
    printf 'curl: %s, dig through %s: %s, curl over IPv6: HTTP %s\n' \
        "${direct_address:-none}" "$system_resolver" "${direct_resolver:-none}" "$direct_ipv6"
    if [[ -n "$background_address" ]]; then
        printf 'background download: %s\n' "$background_address"
    fi
}

check_selected() {
    local probe_address probe_resolver_code probe_resolver
    probe_address="$(probe_field address 3)"
    probe_resolver_code="$(probe_field resolver 3)"
    probe_resolver="$(probe_field resolver 4)"
    check "the selected RoutingProbe reaches the internet" is_true "$([[ "$(probe_field address 2)" == ok ]] && echo true)"
    check "the unselected curl reaches the internet" is_true "$([[ -n "$direct_address" ]] && echo true)"
    check "the selected RoutingProbe leaves through the tunnel, curl directly" \
        is_true "$([[ -n "$probe_address" && "$probe_address" != "$direct_address" ]] && echo true)"
    check "the unselected dig gets an answer from the system resolver" \
        is_true "$([[ -n "$direct_resolver" ]] && echo true)"
    check "the DNS query of the selected RoutingProbe is answered through the tunnel" \
        is_true "$([[ "$probe_resolver_code" == NOERROR && -n "$probe_resolver" && "$probe_resolver" != "$direct_resolver" ]] && echo true)"
    if [[ "$direct_ipv6" == 000 ]]; then
        report SKIP "IPv6 of the selected RoutingProbe: this network has no IPv6"
    elif [[ "${TUNNEL_CARRIES_IPV6:-no}" == yes ]]; then
        check "IPv6 of the selected RoutingProbe goes through the tunnel" \
            is_true "$([[ "$(probe_field ipv6 3)" == connected ]] && echo true)"
    else
        check "IPv6 of the selected RoutingProbe is refused on a tunnel without IPv6" \
            is_true "$([[ "$(probe_field ipv6 3)" == refused && "$(probe_elapsed ipv6)" -lt "$blocking_budget_milliseconds" ]] && echo true)"
    fi
}

check_unavailable() {
    check "the selected RoutingProbe cannot reach the internet" \
        is_true "$([[ "$(probe_field address 2)" == failed ]] && echo true)"
    check "the selected RoutingProbe fails at once, not after a timeout" \
        is_true "$([[ "$(probe_elapsed address)" -lt "$blocking_budget_milliseconds" ]] && echo true)"
    check "the DNS query of the selected RoutingProbe is refused" \
        is_true "$([[ "$(probe_field resolver 2)" == ok && "$(probe_field resolver 3)" == REFUSED ]] && echo true)"
    check "the unselected curl still reaches the internet" is_true "$([[ -n "$direct_address" ]] && echo true)"
}

check_background() {
    local probe_address
    probe_address="$(probe_field address 3)"
    "$probe" background-start "$echo_address" "$background_delay_seconds" >/dev/null
    sleep "$background_wait_seconds"
    background_address="$("$probe" background-collect "$background_collection_seconds" | awk '$1 == "background" && $2 == "ok" { print $3 }')"
    check "the background download of RoutingProbe, begun after it exited, completes" \
        is_true "$([[ -n "$background_address" ]] && echo true)"
    if [[ -n "$background_address" && "$background_address" == "$probe_address" ]]; then
        report INFO "the background download of the exited RoutingProbe leaves through the tunnel"
    else
        report INFO "the background download of the exited RoutingProbe leaves directly: nsurlsessiond sends it under its own identity"
    fi
}

[[ $# -ge 1 ]] || usage
scenario="$1"
shows_addresses=false
[[ "${2-}" == --show-addresses ]] && shows_addresses=true
[[ -x "$probe" ]] || {
    printf 'RoutingProbe not found at %s, build it with Scripts/build-routing-probe.sh\n' "$probe" >&2
    exit 2
}

measure
case "$scenario" in
selected) check_selected ;;
unavailable) check_unavailable ;;
background) check_background ;;
*) usage ;;
esac
if [[ "$shows_addresses" == true ]]; then
    show_addresses
fi
if ((failures > 0)); then
    printf '\n%d check(s) failed\n' "$failures"
    exit 1
fi
printf '\nAll checks passed\n'
