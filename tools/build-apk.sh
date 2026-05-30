#!/usr/bin/env bash
# Kurukshetra — D5 Android APK build script.
#
# Exports a debug-signed APK for sideload onto a stock Android phone.
#
# Output: build/kurukshetra-debug.apk (signed with the debug keystore at
# ~/.local/share/godot/keystores/debug.keystore — see tools/gen-debug-keystore.sh).
#
# Validation: after export, runs `aapt dump badging` to confirm the APK
# is a valid Android package and exits non-zero if anything is off.
#
# Env vars:
#   GODOT       — path to Godot (default: ~/tools/godot/godot)
#   ANDROID_HOME — path to Android SDK (default: ~/android-sdk)
#   JAVA_HOME    — path to JDK (default: /usr/lib/jvm/java-17-openjdk-amd64)
#   PRESET       — preset name in export_presets.cfg (default: android-debug)
#
# Pre-reqs (one-time on a fresh machine):
#   1. Install JDK 17+: sudo apt-get install default-jdk
#   2. Install Android SDK cmdline-tools, platform-tools, platforms;android-34,
#      build-tools;34.0.0. Accept licenses with `sdkmanager --licenses`.
#   3. Install Godot 4.3 export templates (see tools/build-server.sh comment).
#   4. Run tools/gen-debug-keystore.sh.

set -euo pipefail

cd "$(dirname "$0")/.."
ROOT="$(pwd)"

GODOT="${GODOT:-$HOME/tools/godot/godot}"
if ! [ -x "$GODOT" ]; then
  GODOT="$(command -v godot || true)"
fi
if ! [ -x "$GODOT" ]; then
  echo "ERROR: Godot binary not found. Set GODOT env var or install at ~/tools/godot/godot" >&2
  exit 1
fi

ANDROID_HOME="${ANDROID_HOME:-$HOME/android-sdk}"
JAVA_HOME="${JAVA_HOME:-/usr/lib/jvm/java-17-openjdk-amd64}"
PRESET="${PRESET:-android-debug}"
KEYSTORE="${HOME}/.local/share/godot/keystores/debug.keystore"

# Validate prereqs early with a clear error.
if [ ! -d "$ANDROID_HOME" ]; then
  echo "ERROR: Android SDK not found at $ANDROID_HOME" >&2
  echo "  Install cmdline-tools + platform-tools + platforms;android-34 + build-tools;34.0.0" >&2
  exit 1
fi
if [ ! -d "$JAVA_HOME" ]; then
  echo "ERROR: JDK not found at $JAVA_HOME — install OpenJDK 17 (sudo apt-get install default-jdk)" >&2
  exit 1
fi
if [ ! -f "$KEYSTORE" ]; then
  echo "ERROR: debug keystore not found at $KEYSTORE" >&2
  echo "  Run: tools/gen-debug-keystore.sh" >&2
  exit 1
fi

# Find a build-tools dir (use the highest-numbered one).
BUILD_TOOLS_DIR="$(ls -1 "$ANDROID_HOME/build-tools" 2>/dev/null | sort -V | tail -1)"
if [ -z "$BUILD_TOOLS_DIR" ]; then
  echo "ERROR: no build-tools installed under $ANDROID_HOME/build-tools" >&2
  exit 1
fi
AAPT="$ANDROID_HOME/build-tools/$BUILD_TOOLS_DIR/aapt"
if [ ! -x "$AAPT" ]; then
  echo "ERROR: aapt not found at $AAPT" >&2
  exit 1
fi

OUT_DIR="$ROOT/build"
OUT_APK="$OUT_DIR/kurukshetra-debug.apk"
mkdir -p "$OUT_DIR"

# Sanity: Godot Android export templates must exist.
GODOT_VER="4.3.stable"
TEMPLATE_DIR="${HOME}/.local/share/godot/export_templates/${GODOT_VER}"
if [ ! -f "$TEMPLATE_DIR/android_debug.apk" ]; then
  echo "ERROR: Godot export templates missing at $TEMPLATE_DIR" >&2
  echo "  Install with the same procedure as tools/build-server.sh" >&2
  exit 1
fi

export ANDROID_HOME JAVA_HOME

echo "[build-apk] Godot:        $GODOT"
echo "[build-apk] ANDROID_HOME: $ANDROID_HOME"
echo "[build-apk] JAVA_HOME:    $JAVA_HOME"
echo "[build-apk] preset:       $PRESET"
echo "[build-apk] output:       $OUT_APK"

# Import once to refresh the resource cache (idempotent, OK to re-run).
"$GODOT" --headless --path "$ROOT" --import 2>&1 | tail -10 || true

# Export. --export-debug uses the debug keystore configured in editor settings.
"$GODOT" --headless --path "$ROOT" --export-debug "$PRESET" "$OUT_APK"

if [ ! -f "$OUT_APK" ]; then
  echo "ERROR: export reported success but $OUT_APK does not exist" >&2
  exit 1
fi

SIZE_KB=$(du -k "$OUT_APK" | cut -f1)
echo "[build-apk] OK — $OUT_APK (${SIZE_KB} KiB)"

# ---- Validation: aapt dump badging ----
echo
echo "[build-apk] === aapt dump badging ==="
BADGING_OUT="$("$AAPT" dump badging "$OUT_APK" 2>&1)"
echo "$BADGING_OUT" | head -20

# Sanity-check the manifest.
EXPECT_PKG="dev.kurukshetra.app"
if ! echo "$BADGING_OUT" | grep -q "package: name='$EXPECT_PKG'"; then
  echo "ERROR: package name in APK does not match $EXPECT_PKG" >&2
  exit 1
fi
if ! echo "$BADGING_OUT" | grep -q "application-label.*Kurukshetra"; then
  echo "ERROR: application-label in APK does not include 'Kurukshetra'" >&2
  exit 1
fi
echo
echo "[build-apk] APK validated — package=$EXPECT_PKG"
