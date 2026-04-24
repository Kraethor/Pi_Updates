# Raspberry Pi Inventory & Patching Scripts

This repository contains a collection of lightweight tools and notes for maintaining Raspberry Pi systems:

- 📋 `pi-inventory.sh`: Collects and displays key system information  
- 🔧 `patch-system.sh`: Performs automated system patching via `apt-get`  
    - ⚙️ Supporting configurations for patching:
      - Cron scheduling  
      - Log rotation  
      - APT IPv4 workaround  
- 🔧 Hardware notes:
  - Raspberry Pi 4 USB boot fix (JMicron JMS578 firmware)

## 📁 Repository Structure

- `scripts/` — Bash scripts  
- `cron/` — Cron job examples  
- `logrotate/` — Log rotation configs  
- `apt/` — APT configuration snippets

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

1. Copy the `/scripts/pi-inventory.sh` script to `/usr/local/bin/pi-inventory.sh`

2. Make it executable:

```bash
chmod +x /usr/local/bin/pi-inventory.sh
```

---

## 🔧 Automated Patching Script (`patch-system.sh`)

This script `/scripts/patch-system.sh` updates the system weekly and performs common cleanup tasks.

---

### Installation

1. Copy the `/scripts/patch-system.sh` script to `/usr/local/bin/patch-system.sh`

2. Make it executable:

```bash
sudo chmod +x /usr/local/bin/patch-system.sh
```

---

### ⏰ Schedule with Cron

Add a weekly cron job (runs every Friday at 3:15 AM):

```bash
sudo crontab -e
```

Then add:

```cron
15 3 * * 5 /usr/local/bin/patch-system.sh >> /var/log/patch-system.log 2>&1
```

---

### 🧾 Log Rotation

Create a logrotate configuration:

```bash
sudo nano /etc/logrotate.d/patch-system
```

Then add:

```bash
/var/log/patch-system.log {
 weekly
 rotate 8
 compress
 missingok
 notifempty
 create 640 root adm
}
```

---

### 🌐 Optional: Force IPv4 for APT

If your system has broken or incomplete IPv6 connectivity, APT may fail to download packages.

To force IPv4:

```bash
sudo nano /etc/apt/apt.conf.d/99force-ipv4
```

Add:

```bash
Acquire::ForceIPv4 "true";
```

---

## 💬 Notes

- These scripts are designed to be simple, portable, and run on Raspberry Pi OS or Debian-based systems.  
- The patch script is safe for unattended execution via cron.  
- Logs are written to `/var/log/patch-system.log`.  
- The script will stop immediately on failure and log the error.  

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
