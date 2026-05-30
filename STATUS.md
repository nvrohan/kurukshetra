# Status

> **v0.1.1 SHIPPED on 2026-05-30.** Real CC0 3D assets replace v0.1.0's grey
> placeholders: Kenney-class character + weapon meshes, textured grass ground,
> survival-kit cover props, and a dawn skybox with tuned sun + fog. Gameplay
> unchanged. New debug-signed APK published to GitHub Releases and delivered to
> Rohan via Telegram. Cron job `c6b6a80bea21` self-removed.

## Last updated

2026-05-30 — v0.1.1 visual overhaul complete. CI green. Release published.

## v0.1.1 — sub-task tracker (final)

| # | Sub-task | Status | Notes |
|---|---|---|---|
| 1 | CC0 asset acquisition + ATTRIBUTIONS | ✅ | OGA + ambientCG + Poly Haven (Kenney CDN not curl-reachable headless; ADR 0011). 49 committed assets attributed by literal path. |
| 2 | Headless GLTF/OBJ import | ✅ | `--import` pass clean, no errors. `_downloads/.gdignore` prevents scan hang. |
| 3 | Player capsule → character mesh | ✅ | `character1.glb` in `player.tscn`; CharacterBody3D collision shape preserved; stance handling updated for Node3D mesh. |
| 4 | Weapon stubs → real meshes | ✅ | Kenney-class FPS weapon OBJs (pistol/revolver/SMG/shotgun/sniper) at WeaponMount. |
| 5 | Retexture playground + props | ✅ | Tiled grass material on 200m ground; barrel/crate StaticBody3D cover across map. |
| 6 | Skybox + lighting | ✅ | `WorldEnvironment` + Kloofendal dawn sky HDR; tuned DirectionalLight3D + distance fog. |
| 7 | Validate | ✅ | Headless import clean; 3-process LAN smoke test clean (no script errors); screenshot captured. |
| 8 | Rebuild APK | ✅ | `versionName=0.1.1` (code 2), debug-signed, aapt-validated, classes.dex + arm64-v8a libgodot present. |
| 9 | Publish GitHub Release v0.1.1 | ✅ | https://github.com/nvrohan/kurukshetra/releases/tag/v0.1.1 — APK SHA256 verified by re-download. v0.1.0 preserved. |
| 10 | Deliver to Rohan via Telegram | ✅ | APK + release URL delivered. |

## ADRs

- ADR 0009 (Kenney assets) — **ratified, Status: Accepted**.
- ADR 0011 — CC0 asset import pipeline (OGA/ambientCG/Poly Haven; headless `--import`).

## Honesty note

v0.1.0 shipped with placeholder geometry (grey capsules, untextured planes,
stub weapon boxes). v0.1.1 replaces all of them with CC0 assets. No gameplay,
netcode, or control changes — visual layer only.

## Released APK

- File: `build/kurukshetra-debug.apk` (59,761,663 bytes)
- SHA256: `2755300477cd916fc4693ab159e995ddce9908be620e36345dd0aae520f60536`
- package: `dev.kurukshetra.app`, versionName `0.1.1`, versionCode `2`
