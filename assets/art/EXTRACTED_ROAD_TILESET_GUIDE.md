# Extracted Road Tileset Guide

Source image:

`res://assets/ui/9Byok-H1rlLE0FIZxokJ_.png`

Generated assets:

- `res://assets/tiles/extracted_road_elements_64.png`
- `res://assets/tiles/extracted_road_elements_64.tres`
- `res://assets/art/extracted_road_elements_64_preview.png`

Tile size: `64x64`

Atlas layout: `8 columns x 6 rows`

Main scene TileMap:

`res://scenes/world/city_map.tscn` -> `RoadElementTileMap`

## Tile Rows

Row 0: asphalt, lane markings, diagonal roads, road edges.

Row 1: roundabout pieces and crosswalk pieces.

Row 2: sidewalk, pavement, curb, grass and grass-rock ground.

Row 3: tree patches, puddles, manhole and street lamp.

Row 4: building corner and mixed sidewalk/grass details.

Row 5: road corners, wide asphalt, steps and extra road detail.

## Editing Workflow

Open `city_map.tscn`, select `RoadElementTileMap`, then use the Godot TileMap editor to paint with `extracted_road_elements_64.tres`.

`PixelTileMap` is kept hidden as the old fallback tile layer. The main editable road layer is now `RoadElementTileMap`.
