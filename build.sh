#!/usr/bin/env bash
# Builds all packages and the signed APT repository into docs/ (served by GitHub Pages / Cloudflare Pages).
#   ./build.sh                 RackPanel from the latest GitHub release
#   RP_DIST=../rackpanel/dist RP_VERSION=1.2.0 ./build.sh   from a local build
# Signing key: GNUPGHOME (default /root/rsrb-apt/gnupg) – never commit it.
set -euo pipefail
cd "$(dirname "$0")"
export GNUPGHOME=${GNUPGHOME:-/root/rsrb-apt/gnupg}
REPO=Syntax-XXX/rackpanel
OUT=docs; POOL=$OUT/pool/main; DIST=$OUT/dists/stable
work=$(mktemp -d); trap 'rm -rf "$work"' EXIT

RP_VERSION=${RP_VERSION:-$(curl -fsSL https://api.github.com/repos/$REPO/releases/latest | sed -n 's/.*"tag_name": *"v\([^"]*\)".*/\1/p' | head -1)}
[ -n "$RP_VERSION" ] || { echo "RackPanel version unknown" >&2; exit 1; }
# kernel packages can only be built where the kernel was built; elsewhere keep the published ones
mkdir -p "$work/keep"; [ -d "$POOL" ] && cp "$POOL"/linux-image-*.deb "$work/keep/" 2>/dev/null || true
rm -rf "$POOL" "$OUT/dists" && mkdir -p "$POOL"

# rackpanel: one package per architecture (Debian arch name / release archive name)
for pair in armel:armv5 armhf:armv7 arm64:arm64 amd64:amd64; do
  deb=${pair%%:*} tar=${pair##*:}
  r="$work/rackpanel-$deb"; mkdir -p "$r/usr/bin" "$r/usr/share/rackpanel"
  if [ -n "${RP_DIST:-}" ]; then cp "$RP_DIST/rackpanel-linux-$tar.tar.gz" "$work/rp.tgz"
  else curl -fsSL -o "$work/rp.tgz" "https://github.com/$REPO/releases/download/v$RP_VERSION/rackpanel-linux-$tar.tar.gz"; fi
  tar -xzf "$work/rp.tgz" -C "$work" && mv "$work/rackpanel" "$r/usr/bin/" && mv "$work/www" "$r/usr/share/rackpanel/www"
  cp -r packages/rackpanel/. "$r/"
  sed -i "s/@VERSION@/$RP_VERSION/; s/@ARCH@/$deb/; s/@SIZE@/$(du -sk "$r" --exclude=DEBIAN | cut -f1)/" "$r/DEBIAN/control"
  dpkg-deb --root-owner-group -Zxz --build "$r" "$POOL/rackpanel_${RP_VERSION}_$deb.deb" >/dev/null
done
# RSRB kernels (armel, RS812): per flavor a versioned package + a linux-image-<flavor> metapackage
KB=${KERNEL_BUILD:-/root/rs812-debian/kernel/build}
built=0
for fl in "out-flash:rsrb:core:Only what a NAS needs is built in." \
          "out-full:rsrb-full:full:Adds memory limits (memory cgroup), netfilter/NAT, WireGuard, IPv6, NTFS3 and CIFS."; do
  IFS=: read -r od meta flavor fdesc <<<"$fl"
  KOUT=$KB/$od
  [ -f "$KOUT/uImage" ] && [ -f "$KOUT/spi-nor-unlock.ko" ] || continue
  KVER=$(ls "$KOUT/modules/lib/modules"); KPKG=6.1.176-${KERNEL_REV:-3}
  r="$work/linux-image-$flavor"; cp -r packages/linux-image "$r"
  mkdir -p "$r/usr/lib/modules" "$r/usr/lib/rsrb/kernel"
  cp -a "$KOUT/modules/lib/modules/$KVER" "$r/usr/lib/modules/" && rm -f "$r/usr/lib/modules/$KVER/build" "$r/usr/lib/modules/$KVER/source"
  cp "$KOUT/uImage" "$r/usr/lib/rsrb/kernel/uImage-$KVER"
  cp "$KOUT/spi-nor-unlock.ko" "$r/usr/lib/rsrb/kernel/spi-nor-unlock-$KVER.ko"
  # the full kernel ships WireGuard: say so, or apt pulls in a Debian kernel to satisfy wireguard-tools
  prov=linux-image; [ "$flavor" = full ] && prov="linux-image, wireguard-modules (= 1.0.20210914)"
  sed -i "s/@KVER@/$KVER/g; s/@PKGVER@/$KPKG/; s/@FLAVOR@/$flavor/g; s|@FLAVORDESC@|$fdesc|; s/@PROVIDES@/$prov/; s/@SIZE@/$(du -sk "$r" --exclude=DEBIAN | cut -f1)/" "$r"/DEBIAN/*
  dpkg-deb --root-owner-group -Zxz --build "$r" "$POOL/linux-image-${KVER}_${KPKG}_armel.deb" >/dev/null
  m="$work/meta-$flavor"; cp -r packages/linux-image-rsrb "$m"
  sed -i "s/@META@/$meta/; s/@KVER@/$KVER/; s/@PKGVER@/$KPKG/; s/@FLAVOR@/$flavor/g" "$m/DEBIAN/control"
  dpkg-deb --root-owner-group --build "$m" "$POOL/linux-image-${meta}_${KPKG}_armel.deb" >/dev/null
  built=1
done
[ $built = 1 ] || cp "$work/keep"/*.deb "$POOL/" 2>/dev/null || echo "note: no kernel build in $KB and no published kernel packages" >&2

# rackbox: from the rackpanel release (same archives layout as rackpanel)
RB_VERSION=${RB_VERSION:-0.1.0}
for pair in armel:armv5 armhf:armv7 arm64:arm64 amd64:amd64; do
  deb=${pair%%:*} tar=${pair##*:}
  r="$work/rackbox-$deb"; mkdir -p "$r/usr/bin" "$r/usr/share/rackpanel/addons"
  if [ -n "${RP_DIST:-}" ]; then cp "$RP_DIST/rackbox-linux-$tar.tar.gz" "$work/rb.tgz"
  else curl -fsSL -o "$work/rb.tgz" "https://github.com/$REPO/releases/download/v$RP_VERSION/rackbox-linux-$tar.tar.gz"; fi
  rm -rf "$work/rbx" && mkdir "$work/rbx" && tar -xzf "$work/rb.tgz" -C "$work/rbx"
  mv "$work/rbx/rackbox" "$r/usr/bin/" && mv "$work/rbx/addon" "$r/usr/share/rackpanel/addons/rackbox"
  cp -r packages/rackbox/. "$r/"
  sed -i "s/@VERSION@/$RB_VERSION/; s/@ARCH@/$deb/; s/@SIZE@/$(du -sk "$r" --exclude=DEBIAN | cut -f1)/" "$r/DEBIAN/control"
  dpkg-deb --root-owner-group -Zxz --build "$r" "$POOL/rackbox_${RB_VERSION}_$deb.deb" >/dev/null
done

# apps packaged from upstream release binaries
FB_VERSION=${FB_VERSION:-$(curl -fsSL https://api.github.com/repos/filebrowser/filebrowser/releases/latest | sed -n 's/.*"tag_name": *"v\([^"]*\)".*/\1/p' | head -1)}
for pair in armel:armv5 armhf:armv7 arm64:arm64 amd64:amd64; do
  deb=${pair%%:*} up=${pair##*:}
  r="$work/filebrowser-$deb"; mkdir -p "$r/usr/bin"
  curl -fsSL "https://github.com/filebrowser/filebrowser/releases/download/v$FB_VERSION/linux-$up-filebrowser.tar.gz" | tar -xz -C "$r/usr/bin" filebrowser
  cp -r packages/filebrowser/. "$r/"
  sed -i "s/@VERSION@/$FB_VERSION-1/; s/@ARCH@/$deb/; s/@SIZE@/$(du -sk "$r" --exclude=DEBIAN | cut -f1)/" "$r/DEBIAN/control"
  dpkg-deb --root-owner-group -Zxz --build "$r" "$POOL/filebrowser_${FB_VERSION}-1_$deb.deb" >/dev/null
done

for p in rsrb-flash-kernel rsrb rsrb-core rsrb-full rsrb-rs812 rsrb-rs812-core rsrb-rs812-full rsrb-rs812-hw rsrb-neofetch rsrb-release; do
  v=$(sed -n 's/^Version: //p' packages/$p/DEBIAN/control)
  a=$(sed -n 's/^Architecture: //p' packages/$p/DEBIAN/control)
  dpkg-deb --root-owner-group -Zxz --build packages/$p "$POOL/${p}_${v}_$a.deb" >/dev/null
done

# index + signed Release
for a in armel armhf arm64 amd64; do
  mkdir -p "$DIST/main/binary-$a"
  (cd "$OUT" && apt-ftparchive --arch "$a" packages pool) > "$DIST/main/binary-$a/Packages"
  gzip -9nkf "$DIST/main/binary-$a/Packages"
done
apt-ftparchive -o APT::FTPArchive::Release::Origin=RSRB -o APT::FTPArchive::Release::Label=RSRB \
  -o APT::FTPArchive::Release::Suite=stable -o APT::FTPArchive::Release::Codename=stable \
  -o APT::FTPArchive::Release::Architectures="armel armhf arm64 amd64" -o APT::FTPArchive::Release::Components=main \
  -o APT::FTPArchive::Release::Description="RSRB – RackStation ReBoot packages" release "$DIST" > "$work/Release"
mv "$work/Release" "$DIST/Release"
gpg --batch --yes --clearsign -o "$DIST/InRelease" "$DIST/Release"
gpg --batch --yes -abs -o "$DIST/Release.gpg" "$DIST/Release"
gpg --export > "$OUT/rsrb.gpg"; gpg --armor --export > "$OUT/rsrb.asc"

cp -r site/. "$OUT/"; touch "$OUT/.nojekyll"
ls -l "$POOL"
