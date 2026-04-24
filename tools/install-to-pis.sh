#!/bin/bash
set -Eeuo pipefail

# install-to-pis.sh
#
# Installs or updates Pi_Updates scripts and configs on multiple Raspberry Pis over SSH.
#
# This script is standalone. It does not require a local clone of the full repository.
# Each target system downloads the current files directly from GitHub using curl.
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

RUN_NOW=false
INSTALL_IPV4=false
BRANCH="main"
REPO_RAW_BASE="https://raw.githubusercontent.com/Kraethor/Pi_Updates"

# Show usage information
usage() {
    cat << EOF
Usage: $0 [options] hosts.txt

Options:
  --run-now                   Run patch-system.sh immediately after install
  --install-ipv4-workaround   Install apt/99force-ipv4 on each target
  --branch BRANCH             Git branch to install from (default: main)
  -h, --help                  Show this help message
EOF
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --run-now)
            RUN_NOW=true
            shift
            ;;
        --install-ipv4-workaround)
            INSTALL_IPV4=true
            shift
            ;;
        --branch)
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
            HOST_FILE="$1"
            shift
            ;;
    esac
done

if [[ -z "${HOST_FILE:-}" ]]; then
    echo "ERROR: No host file specified"
    usage
    exit 1
fi

if [[ ! -f "$HOST_FILE" ]]; then
    echo "ERROR: Host file not found: $HOST_FILE"
    exit 1
fi

RAW_BASE="${REPO_RAW_BASE}/${BRANCH}"

# Deploy to each host
while IFS= read -r host || [[ -n "$host" ]]; do
    # Ignore blank lines and comments in the host file
    [[ -z "$host" ]] && continue
    [[ "$host" =~ ^[[:space:]]*# ]] && continue

    echo "===== Deploying Pi_Updates to $host from branch $BRANCH ====="

    ssh "$host" \
        "RAW_BASE='$RAW_BASE' INSTALL_IPV4='$INSTALL_IPV4' RUN_NOW='$RUN_NOW' bash -s" << 'EOF'
set -Eeuo pipefail

# Download a file from GitHub and install it with the requested mode.
install_from_github() {
    local source_path="$1"
    local destination_path="$2"
    local mode="$3"
    local tmp_file

    tmp_file="$(mktemp)"

    curl -fsSL "${RAW_BASE}/${source_path}" -o "$tmp_file"
    sudo install -m "$mode" "$tmp_file" "$destination_path"
    rm -f "$tmp_file"
}

# Verify required commands exist on the target before changing the system.
command -v curl >/dev/null 2>&1 || { echo "ERROR: curl is required on target system"; exit 1; }
command -v sudo >/dev/null 2>&1 || { echo "ERROR: sudo is required on target system"; exit 1; }

# Install scripts
install_from_github "scripts/pi-inventory.sh" "/usr/local/bin/pi-inventory.sh" "755"
install_from_github "scripts/patch-system.sh" "/usr/local/bin/patch-system.sh" "755"

# Install supporting configs
install_from_github "cron/patch-system.cron" "/etc/cron.d/patch-system" "644"
install_from_github "logrotate/patch-system" "/etc/logrotate.d/patch-system" "644"

# Install optional APT IPv4 workaround only when requested.
if [[ "$INSTALL_IPV4" == "true" ]]; then
    install_from_github "apt/99force-ipv4" "/etc/apt/apt.conf.d/99force-ipv4" "644"
fi

# Validate script syntax after installation.
bash -n /usr/local/bin/pi-inventory.sh
bash -n /usr/local/bin/patch-system.sh

# Validate logrotate configuration if logrotate is installed.
if command -v logrotate >/dev/null 2>&1; then
    sudo logrotate -d /etc/logrotate.d/patch-system >/dev/null
else
    echo "WARNING: logrotate not found; skipping logrotate validation"
fi

# Run the patching script immediately only when requested.
if [[ "$RUN_NOW" == "true" ]]; then
    sudo /usr/local/bin/patch-system.sh
fi
EOF

    echo "===== Completed $host ====="
done < "$HOST_FILE"

echo "All hosts processed."
