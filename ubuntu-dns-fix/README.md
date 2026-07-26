# Ubuntu DNS Fix

Makes Ubuntu use the DNS servers supplied by DHCP instead of the local `systemd-resolved` stub.

## What It Does

By default Ubuntu symlinks `/etc/resolv.conf` to a `systemd-resolved` stub file pointing at `127.0.0.53`,
and NetworkManager is configured to hand DNS off to `systemd-resolved`. This breaks setups that rely on
the DNS server advertised by DHCP — local zones, split-horizon records, and network-wide filtering all
resolve inconsistently or not at all.

These steps:

- Replace the `resolv.conf` symlink with a real file NetworkManager can write
- Tell NetworkManager to manage DNS directly (`dns=default`)
- Stop and disable `systemd-resolved`

## Steps

### 1. Replace the resolv.conf symlink

```bash
sudo rm -f /etc/resolv.conf
sudo touch /etc/resolv.conf
```

### 2. Point NetworkManager at default DNS handling

```bash
sudo sed -i 's/^dns.*/dns=default/g' /usr/lib/NetworkManager/conf.d/10-dns-resolved.conf
```

If `dns=default` is already set in `/etc/NetworkManager/NetworkManager.conf`, delete the drop-in instead:

```bash
sudo rm -f /usr/lib/NetworkManager/conf.d/10-dns-resolved.conf
```

### 3. Stop and disable systemd-resolved

```bash
sudo systemctl disable --now systemd-resolved
```

### 4. Restart NetworkManager

```bash
sudo systemctl restart NetworkManager
```

## Verify

```bash
cat /etc/resolv.conf
```

The file should list the nameservers handed out by DHCP, not `127.0.0.53`. Confirm resolution works:

```bash
resolvectl query example.com || nslookup example.com
```

## Revert

```bash
sudo systemctl enable --now systemd-resolved
sudo ln -sf ../run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
sudo systemctl restart NetworkManager
```

If step 2 modified the drop-in, restore `dns=systemd-resolved` in
`/usr/lib/NetworkManager/conf.d/10-dns-resolved.conf` before restarting.

## Notes

- Applies to Ubuntu releases using NetworkManager. Server installs using `systemd-networkd` or Netplan
  with `renderer: networkd` need a different approach.
- The path in step 2 varies by release; check `/usr/lib/NetworkManager/conf.d/` if the file is missing.
- Restarting NetworkManager briefly drops network connectivity — avoid running step 4 over SSH on a
  host you cannot reach physically or out-of-band.
- Disabling `systemd-resolved` also disables its DNS caching and DNSSEC validation.
