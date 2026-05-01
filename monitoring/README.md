# System Health Monitor (Bash + Cron + Discord)

Lightweight Linux system health monitoring script for homelab and server use.

## Features
- CPU load (normalized per core)
- CPU utilization %
- Memory, disk, IO wait, swap monitoring
- Clean structured logging (no noise)
- Discord webhook alerts
- Heartbeat logging
- Boot detection
- Cron-friendly
- Logrotate compatible

---

## Script Location
/usr/local/bin/system-health.sh

---

## Script Overview

The script monitors system health and only logs or alerts when thresholds are exceeded.

It also:
- Logs a heartbeat every 15 minutes
- Tracks last execution time
- Sends alerts to Discord

---

## Installation

### 1. Copy Script
sudo cp system-health.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/system-health.sh

### 2. Install Dependencies
sudo apt install -y bc jq

### 3. Create Log File
sudo touch /var/log/system-health.log
sudo chmod 644 /var/log/system-health.log

### 4. Setup Cron
sudo crontab -e

Add:
* * * * * /usr/local/bin/system-health.sh

---

## Log Rotation

Create file:
/etc/logrotate.d/system-health

Contents:
```
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

## Discord Webhook Setup

Replace in script:
WEBHOOK_URL="https://discord.com/api/webhooks/REPLACE_ME"

---

## Logging Behavior

| Condition            | Log | Alert |
|---------------------|-----|------|
| Threshold exceeded  | Yes | Yes  |
| Heartbeat           | Yes | No   |
| Normal operation    | No  | No   |

---

## Key Files

| File | Purpose |
|------|--------|
| /var/log/system-health.log | Event log |
| /var/run/system-health.last | Last run timestamp |
| /var/run/system-health.boot | Boot detection |

---

## Example Output

2026-05-01 09:12:01 | [SER9] ALERT: HIGH CPU LOAD
Load: 17.75 / 16 cores (111%)
CPU Usage: 27.6%

Top Processes:
PID     COMMAND             CPU%
19075   Torch.Server.ex     284
18725   Torch.Server.ex     282
18862   Torch.Server.ex     277

--------------------------------------------------

---

## Testing

Test Webhook:
curl -H "Content-Type: application/json" -X POST -d '{"content": "Test"}' "YOUR_WEBHOOK_URL"

Test Script Run:
sudo /usr/local/bin/system-health.sh
cat /var/run/system-health.last

Force Alert:
sudo sed -i 's/LOAD_PCT_THRESHOLD=80/LOAD_PCT_THRESHOLD=1/' /usr/local/bin/system-health.sh
sudo /usr/local/bin/system-health.sh

Test Heartbeat:
sudo sed -i 's/HEARTBEAT_INTERVAL=15/HEARTBEAT_INTERVAL=1/' /usr/local/bin/system-health.sh
sudo /usr/local/bin/system-health.sh

---

## Notes

- Script must run as root
- /var/run resets on reboot (expected)
- Webhook URL is sensitive
- CPU load != CPU usage

---

## Future Improvements

- Alert cooldown
- Severity levels
- Grafana / Loki integration
- Historical tracking

---

## Summary

Reliable monitoring with clean logs and real-time alerts.
