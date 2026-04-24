# Firmware

Hardware-specific fixes and firmware updates for Raspberry Pi environments.

---

## JMS578 USB-SATA Firmware Fix

### Reference

Guide used:
https://winraid.level1techs.com/t/jms578-usb-to-sata-firmware-update-remove-uasp-and-enables-trim/98621

Firmware package:

`JMS578 Update.zip`

(Currently located at the repository root — recommended to move under this directory.)

---

## Background

The JMicron JMS578 controller has known issues when running **UASP and TRIM simultaneously**, which can cause instability.

This is especially noticeable on:

- Raspberry Pi systems
- Certain USB-to-SATA adapters and enclosures

### Common Symptoms

- Boot failures from USB
- `mmc1` controller errors
- Intermittent disconnect/reconnect behavior
- General storage instability under load

---

## What This Firmware Fix Does

The firmware used in this fix (from ADATA HM800):

1. Disables UASP
2. Enables TRIM support for SSDs
3. Enables controller power saving without instability

---

## Firmware Update Steps

1. Connect the enclosure to your system with a drive installed
2. Open the firmware update tool and confirm the device is detected
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

## Result

After applying this firmware:

- Raspberry Pi boots reliably from USB
- No `mmc1` controller errors
- Storage remains stable under load

---

## Notes

- A drive must be installed in the enclosure during the update
- Firmware is not vendor-provided (use at your own risk)
- This fix prioritizes compatibility over maximum performance (UASP is disabled)

---

## Recommendation

Only apply this firmware if you are experiencing issues.

If your enclosure is already stable:

👉 Do not change firmware unnecessarily

---

## Future Use

This directory is intended for additional firmware fixes and hardware-specific workarounds.
