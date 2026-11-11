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
sudo apt install rackpanel rsrb-neofetch rsrb-release
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
Schlüssel in `GNUPGHOME` (Standard `/root/rsrb-apt/gnupg`, wird nie eingecheckt). `docs/` wird von GitHub Pages
ausgeliefert; Cloudflare Pages geht genauso (Repository verbinden, kein Build-Befehl, Ausgabeordner `docs`).
