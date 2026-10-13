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

PKG=$(find "$WORK" -maxdepth 4 -name package.json -type f | head -n 1 || true)

publish_dir() {
  local dir="$1"
  rm -rf "$OUT"
  mkdir -p "$OUT"
  cp -a "$dir"/. "$OUT"/
  echo "Published static site from $dir"
  echo "Publish root contents:"
  find "$OUT" -maxdepth 2 -type f | sort | head -n 100

  if [ ! -f "$OUT/index.html" ]; then
    echo "ERROR: published directory has no root index.html" >&2
    exit 1
  fi
}

if [ -n "$PKG" ]; then
  APP_DIR=$(dirname "$PKG")
  cd "$APP_DIR"

  echo "=== Museum package scripts ==="
  node -e "const p=require('./package.json'); console.log(JSON.stringify({name:p.name,engines:p.engines,scripts:p.scripts},null,2))"

  if [ -f package-lock.json ]; then
    npm ci
  else
    npm install
  fi

  if npm run | grep -qE '^  build'; then
    npm run build
  else
    echo "No npm build script found" >&2
    exit 1
  fi

  echo "=== Museum build output ==="
  find . -maxdepth 4 -type f \( -path './dist/*' -o -path './build/*' -o -path './out/*' \) | sort | head -n 200

  cd - >/dev/null

  for candidate in "$APP_DIR/dist" "$APP_DIR/build" "$APP_DIR/out"; do
    if [ ! -d "$candidate" ]; then
      continue
    fi

    if [ -f "$candidate/index.html" ]; then
      publish_dir "$candidate"
      exit 0
    fi

    INDEX=$(find "$candidate" -maxdepth 4 -name index.html -type f | head -n 1 || true)
    if [ -n "$INDEX" ]; then
      STATIC_DIR=$(dirname "$INDEX")
      publish_dir "$STATIC_DIR"
      exit 0
    fi
  done

  echo "Build completed but no browser index.html was found in dist/build/out" >&2
  find "$APP_DIR" -maxdepth 4 -type f | sort | tail -n 200 >&2
  exit 1
fi

INDEX=$(find "$WORK" -maxdepth 5 -name index.html -type f | head -n 1 || true)
if [ -n "$INDEX" ]; then
  STATIC_DIR=$(dirname "$INDEX")
  publish_dir "$STATIC_DIR"
  exit 0
fi

echo "Could not locate package.json or index.html inside $ZIP" >&2
exit 1
