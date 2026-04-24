#!/usr/bin/env bash

echo "=== Raspberry Pi Inventory ==="
echo "Hostname: $(hostname)"
echo "Model: $(tr -d '\0' < /proc/device-tree/model 2>/dev/null || echo 'Unknown')"
echo "CPU: $(lscpu | grep 'Model name' | awk -F: '{print $2}' | xargs)"
echo "RAM: $(free -h | awk '/Mem:/ { print $2 }')"
echo "OS: $(grep PRETTY_NAME /etc/os-release | cut -d= -f2 | tr -d '"')"
echo "Kernel: $(uname -r)"
echo "Architecture: $(uname -m)"

echo "Storage Devices:"
lsblk -o NAME,SIZE,TYPE,MOUNTPOINT | grep -E 'disk|part'

echo "IP Addresses:"
hostname -I
