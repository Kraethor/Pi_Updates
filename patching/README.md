# Patching Module

Automates system updates using apt.

## Install

```bash
sudo curl -fsSL https://raw.githubusercontent.com/Kraethor/Pi_Updates/main/patching/patch-system.sh -o /usr/local/bin/patch-system.sh
sudo chmod 755 /usr/local/bin/patch-system.sh
```

## Cron

```bash
sudo curl -fsSL https://raw.githubusercontent.com/Kraethor/Pi_Updates/main/patching/cron/patch-system.cron -o /etc/cron.d/patch-system
```

## Logrotate

```bash
sudo curl -fsSL https://raw.githubusercontent.com/Kraethor/Pi_Updates/main/patching/logrotate/patch-system -o /etc/logrotate.d/patch-system
```

## Notes

Uses apt-get full-upgrade which may install/remove packages.
