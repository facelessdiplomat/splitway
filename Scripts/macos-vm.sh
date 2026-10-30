#!/usr/bin/env bash
set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$repository_root/Scripts/lib/xcode-environment.sh"
cd "$repository_root"

image_reference="ghcr.io/cirruslabs/macos-tahoe-base@sha256:4aaa751fa7538902d73c767f27a066fc87e83f183069da4e4b5022863abd4c77"
virtual_machine_name="${SPLITWAY_MACOS_VM_NAME:-splitway-macos26}"
virtual_machine_directory="$HOME/.tart/vms/$virtual_machine_name"
clean_state_directory="$HOME/.tart/clean-states/$virtual_machine_name"
shared_directory="$repository_root/build/macos-vm/shared"
shared_directory_in_guest="/Volumes/My Shared Files/splitway"
run_log="$repository_root/build/macos-vm/run.log"
guest_screenshot="/tmp/splitway-screen.png"
derived_data_directory="build/DerivedData-signed"
guest_agent_attempts=90
guest_agent_retry_seconds=2
shutdown_attempts=60
disk_files=(disk.img nvram.bin)

usage() {
    printf 'usage: Scripts/macos-vm.sh <command>\n\n' >&2
    printf '  create                download the macOS 26 image and create the VM\n' >&2
    printf '  start [--headless]    start the VM with the build folder shared read-only\n' >&2
    printf '  device-id             print the Provisioning UDID to register in the developer account\n' >&2
    printf '  install [checkout]    build the signed Mac app of a checkout and install it in the VM\n' >&2
    printf '  launch [arguments]    open the installed app in the VM\n' >&2
    printf '  exec <command>        run a command in the VM\n' >&2
    printf '  screenshot <file>     save a PNG of the VM screen\n' >&2
    printf '  save-clean-state      stop the VM and keep its disk as the clean state\n' >&2
    printf '  restore-clean-state   stop the VM and return its disk to the clean state\n' >&2
    printf '  stop                  stop the VM\n' >&2
    exit 2
}

guest_exec() {
    tart exec "$virtual_machine_name" "$@"
}

is_running() {
    tart list --format json | python3 -I -c '
import json, sys
states = {machine["Name"]: machine["State"] for machine in json.load(sys.stdin)}
sys.exit(0 if states.get(sys.argv[1]) == "running" else 1)
' "$virtual_machine_name"
}

wait_for_guest_agent() {
    local attempt
    for ((attempt = 1; attempt <= guest_agent_attempts; attempt++)); do
        if guest_exec true >/dev/null 2>&1; then
            return 0
        fi
        sleep "$guest_agent_retry_seconds"
    done
    printf 'the guest agent of %s did not answer\n' "$virtual_machine_name" >&2
    return 1
}

create_virtual_machine() {
    tart clone "$image_reference" "$virtual_machine_name"
}

start_virtual_machine() {
    if is_running; then
        printf '%s is already running\n' "$virtual_machine_name" >&2
        return 0
    fi
    mkdir -p "$shared_directory"
    if [[ "${1:-}" == "--headless" ]]; then
        nohup tart run "$virtual_machine_name" --no-graphics --dir="splitway:$shared_directory:ro" >"$run_log" 2>&1 &
    else
        nohup tart run "$virtual_machine_name" --dir="splitway:$shared_directory:ro" >"$run_log" 2>&1 &
    fi
    wait_for_guest_agent
}

stop_virtual_machine() {
    is_running || return 0
    guest_exec sudo -n /sbin/shutdown -h now >/dev/null 2>&1 || true
    local attempt
    for ((attempt = 1; attempt <= shutdown_attempts; attempt++)); do
        is_running || return 0
        sleep "$guest_agent_retry_seconds"
    done
    tart stop "$virtual_machine_name"
}

print_device_identifier() {
    guest_exec system_profiler SPHardwareDataType | awk -F': ' '/Provisioning UDID/ { print tolower($2) }'
}

install_application() {
    local checkout build_number install_directory
    checkout="$(cd "${1:-$repository_root}" && pwd)"
    build_number="$(date +%s)"
    install_directory="install-$build_number"
    (
        cd "$checkout"
        Scripts/generate-project.sh >/dev/null
        xcodebuild build -project Splitway.xcodeproj -scheme macOSApp -configuration Debug \
            -destination 'platform=macOS,arch=arm64' -derivedDataPath "$derived_data_directory" \
            -allowProvisioningUpdates -quiet CURRENT_PROJECT_VERSION="$build_number"
    )
    rm -rf "$shared_directory"/install-*
    mkdir -p "$shared_directory/$install_directory"
    ditto "$checkout/$derived_data_directory/Build/Products/Debug/Splitway.app" \
        "$shared_directory/$install_directory/Splitway.app"
    guest_exec pkill -x Splitway || true
    guest_exec rm -rf /Applications/Splitway.app
    guest_exec ditto "$shared_directory_in_guest/$install_directory/Splitway.app" /Applications/Splitway.app
}

save_screenshot() {
    if [[ $# -lt 1 ]]; then
        usage
    fi
    guest_exec /usr/sbin/screencapture -x -t png "$guest_screenshot"
    guest_exec /bin/cat "$guest_screenshot" >"$1"
}

launch_application() {
    guest_exec open -a /Applications/Splitway.app --args "$@"
}

save_clean_state() {
    stop_virtual_machine
    mkdir -p "$clean_state_directory"
    local file
    for file in "${disk_files[@]}"; do
        rm -f "$clean_state_directory/$file"
        cp -c "$virtual_machine_directory/$file" "$clean_state_directory/$file"
    done
}

restore_clean_state() {
    local file
    for file in "${disk_files[@]}"; do
        if [[ ! -f "$clean_state_directory/$file" ]]; then
            printf 'no clean state saved for %s\n' "$virtual_machine_name" >&2
            exit 1
        fi
    done
    stop_virtual_machine
    for file in "${disk_files[@]}"; do
        rm -f "$virtual_machine_directory/$file"
        cp -c "$clean_state_directory/$file" "$virtual_machine_directory/$file"
    done
}

if [[ $# -lt 1 ]]; then
    usage
fi

command="$1"
shift
case "$command" in
create) create_virtual_machine ;;
start) start_virtual_machine "$@" ;;
device-id) print_device_identifier ;;
install) install_application "$@" ;;
launch) launch_application "$@" ;;
exec) guest_exec "$@" ;;
screenshot) save_screenshot "$@" ;;
save-clean-state) save_clean_state ;;
restore-clean-state) restore_clean_state ;;
stop) stop_virtual_machine ;;
*) usage ;;
esac
