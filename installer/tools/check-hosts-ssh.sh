#!/bin/bash
set -Eeuo pipefail

# check-hosts-ssh.sh
#
# Validates SSH connectivity for hosts in a host file.
#
# Usage:
#   ./check-hosts-ssh.sh hosts.txt

HOST_FILE="${1:-}"

if [[ -z "$HOST_FILE" ]]; then
    echo "Usage: $0 hosts.txt"
    exit 1
fi

if [[ ! -f "$HOST_FILE" ]]; then
    echo "ERROR: File not found: $HOST_FILE"
    exit 1
fi

echo "Checking SSH connectivity for hosts in $HOST_FILE..."
echo

FAIL=0

while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "$line" ]] && continue
    [[ "$line" =~ ^[[:space:]]*# ]] && continue

    target="$line"
    host="${target##*@}"

    ip="$(getent ahostsv4 "$host" | awk '{print $1}' | head -n1 || true)"

    if [[ -z "$ip" ]]; then
        echo "[FAIL] $target (no IPv4 resolution)"
        FAIL=1
        continue
    fi

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
