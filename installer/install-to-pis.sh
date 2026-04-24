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

RUN_NOW=false
INSTALL_IPV4=false
BRANCH="main"

REPO_RAW_BASE="https://raw.githubusercontent.com/Kraethor/Pi_Updates"

SUCCESS_HOSTS=()
FAILED_HOSTS=()

usage() {
    echo "Usage: $0 [--run-now] [--install-ipv4-workaround] [--branch BRANCH] hosts.txt"
}

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

while IFS= read -r host || [[ -n "$host" ]]; do
    [[ -z "$host" ]] && continue
    [[ "$host" =~ ^[[:space:]]*# ]] && continue

    echo "===== Deploying Pi_Updates to $host from branch $BRANCH ====="

    if ssh "$host" "RAW_BASE='$RAW_BASE' INSTALL_IPV4='$INSTALL_IPV4' RUN_NOW='$RUN_NOW' bash -s" << 'EOF'
set -Eeuo pipefail

export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

install_file() {
    local src="$1"
    local dst="$2"
    local mode="$3"
    local tmp

    tmp="$(mktemp)"
    curl -4 -fsSL "$RAW_BASE/$src" -o "$tmp"
    sudo install -m "$mode" "$tmp" "$dst"
    rm -f "$tmp"
}

command -v curl >/dev/null 2>&1 || { echo "ERROR: curl is required on target system"; exit 1; }
command -v sudo >/dev/null 2>&1 || { echo "ERROR: sudo is required on target system"; exit 1; }

install_file "inventory/pi-inventory.sh" "/usr/local/bin/pi-inventory.sh" 755
install_file "patching/patch-system.sh" "/usr/local/bin/patch-system.sh" 755
install_file "patching/cron/patch-system.cron" "/etc/cron.d/patch-system" 644
install_file "patching/logrotate/patch-system" "/etc/logrotate.d/patch-system" 644

if [[ "$INSTALL_IPV4" == "true" ]]; then
    install_file "patching/apt/99force-ipv4" "/etc/apt/apt.conf.d/99force-ipv4" 644
fi

# Pre-create log file
sudo touch /var/log/patch-system.log
sudo chmod 640 /var/log/patch-system.log

bash -n /usr/local/bin/pi-inventory.sh
bash -n /usr/local/bin/patch-system.sh

# Validate logrotate silently
if command -v logrotate >/dev/null 2>&1; then
    sudo logrotate -d /etc/logrotate.d/patch-system >/dev/null 2>&1 || {
        echo "ERROR: logrotate config validation failed"
        exit 1
    }
fi

if [[ "$RUN_NOW" == "true" ]]; then
    sudo /usr/local/bin/patch-system.sh
fi
EOF
    then
        SUCCESS_HOSTS+=("$host")
        echo "===== Completed $host ====="
    else
        FAILED_HOSTS+=("$host")
        echo "===== FAILED $host ====="
    fi

done < "$HOST_FILE"

echo

echo "Deployment summary:"
echo "  Successful hosts: ${#SUCCESS_HOSTS[@]}"
for host in "${SUCCESS_HOSTS[@]}"; do
    echo "    [OK]   $host"
done

echo "  Failed hosts: ${#FAILED_HOSTS[@]}"
for host in "${FAILED_HOSTS[@]}"; do
    echo "    [FAIL] $host"
done

if [[ ${#FAILED_HOSTS[@]} -gt 0 ]]; then
    echo
    echo "One or more hosts failed. Review the errors above."
    exit 1
fi

echo

echo "All hosts processed successfully."
