#!/usr/bin/env bash
# Kurukshetra — D4 server build script.
#
# Exports a headless Linux dedicated-server binary using Godot 4.3 export
# templates. Output: build/server/kurukshetra-server.x86_64 (PCK embedded).
#
# Used both by humans on dev machines and by the multi-stage Dockerfile.
#
# Env vars:
#   GODOT  — path to Godot binary (defaults to ~/tools/godot/godot)
#   PRESET — export preset name in export_presets.cfg (default: linux-server)
#
# Validation: exits non-zero if export fails or the output binary is missing.

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

PRESET="${PRESET:-linux-server}"
OUT_DIR="$ROOT/build/server"
OUT_BIN="$OUT_DIR/kurukshetra-server.x86_64"

mkdir -p "$OUT_DIR"

# Sanity: export templates must exist for 4.3.stable.
GODOT_VER="4.3.stable"
TEMPLATE_DIR="${HOME}/.local/share/godot/export_templates/${GODOT_VER}"
if [ ! -d "$TEMPLATE_DIR" ]; then
  echo "ERROR: Godot export templates missing at $TEMPLATE_DIR" >&2
  echo "  Install with:" >&2
  echo "    curl -L -o /tmp/templates.tpz \\" >&2
  echo "      https://github.com/godotengine/godot/releases/download/${GODOT_VER%.*}-stable/Godot_v${GODOT_VER%.*}-stable_export_templates.tpz" >&2
  echo "    unzip /tmp/templates.tpz -d /tmp/godot_tpl && \\" >&2
  echo "      mv /tmp/godot_tpl/templates \"$TEMPLATE_DIR\"" >&2
  exit 1
fi

echo "[build-server] Godot: $GODOT"
echo "[build-server] Preset: $PRESET"
echo "[build-server] Output: $OUT_BIN"

# Note: --import is needed once before --export-debug works; safe to call again.
"$GODOT" --headless --path "$ROOT" --import 2>&1 | tail -20 || true

"$GODOT" --headless --path "$ROOT" --export-debug "$PRESET" "$OUT_BIN"

if [ ! -f "$OUT_BIN" ]; then
  echo "ERROR: export reported success but $OUT_BIN does not exist" >&2
  exit 1
fi

chmod +x "$OUT_BIN"
SIZE_KB=$(du -k "$OUT_BIN" | cut -f1)
echo "[build-server] OK — $OUT_BIN (${SIZE_KB} KiB)"
