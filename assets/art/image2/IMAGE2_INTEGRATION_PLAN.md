# Image2 Integration Plan

This plan maps existing demo resources to high-quality Image2 replacement assets.

## Current Resource Map

| Current asset | Current use | Replacement target |
| --- | --- | --- |
| `res://assets/tiles/apartment_hd_tileset.png` | Editable apartment TileMap | `res://assets/art/image2/godot/apartment_tileset_v1.png` |
| `res://assets/sprites/apartment_hd_props.png` | Apartment furniture props | `res://assets/art/image2/godot/apartment_props_v1.png` |
| `res://assets/tiles/urban_life_tileset.png` | Street, office, metro, media, market base tiles | `res://assets/art/image2/godot/urban_tileset_v1.png` |
| `res://assets/sprites/urban_props_atlas.png` | Shared city props | `res://assets/art/image2/godot/urban_props_v1.png` |
| `res://assets/sprites/characters_atlas.png` | Player and NPC sprites | `res://assets/art/image2/godot/characters_v1.png` |
| `res://assets/ui/hud_icons.png` | HUD and phone icons | `res://assets/art/image2/godot/hud_icons_v1.png` |

## First Production Batch

Start with the Apartment Interior Pack because:

- It is isolated and easy to verify.
- It already has `apartment_interior.tscn` and a visible `ApartmentTileMap`.
- The player sees the room often for sleep, fridge, rent, and survival pressure.

Deliverables:

- `apartment_tileset_v1.png`: 8 columns x 4 rows, 64x64 cells, 512x256 total.
- `apartment_props_v1.png`: 4 columns x 3 rows, 128x128 cells, 512x384 total.
- `apartment_room_concept_v1.png`: 1536x1024 or 2048x1152 reference composition for judging mood.

## Image2 Workflow

1. Generate concept image first.
2. Generate tileset-compatible version from the concept prompt.
3. Generate prop atlas on a flat transparent-safe background or clean solid matte.
4. Inspect readability at game scale.
5. Save selected outputs into `assets/art/image2/outputs`.
6. Post-process or crop into `assets/art/image2/godot`.
7. Swap the Godot TileSet/atlas references only after the asset passes readability.

## Godot Swap Strategy

For the apartment pack:

- Duplicate `assets/tiles/apartment_hd_tileset.tres` to a new TileSet resource when the Image2 tileset is ready.
- Point `scenes/world/apartment_interior.tscn` `ApartmentTileMap.tile_set` to the new TileSet.
- Keep `scripts/world/apartment_interior.gd` prop drawing regions unchanged if the atlas layout stays 4x3 and 128x128.

## Acceptance Checklist

- Top-down or three-quarter top-down perspective is consistent.
- Edges tile cleanly enough for floors/walls.
- Important interaction objects are recognizable at 640x360 viewport.
- No readable accidental text, logos, watermarks, or brand marks.
- Palette matches the art bible.
- No cyberpunk, fantasy, sci-fi, or idol/gacha drift.

