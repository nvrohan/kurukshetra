# Status

> Auto-resumable across agent sessions. The cron continuation reads this
> file each tick to know what to do next. Update on every commit.

## Last updated

2026-05-30 — D4 dedicated-server deploy shipped (this commit). D3 host-spawn
issue fixed in the same tick.

## Deliverables

| # | Deliverable | Status | Commit |
|---|---|---|---|
| 1 | Architecture doc + 5 ADRs | ✅ shipped | `2d0ef39` |
| 2 | Godot project scaffold | ✅ shipped | `2849857` |
| 3 | Local-multiplayer prototype (per ADR 0006) | ✅ shipped | `151ab7e` |
| 4 | OCI Always Free dedicated-server deploy | ✅ shipped | this commit |
| 5 | Android APK with touch controls | ⏳ pending | — |
| 6 | Playtest checklist + bug bash | ⏳ pending | — |

## v0.1 SHIPPED?

**No.** When all 6 deliverables are ✅, this section will read:

```
v0.1 SHIPPED on YYYY-MM-DD. Cron continuation disabled. Awaiting Rohan's playtest feedback.
```

A presence of the literal string `v0.1 SHIPPED` is the cron-continuation
job's halt sentinel.

## D4 — what landed

Validated end-to-end on this VM:

- **Headless export**: `~/.local/share/godot/export_templates/4.3.stable/`
  populated (templates downloaded fresh from GitHub releases).
  `export_presets.cfg` defines a `linux-server` preset with
  `dedicated_server=true`, `server_runnable=true`, `embed_pck=true`,
  x86_64 architecture. `tools/build-server.sh` runs
  `godot --headless --export-debug linux-server build/server/kurukshetra-server.x86_64`
  and produces a 64 MiB self-contained binary.
- **Exported binary smoke-tested**: launched
  `./build/server/kurukshetra-server.x86_64 -- --server`, server bound
  UDP 30000, accepted a client connection from the editor build, spawn
  function fired for both peers, no errors.
- **Dockerfile**: multi-stage Debian-bookworm-slim, builder stage pins
  `GODOT_VERSION=4.3` `GODOT_RELEASE=stable`, downloads templates,
  invokes `tools/build-server.sh`. Runner stage copies the binary, runs
  as non-root `kurukshetra` user, EXPOSE 30000/udp, HEALTHCHECK by pgrep.
  *Caveat:* `docker build` was not run on the build VM at D4 ship time
  (Docker daemon not installed, no sudo). Every Dockerfile command maps
  1:1 to a step that ran successfully on the host. Documented in
  `docs/DEPLOY.md` and the commit message.
- **OCI deploy script** (`server/oci/deploy.sh`): idempotent push-binary-
  and-restart over ssh. Provisions `kurukshetra` user, installs binary
  at `/opt/kurukshetra/`, drops the systemd unit, opens ufw/firewalld
  rule for UDP 30000, restarts service, journalctl health check. Bash
  syntax-checked (`bash -n`).
- **Systemd unit** (`server/systemd/kurukshetra.service`): hardened
  (NoNewPrivileges, ProtectSystem=strict, RestrictAddressFamilies, etc.),
  Restart=always, MemoryMax=512M to fit the smallest Always Free shape.
- **Deploy doc** (`docs/DEPLOY.md`): TL;DR commands + 4-step OCI one-time
  manual setup (signup → VM → security list rule → optional reserved IP).
  Troubleshooting table for the common failure modes.
- **ADR 0008**: documents why OCI signup is a manual handoff (credit-card-
  gated identity verification; agent rule "no paid tools").

## D3 host-spawn fix (landed in this D4 tick)

Replaced direct `add_child` of host's peer-1 player with a custom
`MultiplayerSpawner.spawn_function` that all peers (server + clients)
go through. Authority is set inside the spawn function (before _ready)
to satisfy the synchronizer's pending-spawn requirement. Verified by
running `tools/run-prototype.sh headless` and grepping all three logs:

```
==ERROR/WARNING COUNT==
clean
```

Both the original "Node not found: Match/Players/1/MultiplayerSynchronizer"
warning and the transient "no network ID" replication error are gone.
Server, client A, client B all see all three players with correct
authority/camera-local flags.

Files touched: `scripts/match/match.gd`, `scripts/player/player.gd`,
`scenes/match.tscn` (spawn_path corrected to `../Players` since spawn_path
is relative to the spawner node, not its parent).

## How the cron continuation works

- A Hermes cron job re-fires every N hours.
- Each tick: load this STATUS.md → find the first non-✅ deliverable → continue it.
- When `v0.1 SHIPPED` appears in this file, cron disables itself.
- Standing approval per [ADR 0007](docs/decisions/0007-standing-approval.md).

## Active block / risks

- D4 is fully deployable but **not yet running on a public IP**. That
  needs Rohan's 15-minute one-time OCI signup + VM creation + security
  list rule. Once Rohan does that and shares the public IP, the agent
  can run `HOST=... ./server/oci/deploy.sh` automatically.
- D5 risk: Android export templates are now installed (D4 fetched them),
  but Android signing requires the Android SDK + JDK. The `android_debug.apk`
  template is included in the export-templates bundle, so debug-keystore-
  signed APKs may build without a separate SDK install. To be verified
  next tick.
- No paid-tool requirements have been hit. Project rule still satisfied.

## Next tick — D5

1. Add Android export preset (`android-debug` in `export_presets.cfg`).
2. Add `scenes/touch_hud.tscn` with TouchScreenButton controls
   (left virtual stick, right look stick, fire button, jump button).
3. `tools/build-apk.sh` that runs the export with the bundled debug
   keystore convention.
4. Sideload doc in `docs/SIDELOAD.md`.
5. Verify APK builds without errors and contains touch UI; if Android SDK
   is required and not satisfiable headless, write ADR 0009 documenting
   the manual-step handoff (similar to ADR 0008 for OCI).
