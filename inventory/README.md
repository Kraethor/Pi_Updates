# Inventory Module

Collects key system information from a Raspberry Pi or Debian-based system.

## What It Does

This script gathers:

- Hostname
- Raspberry Pi Model
- CPU model
- RAM
- Operating System version
- Kernel version
- Architecture
- Storage devices
- IP addresses

## Example Output

```
=== Raspberry Pi Inventory ===
Hostname: rpi-node
Model: Raspberry Pi 4 Model B Rev 1.4
CPU: ARM Cortex-A72 rev 3
RAM: 3.8G
OS: Debian GNU/Linux 12 (bookworm)
Kernel: 6.1.0-rpi4-rpi-v8
Architecture: aarch64
Storage Devices:
sda      238.5G disk
├─sda1    256M part /boot
└─sda2  238.2G part /
IP Addresses:
192.168.1.100
```

## Installation

```bash
sudo curl -4 -fsSL \
  https://raw.githubusercontent.com/Kraethor/Pi_Updates/main/inventory/pi-inventory.sh \
  -o /usr/local/bin/pi-inventory.sh

sudo chmod 755 /usr/local/bin/pi-inventory.sh
```

## Usage

```bash
pi-inventory.sh
```

---

## 🔄 Parallel Inventory Runner (`run-pi-inventory.sh`)

This helper script runs `pi-inventory.sh` across multiple hosts in parallel and aggregates the output into a single file.

### What It Does

- Connects to each host in a hosts file via SSH
- Executes `/usr/local/bin/pi-inventory.sh`
- Runs multiple hosts in parallel (configurable)
- Collects output into a single, clean report file

### Requirements

- SSH key-based access to all target hosts
- `pi-inventory.sh` installed on each host (via installer)

### Usage

```bash
./run-pi-inventory.sh hosts.txt
```

### Optional Environment Variables

```bash
PARALLEL=10 OUTFILE=lab-inventory.txt ./run-pi-inventory.sh hosts.txt
```

- `PARALLEL` — number of concurrent SSH jobs (default: 5)
- `OUTFILE` — output file name (default: inventory.txt)

### Output Example

```
Raspberry Pi Inventory Run
Generated: Fri Apr 24 18:00:00 UTC 2026
======================================

===== pi01 =====
REMOTE_HOST: pi01
=== Raspberry Pi Inventory ===
...

===== pi02 =====
REMOTE_HOST: pi02
=== Raspberry Pi Inventory ===
...
```

### Notes

- Output is grouped per host to avoid interleaving
- Temporary files are used during execution and cleaned up automatically
- Failed hosts will include error messages in their section
