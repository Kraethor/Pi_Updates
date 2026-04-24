#!/bin/bash
set -e
set -o pipefail

# Ensure predictable environment for cron
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export DEBIAN_FRONTEND=noninteractive

# Log failure if anything breaks
trap 'echo "===== $(date "+%Y-%m-%d %H:%M:%S %Z") FAILED patch-system ====="' ERR

echo "===== $(date "+%Y-%m-%d %H:%M:%S %Z") START patch-system ====="

# Update and upgrade system
apt-get update
apt-get -y full-upgrade

# Cleanup
apt-get -y autoremove
apt-get -y autoclean

echo "===== $(date "+%Y-%m-%d %H:%M:%S %Z") END patch-system SUCCESS ====="
