# Architecture — Kurukshetra

> **A free, open-source 16-player battle-royale for Android, built in Godot 4.3+. Playable with friends, $0/month infra, zero dependency on PUBG/BGMI/Krafton.**

Status: **Draft v1** — awaiting Rohan's approval before any code is written.
Last updated: 2026-05-30

---

## 0. Naming

**Project name: Kurukshetra** (कुरुक्षेत्र — the legendary battlefield of the Mahabharata, where the 18-day war between Kauravas and Pandavas was fought).

Chosen by Rohan 2026-05-30. Locked.

- **Trademark**: Kurukshetra is a generic geographic/mythological term and a real place in Haryana, India. Not trademarkable as-is for video games per USPTO + IndiaTM precedent. Two films share the name (2008 Tamil, 2019 Kannada) — different IP class, no overlap with gaming.
- **GitHub**: only ~10 dormant repos with the name, all hobby-scale, no commercial conflict.
- **Niche fit**: directly aligned with the YT mythology-crime channel. Mythology-driven naming themes available downstream — squad colors as Kuru clans (Pandavas/Kauravas/Yadavas/Panchalas), zone shrink as the tightening discus, kill feed as "fallen on the field," etc.
- **Pronunciation**: Ku-ruk-she-tra (4 syllables). Crisp, unambiguous in Devanagari.

Repo will be `kurukshetra` (lowercase, hyphen-free per Godot/Android convention). Android package: `com.<owner>.kurukshetra`.

Logged in `docs/decisions/0001-project-name.md`.

---

## 1. Goals & Non-Goals

### Goals (v0.1 MVP)
1. 16 players, 4 squads of 4, single 1km² map.
2. Playable end-to-end on a mid-range Android phone (4GB RAM, Adreno 612-class GPU, Android 10+).
3. LAN match starts in <30s with 4 friends on the same WiFi.
4. WAN match works for friends across India on 4G/5G with <120ms p50 latency to a free-tier Mumbai/Singapore server.
5. Source code MIT-licensed on GitHub. All assets CC0 or CC-BY with attribution.
6. $0/month infra (Oracle Cloud Always Free or Fly.io free tier).
7. APK installable via sideload (not Play Store) — signed with a debug key for v0.1.

### Non-Goals (deferred to v0.2+)
- Voice chat (use Discord/Mumble out-of-game for MVP).
- Anti-cheat beyond server authority.
- Cosmetics, progression, ranked, accounts.
- Cross-play with iOS or PC.
- Bots/AI players.
- Tournaments / spectator mode.
- 100-player matches. **We are intentionally not competing with PUBG on scale.**
- Custom maps / map editor.

---

## 2. Tech Stack

| Layer | Choice | Why | License |
|---|---|---|---|
| Engine | Godot 4.3+ | Free, open source, native multiplayer API, exports to Android out-of-box, lightweight runtime (~30MB APK overhead vs Unity ~80MB) | MIT |
| Language | GDScript primary, GDExtension/C++ for any hot path (probably none in v0.1) | GDScript faster to iterate, C++ available if profiling shows it's needed | MIT |
| Network transport | ENet (UDP) for LAN, ENet-tunneled-over-WebSocket for WAN | Godot built-in `MultiplayerAPI`, no extra deps | MIT |
| Server hosting | Oracle Cloud Always Free (4 OCPU + 24GB ARM64) primary; Fly.io free tier fallback | OCI gives 4 ARM cores forever-free; Fly is more dev-friendly but has stricter free limits in 2026 | — |
| Art assets | Kenney.nl (FPS Pack, Survival Kit, Modular Buildings) | CC0, professional quality, consistent style | CC0 |
| Audio | Freesound.org + Kenney audio + OpenGameArt | CC0/CC-BY, attribution where required | CC0/CC-BY |
| Map authoring | Blender (free, FOSS) → glTF export → Godot import | Standard FOSS pipeline | GPL/MIT |
| Version control | Git + GitHub (public repo, MIT) | Free for public repos, integrates with Actions for CI builds | — |
| CI/CD | GitHub Actions (2000 min/mo free for public repos) | Auto-build APK on every tag push | — |
| Issue tracking | GitHub Issues | Free, in-repo | — |

**Why not Unity / Unreal:** licensing landmines (Unity's runtime fee saga in 2023-24, Unreal's revenue share), heavier APKs, higher Android battery drain, less FOSS-friendly. Godot wins on every axis for this project size.

---

## 3. Networking Architecture

### 3.1 Topology

**Authoritative dedicated server.** Every match has one process running a headless Godot build (`--headless --server`). Clients connect to it; the server owns all game state.

```
                    ┌─────────────────────────┐
                    │  Dedicated Server       │
                    │  (OCI free-tier ARM)    │
                    │                         │
                    │  • Authoritative state  │
                    │  • Tick rate: 30Hz      │
                    │  • Snapshot rate: 20Hz  │
                    │  • Headless Godot 4.3   │
                    └─────────────────────────┘
                            ▲     ▲     ▲     ▲
              ENet/UDP      │     │     │     │   ENet/UDP
              (LAN) or      │     │     │     │   (LAN) or
              WSS (WAN)     │     │     │     │   WSS (WAN)
                            │     │     │     │
                       ┌────┴─┐ ┌─┴──┐ ┌┴───┐ ┌┴─────┐
                       │ P1   │ │ P2 │ │ P3 │ │ ... 16│
                       │ phone│ │    │ │    │ │       │
                       └──────┘ └────┘ └────┘ └───────┘
```

**Why server-authoritative not P2P:**
- P2P requires NAT traversal (STUN/TURN) → either a paid relay or unreliable on Indian mobile networks
- P2P trusts the host = trivial cheating
- P2P's host migration on disconnect is a multi-week engineering project on its own
- Free-tier OCI gives us 4 ARM cores for free forever, easily enough for 16-player matches at 30Hz

**LAN mode** uses the same server binary running on one phone or laptop, others connect via local IP. No internet needed.

### 3.2 Authority Model

| State | Authority | Why |
|---|---|---|
| Player position | Server | Cheat prevention (no teleport/speed hacks) |
| Player input | Client → server | Client sends intent (move forward, fire); server validates and applies |
| Health, damage, kills | Server | Cannot be tampered with |
| Loot spawns, crate drops | Server | Deterministic seed at match start |
| Zone shrink timer & geometry | Server | Synced via RPC at each phase transition |
| Animations, particle effects, UI | Client | Cosmetic only, no gameplay impact |
| Voice chat (post-MVP) | Out-of-band (Discord/Mumble) | Don't reinvent |

**Client-side prediction** for player movement to hide latency: client moves immediately on input, server reconciles ~100ms later. Standard pattern, well-documented in Godot demos. Defer the netcode-rollback complexity — for a casual squad shooter, simple prediction + reconciliation is fine.

### 3.3 Tick & Snapshot Rates

- **Server simulation tick:** 30Hz (33ms) — good enough for a casual shooter, halves CPU vs 60Hz
- **State snapshot to clients:** 20Hz (50ms) — interpolated client-side
- **Client input to server:** 30Hz (matched to sim tick)
- **Bandwidth budget:** ~15 KB/s per client up, ~25 KB/s down. 16 players × 25 KB/s = 400 KB/s server egress = 1.4 GB/hour. OCI free tier includes 10 TB/mo egress — we'd need 7000 hours of matches to hit the cap.

### 3.4 Lobby & Matchmaking

**v0.1: room codes only, no matchmaker.**

Flow:
1. Friend with the dedicated-server URL hits "Host Match" → server allocates a 4-character room code (`AB12`).
2. Other friends type the code in their app → client connects to same server, joins the lobby.
3. Host taps "Start" when 2+ squads are ready.
4. Match runs 15-25 min, server reports winners, all clients return to lobby.

A single OCI VM can run multiple match servers on different ports. We start with 1 process per match (simple), upgrade to a "match manager" parent process in v0.2 if needed.

### 3.5 Anti-Cheat Posture (v0.1)

**Honest level: minimal.** Server authority blocks the obvious stuff (teleport, infinite ammo, instant kill). Anything client-side (aim assist, wall-hacks via reading position state) is **not prevented** in v0.1.

Mitigations we will do:
- Server validates every shot's geometry (raycast on server, not just client)
- Rate-limit fire commands to weapon's RPM
- Movement speed cap enforced server-side
- Damage capped at weapon's max per shot

Mitigations we are **not** doing in v0.1:
- Client integrity checks
- Process scanning
- Encrypted network traffic (it's all over WSS to the cloud server; LAN mode is in-the-clear, acceptable)
- Replay/match recording for review

**This is fine because:** we're playing with friends. Cheating is a v0.3 problem when/if we open it to strangers. Documented so we don't pretend otherwise.

---

## 4. Game Architecture

### 4.1 Scene Graph (Godot)

```
Main (autoload singleton)
├── NetworkManager (autoload) — wraps MultiplayerAPI
├── GameState (autoload) — match phase, player roster
├── AudioManager (autoload)
└── SceneRoot
    ├── MainMenu.tscn
    ├── Lobby.tscn — room code entry, squad assignment
    ├── Match.tscn
    │   ├── Map (loaded from res://maps/island_v1.tscn)
    │   ├── Players (Node, replicated)
    │   │   └── Player_<peer_id> (CharacterBody3D × N)
    │   ├── LootSpawner (server-only)
    │   ├── ZoneManager (server-only)
    │   └── HUD (client-only)
    └── PostMatch.tscn — results screen
```

### 4.2 Player Controller

`CharacterBody3D` with:
- 3rd-person camera on `SpringArm3D` (3m behind, 1.5m above shoulder)
- States: Idle, Walk, Sprint, Crouch, Prone, Jumping, Knocked, Dead
- Movement speeds: walk 4 m/s, sprint 7 m/s, crouch 2 m/s, prone 1 m/s
- Jump: 4.5 m initial velocity, gravity -20 m/s² (snappier than realistic)
- Stamina: 100 max, sprint drains 10/s, regen 5/s after 1s of not sprinting

### 4.3 Weapon System

Data-driven via `WeaponResource` (Godot custom Resource):

```gdscript
@export var name: String
@export var category: String          # "pistol" | "ar" | "smg" | "sniper"
@export var damage: float             # base damage per shot
@export var rpm: int                  # rounds per minute
@export var magazine_size: int
@export var reload_time: float
@export var bullet_velocity: float    # m/s, for travel-time calc
@export var spread_base: float        # degrees of cone
@export var recoil_pattern: Vector2[] # camera kick per shot
@export var range_falloff_curve: Curve
@export var model: PackedScene        # Kenney FPS Pack model
@export var fire_sound: AudioStream
@export var rarity: int               # 1-4
```

5 weapons in v0.1: P1 pistol, AR1 + AR2, SMG1, S1 sniper. All Kenney FPS Pack models, no custom modeling needed.

### 4.4 Loot

- **Ground spawns:** 200 pre-placed `LootSpawner` nodes on the map. At match start, server picks ~120 of them (random) and spawns weapons/ammo/armor based on rarity table.
- **Crate drops:** 1 air drop per zone phase (5 total). Spawns at random unzone-edge location, contains 1 high-rarity weapon + ammo.
- **Rarity tiers:** white (common, 50%), green (uncommon, 30%), blue (rare, 15%), purple (epic, 5%).

### 4.5 Zone Shrink

6 phases over ~22 minutes:
| Phase | Wait | Shrink time | New radius | Damage/sec outside |
|---|---|---|---|---|
| 0 | 0s | — | 500m (full map) | 0 |
| 1 | 90s | 60s | 350m | 1 |
| 2 | 90s | 60s | 220m | 2 |
| 3 | 90s | 50s | 130m | 4 |
| 4 | 75s | 40s | 70m | 8 |
| 5 | 60s | 30s | 30m | 15 |
| 6 | 45s | 25s | 0m | ∞ |

`ZoneManager` (server-only) broadcasts phase transitions via reliable RPC; clients animate the visual ring.

### 4.6 Knockdown & Revive

- HP 0 with squadmates alive → knocked (60s bleed-out, crawl at 1 m/s)
- Squadmate within 1.5m can hold "Revive" 8s → restored to 30 HP
- HP 0 alone or all squadmates dead → eliminated
- Revives don't use medical items in v0.1 (simpler)

---

## 5. Asset Pipeline

```
Source (CC0/CC-BY) ─► import/ folder (raw FBX/OBJ/PNG/WAV)
                              │
                              ▼
                 Blender (.blend) ─► glTF 2.0 export
                              │
                              ▼
                 Godot import — auto-generates .import sidecar
                              │
                              ▼
                 res://assets/<category>/ — committed
                              │
                              ▼
                 ATTRIBUTIONS.md auto-updated by scripts/build_attributions.py
```

**Rule:** every asset checked in must have an entry in `ATTRIBUTIONS.md` with: source URL, license, original author. Build fails if a file in `res://assets/` lacks an attribution row. Enforced by a pre-commit hook + CI check.

**Asset budget for v0.1:**
- 1 character model (Kenney Mini Characters, retextured)
- 5 weapon models (Kenney FPS Pack)
- 1 map (Kenney Modular Buildings + nature props, hand-assembled in Blender)
- ~30 SFX (footsteps, weapon fire, reload, hit, zone, UI)
- 2 music tracks (lobby + match end)

---

## 6. Build Pipeline

### 6.1 Local dev
- Editor: Godot 4.3+ on Linux/Windows/Mac, opens `project.godot`
- Run client: F5 in editor
- Run server: `godot --headless --server` from CLI (separate terminal)

### 6.2 Android export
1. Install Godot Android export templates (one-time: download from godotengine.org, ~150MB)
2. Generate debug keystore: `keytool -genkey -v -keystore debug.keystore -alias androiddebugkey -storepass android -keypass android -keyalg RSA -keysize 2048 -validity 10000`
3. Configure export preset: `Android (debug)` with min SDK 24 (Android 7.0), target SDK 34
4. Build: `godot --headless --export-debug "Android" build/kurukshetra-debug.apk`

### 6.3 CI (GitHub Actions)
- Trigger: push to `main` or tag `v*`
- Job: install Godot 4.3, install export templates, build APK + Linux server binary
- Artifact: APK + server tarball uploaded to GitHub Release
- Free for public repos; private repos get 2000 min/mo on free tier

### 6.4 Server deployment (Oracle Cloud Always Free)
- VM: 1× ARM A1 instance, 2 OCPU + 12GB RAM (we get 4 OCPU + 24GB total free, save half for second instance)
- OS: Ubuntu 22.04 ARM64
- Server binary: built for `linuxbsd_arm64` target
- Process supervision: `systemd` user unit, restart on crash
- Firewall: open UDP 30000-30099 (one port per concurrent match)
- DNS: Cloudflare (free) → A record → OCI public IP
- Cost: $0 forever per OCI Always Free terms (as of May 2026)

---

## 7. Repository Layout

```
kurukshetra/
├── README.md
├── LICENSE                       # MIT
├── ATTRIBUTIONS.md               # all CC0/CC-BY assets credited
├── .github/workflows/
│   ├── build-android.yml
│   ├── build-server.yml
│   └── lint.yml
├── project.godot
├── icon.svg
├── scenes/
│   ├── main_menu.tscn
│   ├── lobby.tscn
│   ├── match.tscn
│   └── post_match.tscn
├── scripts/
│   ├── autoload/
│   │   ├── network_manager.gd
│   │   ├── game_state.gd
│   │   └── audio_manager.gd
│   ├── player/
│   │   ├── player.gd
│   │   ├── player_camera.gd
│   │   └── input_router.gd
│   ├── weapons/
│   │   ├── weapon.gd
│   │   └── weapon_resource.gd
│   ├── world/
│   │   ├── zone_manager.gd
│   │   └── loot_spawner.gd
│   └── ui/
├── resources/
│   ├── weapons/                  # WeaponResource .tres files
│   └── characters/
├── assets/
│   ├── models/
│   ├── textures/
│   ├── audio/
│   └── ui/
├── maps/
│   └── island_v1.tscn
├── tools/
│   ├── build_attributions.py
│   └── package_release.sh
├── server/
│   └── systemd/kurukshetra-server@.service
└── docs/
    ├── ARCHITECTURE.md           # this file
    ├── NETWORKING.md
    ├── BUILDING.md
    ├── DEPLOY.md
    └── decisions/
        ├── 0001-project-name.md
        ├── 0002-server-authoritative-not-p2p.md
        └── 0003-godot-not-unity-or-unreal.md
```

---

## 8. Decision Log Entries (to write before deliverable 2)

- `0001-project-name.md` — picks the actual name
- `0002-server-authoritative-not-p2p.md` — captures section 3.1 reasoning
- `0003-godot-not-unity-or-unreal.md` — captures section 2 reasoning
- `0004-godot-multiplayerapi-not-custom-netcode.md`
- `0005-no-voice-chat-in-mvp.md`

---

## 9. Risks & Open Questions

| Risk | Severity | Mitigation |
|---|---|---|
| OCI Always Free policy change → free tier ends | Medium | Fly.io fallback; document migration path; <50 rupees/mo paid tier worst case |
| Godot Android export templates break on a future Godot release | Low | Pin Godot version in CI; upgrade deliberately |
| Indian mobile networks have high jitter (>200ms p99) → game feels bad | High | Deploy server in Mumbai region (OCI has it); add lag compensation in v0.2 if needed |
| Asset license drift (Kenney's CC0 status changes) | Very Low | Snapshot all asset sources locally; CC0 is irrevocable per Creative Commons |
| Garena/Krafton trademark complaint despite original assets | Low (if we name carefully) | Project name decided in `0001-project-name.md`; no PUBG references in code/comments |
| Scope creep — "just one more feature" delays MVP forever | High | This doc is the contract. Anything not in §1 Goals is post-MVP. |
| Single dev can't build all of this in <6 months | Medium | Pace across many sessions per Rohan's working style; ship deliverables 2-6 incrementally; OK if v0.1 takes 4-6 months |

**Open questions for Rohan to answer before deliverable 2:**

1. **Project name** — Akhada Royale, or one of the alternatives, or your own?
2. **GitHub username/org** — push to `nvrohang/<name>` (your existing HF handle suggests this) or a new org?
3. **Repo visibility** — public from day 1 (gets you free CI minutes + early discoverability), or private until v0.1 ships?
4. **First-target Android device** — what phone(s) will you and friends actually play on? Drives our minimum-spec testing target. (mid-range 2022+, budget 2020+, etc.)
5. **Tablet support** — yes/no? (UI scaling work if yes.)
6. **Map theme for v0.1** — the YT channel is mythology-crime. Lean into that (a dharmic-themed island with temple ruins) or stay generic (military island like PUBG's Erangel)?

---

## 10. What "approved" looks like

Reply "**approved**" or "**approved with changes: X, Y**" and I'll:
1. Write the 3-5 decision-log entries (`docs/decisions/000*.md`)
2. Initialize the Godot project at `~/kurukshetra/` with the §7 layout
3. Push to GitHub as a public MIT repo
4. Send back a short "deliverable 2 done" summary

Until then, no code gets written.
