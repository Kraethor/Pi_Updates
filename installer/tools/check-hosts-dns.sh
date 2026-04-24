#!/bin/bash
set -Eeuo pipefail

# check-hosts-dns.sh
#
# Pre-flight DNS/name-resolution checker for installer host files.
#
# This script validates that every host listed in a host file resolves to an
# IPv4 address before running installer/install-to-pis.sh. It is intentionally
# IPv4-first because the Raspberry Pi lab network uses IPv4 addressing and some
# systems may have incomplete or broken IPv6 connectivity.
#
# Host file format:
#   - One host or SSH target per line
#   - Blank lines are ignored
#   - Lines beginning with # are ignored
#   - user@host entries are supported; only the host portion is resolved
#
# Example hosts.txt:
#   # Raspberry Pi hosts
#   pi01
#   pi@pi02
#   192.168.169.103
#
# Exit codes:
#   0 = all hosts resolved successfully
#   1 = one or more hosts failed resolution
#
# Usage:
#   ./check-hosts-dns.sh hosts.txt

# First argument is the host file to check.
# ${1:-} avoids an unset-variable error when set -u is enabled.
HOST_FILE="${1:-}"

# Require a host file argument.
if [[ -z "$HOST_FILE" ]]; then
    echo "Usage: $0 hosts.txt"
    exit 1
fi

# Validate that the provided host file exists before processing it.
if [[ ! -f "$HOST_FILE" ]]; then
    echo "ERROR: File not found: $HOST_FILE"
    exit 1
fi

echo "Checking DNS resolution for hosts in $HOST_FILE..."
echo

# Track whether any host fails resolution.
# The script checks all hosts before exiting so the full failure list is visible.
FAIL=0

# Read the host file line by line.
# The '|| [[ -n "$line" ]]' clause ensures the final line is processed even if
# the file does not end with a trailing newline.
while IFS= read -r line || [[ -n "$line" ]]; do
    # Skip blank lines.
    [[ -z "$line" ]] && continue

    # Skip comments, including comments with leading whitespace.
    [[ "$line" =~ ^[[:space:]]*# ]] && continue

    # Keep the original target for display.
    # This may be a hostname, IP address, or user@host SSH target.
    target="$line"

    # Strip user@ if present so only the hostname is passed to getent.
    # Example: pi@pi02 becomes pi02.
    host="${target##*@}"

    # Resolve using the system's normal resolver stack, but request IPv4 only.
    # getent ahostsv4 respects /etc/hosts, DNS, mDNS/NSS configuration, etc.
    # awk prints the first address column and head selects the first result.
    ip="$(getent ahostsv4 "$host" | awk '{print $1}' | head -n1 || true)"

    # Treat lack of IPv4 resolution as a failure.
    # This avoids false positives from broken IPv6-only responses such as ::.
    if [[ -z "$ip" ]]; then
        echo "[FAIL] $target (no IPv4 resolution)"
        FAIL=1
        continue
    fi

    echo "[OK]   $target → $ip"

done < "$HOST_FILE"

echo

# Return a non-zero exit code if any host failed.
# This makes the script useful in simple automation or pre-flight checks.
if [[ $FAIL -eq 0 ]]; then
    echo "All hosts resolved successfully."
else
    echo "One or more hosts failed DNS resolution."
    exit 1
fi
