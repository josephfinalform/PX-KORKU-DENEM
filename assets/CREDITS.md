# Asset sources

Downloaded 2026-10-11. The assets in the following list are released by their publishers under CC0 1.0; no Outlast game assets are used.

- `models/hospital-bed.glb`: Innerscene, Hospital bed flat mattress. https://www.innerscene.com/tools/library/3d-parts/hospital-bed-flat-mattress-44fc9faf — CC0. Original model, real-world dimensions; rotated and recoloured in game.
- Numbered `models/*.glb`: 3DAssets.dev, Hospital Wards and Clinic Operations. https://3dassets.dev/packs/hospital-wards-and-clinic-operations — CC0. Individual identifiers and descriptions in `hospital-manifest.json`. Stylized medical props; recoloured in game. Publisher discloses AI-assisted generation.
- `textures/plaster`: ambientCG, PaintedPlaster017. https://ambientcg.com/view?id=PaintedPlaster017 — CC0. Scanned painted plaster, colour/normal/roughness maps.
- `textures/tiles`: ambientCG, Tiles002. https://ambientcg.com/view?id=Tiles002 — CC0. Tile colour/normal/roughness maps.
- Monster geometry, game layout, scripts, synthetic audio and family portrait: authored for this project.

The numbered GLBs were dequantized to standard float vertex attributes for Godot compatibility; the `.scn` files are generated Godot scene versions of those same models. Original model URLs remain in the manifest.

## User-supplied hospital pack

`user_hospital/` comes from the user's `source.zip`, `textures.zip`, and `ue5_textures.zip`, supplied on 2026-10-11. No author or license document was included in these archives; the CC0 attribution above does not apply to this pack.

The 25 FBX models are preserved under `source/`, standard texture images under `textures/`, and selected packed occlusion/roughness/metallic maps under `ue5/`. The original ZIP files are unchanged. `ready/` contains Godot scenes with matching original UV materials: 14 material sets and 40 shared textures resized to at most 1024 pixels with mipmaps and S3TC compression. Regenerate with `tests/prepare_user_assets.gd`. Raw source directories contain `.gdignore` to avoid redundant imports. The game uses the supplied beds, wheelchairs, cabinets, bench, IV stand and bag, doors, exit sign, lights, walls, floor and ceiling modules. This pack contains no creature model.
