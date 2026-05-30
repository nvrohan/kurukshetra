# Attributions

Kurukshetra ships only assets under **CC0** or **CC-BY**. This file is the
authoritative manifest of every third-party asset in the repo, with source,
license, and attribution required by the original creator.

> **Hard rule:** any file in `assets/`, `maps/`, or `resources/` that has no
> entry below MUST fail the CI attribution check. See
> `tools/build_attributions.py` (deliverable 3+).

The MVP asset budget is documented in `docs/ARCHITECTURE.md` §5.

## v0.1.1 status

v0.1.1 imports the first batch of CC0 3D content. Per ADR 0011 the chosen
upstream is **OpenGameArt.org + Poly Haven + ambientCG** (Kenney's `kenney.nl`
asset pages JS-load their download links and are not curl-reachable from a
headless cron worker — the CDN URLs are not exposed in HTML; OGA + ambientCG
expose direct attachment URLs, and that's what made v0.1.1 actually buildable).

| File | License | Author | Source | SHA256 (upstream zip) |
|---|---|---|---|---|
| `icon.svg` | CC0 | Kurukshetra contributors | Drawn for this project | — |
| `assets/models/characters/character{1..5}.glb` | CC0 | PS Tech (OGA) | https://opengameart.org/content/10x-blocky-character-bundle (`character-bundle.zip` → `character.zip`) | `79b150f220b9b0272a483f5dfd851d7ddb23fdce23b0d2617126ecb7bd2823f8` |
| `assets/models/weapons/{pistol-coonan,smg-mp5,sniper,shotgun,revolver-python}.{obj,mtl}` | CC0 | Bonsaiheldin (OGA) | https://opengameart.org/content/3d-weapons-pack (`weapons_pack_guns_0.zip`) | `ba1cd7d2061184eee2a6412fccc5d6b809bb526e42f617e92f28de0c92f2e7ba` |
| `assets/models/props/{barrel_mesh,crate_mesh}.obj` + PNGs | CC0 | rubberduck (OGA) | https://opengameart.org/content/crate-barrel-bundle (`crate&barrel.zip`) | `ba001a1908c7bb2244276ce4d28d2e8183bd6f28885428a30c5d1412cadfc706` |
| `assets/textures/ground/grass_*.jpg` | CC0 | ambientCG | https://ambientcg.com/view?id=Grass001 (`Grass001_1K-JPG.zip`) | `902f447a64171c8099589642d5bf2d1d6e52c40e94d957eb78eae722084b0cfb` |
| `assets/textures/skybox/sky_kloofendal_1k.hdr` | CC0 | Greg Zaal (Poly Haven) | https://polyhaven.com/a/kloofendal_48d_partly_cloudy_puresky | `fd94c84997b8a3c353b62c2125a9b44e19509956986a126e472684432a02d798` |

The original zips live in `assets/_downloads/` (gitignored). Only imported
`.glb`, `.obj`, `.mtl`, `.png`, `.jpg`, `.hdr`, and Godot-generated `.import`
sidecars are committed.

## License rules

| License | Allowed? | Attribution required in this file? |
|---|---|---|
| CC0 / Public Domain | Yes | No (we credit anyway as good practice) |
| CC-BY 3.0 / 4.0 | Yes | **Yes** — author + source URL + license URL |
| CC-BY-SA | **No** | — viral copyleft conflicts with MIT codebase + redistribution |
| CC-BY-NC | **No** | — non-commercial blocks Play Store / monetization later |
| CC-BY-ND | **No** | — no-derivatives blocks remixing/retexturing |
| GPL textures/audio | **No** | — keeps repo MIT-clean |
| "Free for personal use" | **No** | — too vague; ambiguous redistribution rights |
| Ripped from PUBG / BGMI / Free Fire / Krafton | **Absolutely no** | — non-negotiable |

## Trusted sources

- **Kenney.nl** — CC0, professional quality, recommended primary.
- **Freesound.org** — CC0 + CC-BY mix; filter to CC0 first.
- **OpenGameArt.org** — CC0 + CC-BY mix; check each asset.
- **ambientCG.com** — CC0 PBR textures.
- **Mixkit** — Free assets but check license per file (some are CC-BY-NC, skip those).

## Attribution format example (for CC-BY assets)

```
| assets/audio/wind_loop.ogg | CC-BY 4.0 | Erokia (freesound.org/people/Erokia) | https://freesound.org/s/123456/ |
```

## Per-file manifest (committed assets)

This section lists every committed file under `assets/` (excluding the
gitignored `assets/_downloads/` originals and `.gdkeep` markers) by its
literal path, so the CI attribution check matches each one. All are **CC0**;
upstream zip SHA256s are in the summary table above. The per-file SHA256
(first 16 hex) is the hash of the committed file.

| File | License | Source | SHA256 (committed file) |
|---|---|---|---|
| `assets/models/characters/character1.glb` | CC0 | OGA — PS Tech, 10x Blocky Character Bundle (CC0) | `2a60bab89de7dc80…` |
| `assets/models/characters/character1.glb.import` | CC0 | OGA — PS Tech, 10x Blocky Character Bundle (CC0) | `956299a14c8f7a6d…` |
| `assets/models/characters/character2.glb` | CC0 | OGA — PS Tech, 10x Blocky Character Bundle (CC0) | `67639e5c04be701d…` |
| `assets/models/characters/character2.glb.import` | CC0 | OGA — PS Tech, 10x Blocky Character Bundle (CC0) | `12aa3c0e448928df…` |
| `assets/models/characters/character3.glb` | CC0 | OGA — PS Tech, 10x Blocky Character Bundle (CC0) | `9a1bc9159c207be6…` |
| `assets/models/characters/character3.glb.import` | CC0 | OGA — PS Tech, 10x Blocky Character Bundle (CC0) | `48d0bdb6042b1baa…` |
| `assets/models/characters/character4.glb` | CC0 | OGA — PS Tech, 10x Blocky Character Bundle (CC0) | `f0918ce01472fc74…` |
| `assets/models/characters/character4.glb.import` | CC0 | OGA — PS Tech, 10x Blocky Character Bundle (CC0) | `68c073a9b10819f1…` |
| `assets/models/characters/character5.glb` | CC0 | OGA — PS Tech, 10x Blocky Character Bundle (CC0) | `1d792219240520b5…` |
| `assets/models/characters/character5.glb.import` | CC0 | OGA — PS Tech, 10x Blocky Character Bundle (CC0) | `e94ecbade07c5a33…` |
| `assets/models/props/barrel_closed.PNG` | CC0 | OGA — rubberduck, Crate & Barrel Bundle (CC0) | `0ac177c463a38132…` |
| `assets/models/props/barrel_closed.PNG.import` | CC0 | OGA — rubberduck, Crate & Barrel Bundle (CC0) | `e9a11b4444233530…` |
| `assets/models/props/barrel_gun_powder.PNG` | CC0 | OGA — rubberduck, Crate & Barrel Bundle (CC0) | `9e8ebf85db8db74f…` |
| `assets/models/props/barrel_gun_powder.PNG.import` | CC0 | OGA — rubberduck, Crate & Barrel Bundle (CC0) | `86ec73883eb7b8de…` |
| `assets/models/props/barrel_mesh.obj` | CC0 | OGA — rubberduck, Crate & Barrel Bundle (CC0) | `946b6fa5cc3fd99a…` |
| `assets/models/props/barrel_mesh.obj.import` | CC0 | OGA — rubberduck, Crate & Barrel Bundle (CC0) | `48f6ec61fbbf7b47…` |
| `assets/models/props/barrel_water.PNG` | CC0 | OGA — rubberduck, Crate & Barrel Bundle (CC0) | `5ef61ff0c0146150…` |
| `assets/models/props/barrel_water.PNG.import` | CC0 | OGA — rubberduck, Crate & Barrel Bundle (CC0) | `254ea9e2e41a080a…` |
| `assets/models/props/crate_diff.PNG` | CC0 | OGA — rubberduck, Crate & Barrel Bundle (CC0) | `2fa93a5387419715…` |
| `assets/models/props/crate_diff.PNG.import` | CC0 | OGA — rubberduck, Crate & Barrel Bundle (CC0) | `55b05446ad1f130b…` |
| `assets/models/props/crate_mesh.obj` | CC0 | OGA — rubberduck, Crate & Barrel Bundle (CC0) | `dc1abd4bb2d04d48…` |
| `assets/models/props/crate_mesh.obj.import` | CC0 | OGA — rubberduck, Crate & Barrel Bundle (CC0) | `b9b361d1bcc46e63…` |
| `assets/models/weapons/pistol-coonan.mtl` | CC0 | OGA — Bonsaiheldin, 3D Weapons Pack (CC0) | `aacaefb48c650124…` |
| `assets/models/weapons/pistol-coonan.obj` | CC0 | OGA — Bonsaiheldin, 3D Weapons Pack (CC0) | `14f748777908643a…` |
| `assets/models/weapons/pistol-coonan.obj.import` | CC0 | OGA — Bonsaiheldin, 3D Weapons Pack (CC0) | `78d4d7914b6424b8…` |
| `assets/models/weapons/revolver-python.mtl` | CC0 | OGA — Bonsaiheldin, 3D Weapons Pack (CC0) | `a90a13ac9b583a36…` |
| `assets/models/weapons/revolver-python.obj` | CC0 | OGA — Bonsaiheldin, 3D Weapons Pack (CC0) | `309995cd7b7e7740…` |
| `assets/models/weapons/revolver-python.obj.import` | CC0 | OGA — Bonsaiheldin, 3D Weapons Pack (CC0) | `0ae292d9d56166d3…` |
| `assets/models/weapons/shotgun.mtl` | CC0 | OGA — Bonsaiheldin, 3D Weapons Pack (CC0) | `57715bea3e52f31e…` |
| `assets/models/weapons/shotgun.obj` | CC0 | OGA — Bonsaiheldin, 3D Weapons Pack (CC0) | `839f8d130bf1e1b6…` |
| `assets/models/weapons/shotgun.obj.import` | CC0 | OGA — Bonsaiheldin, 3D Weapons Pack (CC0) | `44acbd514fb16ff4…` |
| `assets/models/weapons/smg-mp5.mtl` | CC0 | OGA — Bonsaiheldin, 3D Weapons Pack (CC0) | `ca336697aded2cbb…` |
| `assets/models/weapons/smg-mp5.obj` | CC0 | OGA — Bonsaiheldin, 3D Weapons Pack (CC0) | `b36deb68b16ae43e…` |
| `assets/models/weapons/smg-mp5.obj.import` | CC0 | OGA — Bonsaiheldin, 3D Weapons Pack (CC0) | `591023c3311c1115…` |
| `assets/models/weapons/sniper.mtl` | CC0 | OGA — Bonsaiheldin, 3D Weapons Pack (CC0) | `f9daf65fc268eb6c…` |
| `assets/models/weapons/sniper.obj` | CC0 | OGA — Bonsaiheldin, 3D Weapons Pack (CC0) | `f789aca4d7f80f5b…` |
| `assets/models/weapons/sniper.obj.import` | CC0 | OGA — Bonsaiheldin, 3D Weapons Pack (CC0) | `06c2228a36e9901c…` |
| `assets/textures/ground/grass_ao.jpg` | CC0 | ambientCG — Grass001 (CC0) | `a5e6e6a1c4329562…` |
| `assets/textures/ground/grass_ao.jpg.import` | CC0 | ambientCG — Grass001 (CC0) | `531ef61a3bd04906…` |
| `assets/textures/ground/grass_color.jpg` | CC0 | ambientCG — Grass001 (CC0) | `b9b6d61bc3b6137b…` |
| `assets/textures/ground/grass_color.jpg.import` | CC0 | ambientCG — Grass001 (CC0) | `2eff6b7b92157418…` |
| `assets/textures/ground/grass_ground.material.tres` | CC0 | ambientCG — Grass001 (CC0) | `285ccd2caf78716b…` |
| `assets/textures/ground/grass_normal.jpg` | CC0 | ambientCG — Grass001 (CC0) | `eef0b56db5f00a6f…` |
| `assets/textures/ground/grass_normal.jpg.import` | CC0 | ambientCG — Grass001 (CC0) | `f4e33f54e93f79a1…` |
| `assets/textures/ground/grass_roughness.jpg` | CC0 | ambientCG — Grass001 (CC0) | `8810effd44756341…` |
| `assets/textures/ground/grass_roughness.jpg.import` | CC0 | ambientCG — Grass001 (CC0) | `88750ac9adf29e7d…` |
| `assets/textures/skybox/dawn_sky.tres` | CC0 | Poly Haven — Greg Zaal, Kloofendal (CC0) | `939a42b6207412f9…` |
| `assets/textures/skybox/sky_kloofendal_1k.hdr` | CC0 | Poly Haven — Greg Zaal, Kloofendal (CC0) | `fd94c84997b8a3c3…` |
| `assets/textures/skybox/sky_kloofendal_1k.hdr.import` | CC0 | Poly Haven — Greg Zaal, Kloofendal (CC0) | `d550c49b2b76f4c5…` |
