#!/usr/bin/env bash
set -e

SRC="$(dirname "$(readlink -f "$0")")"
OUT="$SRC/../k6a-godmode.zip"

cd "$SRC"
rm -f "$OUT"

find . -type f ! -path './.git/*' ! -name '*.swp' ! -name '*.swo' ! -name '*~' \
  | sed 's|^\./||' | sort | zip -q "$OUT" -@

echo "Built: $OUT"
echo "Size: $(wc -c < "$OUT") bytes"
