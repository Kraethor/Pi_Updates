Ubuntu - Use DHCP DNS Server
	1. Remove symlink for /etc/resolv.conf
Code:
sudo rm -rf /etc/resolv.conf
	2. Create empty file for /etc/resolv.conf
Code:
sudo touch /etc/resolv.conf
	3. Edit NetworkManager configuration file that forces use of dnsmasq so that it actually use default DNS entries, or remove that file all-together if you have "dns=default" set in default NetworkManager.conf
Code:
sudo sed -i 's/^dns.*/dns=default/g' /usr/lib/NetworkManager/conf.d/10-dns-resolved.conf
	4. Stop and disable systemd-resolved
Code:
sudo systemctl stop systemd-resolved && sudo systemctl disable systemd-resolved
	5. Restart NetworkManager
Code:
sudo systemctl restart NetworkManager
