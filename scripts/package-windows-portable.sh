#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="${DIST_DIR:-$ROOT_DIR/dist}"
BUILD_DIR="${BUILD_DIR:-$ROOT_DIR/.build/windows-portable}"
LOVE_URL="${LOVE_URL:-https://github.com/love2d/love/releases/download/11.5/love-11.5-win64.zip}"
LOVE_ARCHIVE_NAME="${LOVE_ARCHIVE_NAME:-love-11.5-win64.zip}"
APP_NAME="${APP_NAME:-pokemon-strike}"
APP_TITLE="${APP_TITLE:-Pokemon Strike}"
PORTABLE_DIR_NAME="${PORTABLE_DIR_NAME:-${APP_NAME}-windows-portable}"
LOVE_FILE="${DIST_DIR}/${APP_NAME}.love"
PORTABLE_DIR="${BUILD_DIR}/${PORTABLE_DIR_NAME}"
OUTPUT_ZIP="${DIST_DIR}/${PORTABLE_DIR_NAME}.zip"

require_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Missing required command: $cmd" >&2
    exit 1
  fi
}

download_file() {
  local url="$1"
  local output="$2"

  if command -v curl >/dev/null 2>&1; then
    curl -L --fail --output "$output" "$url"
    return
  fi

  if command -v wget >/dev/null 2>&1; then
    wget -O "$output" "$url"
    return
  fi

  echo "Need either curl or wget to download $url" >&2
  exit 1
}

require_cmd zip
require_cmd unzip

mkdir -p "$DIST_DIR" "$BUILD_DIR"

LOVE_ARCHIVE_PATH="$BUILD_DIR/$LOVE_ARCHIVE_NAME"
if [[ ! -f "$LOVE_ARCHIVE_PATH" ]]; then
  echo "Downloading LOVE runtime from $LOVE_URL"
  download_file "$LOVE_URL" "$LOVE_ARCHIVE_PATH"
fi

echo "Building ${APP_TITLE}.love"
rm -f "$LOVE_FILE"
(
  cd "$ROOT_DIR"
  zip -q -9 -r "$LOVE_FILE" . \
    -x ".git/*" \
    -x ".build/*" \
    -x "dist/*" \
    -x "*.zip" \
    -x "*.love" \
    -x "*.exe" \
    -x "__MACOSX/*"
)

rm -rf "$PORTABLE_DIR"
mkdir -p "$PORTABLE_DIR"

echo "Unpacking LOVE runtime"
rm -rf "$BUILD_DIR/runtime"
unzip -q "$LOVE_ARCHIVE_PATH" -d "$BUILD_DIR/runtime"

RUNTIME_ROOT="$(find "$BUILD_DIR/runtime" -mindepth 1 -maxdepth 1 -type d | head -n 1)"
if [[ -z "$RUNTIME_ROOT" ]]; then
  echo "Could not find extracted LOVE runtime directory" >&2
  exit 1
fi

cp -R "$RUNTIME_ROOT"/. "$PORTABLE_DIR"/

LOVE_EXE="$PORTABLE_DIR/love.exe"
APP_EXE="$PORTABLE_DIR/${APP_NAME}.exe"

if [[ ! -f "$LOVE_EXE" ]]; then
  echo "Expected $LOVE_EXE in runtime bundle" >&2
  exit 1
fi

echo "Creating Windows executable"
cat "$LOVE_EXE" "$LOVE_FILE" > "$APP_EXE"
rm -f "$LOVE_EXE"

echo "Writing portable zip"
rm -f "$OUTPUT_ZIP"
(
  cd "$BUILD_DIR"
  zip -q -9 -r "$OUTPUT_ZIP" "$PORTABLE_DIR_NAME"
)

echo "Portable package ready:"
echo "  $OUTPUT_ZIP"
