# Raspberry Pi Inventory & Patching Scripts

This repository contains two lightweight Bash scripts designed for Raspberry Pi systems:

- 📋 `pi-inventory.sh`: Collects and displays key system information.
- 🔧 `patch-system.sh`: Performs regular system patching via `apt`.

---

## 📋 Inventory Script (`pi-inventory.sh`)

This script gathers important system information including:

- Hostname  
- Pi Model  
- CPU model  
- RAM  
- OS Version  
- Kernel Version  
- Architecture  
- Storage Devices  
- IP Addresses  

### Example Output

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

### Usage

Save the following as `pi-inventory.sh` and make it executable:

```bash
#!/bin/bash

echo "=== Raspberry Pi Inventory ==="
echo "Hostname: $(hostname)"
echo "Model: $(tr -d '\0' < /proc/device-tree/model)"
echo "CPU: $(lscpu | grep 'Model name' | awk -F: '{print $2}' | xargs)"
echo "RAM: $(free -h | awk '/Mem:/ { print $2 }')"
echo "OS: $(lsb_release -ds 2>/dev/null || grep PRETTY_NAME /etc/os-release | cut -d= -f2 | tr -d '"')"
echo "Kernel: $(uname -r)"
echo "Architecture: $(uname -m)"
echo "Storage Devices:"
lsblk -o NAME,SIZE,TYPE,MOUNTPOINT | grep -E 'disk|part'
echo "IP Addresses:"
hostname -I
```

Make it executable:

```bash
chmod +x pi-inventory.sh
```

---

## 🔧 Automated Patching Script (`patch-system.sh`)

This script updates the system weekly and performs common cleanup tasks.

### Script Contents

```bash
#!/bin/bash
apt update
apt upgrade -y
apt autoremove -y
apt autoclean -y
```

### Installation

1. Save the script:

   ```bash
   sudo nano /usr/local/bin/patch-system.sh
   ```

2. Paste the contents and save.
3. Make it executable:

   ```bash
   sudo chmod +x /usr/local/bin/patch-system.sh
   ```

4. Add a weekly cron job (runs every Friday at 3:15 AM):

   ```bash
   sudo crontab -e
   ```

   Then add:

   ```cron
   15 3 * * 5 /usr/local/bin/patch-system.sh
   ```

---

## 💬 Notes

- These scripts are designed to be simple, portable, and run on vanilla Raspberry Pi OS or Debian-based systems.
- If you're running these on systems other than a Raspberry Pi, some output (e.g., model detection) may vary.

---

## 📄 License

MIT License – do as you wish, just don't blame us if your Pi rebels. 😄
