# Kurukshetra

> **A free, open-source 16-player mobile battle royale built in Godot 4.3+.
> MIT-licensed. CC0/CC-BY assets only. $0/month infrastructure. Zero dependency
> on PUBG / BGMI / Krafton / Garena.**

कुरुक्षेत्र — *Kurukshetra*, the legendary battlefield of the Mahabharata.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Engine: Godot 4.3+](https://img.shields.io/badge/Engine-Godot%204.3%2B-478cbf)](https://godotengine.org)
[![Status: scaffold](https://img.shields.io/badge/Status-v0.1%20scaffold-orange)]()

## Status — v0.1 scaffold (deliverable 2)

This repo currently contains the **architecture + project skeleton**, not a
playable game. See [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) for the
full plan, and [`docs/decisions/`](docs/decisions/) for the
architectural decision records.

### What works right now

- Godot 4.3+ project opens cleanly (`project.godot` valid)
- Three autoload singletons stubbed: `NetworkManager`, `GameState`, `AudioManager`
- Main menu scene with placeholder Host / Join / Quit buttons
- §7 directory tree fully scaffolded with `.gdkeep` placeholders

### What does NOT work yet

- **Networking** — `NetworkManager.host_match()` / `join_match()` are stubs (deliverable 3)
- **Player controller** — empty (deliverable 3)
- **Weapons / loot / zone** — none yet (deliverable 3)
- **Android export** — preset not configured (deliverable 5)
- **CI APK build** — workflow placeholder only (deliverable 5)

## Quick start (developers)

### Requirements

- Godot 4.3 or later — [godotengine.org/download](https://godotengine.org/download)
- Git
- (Android build, deliverable 5) Android Studio + Godot Android export templates

### Open in Godot

```bash
git clone https://github.com/nvrohan/kurukshetra.git
cd kurukshetra
godot --editor project.godot
# or just double-click project.godot in the Godot project manager
```

Press **F5** in the editor to launch the main menu scene.

### Run headless server (no transport wired yet — placeholder)

```bash
godot --headless --main-pack . -- --server
```

## Project layout

See [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md#7-repository-layout) for
the full §7 layout. Quick reference:

| Path | Contents |
|---|---|
| `project.godot` | Godot project entry point |
| `scenes/` | `main_menu.tscn`, `lobby.tscn`, `match.tscn`, `post_match.tscn` |
| `scripts/autoload/` | `NetworkManager`, `GameState`, `AudioManager` |
| `scripts/{player,weapons,world,ui}/` | Subsystem scripts |
| `resources/{weapons,characters}/` | `.tres` data resources |
| `assets/{models,textures,audio,ui}/` | CC0/CC-BY assets — see `ATTRIBUTIONS.md` |
| `maps/` | `island_v1.tscn` (deliverable 3) |
| `tools/` | Build + attribution scripts |
| `server/` | systemd unit, deploy notes (deliverable 4) |
| `docs/` | Architecture, ADRs, networking, deployment |

## Contributing

1. **All assets** must be CC0 or CC-BY. CC-BY-SA / NC / ND are rejected — see
   [`ATTRIBUTIONS.md`](ATTRIBUTIONS.md) for the full license-allow list.
2. **No PUBG/BGMI/Free Fire/Krafton/Garena assets, names, logos, sounds, or
   textures.** Originality is non-negotiable.
3. Architectural changes require a new ADR in `docs/decisions/000N-*.md`.
4. PRs welcome once deliverable 3 lands. For now the repo is solo-author + scaffolding.

## License

- **Code:** MIT — see [`LICENSE`](LICENSE).
- **Assets:** Each file's individual license (CC0 or CC-BY) is recorded in
  [`ATTRIBUTIONS.md`](ATTRIBUTIONS.md).

## Deliverable status

| # | Deliverable | Status |
|---|---|---|
| 1 | Architecture doc + ADRs | ✅ Done |
| 2 | Godot project scaffold | ✅ Done (this commit) |
| 3 | Local-multiplayer prototype (movement + 1 weapon + zone shrink) | ⏳ Next |
| 4 | Dedicated-server build + OCI Always Free deploy doc | ⏳ Pending |
| 5 | Android APK with touch controls | ⏳ Pending |
| 6 | Playtest checklist + first bug bash | ⏳ Pending |
