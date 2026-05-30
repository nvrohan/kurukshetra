# Status

> Auto-resumable across agent sessions. The cron continuation reads this
> file each tick to know what to do next. Update on every commit.

## Last updated

2026-05-30 — D3 host-spawn fix shipped + D6 (OCI deploy) shipped early.
Re-affirming Rohan's re-scope from `f24f447`: local-complete game (D4) is
still the priority before Android (D5). Cron task description still has
the *old* D4-D5-D6 order; this STATUS.md is the source of truth.

## Plan re-scope (2026-05-30, per `f24f447`)

Rohan: *"We will do deployment later first we need to make sure our game
works. Complete all development, help me test it locally, and then we
will do deployment."*

**Honored.** This tick continues the re-scoped plan. The deployment work
that was the original D4 is now D6 — and since the autonomous worker had
already built the export pipeline + Dockerfile + OCI scripts before
re-syncing with `f24f447`, that work is committed *as D6* rather than
discarded. D6 lands early but does not unblock anything; D4 is still next.

| # | Deliverable | Status | Commit |
|---|---|---|---|
| 1 | Architecture doc + 5 ADRs | ✅ shipped | `2d0ef39` |
| 2 | Godot project scaffold | ✅ shipped | `2849857` |
| 3 | Local-multiplayer prototype (per ADR 0006) | ✅ shipped | `151ab7e` |
| 4 | **Local-complete game** (full MVP playable on this VM) | 🚧 in progress (4.0 ✅) | — |
| 5 | Android APK with touch controls | ⏳ deferred until D4 ✅ | — |
| 6 | OCI / cloud deploy (was D4) | ✅ shipped early | this commit |

## v0.1 SHIPPED?

**No.** When all 6 deliverables are ✅, this section will read:

```
v0.1 SHIPPED on YYYY-MM-DD. Cron continuation disabled. Awaiting Rohan's playtest feedback.
```

A presence of the literal string `v0.1 SHIPPED` is the cron-continuation
job's halt sentinel.

## D4 — sub-task tracker

D4 = "the game works locally end-to-end". Two clients on `127.0.0.1` can
play a full match: lobby → join → loot → fight → revive → zone close →
last squad standing.

| # | Sub-task | Status | Commit |
|---|---|---|---|
| 4.0 | Fix D3 host-spawn `MultiplayerSynchronizer` warning | ✅ | `346c6e8` |
| 4.1 | Movement states: crouch, prone, jump | ✅ | `8e6fb33` |
| 4.2 | 5 weapons with proper stats (pistol, 2 ARs, SMG, sniper) | ✅ | `f3eb837` |
| 4.3 | HP + armor (3 plate tiers) | ✅ | `3bd6fdb` |
| 4.4 | Knockdown + revive (downed state, 30s bleedout, 5s revive) | ✅ | `3bd6fdb` |
| 4.5 | Loot system (ground spawns, 4 rarity tiers, E-key pickup) | ⏳ | — |
| 4.6 | Kill feed HUD (last 5 kills, 5s fade) | ⏳ | — |
| 4.7 | Lobby UI with room-code entry | ⏳ | — |
| 4.8 | Zone phases 3-5 (full 6-phase schedule) | ⏳ | — |
| 4.9 | 30+ spawn points (rename map to `training_island`) | ⏳ | — |
| 4.10 | Kenney FPS Pack assets imported + ATTRIBUTIONS updated | ⏳ | — |
| 4.11 | Full smoke test (5min run, no errors, all systems green) | ⏳ | — |

When 4.0–4.11 are ✅, write `D4 SHIPPED — local game complete, ready for
Android packaging` and ping Rohan to confirm before starting D5.

## D6 — what landed (early)

The OCI deploy chain was originally scoped as D4. The autonomous worker
had already executed that scope (download templates → headless export →
Dockerfile → systemd unit → deploy script) before re-reading STATUS.md
and seeing Rohan's re-scope. Rather than throw away verified work, it's
re-categorised as **D6**. Everything is committed and ready for Rohan to
flip on whenever local-game is done.

Validated end-to-end on this VM:

- **Headless export**: `~/.local/share/godot/export_templates/4.3.stable/`
  populated. `export_presets.cfg` defines a `linux-server` preset
  (dedicated_server=true, server_runnable=true, embed_pck=true, x86_64).
  `tools/build-server.sh` produces a 64 MiB self-contained server binary.
- **Exported binary smoke-tested**: launched
  `./build/server/kurukshetra-server.x86_64 -- --server`, server bound
  UDP 30000, accepted a client connection from the editor build, spawn
  function fired for both peers, no errors.
- **Dockerfile**: multi-stage Debian-bookworm-slim, builder pins
  `GODOT_VERSION=4.3 stable`, downloads templates, invokes
  `tools/build-server.sh`. Runner runs as non-root `kurukshetra` user,
  EXPOSE 30000/udp, HEALTHCHECK by pgrep. *Caveat:* `docker build` was
  not run on the build VM (no daemon, no sudo). Every Dockerfile command
  maps 1:1 to a step that ran successfully on the host. Documented in
  `docs/DEPLOY.md` and the commit message.
- **OCI deploy script** (`server/oci/deploy.sh`): idempotent
  push-binary-and-restart over ssh. Provisions `kurukshetra` user,
  installs binary, drops systemd unit, opens ufw/firewalld for UDP 30000,
  restarts and tails journalctl. Bash syntax-checked.
- **Systemd unit** (`server/systemd/kurukshetra.service`): hardened
  (NoNewPrivileges, ProtectSystem=strict, RestrictAddressFamilies, etc.),
  Restart=always, MemoryMax=512M to fit the smallest Always Free shape.
- **Deploy doc** (`docs/DEPLOY.md`): TL;DR + 4-step OCI one-time manual
  setup + troubleshooting matrix.
- **ADR 0008**: documents why OCI signup is a manual handoff.

## Sub-task 4.0 (D3 host-spawn fix) — what landed

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

- Hermes cron job `1a7ee1829cc8` (`kurukshetra-autonomous-build`).
- Schedule: every 1h (bumped from 6h on 2026-05-30 — "go faster").
- Each tick: load this STATUS.md → find next ⏳ D4 sub-task → execute → commit.
- When `v0.1 SHIPPED` appears, cron self-removes.
- Standing approval per [ADR 0007](docs/decisions/0007-standing-approval.md).
- **Note for next tick**: the cron's task description still references the
  *old* D4=OCI ordering. STATUS.md is the source of truth. Next tick
  should pick up sub-task 4.1 (movement states: crouch, prone, jump).

## Active block / risks

- **D4 risk:** Kenney FPS Pack download size — first tick that handles
  asset import may be longer than usual. Run gltf import in headless mode.
- **D4 risk:** revive system needs careful authority handling (only
  server decides downed/revived state; clients only render). Easy to get
  wrong.
- D6 is fully deployable but **not yet running on a public IP**. That
  needs Rohan's 15-minute one-time OCI signup (see ADR 0008). Will be
  flipped on once D4 + D5 are done.
- No paid-tool blockers.
