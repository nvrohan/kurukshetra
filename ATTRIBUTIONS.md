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
