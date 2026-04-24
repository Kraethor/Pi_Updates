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
sudo curl -fsSL \
  https://raw.githubusercontent.com/Kraethor/Pi_Updates/main/inventory/pi-inventory.sh \
  -o /usr/local/bin/pi-inventory.sh

sudo chmod 755 /usr/local/bin/pi-inventory.sh
```

## Usage

```bash
pi-inventory.sh
```
