# Patching Module

Automates system updates and cleanup tasks on Raspberry Pi or Debian-based systems.

## What It Does

The patching system:

- Updates package lists (`apt-get update`)
- Upgrades installed packages (`apt-get full-upgrade`)
- Removes unused packages (`autoremove`)
- Cleans package cache (`autoclean`)
- Logs all activity for troubleshooting

## Installation

Install the main script:

```bash
sudo curl -4 -fsSL https://raw.githubusercontent.com/Kraethor/Pi_Updates/main/patching/patch-system.sh -o /usr/local/bin/patch-system.sh
sudo chmod 755 /usr/local/bin/patch-system.sh
```

Test manually:

```bash
sudo /usr/local/bin/patch-system.sh
```

## Cron Scheduling

Install the cron job:

```bash
sudo curl -4 -fsSL https://raw.githubusercontent.com/Kraethor/Pi_Updates/main/patching/cron/patch-system.cron -o /etc/cron.d/patch-system
sudo chmod 644 /etc/cron.d/patch-system
```

Runs every Friday at 03:15 and logs to `/var/log/patch-system.log`.

## Log Rotation

```bash
sudo curl -4 -fsSL https://raw.githubusercontent.com/Kraethor/Pi_Updates/main/patching/logrotate/patch-system -o /etc/logrotate.d/patch-system
sudo chmod 644 /etc/logrotate.d/patch-system
```

Test configuration:

```bash
sudo logrotate -d /etc/logrotate.d/patch-system
```

## Optional: Force IPv4 for APT

```bash
sudo curl -4 -fsSL https://raw.githubusercontent.com/Kraethor/Pi_Updates/main/patching/apt/99force-ipv4 -o /etc/apt/apt.conf.d/99force-ipv4
sudo chmod 644 /etc/apt/apt.conf.d/99force-ipv4
```

## Notes

- Designed for unattended execution via cron
- Logs to `/var/log/patch-system.log`
- Stops immediately on failure and logs the error
- Uses `apt-get full-upgrade`, which may install or remove packages to complete upgrades
