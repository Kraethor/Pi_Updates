# Raspberry Pi Inventory & Patching Scripts

This repository contains a collection of lightweight tools and notes for maintaining Raspberry Pi systems:

- 📋 `pi-inventory.sh`: Collects and displays key system information  
- 🔧 `patch-system.sh`: Performs automated system patching via `apt-get`  
    - ⚙️ Supporting configurations for patching:
      - Cron scheduling  
      - Log rotation  
      - APT IPv4 workaround  
- 🧰 `tools/install-to-pis.sh`: Installs or updates the scripts/configs on multiple Raspberry Pis over SSH
- 🔧 Hardware notes:
  - Raspberry Pi 4 USB boot fix (JMicron JMS578 firmware)

## 📁 Repository Structure

- `scripts/` — Bash scripts  
- `cron/` — Cron job examples  
- `logrotate/` — Log rotation configs  
- `apt/` — APT configuration snippets
- `tools/` — Helper scripts for installing or updating multiple systems

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

### Installation

Install directly from GitHub:

```bash
sudo curl -fsSL \
  https://raw.githubusercontent.com/Kraethor/Pi_Updates/main/scripts/pi-inventory.sh \
  -o /usr/local/bin/pi-inventory.sh

sudo chmod 755 /usr/local/bin/pi-inventory.sh
```

Run it:

```bash
pi-inventory.sh
```

---

## 🔧 Automated Patching Script (`patch-system.sh`)

This script `/scripts/patch-system.sh` updates the system and performs common cleanup tasks.

It is designed to run manually or from cron.

### Installation

Install directly from GitHub:

```bash
sudo curl -fsSL \
  https://raw.githubusercontent.com/Kraethor/Pi_Updates/main/scripts/patch-system.sh \
  -o /usr/local/bin/patch-system.sh

sudo chmod 755 /usr/local/bin/patch-system.sh
```

Test the script manually:

```bash
sudo /usr/local/bin/patch-system.sh
```

---

### ⏰ Schedule with Cron

Install the provided cron file:

```bash
sudo curl -fsSL \
  https://raw.githubusercontent.com/Kraethor/Pi_Updates/main/cron/patch-system.cron \
  -o /etc/cron.d/patch-system

sudo chmod 644 /etc/cron.d/patch-system
```

The included cron job runs every Friday at 03:15 AM and writes output to `/var/log/patch-system.log`.

---

### 🧾 Log Rotation

Install the provided logrotate file:

```bash
sudo curl -fsSL \
  https://raw.githubusercontent.com/Kraethor/Pi_Updates/main/logrotate/patch-system \
  -o /etc/logrotate.d/patch-system

sudo chmod 644 /etc/logrotate.d/patch-system
```

Test the logrotate configuration:

```bash
sudo logrotate -d /etc/logrotate.d/patch-system
```

---

### 🌐 Optional: Force IPv4 for APT

If your system has broken or incomplete IPv6 connectivity, APT may fail to download packages.

Install the optional APT IPv4 workaround:

```bash
sudo curl -fsSL \
  https://raw.githubusercontent.com/Kraethor/Pi_Updates/main/apt/99force-ipv4 \
  -o /etc/apt/apt.conf.d/99force-ipv4

sudo chmod 644 /etc/apt/apt.conf.d/99force-ipv4
```

---

## 🧰 Installing or Updating Multiple Raspberry Pis

Use `tools/install-to-pis.sh` from a local clone of this repository when you want to push the scripts and configs to multiple systems over SSH.

Example host file:

```text
pi01
pi02
pi03
pi04
```

Run the installer:

```bash
git clone https://github.com/Kraethor/Pi_Updates.git
cd Pi_Updates
chmod +x tools/install-to-pis.sh
./tools/install-to-pis.sh hosts.txt
```

By default, the installer deploys:

- `/usr/local/bin/pi-inventory.sh`
- `/usr/local/bin/patch-system.sh`
- `/etc/cron.d/patch-system`
- `/etc/logrotate.d/patch-system`

The optional APT IPv4 workaround is not installed unless requested:

```bash
./tools/install-to-pis.sh --install-ipv4-workaround hosts.txt
```

To install files and immediately run patching on each host:

```bash
./tools/install-to-pis.sh --run-now hosts.txt
```

The installer expects SSH access and sudo rights on each target system.

---

## 💬 Notes

- These scripts are designed to be simple, portable, and run on Raspberry Pi OS or Debian-based systems.  
- The patch script is safe for unattended execution via cron.  
- Logs are written to `/var/log/patch-system.log`.  
- The script will stop immediately on failure and log the error.  
- `patch-system.sh` uses `apt-get full-upgrade`, which may install new packages or remove existing packages if needed to complete an upgrade.

---

## 🔧 Fix: Raspberry Pi 4 USB Boot Issues (Vantec CB-STU3-2PB / JMicron JMS578)

### Reference

Guide used:  
https://winraid.level1techs.com/t/jms578-usb-to-sata-firmware-update-remove-uasp-and-enables-trim/98621  

Firmware package:  
`JMS578 Update.zip`

---

### Background

The JMicron JMS578 controller has known issues with running **UASP and TRIM simultaneously**, which can cause instability.

This is especially noticeable on Raspberry Pi systems and certain USB controllers.

The firmware used in this fix (from ADATA HM800) provides:

1. Disables UASP  
2. Enables TRIM support for SSDs  
3. Enables controller power saving without causing disconnect/reconnect issues  

---

### Steps for Firmware Update

1. Connect the enclosure to your system with an HDD/SSD installed  
2. Open the firmware update tool and confirm the drive is detected  
3. Tick **RD Version**  
4. Tick **Erase All Flash Only**  
5. Click **Run**  
6. When prompted, power cycle the enclosure:  
   - Disconnect power  
   - Reconnect power  
   - Wait ~10 seconds  
7. Untick **Erase All Flash Only**  
8. Load the HM800 firmware using **Load File**  
9. Ensure **Include JMS577 NVRAM** is checked  
10. Click **Run** again to flash the firmware  
11. After completion, power cycle the enclosure again  
12. Close the firmware update tool  

---

### Result

- Raspberry Pi boots reliably from USB  
- No `mmc1` controller errors  
- Storage operates stably under load  

---

### Notes

- A drive must be installed in the enclosure during the update  
- Firmware is not vendor-provided (use at your own risk)  
- This fix effectively disables UASP and improves compatibility  

---

## 📄 License

MIT License – do as you wish, just don't blame us if your Pi rebels. 😄
