#!/bin/bash
set -Eeuo pipefail

# check-hosts-dns.sh
#
# Validates DNS/name resolution for every host listed in a hosts file.
#
# Usage:
#   ./check-hosts-dns.sh hosts.txt

HOST_FILE="${1:-}"

if [[ -z "$HOST_FILE" ]]; then
    echo "Usage: $0 hosts.txt"
    exit 1
fi

if [[ ! -f "$HOST_FILE" ]]; then
    echo "ERROR: File not found: $HOST_FILE"
    exit 1
fi

echo "Checking DNS resolution for hosts in $HOST_FILE..."
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

    echo "[OK]   $target → $ip"

done < "$HOST_FILE"

echo

if [[ $FAIL -eq 0 ]]; then
    echo "All hosts resolved successfully."
else
    echo "One or more hosts failed DNS resolution."
    exit 1
fi
