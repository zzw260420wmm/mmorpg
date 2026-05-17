# Image2 Tooling

`validate_image2_assets.ps1` checks whether Image2 outputs have the dimensions expected by `assets/art/image2/image2_asset_manifest.json`.

Run:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/tools/image2/validate_image2_assets.ps1
```

Missing files are reported as `[missing]` but do not fail the command. Size mismatches fail the command because they will break atlas slicing or Godot integration.

## Generate with Rehdasu Image2

The Rehdasu GPT-Image-2 endpoint expects the documented JSON fields `model`, `prompt`, and `output_format`, then returns the image at `data[0].b64_json`.

Set `OPENAI_API_KEY` locally, then run:

```powershell
$prompt = "Top-down 2D game concept art for a cramped modern Shanghai rental apartment interior, cheap single bed, old desk with computer, mini fridge, plastic stool, laundry rack, cardboard boxes, peeling wall, soft tungsten night lighting, muted warm gray and faded green palette, grounded slice-of-life anime mood, gameplay-readable layout, cozy but economically pressured, no character, no text, no logo, no watermark, no cyberpunk, no fantasy."
powershell -ExecutionPolicy Bypass -File scripts/tools/image2/generate_rehdasu_image2.ps1 -Prompt $prompt -OutFile assets/art/image2/outputs/apartment_room_concept_v1.png
```

If the remote Image2 service is unavailable, generate guaranteed local apartment assets:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/tools/image2/generate_guaranteed_apartment_assets.ps1
```

## Apply apartment assets

When Image2 apartment outputs are ready, create a Godot TileSet resource:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/tools/image2/apply_apartment_image2_assets.ps1
```

Then open `res://scenes/world/apartment_interior.tscn`, select `ApartmentTileMap`, and set its TileSet to `res://assets/art/image2/godot/apartment_tileset_v1.tres`.

Apartment props are automatically picked up at runtime if `res://assets/art/image2/godot/apartment_props_v1.png` exists and keeps the documented 4x3 atlas layout.
