#!/usr/bin/env bash
# Fetch TDLib + Retro Messenger into WORKDIR and apply every patch in patches/.
#
# Usage: ./scripts/apply.sh /path/to/workdir
set -euo pipefail

WORKDIR=${1:?usage: apply.sh /path/to/workdir}
HERE=$(cd "$(dirname "$0")/.." && pwd)
TD_COMMIT=a17f87c4cff7b90b278d12b91ba0614383aaee82

mkdir -p "$WORKDIR"
WORKDIR=$(cd "$WORKDIR" && pwd)

if [ ! -d "$WORKDIR/td" ]; then
  curl -sSL "https://github.com/tdlib/td/archive/$TD_COMMIT.tar.gz" -o "$WORKDIR/td.tar.gz"
  tar xzf "$WORKDIR/td.tar.gz" -C "$WORKDIR"
  mv "$WORKDIR/td-$TD_COMMIT" "$WORKDIR/td"
  rm -f "$WORKDIR/td.tar.gz"
fi
(cd "$WORKDIR/td" && patch -p1 < "$HERE/patches/tdlib-selfhosted.patch")

if [ ! -d "$WORKDIR/retro" ]; then
  git clone --depth 1 https://github.com/RetroMessenger/retro-messenger.git "$WORKDIR/retro"
fi
for p in "$HERE"/patches/client-*.patch; do
  if (cd "$WORKDIR/retro" && git apply --check "$p" 2>/dev/null); then
    (cd "$WORKDIR/retro" && git apply "$p")
    echo "applied $(basename "$p")"
  else
    echo "skipped $(basename "$p") (already applied?)"
  fi
done

echo
echo "Next:"
echo "  cd $WORKDIR/retro && ./scripts/deps.sh   # Debian/Ubuntu"
echo "  cd $WORKDIR/retro && ./scripts/build-lnx.sh -DTD_PATCH_DIR=$WORKDIR/td"
