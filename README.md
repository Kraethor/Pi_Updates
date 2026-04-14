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
apt full-upgrade -y
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

Fix: Raspberry Pi 4 USB Boot Issues with Vantec CB-STU3-2PB (JMicron JMS578)

Thanks to:  https://winraid.level1techs.com/t/jms578-usb-to-sata-firmware-update-remove-uasp-and-enables-trim/98621
Use the JMS578 Update.zip file.

The jmicron 578 has problems to work reliably with uasp and trim at the same time .
The problem is bigger when it is used on fl1100 fresco logic host usb 3.0 controller on windows 10-11.
I have found a firmware that it is used on adata hm800 enclosure that works reliably.
1)It disables uasp.
2)It supports trim for ssd(and manual trim from windows manager)
3)it enables power saving on controller, the controller deactivates after some time without creation of problems with the function of the ssd or hdd(this is invisible to pc so, no connection and disconnection of usb device).

Steps for the update:
1)Connect the enclosure to your pc with an hdd-sdd inside it.
2)Open the Firmware update and check that your drive shows up.
3)Tick the RD Version.
4)Tick the option Erase All Flash Only.
5) Click Run, a popup will prompt you to power cycle the drive. click ok.
6) Remove the power from the hard drive enclosure.
7) Connect the power again ,and wait the 10 sec.
8) Untick the option at the bottom to Erase all of the flash.
9) Select the hm800 firmware using the Load File button.
10)Make sure that the Include JMS577 NVRAM option is ticked.
11)Click Run again and after successful update remove the power again.
12) Close the firmware update program.

---

## 📄 License

MIT License – do as you wish, just don't blame us if your Pi rebels. 😄
