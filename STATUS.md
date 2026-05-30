# Status

> **v0.1 SHIPPED on 2026-05-30.** Local game complete + debug-signed APK +
> OCI deploy chain. Cron continuation has self-removed. Awaiting Rohan's
> playtest feedback on the sideloaded build.

## Last updated

2026-05-30 — D5 (Android APK) shipped; v0.1 complete. All three remaining
deliverables (D4, D5, D6) are now ✅. Cron job `1a7ee1829cc8` self-removed.

## Deliverables — final

| # | Deliverable | Status | Commit |
|---|---|---|---|
| 1 | Architecture doc + 5 ADRs | ✅ shipped | `2d0ef39` |
| 2 | Godot project scaffold | ✅ shipped | `2849857` |
| 3 | Local-multiplayer prototype (per ADR 0006) | ✅ shipped | `151ab7e` |
| 4 | **Local-complete game** (full MVP playable on this VM) | ✅ shipped (4.10 deferred per ADR 0009) | `43c147c` |
| 5 | **Android APK with touch controls** | ✅ shipped (debug-signed, sideload — ADR 0010) | this commit |
| 6 | OCI / cloud deploy | ✅ shipped early | `346c6e8` |

## D5 — sub-task tracker (final)

D5 = "the game runs on a phone via sideload, with touch controls".

| # | Sub-task | Status | Commit |
|---|---|---|---|
| 5.1 | Touch HUD scene with virtual joysticks + action buttons | ✅ | this commit |
| 5.2 | Touch input wired to existing keyboard input actions | ✅ | this commit |
| 5.3 | Android export preset in `export_presets.cfg` | ✅ | this commit |
| 5.4 | Editor settings: `ANDROID_HOME` + `JAVA_HOME` paths | ✅ (local only — not in repo) | this commit |
| 5.5 | Debug keystore generator (`tools/gen-debug-keystore.sh`) | ✅ | this commit |
| 5.6 | APK build script (`tools/build-apk.sh`) with `aapt` validation | ✅ | this commit |
| 5.7 | Sideload doc (`docs/ANDROID.md`) | ✅ | this commit |
| 5.8 | ADR 0010 — debug keystore for v0.1 | ✅ | this commit |
| 5.9 | CI: enforce new files exist | ✅ | this commit |
| 5.10 | End-to-end build + `aapt dump badging` validation | ✅ | this commit |

## D5 — what landed (this commit)

### Touch HUD (5.1, 5.2)

`scenes/touch_hud.tscn` instances inside the in-match `HUD` CanvasLayer.
Two virtual analog joysticks (left = move, right = look) plus six action
buttons (FIRE, JUMP, RELOAD, [E], CROUCH, PRONE).

`scripts/ui/touch_hud.gd` (~140 lines):

- Joysticks track per-stick touch indices so multi-touch works (move and
  look at once, like every BR ever).
- Move stick drives `move_forward` / `move_backward` / `move_left` /
  `move_right` analog actions via `Input.action_press(name, strength)` —
  the *same* actions the keyboard input map drives, so player.gd is
  unchanged.
- Look stick synthesises `InputEventMouseMotion` events via
  `Input.parse_input_event()` so any code reading mouse motion (camera /
  weapon aim) keeps working.
- Buttons connect their `button_down` / `button_up` signals to
  `Input.action_press` / `Input.action_release` via lambdas. No
  per-button stub functions.
- Auto-hides on non-mobile/non-touch builds — desktop dev runs continue
  to use K/M without the touch HUD intercepting clicks.

### Build chain (5.3 – 5.6)

- `export_presets.cfg` gains a `[preset.1]` named `android-debug`. Both
  arm64-v8a and armeabi-v7a, package `dev.kurukshetra.app`, version code
  1, version name `0.1.0-dev`. Permissions: `INTERNET`,
  `ACCESS_NETWORK_STATE`, `ACCESS_WIFI_STATE`, `VIBRATE`, `WAKE_LOCK`
  (the minimum needed for a UDP-multiplayer game; no camera, no mic, no
  location).
- `tools/gen-debug-keystore.sh` produces
  `~/.local/share/godot/keystores/debug.keystore` (alias `androiddebugkey`,
  password `android`, 10000-day validity). Idempotent.
- `tools/build-apk.sh` runs `godot --headless --export-debug
  android-debug build/kurukshetra-debug.apk`, then asserts the manifest
  via `aapt dump badging` (package + label + permissions).

### Validation (5.10) — actually-runs-on-this-VM

Built on the build VM with Godot 4.3.stable + Android SDK (cmdline-tools
+ build-tools 34.0.0 + platforms;android-34) + OpenJDK 17:

```
[build-apk] OK — /home/horde/kurukshetra/build/kurukshetra-debug.apk (47188 KiB)

[build-apk] === aapt dump badging ===
package: name='dev.kurukshetra.app' versionCode='1' versionName='0.1.0-dev' …
sdkVersion:'21'
targetSdkVersion:'34'
application-label:'Kurukshetra'
launchable-activity: name='com.godot.game.GodotApp'  label='Kurukshetra'
uses-permission: name='android.permission.ACCESS_NETWORK_STATE'
uses-permission: name='android.permission.ACCESS_WIFI_STATE'
uses-permission: name='android.permission.INTERNET'
uses-permission: name='android.permission.VIBRATE'
uses-permission: name='android.permission.WAKE_LOCK'
supports-screens: 'small' 'normal' 'large' 'xlarge'
native-code: 'arm64-v8a' 'armeabi-v7a'
```

`apksigner verify --print-certs` reports
`CN=Android Debug, O=Android, C=US`, SHA-256 fingerprint
`7a3caed3fe7bf631e84bcb739552b8972733068f091119e1593da88aefe97b03`.

D4 smoke test (`tools/run-prototype.sh headless`, 30 s) re-run after the
HUD changes: clean — zero errors / warnings across server + 2 clients.
The TouchHud node correctly hides itself on non-mobile builds without
spamming logs.

### Caveat (honest validation)

The APK has been *built* and *manifest-validated* on the build VM but
**not run on a real phone** — Rohan's playtest closes that loop. Nothing
in the build pipeline can guarantee the touch joysticks feel right; that
needs a phone. The pre-release smoke test confirms:

- The APK is a valid Android package (manifest, signing, two ABIs).
- The Touch HUD GDScript parses + scene instances cleanly.
- Desktop multiplayer prototype still runs error-free with the HUD wired
  in (proving the HUD doesn't break anything for keyboard players or for
  the headless server).

If the playtest reveals something broken, the next iteration is a small
`docs/ANDROID.md` "v0.1.1" patch loop.

## Earlier deliverables — preserved for context

### D6 (early) — what landed

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

### D4 sub-task tracker (history)

| # | Sub-task | Status | Commit |
|---|---|---|---|
| 4.0 | Fix D3 host-spawn `MultiplayerSynchronizer` warning | ✅ | `346c6e8` |
| 4.1 | Movement states: crouch, prone, jump | ✅ | `8e6fb33` |
| 4.2 | 5 weapons with proper stats (pistol, 2 ARs, SMG, sniper) | ✅ | `f3eb837` |
| 4.3 | HP + armor (3 plate tiers) | ✅ | `3bd6fdb` |
| 4.4 | Knockdown + revive (downed state, 30s bleedout, 5s revive) | ✅ | `3bd6fdb` |
| 4.5 | Loot system (ground spawns, 4 rarity tiers, E-key pickup) | ✅ | `e4f2a62` |
| 4.6 | Kill feed HUD (last 5 kills, 5s fade) | ✅ | `e4f2a62` |
| 4.7 | Lobby UI with room-code entry | ✅ | `43c147c` |
| 4.8 | Zone phases 3-5 (full 6-phase schedule) | ✅ | `e4f2a62` |
| 4.9 | 30+ spawn points (rename map to `training_island`) | ✅ | `e4f2a62` |
| 4.10 | Kenney FPS Pack assets imported + ATTRIBUTIONS updated | 🚧 deferred (ADR 0009) | `43c147c` |
| 4.11 | Full smoke test (5min run, no errors, all systems green) | ✅ | `43c147c` |

### D3 host-spawn fix — what landed

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

## How the cron continuation worked

- Hermes cron job `1a7ee1829cc8` (`kurukshetra-autonomous-build`).
- Schedule: every 1h (bumped from 6h on 2026-05-30 — "go faster").
- Each tick: load this STATUS.md → find next ⏳ sub-task → execute → commit.
- When `v0.1 SHIPPED` appeared in this file, the cron self-removed.
- Standing approval per [ADR 0007](docs/decisions/0007-standing-approval.md).

## Active block / risks (post-ship)

- **Phone playtest**: APK has not been touch-tested on hardware. If the
  joystick deadzone / sensitivity feels wrong, expect a 0.1.1 follow-up.
- **OCI security-list**: D6 still needs Rohan's 15-minute OCI signup +
  security-list step before the dedicated server is reachable from the
  internet. ADR 0008 has the runbook.
- **Release keystore**: deferred per ADR 0010. v0.1 → v0.2 will require
  uninstall + reinstall on phones because the signing key changes.
