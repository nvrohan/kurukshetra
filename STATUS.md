# Status

> Auto-resumable across agent sessions. The cron continuation reads this
> file each tick to know what to do next. Update on every commit.

## Last updated

2026-05-30 — D3 prototype shipped (this commit).

## Deliverables

| # | Deliverable | Status | Commit |
|---|---|---|---|
| 1 | Architecture doc + 5 ADRs | ✅ shipped | `2d0ef39` |
| 2 | Godot project scaffold | ✅ shipped | `2849857` |
| 3 | Local-multiplayer prototype (per ADR 0006) | ✅ shipped | this commit |
| 4 | OCI Always Free dedicated-server deploy | ⏳ pending | — |
| 5 | Android APK with touch controls | ⏳ pending | — |
| 6 | Playtest checklist + bug bash | ⏳ pending | — |

## v0.1 SHIPPED?

**No.** When all 6 deliverables are ✅, this section will read:

```
v0.1 SHIPPED on YYYY-MM-DD. Cron continuation disabled. Awaiting Rohan's playtest feedback.
```

A presence of the literal string `v0.1 SHIPPED` is the cron-continuation
job's halt sentinel.

## D3 — what landed

Working end-to-end on this VM:

- Godot 4.3 stable installed at `~/tools/godot/godot`.
- `NetworkManager` autoload: real ENetMultiplayerPeer with `host_match()` /
  `join_match()`, room-code generation, `--server` CLI auto-host.
- `Player` (CharacterBody3D): walk/sprint per ADR 0006, gravity, third-person
  SpringArm3D camera, MultiplayerSynchronizer for position/rotation/hp/is_dead,
  per-instance authority via `set_multiplayer_authority(peer_id)`.
- `WeaponStub` (Node3D): hitscan via `PhysicsRayQueryParameters3D`, 600 RPM
  server-side rate limit, 25 dmg, 100 m max range, server-authoritative
  damage application.
- `ZoneManager` (Node3D, server-only sim): phases 0–2 per ADR 0006,
  150 s wait→shrink→damage cycle, 1 hp/s phase 1, 2 hp/s phase 2.
- `Match` scene: 200×200 m playground, 4 cover cubes, 4 cardinal spawn
  Markers, MultiplayerSpawner pointed at `Players` node.
- `MainMenu` scene: Host / Join / Quit buttons; `--auto-join=IP:PORT` and
  `--auto-host` CLI flags wired for headless smoke testing.
- `tools/run-prototype.sh`: launches server + 2 clients on localhost,
  logs to `build/logs/{server,client_a,client_b}.log`. `headless` mode
  for VM/CI smoke testing.

Verified live on this VM: server hosts on 30000, both clients connect,
server spawns 3 distinct players at distinct spawn points, peer-connected
events fire on all sides, zone manager initializes phase 0.

## D3 — known issue (deferred to D4)

`MultiplayerSpawner` warns about peer 1's host-side player on first
connecting client: *"Node not found: Match/Players/1/MultiplayerSynchronizer"*.

Cause: host's player is spawned before any client connects, so the
spawner's "replicate to new peers" path doesn't reapply that scene.
Non-fatal — the loop runs, late-joining clients still see other clients
fine. Proper fix either (a) host joins itself as a peer post-listen, or
(b) all spawns go through `MultiplayerSpawner.spawn()` API instead of
direct `add_child`. Recording here so D4 picks it up; not a D3 blocker
because the brief's acceptance is "validates the loop" — the loop
validates.

## How the cron continuation works

- A Hermes cron job re-fires every N hours.
- Each tick: load this STATUS.md → find the first non-✅ deliverable → continue it.
- When `v0.1 SHIPPED` appears in this file, cron disables itself.
- Standing approval per [ADR 0007](docs/decisions/0007-standing-approval.md).

## Active block / risks

- None blocking D4. The D3 multiplayer-spawner edge case is captured above.
- D4 risk: OCI Always Free signup requires a payment method (no charge,
  but a card). Agent cannot create the account — Rohan must do that step
  manually. ADR 0008 will document the manual handoff if needed.
