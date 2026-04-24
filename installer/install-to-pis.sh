#!/bin/bash
set -Eeuo pipefail

# install-to-pis.sh
#
# Standalone fleet installer for the Pi_Updates repository.
#
# This script connects to each Raspberry Pi listed in a host file and installs
# the current Pi_Updates scripts/configs directly from GitHub using curl on the
# target system. It does not require a local clone of the full repository.
#
# Usage:
#   ./install-to-pis.sh [--run-now] [--install-ipv4-workaround] [--branch BRANCH] hosts.txt
#
# Host file format:
#   - One SSH target per line
#   - Blank lines are ignored
#   - Lines beginning with # are ignored
#
# Example hosts.txt:
#   pi01
#   pi@pi02
#   192.168.169.101
#
# Requirements on the system running this script:
#   - bash
#   - ssh
#
# Requirements on each target system:
#   - curl
#   - sudo privileges
#   - outbound HTTPS access to raw.githubusercontent.com

# Default behavior: install/update files only.
# Optional flags below can change this behavior.
RUN_NOW=false
INSTALL_IPV4=false
BRANCH="main"

# Base URL for raw GitHub file downloads.
# The branch is appended later so --branch can override main.
REPO_RAW_BASE="https://raw.githubusercontent.com/Kraethor/Pi_Updates"

# Print command usage.
usage() {
    echo "Usage: $0 [--run-now] [--install-ipv4-workaround] [--branch BRANCH] hosts.txt"
}

# Parse command-line options.
while [[ $# -gt 0 ]]; do
    case "$1" in
        --run-now)
            # Run patch-system.sh immediately after installing/updating files.
            RUN_NOW=true
            shift
            ;;
        --install-ipv4-workaround)
            # Install the optional APT IPv4 workaround on each target.
            INSTALL_IPV4=true
            shift
            ;;
        --branch)
            # Install files from a non-main branch.
            # Useful for testing changes before deploying from main.
            if [[ -z "${2:-}" ]]; then
                echo "ERROR: --branch requires a branch name"
                exit 1
            fi
            BRANCH="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            # First non-option argument is treated as the host file.
            HOST_FILE="$1"
            shift
            ;;
    esac
done

# Validate required host file argument.
if [[ -z "${HOST_FILE:-}" ]]; then
    echo "ERROR: No host file specified"
    usage
    exit 1
fi

# Validate that the host file exists before attempting any SSH connections.
if [[ ! -f "$HOST_FILE" ]]; then
    echo "ERROR: Host file not found: $HOST_FILE"
    exit 1
fi

# Complete raw GitHub base URL for the selected branch.
RAW_BASE="${REPO_RAW_BASE}/${BRANCH}"

# Process each target host sequentially.
# Sequential processing is intentional: it keeps failures easy to read and debug.
while IFS= read -r host || [[ -n "$host" ]]; do
    # Ignore blank lines and comments in the host file.
    [[ -z "$host" ]] && continue
    [[ "$host" =~ ^[[:space:]]*# ]] && continue

    echo "===== Deploying Pi_Updates to $host from branch $BRANCH ====="

    # Run the remote install block on the target host.
    # Variables are passed into the remote shell environment before bash starts.
    ssh "$host" "RAW_BASE='$RAW_BASE' INSTALL_IPV4='$INSTALL_IPV4' RUN_NOW='$RUN_NOW' bash -s" << 'EOF'
set -Eeuo pipefail

# Download a repository file from GitHub and install it with the requested mode.
#
# Arguments:
#   $1 - Source path inside the Pi_Updates repository
#   $2 - Destination path on the target system
#   $3 - File mode to apply with install(1)
install_file() {
    local src="$1"
    local dst="$2"
    local mode="$3"
    local tmp

    # Use mktemp to avoid predictable filenames and collisions in /tmp.
    tmp="$(mktemp)"

    # curl options:
    #   -f fail on HTTP errors
    #   -s silent mode
    #   -S show errors even when silent
    #   -L follow redirects
    curl -4 -fsSL "$RAW_BASE/$src" -o "$tmp"

    # install sets ownership/permissions in one step and replaces the target file.
    sudo install -m "$mode" "$tmp" "$dst"

    # Remove temporary file after successful install.
    rm -f "$tmp"
}

# Verify required commands exist on the target before changing the system.
command -v curl >/dev/null 2>&1 || { echo "ERROR: curl is required on target system"; exit 1; }
command -v sudo >/dev/null 2>&1 || { echo "ERROR: sudo is required on target system"; exit 1; }

# Install inventory script.
install_file "inventory/pi-inventory.sh" "/usr/local/bin/pi-inventory.sh" 755

# Install patching script.
install_file "patching/patch-system.sh" "/usr/local/bin/patch-system.sh" 755

# Install supporting patching configuration.
install_file "patching/cron/patch-system.cron" "/etc/cron.d/patch-system" 644
install_file "patching/logrotate/patch-system" "/etc/logrotate.d/patch-system" 644

# Install optional APT IPv4 workaround only when requested.
if [[ "$INSTALL_IPV4" == "true" ]]; then
    install_file "patching/apt/99force-ipv4" "/etc/apt/apt.conf.d/99force-ipv4" 644
fi

# Validate installed shell scripts before returning success.
bash -n /usr/local/bin/pi-inventory.sh
bash -n /usr/local/bin/patch-system.sh

# Validate logrotate configuration when logrotate is available.
if command -v logrotate >/dev/null 2>&1; then
    sudo logrotate -d /etc/logrotate.d/patch-system >/dev/null
else
    echo "WARNING: logrotate not found; skipping logrotate validation"
fi

# Run patching immediately only when requested.
if [[ "$RUN_NOW" == "true" ]]; then
    sudo /usr/local/bin/patch-system.sh
fi
EOF

    echo "===== Completed $host ====="
done < "$HOST_FILE"

echo "All hosts processed."
