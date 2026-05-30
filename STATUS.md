# Status

> Auto-resumable across agent sessions. The cron continuation reads this
> file each tick to know what to do next. Update on every commit.

## Last updated

2026-05-30 — D3 prototype shipped; D4-D6 re-scoped per Rohan (local game first, then APK, then deploy).

## Plan re-scope (2026-05-30)

Rohan: *"We will do deployment later first we need to make sure our game works. Complete all development, help me test it locally, and then we will do deployment."*

Original D4 (cloud deploy) and D5 (Android APK) are deferred. New order:

| # | Deliverable | Status |
|---|---|---|
| 1 | Architecture doc + 5 ADRs | ✅ shipped (`2d0ef39`) |
| 2 | Godot project scaffold | ✅ shipped (`2849857`) |
| 3 | Local-multiplayer prototype (per ADR 0006) | ✅ shipped (`151ab7e`) |
| 4 | **Local-complete game** (NEW — full MVP playable on this VM) | 🚧 in progress |
| 5 | Android APK with touch controls | ⏳ deferred until D4 ✅ |
| 6 | OCI / cloud deploy | ⏳ deferred until D5 ✅ |

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
| 4.0 | Fix D3 host-spawn `MultiplayerSynchronizer` warning | ⏳ | — |
| 4.1 | Movement states: crouch, prone, jump | ⏳ | — |
| 4.2 | 5 weapons with proper stats (pistol, 2 ARs, SMG, sniper) | ⏳ | — |
| 4.3 | HP + armor (3 plate tiers) | ⏳ | — |
| 4.4 | Knockdown + revive (downed state, 30s bleedout, 5s revive) | ⏳ | — |
| 4.5 | Loot system (ground spawns, 4 rarity tiers, E-key pickup) | ⏳ | — |
| 4.6 | Kill feed HUD (last 5 kills, 5s fade) | ⏳ | — |
| 4.7 | Lobby UI with room-code entry | ⏳ | — |
| 4.8 | Zone phases 3-5 (full 6-phase schedule) | ⏳ | — |
| 4.9 | 30+ spawn points (rename map to `training_island`) | ⏳ | — |
| 4.10 | Kenney FPS Pack assets imported + ATTRIBUTIONS updated | ⏳ | — |
| 4.11 | Full smoke test (5min run, no errors, all systems green) | ⏳ | — |

When 4.0–4.11 are ✅, write `D4 SHIPPED — local game complete, ready for Android packaging` and ping Rohan to confirm before starting D5.

## D3 — what landed (reference)

Working end-to-end on this VM:

- Godot 4.3 stable installed at `~/tools/godot/godot`.
- `NetworkManager` autoload: real ENetMultiplayerPeer with `host_match()` /
  `join_match()`, room-code generation, `--server` CLI auto-host.
- `Player` (CharacterBody3D): walk/sprint per ADR 0006, gravity, third-person
  SpringArm3D camera, MultiplayerSynchronizer for position/rotation/hp/is_dead,
  per-instance authority via `set_multiplayer_authority(peer_id)`.
- `WeaponStub` (Node3D): hitscan, 600 RPM rate-limit, 25 dmg, 100 m max
  range, server-authoritative damage application.
- `ZoneManager` (Node3D, server-only): phases 0–2 per ADR 0006.
- `Match` scene: 200×200 m playground, 4 cover cubes, 4 cardinal spawns.
- `MainMenu` scene: Host / Join / Quit + `--auto-join` / `--auto-host` CLI.
- `tools/run-prototype.sh`: launches server + 2 clients on localhost.

D3 known issue (now D4 task 4.0): `MultiplayerSpawner` warns about peer 1's
host-side player on first connect. Non-fatal; loop runs.

## How the cron continuation works

- Hermes cron job `1a7ee1829cc8` (`kurukshetra-autonomous-build`).
- Schedule: every 1h (bumped from 6h on 2026-05-30 — "go faster").
- Each tick: load this STATUS.md → find next ⏳ D4 sub-task → execute → commit.
- When `v0.1 SHIPPED` appears, cron self-removes.
- Standing approval per [ADR 0007](docs/decisions/0007-standing-approval.md).

## Active block / risks

- **D4 risk:** Kenney FPS Pack download size — first tick that handles asset
  import may be longer than usual. Run gltf import in headless mode.
- **D4 risk:** revive system needs careful authority handling (only server
  decides downed/revived state; clients only render). Easy to get wrong.
- No paid-tool blockers expected for D4.
