#!/bin/bash
set -Eeuo pipefail

# install-to-pis.sh
#
# Deploys Pi_Updates scripts and configs to multiple Raspberry Pis over SSH.
#
# Usage:
#   ./install-to-pis.sh [--run-now] [--install-ipv4-workaround] hosts.txt
#
# Requirements:
#   - SSH access to target hosts
#   - sudo privileges on target hosts
#   - This script must be run from the root of the Pi_Updates repo

RUN_NOW=false
INSTALL_IPV4=false

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
        *)
            HOST_FILE="$1"
            shift
            ;;
    esac
done

if [[ -z "${HOST_FILE:-}" ]]; then
    echo "ERROR: No host file specified"
    exit 1
fi

if [[ ! -f "$HOST_FILE" ]]; then
    echo "ERROR: Host file not found: $HOST_FILE"
    exit 1
fi

# Verify required files exist locally
REQUIRED_FILES=(
    "scripts/pi-inventory.sh"
    "scripts/patch-system.sh"
    "cron/patch-system.cron"
    "logrotate/patch-system"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [[ ! -f "$file" ]]; then
        echo "ERROR: Missing required file: $file"
        exit 1
    fi
done

# Deploy to each host
while read -r host; do
    [[ -z "$host" ]] && continue

    echo "===== Deploying to $host ====="

    scp scripts/pi-inventory.sh "$host:/tmp/pi-inventory.sh"
    scp scripts/patch-system.sh "$host:/tmp/patch-system.sh"
    scp cron/patch-system.cron "$host:/tmp/patch-system.cron"
    scp logrotate/patch-system "$host:/tmp/logrotate-patch-system"

    if $INSTALL_IPV4; then
        scp apt/99force-ipv4 "$host:/tmp/99force-ipv4"
    fi

    ssh "$host" bash << 'EOF'
set -Eeuo pipefail

sudo install -m 755 /tmp/pi-inventory.sh /usr/local/bin/pi-inventory.sh
sudo install -m 755 /tmp/patch-system.sh /usr/local/bin/patch-system.sh
sudo install -m 644 /tmp/patch-system.cron /etc/cron.d/patch-system
sudo install -m 644 /tmp/logrotate-patch-system /etc/logrotate.d/patch-system

if [[ -f /tmp/99force-ipv4 ]]; then
    sudo install -m 644 /tmp/99force-ipv4 /etc/apt/apt.conf.d/99force-ipv4
fi

rm -f /tmp/pi-inventory.sh /tmp/patch-system.sh /tmp/patch-system.cron /tmp/logrotate-patch-system /tmp/99force-ipv4
EOF

    if $RUN_NOW; then
        echo "Running patch-system.sh on $host"
        ssh "$host" "sudo /usr/local/bin/patch-system.sh"
    fi

    echo "===== Completed $host ====="
done < "$HOST_FILE"

echo "All hosts processed."
