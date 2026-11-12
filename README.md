# RSRB · RackStation ReBoot

**English** · [Deutsch](README.de.md)

```
 ██████╗ ███████╗
 ██╔══██╗██╔════╝
 ██████╔╝███████╗
 ██╔══██╗╚════██║
 ██║  ██║███████║
 ╚═╝  ╚═╝╚══════╝
 ██████╗ ██████╗
 ██╔══██╗██╔══██╗
 ██████╔╝██████╔╝
 ██╔══██╗██╔══██╗
 ██║  ██║██████╔╝
 ╚═╝  ╚═╝╚═════╝
```

RSRB is Debian 12 instead of DSM on the Synology RS812 – with its own `-rsrb` kernel, the
[RackPanel](https://github.com/Syntax-XXX/rackpanel) web UI and this APT repository.
Website: **https://syntax-xxx.github.io/rsrb/**

| Repository | What |
|---|---|
| [rs812-debian](https://github.com/Syntax-XXX/rs812-debian) | the OS: kernel, device tree, installation, flashing, recovery |
| [rackpanel](https://github.com/Syntax-XXX/rackpanel) | the NAS web UI |
| **rsrb** (this one) | packages and the APT repository |

## Use the repository

```sh
curl -fsSL https://syntax-xxx.github.io/rsrb/setup.sh | sudo sh
sudo apt install rsrb-rs812-full   # Synology RS812: everything (web UI, containers, full kernel)
sudo apt install rsrb-rs812-core   # Synology RS812: barebone NAS (SSH, SMB, NFS)
sudo apt install rsrb-full         # any other Debian/Ubuntu
sudo apt install rackpanel rackbox # just the web UI and containers
```

Or by hand:

```sh
sudo curl -fsSLo /usr/share/keyrings/rsrb.gpg https://syntax-xxx.github.io/rsrb/rsrb.gpg
echo "deb [signed-by=/usr/share/keyrings/rsrb.gpg] https://syntax-xxx.github.io/rsrb stable main" | sudo tee /etc/apt/sources.list.d/rsrb.list
sudo apt update
```

Signing key: `C967 9F05 04B2 68FE BE8D 73C7 67C5 9D95 3A7E DE6A`

## Packages

| Package | Architectures | Contents |
|---|---|---|
| `rsrb-rs812-full` | armel | **RS812, everything**: `rsrb-full` + hardware support + full kernel |
| `rsrb-rs812-core` | armel | **RS812, barebone NAS**: `rsrb-core` + hardware support + core kernel |
| `rsrb-full` / `rsrb-core` | all | the same flavors for any Debian/Ubuntu (no kernel, no RS812 hardware) |
| `rsrb-rs812`, `rsrb` | | shortcuts for the full flavors |
| `linux-image-rsrb` | armel | newest RSRB **core** kernel: only what a NAS needs is built in |
| `linux-image-rsrb-full` | armel | newest RSRB **full** kernel: + memory cgroup, netfilter/NAT, WireGuard, IPv6, NTFS3, CIFS |
| `rsrb-flash-kernel` | armel | `rsrb-flash-kernel VERSION` writes a kernel to the SPI flash (asks, verifies by reading back, never touches U-Boot) |
| `rsrb-rs812-hw` | armel | fan control by disk temperature (`rs812-fan.service`), front panel like under DSM (`rs812-panel.service`: disk/status/power LEDs, real fan speed), gpio-fan/RTC modules, network and read-ahead tuning measured on the RS812 |
| `rackbox` | armel, armhf, arm64, amd64 | Docker images without a daemon (systemd-nspawn) + the Containers page for RackPanel |
| `rackpanel` | armel, armhf, arm64, amd64 | NAS web UI. Asks for user, password and port (debconf); `dpkg-reconfigure rackpanel` changes them. |
| `rsrb-neofetch` | all | neofetch preset with the RSRB logo and NAS info; `rsrbfetch` command. Your own `~/.config/neofetch/config.conf` still wins. |
| `rsrb-release` | all | system identity: `/etc/os-release` (`ID=rsrb`, `ID_LIKE=debian`, version stays 12/bookworm), console banner, login message. Uses `dpkg-divert`; removing the package restores Debian's files. |

They work on any Debian/Ubuntu with systemd, not only on the RS812.

## Build

```sh
./build.sh                                              # rackpanel from its latest GitHub release
RP_DIST=../rackpanel/dist RP_VERSION=1.1.0 ./build.sh   # from a local build
```

`build.sh` builds the `.deb` files from `packages/`, writes the repository into `docs/` and signs it with the key in
`GNUPGHOME` (default `/root/rsrb-apt/gnupg`, never committed). `./publish.sh` pushes `docs/` as a single commit to the
`gh-pages` branch, which GitHub Pages serves. Cloudflare Pages works too (connect the `gh-pages` branch, no build command).
