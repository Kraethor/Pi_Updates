#!/usr/bin/env bash

set -euo pipefail

# run-pi-inventory.sh
#
# Executes /usr/local/bin/pi-inventory.sh across multiple hosts in parallel
# and aggregates the output into a single file.
#
# Usage:
#   ./run-pi-inventory.sh [hosts.txt]
#
# Environment variables:
#   PARALLEL - number of concurrent SSH jobs (default: 5)
#   OUTFILE  - output file (default: inventory.txt)

HOSTS_FILE="${1:-hosts.txt}"
SCRIPT="/usr/local/bin/pi-inventory.sh"
PARALLEL="${PARALLEL:-5}"
OUTFILE="${OUTFILE:-inventory.txt}"
TMPDIR="$(mktemp -d)"

cleanup() {
    rm -rf "$TMPDIR"
}
trap cleanup EXIT

if [[ ! -f "$HOSTS_FILE" ]]; then
    echo "ERROR: Hosts file not found: $HOSTS_FILE"
    exit 1
fi

run_inventory() {
    TARGET="$1"

    # Skip comments / blanks
    [[ -z "$TARGET" || "$TARGET" =~ ^[[:space:]]*# ]] && exit 0

    TARGET="$(echo "$TARGET" | xargs)"

    HOST="${TARGET#*@}"
    SAFE_HOST="$(echo "$HOST" | tr -c 'A-Za-z0-9._-' '_')"

    {
        echo "===== $TARGET ====="

        # Show where we actually landed (debug sanity)
        ssh -o BatchMode=yes \
            -o ConnectTimeout=5 \
            -o StrictHostKeyChecking=accept-new \
            "$TARGET" 'echo "REMOTE_HOST: $(hostname)"'

        # Run inventory
        ssh -o BatchMode=yes \
            -o ConnectTimeout=5 \
            -o StrictHostKeyChecking=accept-new \
            "$TARGET" "$SCRIPT"

        STATUS=$?
        if [[ $STATUS -ne 0 ]]; then
            echo "[ERROR] $TARGET failed (exit $STATUS)"
        fi

        echo ""
    } > "$TMPDIR/$SAFE_HOST.out" 2>&1
}

export -f run_inventory
export SCRIPT TMPDIR

echo "Running pi-inventory across hosts..."
echo "Hosts file: $HOSTS_FILE"
echo "Output file: $OUTFILE"
echo "Parallel jobs: $PARALLEL"
echo "--------------------------------------"

grep -v '^[[:space:]]*$' "$HOSTS_FILE" | \
grep -v '^[[:space:]]*#' | \
xargs -I{} -P "$PARALLEL" bash -c 'run_inventory "$@"' _ {}

# Build final output
{
    echo "Raspberry Pi Inventory Run"
    echo "Generated: $(date)"
    echo "======================================"
    echo ""

    for file in $(find "$TMPDIR" -type f -name '*.out' | sort); do
        cat "$file"
    done
} > "$OUTFILE"

echo "Inventory written to: $OUTFILE"