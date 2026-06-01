1. Install prerequisites
bashsudo apt install -y dkms git build-essential bc
2. Install the rtw88 backport driver
bashgit clone https://github.com/lwfinger/rtw88.git
cd rtw88
sudo make
sudo make install
3. Blacklist the old out-of-tree driver
bashecho "blacklist 8812au" | sudo tee /etc/modprobe.d/blacklist-8812au.conf
4. Create a udev rule to load the correct driver when the adapter is plugged in
bashsudo tee /etc/udev/rules.d/99-rtw88-8812au.rules << 'EOF'
ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="0bda", ATTRS{idProduct}=="8812", RUN+="/sbin/modprobe rtw_8812au"
EOF
sudo udevadm control --reload-rules
sudo reboot
