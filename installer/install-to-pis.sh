#!/bin/bash
set -Eeuo pipefail

RUN_NOW=false
INSTALL_IPV4=false
BRANCH="main"
REPO_RAW_BASE="https://raw.githubusercontent.com/Kraethor/Pi_Updates"

usage() {
    echo "Usage: $0 [--run-now] [--install-ipv4-workaround] [--branch BRANCH] hosts.txt"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --run-now) RUN_NOW=true; shift ;;
        --install-ipv4-workaround) INSTALL_IPV4=true; shift ;;
        --branch) BRANCH="$2"; shift 2 ;;
        *) HOST_FILE="$1"; shift ;;
    esac
done

[[ -z "${HOST_FILE:-}" ]] && usage && exit 1
[[ ! -f "$HOST_FILE" ]] && echo "Host file not found" && exit 1

RAW_BASE="${REPO_RAW_BASE}/${BRANCH}"

while IFS= read -r host || [[ -n "$host" ]]; do
    [[ -z "$host" ]] && continue
    [[ "$host" =~ ^# ]] && continue

    echo "Deploying to $host"

    ssh "$host" "RAW_BASE='$RAW_BASE' INSTALL_IPV4='$INSTALL_IPV4' RUN_NOW='$RUN_NOW' bash -s" << 'EOF'
set -Eeuo pipefail

install_file() {
    local src="$1" dst="$2" mode="$3"
    tmp=$(mktemp)
    curl -fsSL "$RAW_BASE/$src" -o "$tmp"
    sudo install -m "$mode" "$tmp" "$dst"
    rm -f "$tmp"
}

install_file "inventory/pi-inventory.sh" "/usr/local/bin/pi-inventory.sh" 755
install_file "patching/patch-system.sh" "/usr/local/bin/patch-system.sh" 755
install_file "patching/cron/patch-system.cron" "/etc/cron.d/patch-system" 644
install_file "patching/logrotate/patch-system" "/etc/logrotate.d/patch-system" 644

if [[ "$INSTALL_IPV4" == "true" ]]; then
    install_file "patching/apt/99force-ipv4" "/etc/apt/apt.conf.d/99force-ipv4" 644
fi

if [[ "$RUN_NOW" == "true" ]]; then
    sudo /usr/local/bin/patch-system.sh
fi
EOF

done < "$HOST_FILE"
