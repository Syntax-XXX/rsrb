# RSRB · RackStation ReBoot

[English](README.md) · **Deutsch**

RSRB ist Debian 12 statt DSM auf der Synology RS812 – mit eigenem `-rsrb`-Kernel, der Weboberfläche
[RackPanel](https://github.com/Syntax-XXX/rackpanel) und dieser APT-Paketquelle.
Website: **https://syntax-xxx.github.io/rsrb/**

| Repository | Inhalt |
|---|---|
| [rs812-debian](https://github.com/Syntax-XXX/rs812-debian) | das OS: Kernel, Device Tree, Installation, Flashen, Rettung |
| [rackpanel](https://github.com/Syntax-XXX/rackpanel) | die NAS-Weboberfläche |
| **rsrb** (dieses) | Pakete und APT-Paketquelle |

## Paketquelle nutzen

```sh
curl -fsSL https://syntax-xxx.github.io/rsrb/setup.sh | sudo sh
sudo apt install rsrb-rs812-full   # Synology RS812: alles (Weboberfläche, Container, Full-Kernel)
sudo apt install rsrb-rs812-core   # Synology RS812: Barebone-NAS (SSH, SMB, NFS)
sudo apt install rsrb-full         # jedes andere Debian/Ubuntu
sudo apt install rackpanel rackbox # nur Weboberfläche und Container
```

Oder von Hand:

```sh
sudo curl -fsSLo /usr/share/keyrings/rsrb.gpg https://syntax-xxx.github.io/rsrb/rsrb.gpg
echo "deb [signed-by=/usr/share/keyrings/rsrb.gpg] https://syntax-xxx.github.io/rsrb stable main" | sudo tee /etc/apt/sources.list.d/rsrb.list
sudo apt update
```

Signierschlüssel: `C967 9F05 04B2 68FE BE8D 73C7 67C5 9D95 3A7E DE6A`

## Pakete

| Paket | Architekturen | Inhalt |
|---|---|---|
| `rsrb-rs812-full` | armel | **RS812, alles**: `rsrb-full` + Hardwareunterstützung + Full-Kernel |
| `rsrb-rs812-core` | armel | **RS812, Barebone-NAS**: `rsrb-core` + Hardwareunterstützung + Core-Kernel |
| `rsrb-full` / `rsrb-core` | all | dieselben Flavors für jedes Debian/Ubuntu (ohne Kernel und RS812-Hardware) |
| `rsrb-rs812`, `rsrb` | | Kurzformen für die Full-Flavors |
| `linux-image-rsrb` | armel | neuester RSRB-**Core**-Kernel: fest eingebaut ist nur, was ein NAS braucht |
| `linux-image-rsrb-full` | armel | neuester RSRB-**Full**-Kernel: + memory-cgroup, Netfilter/NAT, WireGuard, IPv6, NTFS3, CIFS |
| `rsrb-flash-kernel` | armel | `rsrb-flash-kernel VERSION` schreibt einen Kernel in den SPI-Flash (fragt nach, prüft durch Rücklesen, fasst U-Boot nie an) |
| `rsrb-rs812-hw` | armel | Lüftersteuerung nach Plattentemperatur (`rs812-fan.service`), Front-Panel wie unter DSM (`rs812-panel.service`: Platten-/Status-/Power-LEDs, echte Lüfterdrehzahl), gpio-fan/RTC-Module, auf der RS812 gemessenes Netzwerk- und Read-Ahead-Tuning |
| `rackbox` | armel, armhf, arm64, amd64 | Docker-Images ohne Daemon (systemd-nspawn) + die Containers-Seite für RackPanel |
| `rackpanel` | armel, armhf, arm64, amd64 | NAS-Weboberfläche. Fragt nach Benutzer, Passwort und Port (debconf); ändern mit `dpkg-reconfigure rackpanel`. |
| `rsrb-neofetch` | all | neofetch-Preset mit RSRB-Logo und NAS-Infos; Befehl `rsrbfetch`. Eine eigene `~/.config/neofetch/config.conf` hat Vorrang. |
| `rsrb-release` | all | Systemidentität: `/etc/os-release` (`ID=rsrb`, `ID_LIKE=debian`, Version bleibt 12/bookworm), Konsolenbanner, Login-Meldung. Nutzt `dpkg-divert`; beim Entfernen kommen Debians Dateien zurück. |

Die Pakete laufen auf jedem Debian/Ubuntu mit systemd, nicht nur auf der RS812.

## Bauen

```sh
./build.sh                                              # rackpanel aus dem neuesten GitHub-Release
RP_DIST=../rackpanel/dist RP_VERSION=1.1.0 ./build.sh   # aus einem lokalen Build
```

`build.sh` baut die `.deb`-Dateien aus `packages/`, schreibt die Paketquelle nach `docs/` und signiert sie mit dem
Schlüssel in `GNUPGHOME` (Standard `/root/rsrb-apt/gnupg`, wird nie eingecheckt). `./publish.sh` schiebt `docs/` als einzelnen Commit
auf den Branch `gh-pages`, den GitHub Pages ausliefert. Cloudflare Pages geht genauso (Branch `gh-pages` verbinden, kein Build-Befehl).
