#!/usr/bin/env bash
# Kurukshetra — D5 debug-keystore generator.
#
# Creates a debug keystore at ~/.local/share/godot/keystores/debug.keystore
# using the standard Android debug-build credentials (alias=androiddebugkey,
# password=android, validity 10000 days). This matches the keystore Godot's
# editor settings expect by default. The keystore is NOT committed — every
# dev / CI runner generates their own via this script.
#
# Idempotent: skips if keystore already exists.
#
# Why a *debug* keystore? Per ADR 0010, v0.1 ships as a sideload-only debug
# APK, not a Play-Store-signed release. Release signing is post-MVP.

set -euo pipefail

KEYSTORE_DIR="${HOME}/.local/share/godot/keystores"
KEYSTORE="${KEYSTORE_DIR}/debug.keystore"

if [ -f "$KEYSTORE" ]; then
  echo "[gen-debug-keystore] already exists at $KEYSTORE — skipping"
  exit 0
fi

mkdir -p "$KEYSTORE_DIR"

if ! command -v keytool >/dev/null 2>&1; then
  echo "ERROR: keytool not on PATH. Install a JDK (sudo apt-get install default-jdk)." >&2
  exit 1
fi

keytool -keyalg RSA \
  -genkeypair \
  -alias androiddebugkey \
  -keystore "$KEYSTORE" \
  -storepass android \
  -keypass android \
  -validity 10000 \
  -dname "CN=Android Debug,O=Android,C=US"

echo "[gen-debug-keystore] OK — $KEYSTORE"
keytool -list -keystore "$KEYSTORE" -storepass android | tail -2
