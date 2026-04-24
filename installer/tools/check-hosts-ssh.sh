#!/bin/bash
set -Eeuo pipefail

# check-hosts-ssh.sh
#
# Pre-flight SSH connectivity checker for installer host files.
#
# This script validates that every host listed in a host file:
#   1. Resolves to an IPv4 address
#   2. Accepts non-interactive SSH connections
#
# It is intended to be run before installer/install-to-pis.sh to prevent
# partial deployments due to unreachable hosts or SSH configuration issues.
#
# Host file format:
#   - One SSH target per line
#   - Blank lines are ignored
#   - Lines beginning with # are ignored
#   - user@host entries are supported and passed directly to ssh
#
# Example hosts.txt:
#   pi-01
#   pi@pi-02
#   192.168.0.103
#
# Exit codes:
#   0 = all hosts reachable via SSH
#   1 = one or more hosts failed DNS or SSH checks
#
# Usage:
#   ./check-hosts-ssh.sh hosts.txt

HOST_FILE="${1:-}"

# Require a host file argument.
if [[ -z "$HOST_FILE" ]]; then
    echo "Usage: $0 hosts.txt"
    exit 1
fi

# Ensure the host file exists before processing.
if [[ ! -f "$HOST_FILE" ]]; then
    echo "ERROR: File not found: $HOST_FILE"
    exit 1
fi

echo "Checking SSH connectivity for hosts in $HOST_FILE..."
echo

FAIL=0

# Process hosts sequentially so failures are easy to identify.
while IFS= read -r line || [[ -n "$line" ]]; do
    # Skip blank lines.
    [[ -z "$line" ]] && continue

    # Skip comments, including comments with leading whitespace.
    [[ "$line" =~ ^[[:space:]]*# ]] && continue

    # The SSH target as provided (e.g., pi02 or pi@pi02).
    target="$line"

    # Extract hostname for resolution checks and display.
    host="${target##*@}"

    # Resolve IPv4 address using the system resolver stack.
    ip="$(getent ahostsv4 "$host" | awk '{print $1}' | head -n1 || true)"

    if [[ -z "$ip" ]]; then
        echo "[FAIL] $target (no IPv4 resolution)"
        FAIL=1
        continue
    fi

    # Test SSH connectivity.
    #
    # timeout 5:
    #   Prevents the script from hanging on unreachable hosts.
    #
    # ssh -n:
    #   Prevents SSH from reading from stdin, which would otherwise consume
    #   the hosts file input in this while loop.
    #
    # BatchMode=yes:
    #   Disables password prompts. Fails immediately if key-based auth is not set.
    #
    # ConnectTimeout=3:
    #   Limits how long SSH waits to establish a connection.
    #
    # StrictHostKeyChecking=accept-new:
    #   Automatically accepts new host keys (safe for lab environments).
    #
    # exit:
    #   Runs a no-op command and disconnects immediately.
    if timeout 5 ssh -n \
        -o BatchMode=yes \
        -o ConnectTimeout=3 \
        -o StrictHostKeyChecking=accept-new \
        "$target" exit >/dev/null 2>&1; then

        echo "[OK]   $target → $ip (SSH reachable)"
    else
        echo "[FAIL] $target → $ip (SSH failed)"
        FAIL=1
    fi

done < "$HOST_FILE"

echo

if [[ $FAIL -eq 0 ]]; then
    echo "All hosts are reachable via SSH."
else
    echo "One or more hosts failed SSH connectivity."
    exit 1
fi
