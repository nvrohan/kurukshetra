# Kurukshetra v0.1.0 — first sideload-able Android build

> **Faceless mythology-themed battle royale, free + open source forever.**
> No corporate publishers, no ads, no in-app purchases — just the game.

This is the v0.1 milestone build: a fully-playable Android APK you can
sideload onto your phone and play with friends on the same WiFi.

## 📥 Download

Tap **`kurukshetra-debug.apk`** in the Assets section below to download
straight to your phone.

- **Size:** 48 MB
- **SHA256:** `1a7efb3f13d13bdd22b0aa85076cdcc82615018cea7cd6f13ed74ee362b99709`
- **Min Android:** 7.0 (API 24)
- **Architectures:** arm64-v8a + armeabi-v7a (covers ~99% of phones from 2016+)

## 📲 How to install

1. Tap the downloaded `.apk` file.
2. Android: *"For your security, your phone is not allowed to install
   unknown apps from this source"* → tap **Settings**.
3. Toggle **"Allow from this source"** ON.
4. Back arrow → tap the APK again → **Install** → **Open**.

## 🎮 How to play (LAN — same WiFi)

1. Friend A: open the app, tap **Host** — they get a room code (e.g.
   `EPEE`) and their local IP (e.g. `192.168.1.42`).
2. Friend B/C/D: tap **Join**, enter Friend A's IP, tap connect.
3. Up to 16 players per match. Last squad standing wins.

## ✅ What works in v0.1

- 5 weapons: pistol, two ARs, SMG, sniper — different stats, server-
  authoritative damage
- HP + 3-tier armor plates (light 50, medium 100, heavy 150)
- Knockdown → 30s bleedout → 5s revive (hold E within 2m of teammate)
- Movement: walk / sprint / crouch / prone / jump
- Loot system: 4 rarity tiers (common / uncommon / rare / legendary)
  on 32+ ground spawn points
- Kill feed HUD (last 5 kills, fades after 5s)
- Full 6-phase shrinking blue zone — phases 0-5 with proper timings
- Touch controls: dual virtual joysticks + 6 action buttons
- Lobby with room-code entry

## ⏳ What's deferred to v0.2

- **Public-internet play:** v0.1 is LAN-only. v0.2 will add OCI Always
  Free dedicated-server deploy (docs/ADR 0008) so friends on different
  networks can join via room code.
- **Voice chat** (per ADR 0005)
- **Crate drops** (loot only via ground spawns currently)
- **Real Kenney FPS Pack 3D models** — v0.1 uses placeholder primitives
  (per ADR 0009 — proper assets needed an interactive Godot import flow
  that doesn't fit the headless build pipeline, deferred to v0.2)
- **Play Store / F-Droid release** — currently debug-signed for sideload
  only (per ADR 0010)

## ⚠️ Known issues

- Debug-signed APK shows "from unknown source" warning on install
  (intentional — production signing comes in v0.2)
- 3D models are primitives, not full character/weapon meshes (deferred
  per ADR 0009)
- Server-side spawn timing has a deferred edge case from D3 — fixed in
  D4 commit `346c6e8` but verify with hosted matches and report back

## 🔍 Verify before installing

```bash
sha256sum kurukshetra-debug.apk
# expected: 1a7efb3f13d13bdd22b0aa85076cdcc82615018cea7cd6f13ed74ee362b99709
```

## 📜 Source + license

- Code: MIT — https://github.com/nvrohan/kurukshetra
- Audio assets (none yet — placeholder beeps)
- Visual assets: primitives (Godot built-in)
- Future assets: Kenney FPS Pack (CC0) + OpenGameArt (CC-BY) only

## 🐛 Found a bug?

Open an issue at https://github.com/nvrohan/kurukshetra/issues with:
- Phone model + Android version
- What you were doing when it broke
- Logcat dump if available (`adb logcat | grep godot`)

— *Built autonomously by a Hermes Agent cron job between
2026-05-30 02:18 UTC and 06:18 UTC. Total elapsed: 4 hours
across D3-D5 deliverables.*
