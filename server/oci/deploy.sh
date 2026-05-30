#!/usr/bin/env bash
# Kurukshetra — D4 OCI Always Free deploy script.
#
# Pushes the locally-built dedicated-server binary + systemd unit to a
# remote host (intended target: an OCI Always Free Compute VM running
# Ubuntu 22.04 or Oracle Linux 9). The script is idempotent — safe to run
# repeatedly to redeploy.
#
# What this script does NOT do:
#   - Provision the OCI account or VM. That requires a credit card and is a
#     manual step Rohan does once. See docs/DEPLOY.md and ADR 0008.
#   - Open the OCI security-list rule for UDP 30000. Also a one-time manual
#     step in the OCI console — documented in docs/DEPLOY.md.
#
# Usage:
#   HOST=ubuntu@1.2.3.4 ./server/oci/deploy.sh
#   HOST=ubuntu@1.2.3.4 SSH_KEY=~/.ssh/oci_key ./server/oci/deploy.sh
#
# Env vars:
#   HOST     — required, ssh target (user@ip)
#   SSH_KEY  — optional, ssh private key path (defaults to ssh's own resolution)
#   BIN      — optional, path to local server binary
#              (default: build/server/kurukshetra-server.x86_64)
#   UNIT     — optional, path to systemd unit
#              (default: server/systemd/kurukshetra.service)
#   PORT     — optional, UDP port the server listens on (default: 30000)
#
# Exit status: 0 on success, non-zero on any deploy step failure.

set -euo pipefail

cd "$(dirname "$0")/../.."
ROOT="$(pwd)"

: "${HOST:?HOST=user@ip is required}"

BIN="${BIN:-$ROOT/build/server/kurukshetra-server.x86_64}"
UNIT="${UNIT:-$ROOT/server/systemd/kurukshetra.service}"
PORT="${PORT:-30000}"

if [ ! -f "$BIN" ]; then
  echo "ERROR: server binary not found at $BIN" >&2
  echo "  Build it first:  ./tools/build-server.sh" >&2
  exit 1
fi
if [ ! -f "$UNIT" ]; then
  echo "ERROR: systemd unit not found at $UNIT" >&2
  exit 1
fi

SSH_OPTS=(-o StrictHostKeyChecking=accept-new -o ServerAliveInterval=30)
if [ -n "${SSH_KEY:-}" ]; then
  SSH_OPTS+=(-i "$SSH_KEY")
fi

ssh_cmd() { ssh "${SSH_OPTS[@]}" "$HOST" "$@"; }
scp_cmd() { scp "${SSH_OPTS[@]}" "$@"; }

echo "[deploy] target: $HOST"
echo "[deploy] binary: $BIN ($(du -h "$BIN" | cut -f1))"
echo "[deploy] unit:   $UNIT"

# 1) Provision user, dirs, ufw rule.
echo "[deploy] step 1/5: provisioning system on remote..."
ssh_cmd 'bash -se' <<EOF_PROVISION
set -euo pipefail
if ! id -u kurukshetra >/dev/null 2>&1; then
  sudo useradd -r -m -d /opt/kurukshetra -s /usr/sbin/nologin kurukshetra
fi
sudo mkdir -p /opt/kurukshetra
sudo chown kurukshetra:kurukshetra /opt/kurukshetra
# Open UDP $PORT in the host firewall (ufw on Ubuntu, firewalld on OL9).
if command -v ufw >/dev/null 2>&1; then
  sudo ufw allow ${PORT}/udp || true
elif command -v firewall-cmd >/dev/null 2>&1; then
  sudo firewall-cmd --permanent --add-port=${PORT}/udp || true
  sudo firewall-cmd --reload || true
elif command -v iptables >/dev/null 2>&1; then
  sudo iptables -C INPUT -p udp --dport ${PORT} -j ACCEPT 2>/dev/null \
    || sudo iptables -I INPUT -p udp --dport ${PORT} -j ACCEPT
fi
echo "[remote] provisioning OK"
EOF_PROVISION

# 2) Copy binary to a tmp path, then atomically move into place.
echo "[deploy] step 2/5: uploading server binary..."
scp_cmd "$BIN" "$HOST:/tmp/kurukshetra-server.new"
ssh_cmd 'bash -se' <<'EOF_INSTALL'
set -euo pipefail
sudo install -o kurukshetra -g kurukshetra -m 0755 \
  /tmp/kurukshetra-server.new /opt/kurukshetra/kurukshetra-server
rm /tmp/kurukshetra-server.new
EOF_INSTALL

# 3) Install systemd unit.
echo "[deploy] step 3/5: installing systemd unit..."
scp_cmd "$UNIT" "$HOST:/tmp/kurukshetra.service"
ssh_cmd 'bash -se' <<'EOF_UNIT'
set -euo pipefail
sudo install -o root -g root -m 0644 \
  /tmp/kurukshetra.service /etc/systemd/system/kurukshetra.service
rm /tmp/kurukshetra.service
sudo systemctl daemon-reload
sudo systemctl enable kurukshetra.service
EOF_UNIT

# 4) Restart and verify.
echo "[deploy] step 4/5: (re)starting service..."
ssh_cmd 'sudo systemctl restart kurukshetra.service'

echo "[deploy] step 5/5: health check..."
sleep 3
ssh_cmd 'bash -se' <<EOF_HEALTH
set -euo pipefail
if ! systemctl is-active --quiet kurukshetra.service; then
  echo "[remote] service NOT active — last 30 log lines:"
  sudo journalctl -u kurukshetra.service -n 30 --no-pager
  exit 1
fi
echo "[remote] service is active."
echo "[remote] last 10 log lines:"
sudo journalctl -u kurukshetra.service -n 10 --no-pager
# UDP port should be bound.
if command -v ss >/dev/null 2>&1; then
  ss -uln | grep -F ":${PORT}" || { echo "[remote] WARN: udp/${PORT} not bound yet"; }
fi
EOF_HEALTH

echo
echo "[deploy] DONE — kurukshetra server deployed to $HOST on udp/${PORT}."
echo "[deploy] tail logs with:  ssh $HOST 'sudo journalctl -u kurukshetra -f'"
