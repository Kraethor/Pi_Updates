# RaspyJack – AWUS036ACH (RTL8812AU) Driver Setup

Getting the Alfa AWUS036ACH working with monitor mode on a Raspberry Pi Zero 2W running Debian Trixie (kernel 6.12).

The default out-of-tree `8812au` driver does not support monitor mode on kernel 6.12. The solution is to use the newer `rtw88` backport driver instead.

---

## Hardware

- Raspberry Pi Zero 2W
- Waveshare 1.3" 240x240 LCD HAT (or 1.44" 128x128)
- Waveshare Ethernet/USB HUB HAT
- SR01 USB GPS Module
- Alfa AWUS036ACH (RTL8812AU chipset)

## OS / Kernel

- Debian Trixie Lite (64-bit)
- Kernel: `6.12.75+rpt-rpi-v8`

---

## Installation

### 1. Install prerequisites

```bash
sudo apt install -y dkms git build-essential bc
```

### 2. Install the rtw88 backport driver

```bash
git clone https://github.com/lwfinger/rtw88.git
cd rtw88
sudo make
sudo make install
```

### 3. Blacklist the old out-of-tree driver

```bash
echo "blacklist 8812au" | sudo tee /etc/modprobe.d/blacklist-8812au.conf
```

### 4. Create a udev rule to load the correct driver on plug-in

```bash
sudo tee /etc/udev/rules.d/99-rtw88-8812au.rules << 'EOF'
ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="0bda", ATTRS{idProduct}=="8812", RUN+="/sbin/modprobe rtw_8812au"
EOF
sudo udevadm control --reload-rules
sudo reboot
```

---

## Verification

After reboot, confirm the driver loaded correctly:

```bash
dmesg | grep -i "8812\|rtw" | tail -20
```

Expected output should include:
```
rtw_core: loading out-of-tree module taints kernel.
rtw_8812au 1-1.3:1.0: Firmware version 52.14.0, H2C version 0
usbcore: registered new interface driver rtw_8812au
```

Confirm monitor mode is available:

```bash
iw phy phy1 info | grep -A 10 "Supported interface modes"
```

Expected output should include `monitor` in the list:
```
Supported interface modes:
         * IBSS
         * managed
         * AP
         * AP/VLAN
         * monitor
         * P2P-client
         * P2P-GO
```

---

## Cleanup

Remove leftover source directories and any old DKMS entries:

```bash
cd ~
rm -rf rtw88

sudo dkms status
# If any old 8812au entries appear, remove them:
sudo dkms remove rtl8812au/<version> --all
sudo rm -rf /usr/src/rtl8812au-<version>
```

---

## Notes

- The `rtw_8812au` module is part of the `rtw88` driver family, which is the modern in-kernel replacement for the old out-of-tree Realtek drivers.
- As of kernel 6.14+, the RTL8812AU is fully supported in-kernel with no extra steps needed. If/when the Pi Foundation ships a 6.14 kernel for Trixie, this setup can be removed and the adapter will work plug and play.
- The AWUS036ACH supports both 2.4GHz and 5GHz, making it the better choice for wardriving with WDGWars.
