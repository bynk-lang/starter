#!/usr/bin/env bash
# Install the Bynk toolchain named in BYNK_VERSION, checked against the
# release's SHA256SUMS, plus wrangler and TypeScript for `bynk dev` and
# `bynk test`. Run by the dev container after it is created.
set -euo pipefail

cd "$(dirname "$0")/.."
tag="$(tr -d '[:space:]' < BYNK_VERSION)"
case "$tag" in v*) ;; *) tag="v$tag" ;; esac

case "$(uname -m)" in
  x86_64) target=x86_64-unknown-linux-gnu ;;
  aarch64 | arm64) target=aarch64-unknown-linux-gnu ;;
  *) echo "No Bynk release for $(uname -m)" >&2; exit 1 ;;
esac

base="https://github.com/bynk-lang/bynk/releases/download/$tag"
archive="bynk-$tag-$target.tar.gz"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

echo "Installing Bynk $tag ($target)…"
curl -fsSL -o "$work/$archive" "$base/$archive"
curl -fsSL -o "$work/SHA256SUMS" "$base/SHA256SUMS"
(cd "$work" && sha256sum --check --ignore-missing SHA256SUMS)
tar -xzf "$work/$archive" -C "$work"
sudo install -m 0755 "$work/bynk-$tag-$target/bynk" "$work/bynk-$tag-$target/bynk-lsp" /usr/local/bin/

npm install --global --no-fund --no-audit wrangler@4 typescript@7

bynk --version
bynk doctor || true
