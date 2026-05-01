# System Health Monitor

Lightweight Bash-based system health monitor for Ubuntu/Linux systems.

This script is intended for small servers and homelab systems where a full monitoring stack may be unnecessary, but basic health visibility and Discord alerting are useful.

## Features

- CPU load monitoring normalized by core count
- Total CPU utilization reporting
- Memory usage monitoring
- Swap usage monitoring
- Disk usage monitoring
- IO wait monitoring
- Structured log output
- Discord webhook alerts
- Heartbeat logging
- Boot marker logging
- Last-run timestamp tracking
- Logrotate support
- Root cron execution

## Files

| File | Purpose |
|---|---|
| `/usr/local/bin/system-health.sh` | Main monitoring script |
| `/var/log/system-health.log` | Event log |
| `/var/run/system-health.last` | Last successful run timestamp |
| `/var/run/system-health.boot` | Per-boot marker file |
| `/etc/logrotate.d/system-health` | Log rotation config |

## Requirements

Install the required packages:

```bash
sudo apt update
sudo apt install -y bc jq curl
```

The script uses:

| Tool | Purpose |
|---|---|
| `bc` | Floating-point calculations |
| `jq` | Safe JSON encoding for Discord messages |
| `curl` | Sending Discord webhook alerts |
| `top`, `ps`, `free`, `df` | System health data collection |

## Main Script

Save this as:

```text
/usr/local/bin/system-health.sh
```

```bash
#!/bin/bash

#############################################
# System Health Monitor
#
# Purpose:
#   Lightweight system monitoring script that:
#   - Tracks CPU load and utilization
#   - Monitors memory, disk, IO wait, and swap
#   - Logs only meaningful events
#   - Sends alerts via Discord webhook
#
# Execution:
#   Intended to run via root cron every minute.
#
# Outputs:
#   - /var/log/system-health.log
#   - /var/run/system-health.last
#############################################

LOGFILE="/var/log/system-health.log"
LASTRUN="/var/run/system-health.last"

#############################################
# Thresholds
#############################################

LOAD_PCT_THRESHOLD=80      # CPU load as percentage of total capacity
MEM_THRESHOLD=90           # Memory usage percentage
DISK_THRESHOLD=90          # Disk usage percentage
IOWAIT_THRESHOLD=20        # IO wait percentage
SWAP_THRESHOLD=10          # Swap usage percentage

HEARTBEAT_INTERVAL=15      # Minutes between heartbeat log entries

#############################################
# Discord Webhook
#
# Replace this placeholder with your Discord
# webhook URL. Treat this URL like a password.
#############################################

WEBHOOK_URL="https://discord.com/api/webhooks/REPLACE_ME"

#############################################
# Host identification
#############################################

HOST=$(hostname)

#############################################
# Utility Functions
#############################################

timestamp() {
    date "+%Y-%m-%d %H:%M:%S"
}

log() {
    printf "%s | %b\n" "$(timestamp)" "$1" >> "$LOGFILE"
}

alert() {
    message="$1"

    # Convert literal \n sequences into real newlines.
    message=$(printf "%b" "$message")

    # Safely JSON-encode the message for Discord.
    json=$(printf '%s' "$message" | jq -Rs .)

    curl -s -H "Content-Type: application/json" \
        -X POST \
        -d "{\"content\": $json}" \
        "$WEBHOOK_URL" > /dev/null
}

#############################################
# Boot Marker
#
# /var/run is tmpfs and resets on reboot.
# This creates one startup log/alert per boot.
#############################################

BOOT_MARKER="/var/run/system-health.boot"

if [ ! -f "$BOOT_MARKER" ]; then
    msg="[$HOST] SYSTEM HEALTH MONITOR STARTED"
    log "$msg"
    alert "$msg"
    touch "$BOOT_MARKER"
fi

#############################################
# CPU Metrics
#############################################

# Load average represents queue pressure.
load=$(awk '{print $1}' /proc/loadavg)
cores=$(nproc)

if [ "$cores" -gt 0 ]; then
    load_pct=$(echo "$load / $cores * 100" | bc -l)
else
    load_pct=0
fi

load_pct_int=$(printf "%.0f" "$load_pct")

# CPU utilization represents actual CPU usage.
cpu_line=$(top -bn1 | grep "Cpu(s)")

idle=$(echo "$cpu_line" | awk -F',' '{for(i=1;i<=NF;i++){if($i ~ /id/){print $i}}}' | sed 's/[^0-9.]//g')
idle=${idle:-0}

cpu_used=$(echo "100 - $idle" | bc)
cpu_used_fmt=$(printf "%.1f" "$cpu_used")

#############################################
# CPU Alert
#############################################

if [ "$load_pct_int" -gt "$LOAD_PCT_THRESHOLD" ]; then

    top_cpu=$(ps -eo pid,comm,%cpu --sort=-%cpu | head -n 6 | awk '
        NR==1 {printf "%-7s %-18s %s\n", "PID", "COMMAND", "CPU%"; next}
        {printf "%-7s %-18s %s\n", $1, $2, $3}
    ')

    msg="[$HOST] ALERT: HIGH CPU LOAD\n\
Load: ${load} / ${cores} cores (${load_pct_int}%)\n\
CPU Usage: ${cpu_used_fmt}%\n\n\
Top Processes:\n$top_cpu\n\
--------------------------------------------------"

    log "$msg"
    alert "$msg"
fi

#############################################
# IO Wait Monitoring
#############################################

iowait=$(echo "$cpu_line" | awk -F',' '{for(i=1;i<=NF;i++){if($i ~ /wa/){print $i}}}' | sed 's/[^0-9.]//g')
iowait=${iowait:-0}
iowait_int=$(printf "%.0f" "$iowait")

if [ "$iowait_int" -gt "$IOWAIT_THRESHOLD" ]; then
    msg="[$HOST] ALERT: HIGH IO WAIT\n\
IO Wait: ${iowait}%\n\
CPU Snapshot: $cpu_line\n\
--------------------------------------------------"

    log "$msg"
    alert "$msg"
fi

#############################################
# Memory Monitoring
#############################################

mem_used=$(free | awk '/Mem:/ {printf("%.0f"), $3/$2 * 100.0}')

if [ "$mem_used" -gt "$MEM_THRESHOLD" ]; then

    top_mem=$(ps -eo pid,comm,%mem --sort=-%mem | head -n 6 | awk '
        NR==1 {printf "%-7s %-18s %s\n", "PID", "COMMAND", "MEM%"; next}
        {printf "%-7s %-18s %s\n", $1, $2, $3}
    ')

    msg="[$HOST] ALERT: HIGH MEMORY USAGE\n\
Memory Usage: ${mem_used}%\n\n\
Top Processes:\n$top_mem\n\
--------------------------------------------------"

    log "$msg"
    alert "$msg"
fi

#############################################
# Swap Monitoring
#############################################

swap_used=$(free | awk '/Swap:/ {if($2==0){print 0}else{printf("%.0f"), $3/$2 * 100.0}}')

if [ "$swap_used" -gt "$SWAP_THRESHOLD" ]; then
    msg="[$HOST] ALERT: SWAP USAGE\n\
Swap Usage: ${swap_used}%\n\
--------------------------------------------------"

    log "$msg"
    alert "$msg"
fi

#############################################
# Disk Usage Monitoring
#############################################

df -P | awk 'NR>1 {print $5 " " $6}' | while read usage mount; do
    percent=${usage%\%}

    if [ "$percent" -gt "$DISK_THRESHOLD" ]; then
        msg="[$HOST] ALERT: HIGH DISK USAGE\n\
Mount: $mount\n\
Usage: ${percent}%\n\
--------------------------------------------------"

        log "$msg"
        alert "$msg"
    fi
done

#############################################
# Heartbeat
#
# This proves the script is running without
# logging every minute.
#############################################

minute=$(date +%M)

if (( minute % HEARTBEAT_INTERVAL == 0 )); then
    log "[$HOST] HEALTH OK (heartbeat)"
fi

#############################################
# Last Run Timestamp
#
# This updates every run, even when there are
# no log entries or alerts.
#############################################

echo "$(date)" > "$LASTRUN"
```

Make it executable:

```bash
sudo chmod +x /usr/local/bin/system-health.sh
```

## Cron Setup

Edit the root crontab:

```bash
sudo crontab -e
```

Add:

```cron
* * * * * /usr/local/bin/system-health.sh
```

The script should run as root because it writes to `/var/log` and `/var/run`.

## Logrotate Setup

Create:

```text
/etc/logrotate.d/system-health
```

With this content:

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

Validate the configuration:

```bash
sudo logrotate --debug /etc/logrotate.d/system-health
```

Force a rotation test:

```bash
sudo logrotate -f /etc/logrotate.d/system-health
ls -lh /var/log/system-health*
```

## Discord Webhook Setup

Create a Discord webhook in the target channel:

1. Open the Discord channel settings.
2. Go to **Integrations**.
3. Select **Webhooks**.
4. Create a webhook.
5. Copy the webhook URL.
6. Replace the placeholder in the script:

```bash
WEBHOOK_URL="https://discord.com/api/webhooks/REPLACE_ME"
```

Do not commit a real webhook URL to a public repository.

## Testing

### Test the Discord Webhook Directly

```bash
curl -H "Content-Type: application/json" \
    -X POST \
    -d '{"content": "Webhook test from system-health"}' \
    "YOUR_WEBHOOK_URL"
```

Expected result: a message appears in the Discord channel.

### Test the Script Manually

```bash
sudo /usr/local/bin/system-health.sh
```

Check the last-run timestamp:

```bash
cat /var/run/system-health.last
```

The timestamp should update even when no alert or log entry is generated.

### Force a CPU Alert

Temporarily lower the CPU load threshold:

```bash
sudo sed -i 's/LOAD_PCT_THRESHOLD=80/LOAD_PCT_THRESHOLD=1/' /usr/local/bin/system-health.sh
sudo /usr/local/bin/system-health.sh
```

Expected result:

- A CPU alert appears in `/var/log/system-health.log`
- A Discord alert is sent

Restore the threshold:

```bash
sudo sed -i 's/LOAD_PCT_THRESHOLD=1/LOAD_PCT_THRESHOLD=80/' /usr/local/bin/system-health.sh
```

### Force Heartbeat Logging

Temporarily lower the heartbeat interval:

```bash
sudo sed -i 's/HEARTBEAT_INTERVAL=15/HEARTBEAT_INTERVAL=1/' /usr/local/bin/system-health.sh
sudo /usr/local/bin/system-health.sh
tail -n 10 /var/log/system-health.log
```

Restore the interval:

```bash
sudo sed -i 's/HEARTBEAT_INTERVAL=1/HEARTBEAT_INTERVAL=15/' /usr/local/bin/system-health.sh
```

### Verify Cron Execution

Wait at least one minute, then check:

```bash
cat /var/run/system-health.last
```

You can also check cron activity:

```bash
grep system-health /var/log/syslog
```

## Example Log Output

```text
2026-05-01 09:12:01 | [SER9] ALERT: HIGH CPU LOAD
Load: 17.75 / 16 cores (111%)
CPU Usage: 27.6%

Top Processes:
PID     COMMAND             CPU%
19075   Torch.Server.ex     284
18725   Torch.Server.ex     282
18862   Torch.Server.ex     277
18612   MainThrd            164
8362    SCUMServer.exe      52.1
--------------------------------------------------
```

## Behavior Summary

| Condition | Log Entry | Discord Alert |
|---|---:|---:|
| Threshold exceeded | Yes | Yes |
| Heartbeat interval reached | Yes | No |
| Normal operation | No | No |
| Script runs successfully | Updates `.last` file | No |

## Notes

CPU load and CPU usage are intentionally tracked separately.

- CPU load indicates process queue pressure.
- CPU usage indicates actual CPU utilization.
- A system can have high load with low CPU usage if tasks are blocked on IO, locks, or other waits.

The script uses `/var/run`, which is normally a tmpfs filesystem. Files there reset on reboot. That is expected and is used intentionally for boot detection.

## Future Improvements

- Alert cooldown to prevent repeated alerts every minute
- Warning vs critical severity levels
- Optional local-only mode with no Discord alerts
- Grafana/Loki integration
- Historical metric trend logging
