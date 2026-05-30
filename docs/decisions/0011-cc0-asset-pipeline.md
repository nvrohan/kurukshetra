# ADR 0011 — CC0 asset pipeline (OpenGameArt + Poly Haven + ambientCG)

Date: 2026-05-30
Status: Accepted
Deciders: nvrohan (standing approval — ADR 0007), kurukshetra-autonomous-build cron

## Context

ADR 0009 documented why v0.1 shipped with placeholder geometry: Kenney.nl's
asset pages JS-load their download links and the cron worker can't drive a
real browser. Rohan saw v0.1.0 screenshots, called the visuals "crude grey
primitives" and asked for a v0.1.1 visual pass.

The cron has to pick CC0 sources whose download URLs are present in raw HTML
(or in a JSON/REST API) — no JS, no session tokens, no captchas — so that
`curl` from a headless cron tick can pull them.

## Decision

Adopt **a three-source CC0 pipeline** and document it here so future ticks
don't re-litigate it:

1. **OpenGameArt.org** — Drupal-rendered HTML exposes file attachments as
   plain `<a href="https://opengameart.org/sites/default/files/<name>.zip">`
   inside the asset page. `curl -sL <page>` then `grep -oE` the file links.
   License is shown inline (`license-name'>CC0`) so a single page fetch
   yields both the URL and the license check.
2. **ambientCG.com** — `https://ambientcg.com/get?file=<AssetName>_<Res>-<Fmt>.zip`
   302-redirects to the `acg-download.struffelproductions.com` CDN with the
   binary. URL pattern is stable and predictable. CC0 by site policy.
3. **Poly Haven** — REST API at `https://api.polyhaven.com/files/<asset_id>`
   returns a JSON tree with direct CDN URLs for every resolution + format.
   CC0 by site policy. HDRIs are ideal for `WorldEnvironment` skybox.

Kenney.nl is **not abandoned** — if a future tick can prove a stable direct
URL it's free to add to the rotation. But the cron worker won't burn whole
ticks on Kenney's JS gate any more. Quaternius via `kirbycope/godot-quaternius`
was also evaluated and rejected: that repo only commits READMEs (it
expects the user to download the source zip from quaternius.com manually
and copy files in), so it can't be a curl-reachable upstream either.

## Pipeline (per asset)

```
1. curl -sL <opengameart-page> -o /tmp/page.html
2. zip_url=$(grep -oE 'href="https://opengameart[.]org/sites/default/files/[^"]+\.zip"' /tmp/page.html | head -1 | cut -d'"' -f2)
3. license=$(grep -oE "license-name'>[A-Z0-9 .-]+" /tmp/page.html | head -1)
4. assert "$license" matches CC0 or CC-BY (reject CC-BY-SA / CC-BY-NC / CC-BY-ND)
5. curl -sL "$zip_url" -o assets/_downloads/<name>.zip
6. sha256sum assets/_downloads/<name>.zip   # record in ATTRIBUTIONS.md
7. unzip into assets/_downloads/extracted/<name>/
8. cp the .glb / .obj / .mtl / textures into assets/{models,textures}/<category>/
9. Run `godot --headless --import` so .import sidecars are written
10. Add row to ATTRIBUTIONS.md (file path, license, author, source URL, sha256)
```

The raw zips and `extracted/` tree stay under `assets/_downloads/` which is
gitignored (see `.gitignore` "v0.1.1 — raw asset zips" rule). Only imported
files used by scenes are committed.

## v0.1.1 batch

| Asset | Source | License | What it replaces |
|---|---|---|---|
| 5× blocky humanoid GLBs (`character{1..5}.glb`) | OGA `10x-blocky-character-bundle` | CC0 | `CapsuleMesh` in `scenes/player.tscn` |
| 5× weapon OBJs (pistol, SMG, sniper, shotgun, revolver) | OGA `3d-weapons-pack` | CC0 | The empty `Weapon` Marker3D in `player.tscn` |
| Crate + barrel OBJs with diffuse PNGs | OGA `crate-barrel-bundle` | CC0 | The 4× `BoxMesh` cover cubes in `scenes/match.tscn` |
| 1K PBR grass texture set (color, normal, roughness, AO) | ambientCG `Grass001_1K-JPG` | CC0 | Flat green ground material |
| 1K HDRI sky (`kloofendal_48d_partly_cloudy_puresky_1k.hdr`) | Poly Haven | CC0 | Empty `WorldEnvironment` (no sky) |

Total committed asset bytes: ≈ 12 MB, well under the 100 MB Android APK budget.

## Consequences

- **APK size grows** from ~46 MB to ~58 MB. Still fine for sideload + GitHub
  Releases (100 MB single-file limit).
- **Headless `--import` pass becomes mandatory** before every export. The
  build script (`tools/build-apk.sh`) already calls `godot --import` once
  before the export step, so this is a no-op.
- **CI attribution check** must verify every committed file under `assets/`
  has a row in `ATTRIBUTIONS.md`. v0.1.1 adds rows for all imported files.
- **OBJ materials are simple Lambert** (no PBR maps in the OGA weapons
  pack). That's fine for v0.1.1 — they're hand-painted vertex colors via
  `.mtl` `Kd` and look distinctly better than untextured BoxMesh stubs. PBR
  weapons can come in v0.2 if Rohan asks.

## Alternatives considered

1. **Procedural meshes in code.** Possible — Godot can build humanoid
   approximations from primitives — but slower than `cp` + `--import`, and
   the result still looks worse than real low-poly art. Rejected.
2. **Sketchfab / Thingiverse / TurboSquid free tiers.** All gated by login
   or non-CC0 license terms. Rejected.
3. **Kenney via a bundle-mirror release on GitHub.** Some exist
   (`iwenzhou/kenney`, `beep2bleep/FreeAssetsByKenneyNLandQuaternius`) but
   their content is 2D / 8-bit / car-themed, not the FPS pack. Rejected.

## Reversal

If we later get reliable Kenney access, this ADR doesn't need reversal —
just append Kenney to the source list and amend the table. The pipeline
shape (`curl → unzip → cp → --import → attribution`) is source-agnostic.
