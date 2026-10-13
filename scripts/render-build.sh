#!/usr/bin/env bash
set -euo pipefail

ZIP="museame-github-source.zip"
WORK=".render-src"
OUT="render-dist"

rm -rf "$WORK" "$OUT"
mkdir -p "$WORK" "$OUT"

if [ ! -f "$ZIP" ]; then
  echo "Missing $ZIP" >&2
  exit 1
fi

unzip -q "$ZIP" -d "$WORK"

# Find the actual app root by locating package.json.
PKG=$(find "$WORK" -maxdepth 4 -name package.json -type f | head -n 1 || true)

if [ -n "$PKG" ]; then
  APP_DIR=$(dirname "$PKG")
  cd "$APP_DIR"

  if [ -f package-lock.json ]; then
    npm ci
  else
    npm install
  fi

  # Prefer an existing production build script.
  if npm run | grep -qE '^  build'; then
    npm run build
  else
    echo "No npm build script found" >&2
    exit 1
  fi

  cd - >/dev/null

  # Support common frontend output directories.
  for candidate in "$APP_DIR/dist" "$APP_DIR/build" "$APP_DIR/out"; do
    if [ -d "$candidate" ]; then
      cp -a "$candidate"/. "$OUT"/
      echo "Published static output from $candidate"
      exit 0
    fi
  done

  echo "Build completed but no dist/build/out directory was found" >&2
  exit 1
fi

# Fallback for a plain static HTML archive.
INDEX=$(find "$WORK" -maxdepth 4 -name index.html -type f | head -n 1 || true)
if [ -n "$INDEX" ]; then
  STATIC_DIR=$(dirname "$INDEX")
  cp -a "$STATIC_DIR"/. "$OUT"/
  echo "Published static site from $STATIC_DIR"
  exit 0
fi

echo "Could not locate package.json or index.html inside $ZIP" >&2
exit 1
