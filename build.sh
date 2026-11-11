#!/usr/bin/env bash
# Builds all packages and the signed APT repository into docs/ (served by GitHub Pages / Cloudflare Pages).
#   ./build.sh                 RackPanel from the latest GitHub release
#   RP_DIST=../rackpanel/dist RP_VERSION=1.1.0 ./build.sh   from a local build
# Signing key: GNUPGHOME (default /root/rsrb-apt/gnupg) – never commit it.
set -euo pipefail
cd "$(dirname "$0")"
export GNUPGHOME=${GNUPGHOME:-/root/rsrb-apt/gnupg}
REPO=Syntax-XXX/rackpanel
OUT=docs; POOL=$OUT/pool/main; DIST=$OUT/dists/stable
work=$(mktemp -d); trap 'rm -rf "$work"' EXIT

RP_VERSION=${RP_VERSION:-$(curl -fsSL https://api.github.com/repos/$REPO/releases/latest | sed -n 's/.*"tag_name": *"v\([^"]*\)".*/\1/p' | head -1)}
[ -n "$RP_VERSION" ] || { echo "RackPanel version unknown" >&2; exit 1; }
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
for p in rsrb-neofetch rsrb-release; do
  v=$(sed -n 's/^Version: //p' packages/$p/DEBIAN/control)
  dpkg-deb --root-owner-group -Zxz --build packages/$p "$POOL/${p}_${v}_all.deb" >/dev/null
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
