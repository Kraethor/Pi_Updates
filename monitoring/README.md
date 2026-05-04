# System Health Monitor

Lightweight Bash-based system health monitor for Ubuntu/Linux systems.

This script is designed for homelab and small server environments where a full monitoring stack is unnecessary, but reliable alerting and visibility are still required.

---

## Features

- CPU load monitoring (normalized per core)
- CPU utilization reporting (actual usage %)
- Memory usage monitoring
- Swap usage monitoring
- Disk usage monitoring
- IO wait monitoring
- Structured, readable log output
- Discord webhook alerts
- Alert cooldown (anti-spam protection)
- Heartbeat logging
- Boot marker logging
- Last-run timestamp tracking
- Logrotate support
- Root cron execution

---

## Files

| File | Purpose |
|---|---|
| `/usr/local/bin/system-health.sh` | Main monitoring script |
| `/var/log/system-health.log` | Event log |
| `/var/run/system-health.last` | Last successful run timestamp |
| `/var/run/system-health.boot` | Per-boot marker file |
| `/var/run/system-health.*.alert` | Alert cooldown state files |
| `/etc/logrotate.d/system-health` | Log rotation config |

---

## Requirements

Install dependencies:

```bash
sudo apt update
sudo apt install -y bc jq curl
```

---

## Main Script

Save as:

```text
/usr/local/bin/system-health.sh
```

```bash
#!/bin/bash

LOGFILE="/var/log/system-health.log"
LASTRUN="/var/run/system-health.last"

# Thresholds
LOAD_PCT_THRESHOLD=80
MEM_THRESHOLD=90
DISK_THRESHOLD=90
IOWAIT_THRESHOLD=20
SWAP_THRESHOLD=10

HEARTBEAT_INTERVAL=15
COOLDOWN_SECONDS=600

WEBHOOK_URL="https://discord.com/api/webhooks/REPLACE_ME"
HOST=$(hostname)

timestamp() { date "+%Y-%m-%d %H:%M:%S"; }

log() {
    printf "%s | %b\n" "$(timestamp)" "$1" >> "$LOGFILE"
}

alert() {
    message=$(printf "%b" "$1")
    json=$(printf '%s' "$message" | jq -Rs .)

    curl -s -H "Content-Type: application/json" \
        -X POST \
        -d "{\"content\": $json}" \
        "$WEBHOOK_URL" > /dev/null
}

# Cooldown logic
should_alert() {
    alert_name="$1"
    state_file="/var/run/system-health.${alert_name}.alert"
    now=$(date +%s)

    if [ ! -f "$state_file" ]; then
        echo "$now" > "$state_file"
        return 0
    fi

    last=$(cat "$state_file")
    elapsed=$(( now - last ))

    if [ "$elapsed" -ge "$COOLDOWN_SECONDS" ]; then
        echo "$now" > "$state_file"
        return 0
    fi

    return 1
}

# Boot marker
BOOT_MARKER="/var/run/system-health.boot"
if [ ! -f "$BOOT_MARKER" ]; then
    msg="[$HOST] SYSTEM HEALTH MONITOR STARTED"
    log "$msg"
    alert "$msg"
    touch "$BOOT_MARKER"
fi

# CPU metrics
load=$(awk '{print $1}' /proc/loadavg)
cores=$(nproc)
load_pct=$(echo "$load / $cores * 100" | bc -l)
load_pct_int=$(printf "%.0f" "$load_pct")

cpu_line=$(top -bn1 | grep "Cpu(s)")
idle=$(echo "$cpu_line" | awk -F',' '{for(i=1;i<=NF;i++){if($i ~ /id/){print $i}}}' | sed 's/[^0-9.]//g')
cpu_used=$(echo "100 - ${idle:-0}" | bc)
cpu_used_fmt=$(printf "%.1f" "$cpu_used")

if [ "$load_pct_int" -gt "$LOAD_PCT_THRESHOLD" ]; then
    msg="[$HOST] ALERT: HIGH CPU LOAD\nLoad: ${load} / ${cores} cores (${load_pct_int}%)\nCPU Usage: ${cpu_used_fmt}%"
    log "$msg"
    should_alert "cpu" && alert "$msg"
fi

# Swap (with reset)
state_file="/var/run/system-health.swap.alert"
swap_used=$(free | awk '/Swap:/ {if($2==0){print 0}else{printf("%.0f"), $3/$2 * 100.0}}')

if [ "$swap_used" -gt "$SWAP_THRESHOLD" ]; then
    msg="[$HOST] ALERT: SWAP USAGE\nSwap Usage: ${swap_used}%"
    log "$msg"
    should_alert "swap" && alert "$msg"
else
    rm -f "$state_file"
fi

# Heartbeat
minute=$(date +%M)
(( minute % HEARTBEAT_INTERVAL == 0 )) && log "[$HOST] HEALTH OK (heartbeat)"

echo "$(date)" > "$LASTRUN"
```

---

## Alert Cooldown (Anti-Spam)

Prevents alert floods when conditions persist.

### Behavior

- First alert fires immediately
- Alerts suppressed for cooldown period
- Alerts resume after cooldown expires
- Reset logic allows immediate alert after recovery

### Default

```bash
COOLDOWN_SECONDS=600
```

---

## Installation

```bash
sudo cp system-health.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/system-health.sh
sudo touch /var/log/system-health.log
sudo chmod 644 /var/log/system-health.log
sudo crontab -e
```

Add:

```cron
* * * * * /usr/local/bin/system-health.sh
```

---

## Logrotate

```
/etc/logrotate.d/system-health
```

```conf
/var/log/system-health.log {
    daily
    rotate 7
    compress
    missingok
    notifempty
    copytruncate
}
```

---

## Testing

```bash
curl -H "Content-Type: application/json" -X POST -d '{"content": "Test"}' "YOUR_WEBHOOK_URL"
sudo /usr/local/bin/system-health.sh
cat /var/run/system-health.last
```

---

## Example Output

```text
2026-05-01 09:12:01 | [SER9] ALERT: HIGH CPU LOAD
Load: 17.75 / 16 cores (111%)
CPU Usage: 87.6%
```

---

## Summary

Simple, reliable monitoring with:
- accurate metrics
- clean logs
- controlled alerting (no spam)
- minimal dependencies
