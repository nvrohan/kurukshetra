#!/usr/bin/env bash
# Kurukshetra — D3 prototype runner.
#
# Launches a headless server + 2 client windows on localhost. Use this for
# dev iteration; on the VM (no display) the clients also run --headless and
# you'll only see logs.
#
# Usage:
#   ./tools/run-prototype.sh           # local dev (display required)
#   ./tools/run-prototype.sh headless  # CI / VM smoke test (logs only)

set -euo pipefail

cd "$(dirname "$0")/.."
ROOT="$(pwd)"
GODOT="${GODOT:-$HOME/tools/godot/godot}"
if ! [ -x "$GODOT" ]; then
  GODOT="$(command -v godot || true)"
fi
if ! [ -x "$GODOT" ]; then
  echo "ERROR: Godot not found. Set GODOT env var or install at ~/tools/godot/godot" >&2
  exit 1
fi

MODE="${1:-windowed}"
HEADLESS=""
if [ "$MODE" = "headless" ]; then
  HEADLESS="--headless"
fi

LOG_DIR="$ROOT/build/logs"
mkdir -p "$LOG_DIR"
SERVER_LOG="$LOG_DIR/server.log"
CLIENT_A_LOG="$LOG_DIR/client_a.log"
CLIENT_B_LOG="$LOG_DIR/client_b.log"

cleanup() {
  echo
  echo "[run-prototype] cleaning up..."
  jobs -p | xargs -r kill 2>/dev/null || true
  wait 2>/dev/null || true
}
trap cleanup EXIT INT TERM

echo "[run-prototype] mode=$MODE"
echo "[run-prototype] starting server (logs: $SERVER_LOG)"
"$GODOT" --headless --path "$ROOT" -- --server > "$SERVER_LOG" 2>&1 &
SERVER_PID=$!

# Give server time to bind port.
sleep 2
if ! kill -0 "$SERVER_PID" 2>/dev/null; then
  echo "[run-prototype] ERROR: server died early. last log lines:"
  tail -20 "$SERVER_LOG"
  exit 1
fi

echo "[run-prototype] starting client A (logs: $CLIENT_A_LOG)"
"$GODOT" $HEADLESS --path "$ROOT" -- --auto-join=127.0.0.1:30000 > "$CLIENT_A_LOG" 2>&1 &

sleep 1

echo "[run-prototype] starting client B (logs: $CLIENT_B_LOG)"
"$GODOT" $HEADLESS --path "$ROOT" -- --auto-join=127.0.0.1:30000 > "$CLIENT_B_LOG" 2>&1 &

echo
echo "[run-prototype] all 3 processes launched. ctrl-C to stop."
echo "[run-prototype] tail logs in another shell:"
echo "  tail -f $SERVER_LOG $CLIENT_A_LOG $CLIENT_B_LOG"
echo

wait
