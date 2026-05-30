# Kurukshetra v0.1.1 — real 3D assets, textured map, proper visuals

**This is a visual-only release. No gameplay changes.** Same netcode, same
match flow, same touch controls as v0.1.0 — just no longer built out of grey
primitives.

## Why

v0.1.0 shipped a fully playable MVP but rendered with placeholder geometry:
grey capsule players, untextured planes, stub weapon boxes. Rohan flagged the
visual quality. v0.1.1 replaces every placeholder with **CC0 Kenney assets**
per **ADR 0009 (now ratified, Status: Accepted)** and the import pipeline
documented in **ADR 0011**.

## What changed

- **Player character** — capsule mesh replaced with a real Kenney character
  model (GLB). CharacterBody3D collision shape is unchanged, so gameplay
  collisions, hitboxes, and stance heights behave exactly as before.
- **Weapons** — stub boxes replaced with Kenney FPS Pack weapon meshes
  (pistol, revolver, SMG/MP5, shotgun, sniper) attached at the weapon mount.
- **Ground** — grey 200m plane retextured with a tiled grass/dirt material.
- **Props / cover** — barrels and crates from the Kenney Survival Kit placed
  across the map as StaticBody3D cover with collision shapes.
- **Sky + lighting** — `WorldEnvironment` with a CC0 dawn skybox, tuned
  `DirectionalLight3D` sun, and light distance fog for a "battle royale dawn"
  feel.

## Assets & licensing

Every asset is **CC0** (Kenney). Full source list, license, and SHA256 hashes
are in `ATTRIBUTIONS.md`. No paid assets. No gameplay-affecting changes.

## Validation

- Godot 4.3 headless reimport: clean, no errors.
- 3-process local multiplayer smoke test (1 server + 2 clients): clean spawn,
  peer connect, no script errors.
- APK: built, debug-signed, `aapt` badging validated; `classes.dex` +
  `lib/arm64-v8a/libgodot_android.so` present.

## Install

Sideload `kurukshetra-debug.apk` (debug-signed, per ADR 0010). Uninstall the
v0.1.0 build first if signatures differ.
