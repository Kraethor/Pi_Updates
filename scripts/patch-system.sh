#!/bin/bash
set -Eeuo pipefail

# Ensure predictable environment for cron
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export DEBIAN_FRONTEND=noninteractive

# Consistent timestamp format for log entries
LOG_STAMP() {
    date "+%Y-%m-%d %H:%M:%S %Z"
}

# Log failure if anything breaks
# Includes return code and line number so cron failures are not silent
trap 'rc=$?; echo "===== $(LOG_STAMP) FAILED patch-system rc=${rc} line=${LINENO} ====="; exit "$rc"' ERR

# This script must run as root because apt-get and system cleanup require it
if [[ $EUID -ne 0 ]]; then
    echo "ERROR: patch-system.sh must be run as root"
    exit 1
fi

echo "===== $(LOG_STAMP) START patch-system ====="

# Update available package metadata
apt-get update

# Upgrade installed packages
# NOTE: full-upgrade may install new packages or remove existing packages if needed
apt-get -y full-upgrade

# Remove packages that were automatically installed and are no longer required
apt-get -y autoremove

# Remove old downloaded package files from the local apt cache
apt-get -y autoclean

echo "===== $(LOG_STAMP) END patch-system SUCCESS ====="
