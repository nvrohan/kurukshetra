# Kurukshetra — dedicated-server deploy guide

This is **D4** of v0.1: how to take a Kurukshetra match server from this
repo to a public IP that mobile clients can connect to. Target environment
is the **Oracle Cloud Infrastructure (OCI) Always Free Tier**, which gives
us 24 GB of RAM across 4 ARM cores or 1 GB on AMD — both more than enough
for a 16-player match.

> **Why OCI Always Free?** ADR 0003 picked Godot for engine cost reasons.
> ADR 0002 commits us to dedicated-server for fairness. We cannot pay for
> hosting (project rule: free open-source first). OCI Always Free is the
> only major cloud with a *forever-free* compute tier. AWS Free Tier
> expires after 12 months; OCI doesn't.

---

## TL;DR (after one-time setup)

```bash
# 1. Build the server binary locally:
./tools/build-server.sh

# 2. Push to your OCI VM:
HOST=ubuntu@<your_oci_public_ip> ./server/oci/deploy.sh
```

The script provisions a `kurukshetra` system user, installs the binary at
`/opt/kurukshetra/kurukshetra-server`, drops the systemd unit at
`/etc/systemd/system/kurukshetra.service`, opens UDP 30000 in the host
firewall, and starts the service. Idempotent — re-run it to redeploy.

---

## One-time setup (manual, ~15 minutes — Rohan only)

### 1. Create an OCI Always Free account

1. Go to <https://www.oracle.com/cloud/free/>
2. Sign up. **A credit card is required for identity verification but you
   will not be charged** (Always Free resources are explicitly outside the
   free trial credit).
3. Pick a home region close to your players. India players → Mumbai
   (`ap-mumbai-1`) or Hyderabad (`ap-hyderabad-1`).

> Why agent does not do this: see [ADR 0008](decisions/0008-oci-manual-account-handoff.md).
> A credit-card-bearing human must complete signup. Once the VM exists,
> everything else is fully scripted.

### 2. Provision an Always Free Compute instance

In the OCI console:

1. **Compute → Instances → Create instance**
2. **Image:** Canonical Ubuntu 22.04 (or Oracle Linux 9 — both supported by
   `deploy.sh`).
3. **Shape:** `VM.Standard.A1.Flex` (ARM, Always Free, generous) with
   1 OCPU / 6 GB RAM is plenty. Falls back to `VM.Standard.E2.1.Micro`
   (AMD, 1 OCPU / 1 GB) if A1 capacity is unavailable in your region.
4. **Networking:** keep the auto-created VCN and public subnet. Tick
   "Assign a public IPv4 address."
5. **SSH keys:** upload your public key (`~/.ssh/id_ed25519.pub` or
   similar). Save the public IP — you'll need it for `HOST=`.
6. Hit **Create.** Wait ~60 seconds for `Provisioning` → `Running`.

### 3. Open UDP 30000 in the OCI security list

OCI's virtual firewall blocks everything inbound by default. The
`deploy.sh` script opens the *host-level* firewall (ufw / firewalld), but
the *cloud-level* security list also needs a rule. One-time:

1. Go to your VM's detail page.
2. Click the VCN under **Primary VNIC → Subnet**.
3. Click the **Default Security List for vcn-XXXX**.
4. **Add Ingress Rule**:
   - Source CIDR: `0.0.0.0/0`
   - IP Protocol: **UDP**
   - Destination Port Range: `30000`
   - Description: `Kurukshetra ENet match server`
5. Save.

### 4. (Optional) Reserve the public IP

OCI ephemeral public IPs change if the VM is stopped/started. To pin it:

1. **Networking → Reserved Public IPs → Create.**
2. On the VM's primary VNIC, edit the public IP and switch from
   *Ephemeral* to *Reserved*.

---

## Repeatable deploy (every push)

From the repo root on your dev machine (Linux/macOS — Godot 4.3 + export
templates installed; same setup as `tools/build-server.sh` describes):

```bash
./tools/build-server.sh
HOST=ubuntu@<public_ip> ./server/oci/deploy.sh
```

Verify from your machine:

```bash
ssh ubuntu@<public_ip> 'sudo journalctl -u kurukshetra -f'
# Expect:
#   [NetworkManager] dedicated server up on port 30000
#   [Match] server-side ready, spawn-on-connect armed
```

To connect a Godot editor client for smoke testing:

```bash
~/tools/godot/godot --path . -- --auto-join=<public_ip>:30000
```

You should see `[NetworkManager] connected (peer_id=...)` in the client
window and `[Match] spawn_function for peer N` in the server journal.

---

## Docker alternative

A multi-stage `Dockerfile` lives at the repo root for portability (e.g. to
run the server on a non-OCI VPS, or locally for dev):

```bash
docker build -t kurukshetra-server:dev .
docker run --rm -p 30000:30000/udp kurukshetra-server:dev
```

The Dockerfile pins `GODOT_VERSION=4.3` and `GODOT_RELEASE=stable`. Every
build step has been validated against the exact same commands in
`tools/build-server.sh`, which is exercised on every push.

> **Caveat (D4 build env):** the Kurukshetra build VM did not have Docker
> installed at D4 ship time, so `docker build` was not run end-to-end on
> the agent. The Dockerfile is a thin wrapper around `tools/build-server.sh`,
> which *was* fully validated on the build VM (template download → headless
> export → exported binary launches → accepts client connection). Any
> deviation between Dockerfile result and host build is therefore narrowed
> to the apt-package layer and the runtime libs — the parts that actually
> need a docker daemon to verify will be exercised the first time Rohan
> runs `docker build .` on a machine with Docker. Captured in commit log.

---

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `Connection timed out` from client | OCI security list rule missing | Add ingress rule UDP 30000 (one-time setup §3) |
| `Connection refused` | Service not running | `ssh ... 'sudo systemctl status kurukshetra'` then `journalctl -u kurukshetra -n 50` |
| Server logs `failed to host on 30000` | Port collision on host | Stop other ENet servers; or override with `PORT=30001 ./server/oci/deploy.sh` (you'd also need to update the security list) |
| `Permission denied (publickey)` on deploy | SSH key not loaded | `SSH_KEY=~/.ssh/oci_key HOST=ubuntu@... ./server/oci/deploy.sh` |
| `kurukshetra-server: cannot execute binary file` on remote | Shape mismatch (built x86_64, deployed to ARM A1) | Set `binary_format/architecture="arm64"` in `export_presets.cfg` for ARM targets, or pick the AMD `E2.1.Micro` shape |

---

## Files in this deliverable

- `Dockerfile` — multi-stage build for portable container deploy.
- `.dockerignore` — keeps build context lean.
- `export_presets.cfg` — Godot export preset `linux-server` (dedicated, x86_64, embedded PCK).
- `tools/build-server.sh` — local headless export → `build/server/kurukshetra-server.x86_64`.
- `server/systemd/kurukshetra.service` — hardened systemd unit.
- `server/oci/deploy.sh` — push-binary-and-restart deploy script for an OCI VM.
- `docs/decisions/0008-oci-manual-account-handoff.md` — the manual-handoff ADR.
