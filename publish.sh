#!/usr/bin/env bash
# Publishes docs/ (the built repository) as a single commit on the gh-pages branch – history doesn't grow with every .deb.
#   GITHUB_TOKEN=… ./publish.sh
set -euo pipefail
cd "$(dirname "$0")"
[ -f docs/dists/stable/InRelease ] || { echo "run ./build.sh first" >&2; exit 1; }
t=$(mktemp -d); trap 'rm -rf "$t"' EXIT
cp -a docs/. "$t/"
git -C "$t" init -q -b gh-pages
git -C "$t" add -A
git -C "$t" -c user.name="${GITHUB_USER:-Syntax-XXX}" -c user.email="${GITHUB_USER:-Syntax-XXX}@users.noreply.github.com" commit -q -m "repository $(date -u +%F\ %H:%M) UTC"
git -C "$t" -c credential.helper= push -q -f "https://x-access-token:${GITHUB_TOKEN:?}@github.com/Syntax-XXX/rsrb.git" gh-pages 2>&1 | sed "s/$GITHUB_TOKEN/***/g"
echo "published"
