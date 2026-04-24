# Installer Module

Deploys and updates Pi_Updates components across multiple Raspberry Pis over SSH.

This tool is designed for simple, repeatable fleet management without requiring full configuration management tools.

---

## What It Does

For each host, the installer:

- Connects via SSH
- Downloads the latest files directly from GitHub using `curl`
- Installs them with correct permissions
- Optionally installs the APT IPv4 workaround
- Optionally runs patching immediately

Installed components:

- `/usr/local/bin/pi-inventory.sh`
- `/usr/local/bin/patch-system.sh`
- `/etc/cron.d/patch-system`
- `/etc/logrotate.d/patch-system`
- `/etc/apt/apt.conf.d/99force-ipv4` (optional)

---

## Requirements

### On the system running the installer

- `bash`
- `ssh`

### On each Raspberry Pi

- `curl`
- `sudo` privileges
- Network access to GitHub

---

## Host File Format

The installer reads a list of hosts from a file.

Example:

```text
# Raspberry Pi hosts
pi-01
pi-02
pi@pi-03
192.168.0.104
```

Rules:

- One host per line
- Blank lines are ignored
- Lines starting with `#` are ignored

---

## Usage

Basic install:

```bash
./install-to-pis.sh hosts.txt
```

Remote install:

```bash
curl -fsSL https://raw.githubusercontent.com/Kraethor/Pi_Updates/main/installer/install-to-pis.sh | bash -s -- hosts.txt
```

---

## Options

### Run patching immediately after install

```bash
./install-to-pis.sh --run-now hosts.txt
```

---

### Install IPv4 workaround for APT

```bash
./install-to-pis.sh --install-ipv4-workaround hosts.txt
```

---

### Deploy from a different branch

```bash
./install-to-pis.sh --branch dev hosts.txt
```

---

## Behavior Notes

- The installer pulls files directly from GitHub (no local repo required)
- Each host is processed sequentially for easier troubleshooting
- Failures stop processing for that host but do not halt the entire run
- Script uses `set -Eeuo pipefail` to avoid silent failures

---

## Example Workflow

```bash
# Update all lab Pis
./install-to-pis.sh hosts.txt

# Push updates and patch immediately
./install-to-pis.sh --run-now hosts.txt
```

---

## Troubleshooting

### SSH issues

Ensure you can connect manually:

```bash
ssh pi-01
```

---

### curl failures on target

Check network connectivity and DNS:

```bash
ping github.com
```

---

### Permission errors

Ensure the remote user has sudo access.

---

## Design Philosophy

This installer is intentionally:

- Simple
- Transparent
- Easy to debug

It is not meant to replace tools like Ansible, but to provide a lightweight solution for small environments.
