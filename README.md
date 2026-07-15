# AaryanXSky Toolkit

A single menu-driven bash script that wraps native Kali Linux tools into one
easy-to-run OSINT / recon console. No Python web server, no Flask, no
dependencies beyond what's already in Kali (or a one-line `apt install`).

## Install as a real Debian package (recommended — works like any apt install)

A pre-built `.deb` is included: `aaryanxsky_1.0_all.deb`.

```bash
sudo apt install ./aaryanxsky_1.0_all.deb
```

or

```bash
sudo dpkg -i aaryanxsky_1.0_all.deb
sudo apt --fix-broken install   # only if dpkg complains about missing deps
```

This installs `aaryanxsky` to `/usr/bin/aaryanxsky` — available system-wide,
uninstallable with `sudo apt remove aaryanxsky` just like any other package.

### Rebuilding the .deb after editing the tool

```bash
./build-deb.sh
```
Regenerates `aaryanxsky_1.0_all.deb` from the current `aaryanxsky-toolkit.sh`.

### Hosting it in your own APT repo (optional, further down the line)

If you want people to eventually run `sudo apt install aaryanxsky` with zero
manual file download, that requires hosting a signed APT repository
(Packages/Release files + GPG key) — doable via GitHub Pages, but a separate
setup step from the .deb itself. Ask if you want that walkthrough.

## One-line install (curl | bash — needs working HTTPS)

```bash
curl -sSL https://raw.githubusercontent.com/YOUR_USERNAME/aaryanxsky-toolkit/main/install.sh | bash
```

This clones the repo, installs the tool as `aaryanxsky` in `/usr/local/bin`,
optionally installs all dependencies, and launches it — all in one command,
on any fresh Kali machine.

## Manual install (if you already cloned the repo)

```bash
git clone https://github.com/YOUR_USERNAME/aaryanxsky-toolkit.git
cd aaryanxsky-toolkit
./install.sh
```

## Run it directly without installing

```bash
chmod +x aaryanxsky-toolkit.sh
./aaryanxsky-toolkit.sh
```

## Uninstall

```bash
./uninstall.sh
```

On first run, choose option `d` from the menu to check and install any
missing dependencies (whois, geoip-bin, theharvester, dnsenum,
libimage-exiftool-perl, nmap, aircrack-ng).

## Features

| # | Feature | Underlying tool(s) |
|---|---|---|
| 1 | IP Intelligence | `whois`, `geoiplookup` |
| 2 | Domain Recon | `theHarvester`, `whois`, `dnsenum` |
| 3 | EXIF Forensics | `exiftool` |
| 4 | Port / Service Scan | `nmap` |
| 5 | Wi-Fi / BSSID Recon | `airmon-ng`, `airodump-ng` (needs a monitor-mode adapter) |
| 6 | Canary Token | Built-in lightweight Python HTTP listener |
| 7 | Audit Log | Every action is timestamped in `~/.aaryanxsky-toolkit/audit.log` |
| 8 | Loot Directory | All scan output auto-saved as timestamped `.txt` files |
| 9 | Export | Zips loot + canary logs + audit log for reporting |

## Notes

- All output is saved under `~/.aaryanxsky-toolkit/` — nothing is silently lost.
- The canary token listener (`canary_server.py`) is generated automatically
  on first use and runs on port `8901` by default (edit `CANARY_PORT` at the
  top of the script to change it).
- Wi-Fi recon requires a wireless adapter that supports monitor mode and
  root privileges (the script will prompt for `sudo`).
- For authorized security research / educational use only — get permission
  before scanning or fingerprinting systems and networks you don't own.

## Rename it

The display name is a single variable near the top of the script:

```bash
TOOL_NAME="AaryanXSky Toolkit"
```

Change it and the banner/title update everywhere automatically.
