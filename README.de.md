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
sudo apt install rsrb-rs812   # auf einer Synology RS812: komplettes System
sudo apt install rsrb         # auf jedem anderen Debian/Ubuntu
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
| `rsrb-rs812` | armel | **komplettes RSRB-System für die RS812**: zieht Kernel, `rsrb` und die RS812-Hardwareunterstützung (Lüftersteuerung `rs812-fan.service`, gpio-fan/RTC-Module). |
| `rsrb` | all | Basissystem auf jedem Debian: `rsrb-release`, `rsrb-neofetch`, `rackpanel`. |
| `linux-image-rsrb` | armel | immer der neueste RSRB-Kernel (`linux-image-6.1.176-rsrb`: Module + uImage). Geflasht wird nur mit `rsrb-flash-kernel` (fragt nach, prüft durch Rücklesen, fasst U-Boot nie an). |
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
