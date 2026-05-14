param(
	[string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
)

$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

function New-Bitmap {
	param([int]$Width, [int]$Height)
	$bitmap = New-Object System.Drawing.Bitmap $Width, $Height, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
	$bitmap.SetResolution(96, 96)
	return $bitmap
}

function Color-Hex {
	param([string]$Hex)
	$hexValue = $Hex.TrimStart("#")
	$a = 255
	if ($hexValue.Length -eq 8) {
		$a = [Convert]::ToInt32($hexValue.Substring(0, 2), 16)
		$r = [Convert]::ToInt32($hexValue.Substring(2, 2), 16)
		$g = [Convert]::ToInt32($hexValue.Substring(4, 2), 16)
		$b = [Convert]::ToInt32($hexValue.Substring(6, 2), 16)
	} else {
		$r = [Convert]::ToInt32($hexValue.Substring(0, 2), 16)
		$g = [Convert]::ToInt32($hexValue.Substring(2, 2), 16)
		$b = [Convert]::ToInt32($hexValue.Substring(4, 2), 16)
	}
	return [System.Drawing.Color]::FromArgb($a, $r, $g, $b)
}

function Set-PixelSafe {
	param($Bitmap, [int]$X, [int]$Y, $Color)
	if ($X -ge 0 -and $Y -ge 0 -and $X -lt $Bitmap.Width -and $Y -lt $Bitmap.Height) {
		$Bitmap.SetPixel($X, $Y, $Color)
	}
}

function Fill-Rect {
	param($Bitmap, [int]$X, [int]$Y, [int]$W, [int]$H, [string]$Color)
	$c = Color-Hex $Color
	for ($py = $Y; $py -lt $Y + $H; $py++) {
		for ($px = $X; $px -lt $X + $W; $px++) {
			Set-PixelSafe $Bitmap $px $py $c
		}
	}
}

function Stroke-Rect {
	param($Bitmap, [int]$X, [int]$Y, [int]$W, [int]$H, [string]$Color)
	$c = Color-Hex $Color
	for ($px = $X; $px -lt $X + $W; $px++) {
		Set-PixelSafe $Bitmap $px $Y $c
		Set-PixelSafe $Bitmap $px ($Y + $H - 1) $c
	}
	for ($py = $Y; $py -lt $Y + $H; $py++) {
		Set-PixelSafe $Bitmap $X $py $c
		Set-PixelSafe $Bitmap ($X + $W - 1) $py $c
	}
}

function Fill-Tile {
	param($Bitmap, [int]$TileX, [int]$TileY, [string]$Base, [string]$Accent)
	$x0 = $TileX * 16
	$y0 = $TileY * 16
	$baseColor = Color-Hex $Base
	$accentColor = Color-Hex $Accent
	for ($y = 0; $y -lt 16; $y++) {
		for ($x = 0; $x -lt 16; $x++) {
			$color = $baseColor
			if ((($x + $y) % 7 -eq 0) -or (($x * 3 + $y * 5) % 19 -eq 0)) {
				$color = $accentColor
			}
			Set-PixelSafe $Bitmap ($x0 + $x) ($y0 + $y) $color
		}
	}
}

function Draw-Window {
	param($Bitmap, [int]$X, [int]$Y, [string]$Light = "#efc36f", [string]$Frame = "#4c4a44")
	Fill-Rect $Bitmap $X $Y 10 10 $Frame
	Fill-Rect $Bitmap ($X + 2) ($Y + 2) 6 6 $Light
	Set-PixelSafe $Bitmap ($X + 5) ($Y + 2) (Color-Hex $Frame)
	Set-PixelSafe $Bitmap ($X + 5) ($Y + 3) (Color-Hex $Frame)
	Set-PixelSafe $Bitmap ($X + 5) ($Y + 4) (Color-Hex $Frame)
	Set-PixelSafe $Bitmap ($X + 5) ($Y + 5) (Color-Hex $Frame)
	Set-PixelSafe $Bitmap ($X + 5) ($Y + 6) (Color-Hex $Frame)
	Set-PixelSafe $Bitmap ($X + 5) ($Y + 7) (Color-Hex $Frame)
}

function Draw-Scooter {
	param($Bitmap, [int]$X, [int]$Y, [string]$Body = "#e5bd3f")
	Fill-Rect $Bitmap ($X + 3) ($Y + 12) 22 5 $Body
	Fill-Rect $Bitmap ($X + 14) ($Y + 7) 8 7 $Body
	Fill-Rect $Bitmap ($X + 23) ($Y + 6) 3 5 "#26313d"
	Fill-Rect $Bitmap ($X + 4) ($Y + 10) 6 3 "#26313d"
	Fill-Rect $Bitmap ($X + 5) ($Y + 17) 5 5 "#20252b"
	Fill-Rect $Bitmap ($X + 21) ($Y + 17) 5 5 "#20252b"
	Fill-Rect $Bitmap ($X + 6) ($Y + 18) 3 3 "#56606a"
	Fill-Rect $Bitmap ($X + 22) ($Y + 18) 3 3 "#56606a"
}

function Draw-RiderBag {
	param($Bitmap, [int]$X, [int]$Y)
	Fill-Rect $Bitmap ($X + 5) ($Y + 5) 22 20 "#e7c23e"
	Stroke-Rect $Bitmap ($X + 5) ($Y + 5) 22 20 "#7a5d23"
	Fill-Rect $Bitmap ($X + 9) ($Y + 10) 14 3 "#5d4a28"
	Fill-Rect $Bitmap ($X + 9) ($Y + 16) 10 3 "#5d4a28"
}

function Draw-PropCell {
	param($Bitmap, [int]$Col, [int]$Row, [string]$Kind)
	$x = $Col * 32
	$y = $Row * 32
	switch ($Kind) {
		"scooter" { Draw-Scooter $Bitmap $x $y }
		"rider_bag" { Draw-RiderBag $Bitmap $x $y }
		"vending_machine" {
			Fill-Rect $Bitmap ($x + 7) ($y + 2) 18 28 "#5d7980"
			Stroke-Rect $Bitmap ($x + 7) ($y + 2) 18 28 "#344a50"
			Fill-Rect $Bitmap ($x + 10) ($y + 5) 12 8 "#c8e3dc"
			Fill-Rect $Bitmap ($x + 11) ($y + 16) 5 4 "#e5bd3f"
			Fill-Rect $Bitmap ($x + 17) ($y + 16) 4 4 "#c76b6d"
			Fill-Rect $Bitmap ($x + 20) ($y + 23) 3 4 "#26313d"
		}
		"utility_pole" {
			Fill-Rect $Bitmap ($x + 14) ($y + 3) 4 27 "#5c4d43"
			Fill-Rect $Bitmap ($x + 7) ($y + 7) 18 3 "#5c4d43"
			Fill-Rect $Bitmap ($x + 9) ($y + 11) 3 3 "#29343a"
			Fill-Rect $Bitmap ($x + 20) ($y + 11) 3 3 "#29343a"
			Fill-Rect $Bitmap ($x + 5) ($y + 6) 3 1 "#7d8790"
			Fill-Rect $Bitmap ($x + 24) ($y + 6) 3 1 "#7d8790"
		}
		"ac_unit" {
			Fill-Rect $Bitmap ($x + 4) ($y + 8) 24 14 "#cbd2cb"
			Stroke-Rect $Bitmap ($x + 4) ($y + 8) 24 14 "#717b77"
			for ($i = 0; $i -lt 5; $i++) { Fill-Rect $Bitmap ($x + 8 + $i * 4) ($y + 12) 2 6 "#7b8580" }
			Fill-Rect $Bitmap ($x + 23) ($y + 23) 2 5 "#6d7772"
		}
		"laundry_rack" {
			Fill-Rect $Bitmap ($x + 4) ($y + 9) 24 2 "#d8c8a0"
			Fill-Rect $Bitmap ($x + 5) ($y + 11) 5 9 "#bdd3e0"
			Fill-Rect $Bitmap ($x + 13) ($y + 11) 6 9 "#e08772"
			Fill-Rect $Bitmap ($x + 22) ($y + 11) 5 9 "#f2d77b"
			Fill-Rect $Bitmap ($x + 5) ($y + 20) 2 6 "#6c5a48"
			Fill-Rect $Bitmap ($x + 25) ($y + 20) 2 6 "#6c5a48"
		}
		"food_sign" {
			Fill-Rect $Bitmap ($x + 3) ($y + 7) 26 16 "#a45d45"
			Stroke-Rect $Bitmap ($x + 3) ($y + 7) 26 16 "#793d36"
			Fill-Rect $Bitmap ($x + 7) ($y + 11) 8 3 "#ffe0a3"
			Fill-Rect $Bitmap ($x + 17) ($y + 11) 7 3 "#ffe0a3"
			Fill-Rect $Bitmap ($x + 8) ($y + 17) 13 2 "#ffe0a3"
		}
		"metro_sign" {
			Fill-Rect $Bitmap ($x + 4) ($y + 6) 24 18 "#4d5d70"
			Stroke-Rect $Bitmap ($x + 4) ($y + 6) 24 18 "#2f3d4f"
			Fill-Rect $Bitmap ($x + 8) ($y + 10) 16 3 "#a9d7ff"
			Fill-Rect $Bitmap ($x + 13) ($y + 15) 6 6 "#77b9e8"
		}
		"ring_light" {
			Fill-Rect $Bitmap ($x + 15) ($y + 18) 2 10 "#3d3540"
			Fill-Rect $Bitmap ($x + 10) ($y + 27) 12 2 "#3d3540"
			Fill-Rect $Bitmap ($x + 9) ($y + 5) 14 14 "#ffe0e8"
			Fill-Rect $Bitmap ($x + 12) ($y + 8) 8 8 "#806f7d"
			Fill-Rect $Bitmap ($x + 15) ($y + 11) 2 2 "#ffc4d6"
		}
		"camera" {
			Fill-Rect $Bitmap ($x + 9) ($y + 8) 16 10 "#26313d"
			Fill-Rect $Bitmap ($x + 4) ($y + 10) 6 6 "#3b4650"
			Fill-Rect $Bitmap ($x + 18) ($y + 11) 5 5 "#80c7d5"
			Fill-Rect $Bitmap ($x + 16) ($y + 18) 2 10 "#3d3540"
			Fill-Rect $Bitmap ($x + 9) ($y + 27) 16 2 "#3d3540"
		}
		"product_boxes" {
			Fill-Rect $Bitmap ($x + 5) ($y + 15) 10 10 "#e4c06d"
			Stroke-Rect $Bitmap ($x + 5) ($y + 15) 10 10 "#7a5d23"
			Fill-Rect $Bitmap ($x + 16) ($y + 9) 11 16 "#c76b6d"
			Stroke-Rect $Bitmap ($x + 16) ($y + 9) 11 16 "#75494b"
		}
		"office_desk" {
			Fill-Rect $Bitmap ($x + 4) ($y + 10) 24 14 "#4b4540"
			Stroke-Rect $Bitmap ($x + 4) ($y + 10) 24 14 "#302a27"
			Fill-Rect $Bitmap ($x + 7) ($y + 5) 12 8 "#24313a"
			Fill-Rect $Bitmap ($x + 9) ($y + 7) 8 4 "#9fc6d0"
			Fill-Rect $Bitmap ($x + 21) ($y + 13) 4 7 "#e2d0a4"
		}
		"bed" {
			Fill-Rect $Bitmap ($x + 4) ($y + 8) 24 18 "#5c4b45"
			Fill-Rect $Bitmap ($x + 6) ($y + 10) 20 13 "#b45c62"
			Fill-Rect $Bitmap ($x + 7) ($y + 11) 8 5 "#e3d3b8"
		}
		"fridge" {
			Fill-Rect $Bitmap ($x + 9) ($y + 3) 14 26 "#d7ded5"
			Stroke-Rect $Bitmap ($x + 9) ($y + 3) 14 26 "#7d8783"
			Fill-Rect $Bitmap ($x + 10) ($y + 12) 12 1 "#b4c0ba"
			Fill-Rect $Bitmap ($x + 20) ($y + 15) 1 7 "#6f7c78"
		}
		"rent_notice" {
			Fill-Rect $Bitmap ($x + 7) ($y + 8) 18 14 "#efe0b2"
			Stroke-Rect $Bitmap ($x + 7) ($y + 8) 18 14 "#8a6c42"
			Fill-Rect $Bitmap ($x + 10) ($y + 11) 12 2 "#8a4b42"
			Fill-Rect $Bitmap ($x + 10) ($y + 16) 9 2 "#6c5a48"
		}
	}
}

function Draw-Character {
	param(
		$Bitmap,
		[int]$Col,
		[int]$Row,
		[string]$Shirt,
		[string]$Hair,
		[string]$Skin,
		[string]$Accent,
		[string]$Direction = "down",
		[bool]$Walking = $false
	)
	$x = $Col * 32
	$y = $Row * 32
	$armLift = 0
	$leftFootY = 24
	$rightFootY = 24
	if ($Walking) {
		$armLift = 1
		$leftFootY = 23
		$rightFootY = 25
	}

	Fill-Rect $Bitmap ($x + 10) ($y + $leftFootY) 4 4 "#26313d"
	Fill-Rect $Bitmap ($x + 18) ($y + $rightFootY) 4 4 "#26313d"
	Fill-Rect $Bitmap ($x + 10) ($y + 13) 12 13 $Shirt

	switch ($Direction) {
		"up" {
			Fill-Rect $Bitmap ($x + 9) ($y + 9) 14 8 $Skin
			Fill-Rect $Bitmap ($x + 8) ($y + 4) 16 12 $Hair
			Fill-Rect $Bitmap ($x + 10) ($y + 15) 12 3 $Hair
			Fill-Rect $Bitmap ($x + 7) ($y + 15 + $armLift) 4 9 $Shirt
			Fill-Rect $Bitmap ($x + 21) ($y + 15 - $armLift) 4 9 $Shirt
		}
		"left" {
			Fill-Rect $Bitmap ($x + 9) ($y + 9) 14 8 $Skin
			Fill-Rect $Bitmap ($x + 10) ($y + 4) 12 8 $Hair
			Fill-Rect $Bitmap ($x + 8) ($y + 6) 5 8 $Hair
			Fill-Rect $Bitmap ($x + 11) ($y + 12) 2 1 "#1b1720"
			Fill-Rect $Bitmap ($x + 7) ($y + 15 - $armLift) 4 9 $Shirt
			Fill-Rect $Bitmap ($x + 21) ($y + 15 + $armLift) 4 9 $Shirt
		}
		"right" {
			Fill-Rect $Bitmap ($x + 9) ($y + 9) 14 8 $Skin
			Fill-Rect $Bitmap ($x + 10) ($y + 4) 12 8 $Hair
			Fill-Rect $Bitmap ($x + 19) ($y + 6) 5 8 $Hair
			Fill-Rect $Bitmap ($x + 19) ($y + 12) 2 1 "#1b1720"
			Fill-Rect $Bitmap ($x + 7) ($y + 15 + $armLift) 4 9 $Shirt
			Fill-Rect $Bitmap ($x + 21) ($y + 15 - $armLift) 4 9 $Shirt
		}
		default {
			Fill-Rect $Bitmap ($x + 9) ($y + 9) 14 8 $Skin
			Fill-Rect $Bitmap ($x + 10) ($y + 4) 12 7 $Hair
			Fill-Rect $Bitmap ($x + 9) ($y + 5) 3 5 $Hair
			Fill-Rect $Bitmap ($x + 11) ($y + 12) 2 1 "#1b1720"
			Fill-Rect $Bitmap ($x + 19) ($y + 12) 2 1 "#1b1720"
			Fill-Rect $Bitmap ($x + 7) ($y + 15 + $armLift) 4 9 $Shirt
			Fill-Rect $Bitmap ($x + 21) ($y + 15 - $armLift) 4 9 $Shirt
		}
	}

	if ($Accent -ne "") {
		if ($Direction -eq "left") {
			Fill-Rect $Bitmap ($x + 6) ($y + 17) 5 8 $Accent
			Stroke-Rect $Bitmap ($x + 6) ($y + 17) 5 8 "#4a3d32"
		} else {
			Fill-Rect $Bitmap ($x + 22) ($y + 17) 5 8 $Accent
			Stroke-Rect $Bitmap ($x + 22) ($y + 17) 5 8 "#4a3d32"
		}
	}
}

$tilesDir = Join-Path $Root "assets\tiles"
$spritesDir = Join-Path $Root "assets\sprites"
$uiDir = Join-Path $Root "assets\ui"
$artDir = Join-Path $Root "assets\art"
New-Item -ItemType Directory -Force $tilesDir, $spritesDir, $uiDir, $artDir | Out-Null

$tileAtlas = New-Bitmap 128 64
$tiles = @(
	@("old_concrete", "#737267", "#66645b"),
	@("wet_asphalt", "#4a4f55", "#3e4349"),
	@("aged_floor", "#8a806a", "#77705d"),
	@("rain_puddle", "#516a72", "#384d57"),
	@("alley_patch", "#65685d", "#5a5c52"),
	@("office_tile", "#7d8588", "#697176"),
	@("rental_floor", "#9b8971", "#7f6f5a"),
	@("media_floor", "#806f7d", "#675666"),
	@("metro_tile", "#536577", "#405062"),
	@("warm_wall", "#8e6d58", "#6d5046"),
	@("store_wall", "#6d8d83", "#3d635f"),
	@("restaurant_wall", "#a45d45", "#793d36"),
	@("delivery_wall", "#6f7653", "#4d5738"),
	@("media_wall", "#7b647f", "#58445f"),
	@("night_window", "#efc36f", "#c08d48"),
	@("rain_overlay", "#7d96a6", "#5d7483")
)
$tileManifest = @()
for ($i = 0; $i -lt $tiles.Count; $i++) {
	$col = $i % 8
	$row = [Math]::Floor($i / 8)
	Fill-Tile $tileAtlas $col $row $tiles[$i][1] $tiles[$i][2]
	$tileManifest += [ordered]@{ name = $tiles[$i][0]; x = $col * 16; y = $row * 16; w = 16; h = 16 }
}
$tileAtlas.Save((Join-Path $tilesDir "urban_life_tileset.png"), [System.Drawing.Imaging.ImageFormat]::Png)
$tileAtlas.Dispose()

$propAtlas = New-Bitmap 256 128
$props = @(
	"scooter", "rider_bag", "vending_machine", "utility_pole", "ac_unit", "laundry_rack", "food_sign", "metro_sign",
	"ring_light", "camera", "product_boxes", "office_desk", "bed", "fridge", "rent_notice", "scooter"
)
$propManifest = @()
for ($i = 0; $i -lt $props.Count; $i++) {
	$col = $i % 8
	$row = [Math]::Floor($i / 8)
	Draw-PropCell $propAtlas $col $row $props[$i]
	$propManifest += [ordered]@{ name = $props[$i]; x = $col * 32; y = $row * 32; w = 32; h = 32 }
}
$propAtlas.Save((Join-Path $spritesDir "urban_props_atlas.png"), [System.Drawing.Imaging.ImageFormat]::Png)
$propAtlas.Dispose()

$characterAtlas = New-Bitmap 256 256
$characters = @(
	@("player_grad", "#4f6f88", "#2b2527", "#d7a778", ""),
	@("landlord", "#8d7560", "#3a3029", "#c49167", "#b68b55"),
	@("shopkeeper", "#3f806f", "#25262b", "#d6a373", ""),
	@("drifter_girl", "#c55b70", "#241b22", "#d8a17b", "#e4c06d"),
	@("delivery_rider", "#e5bd3f", "#26313d", "#d6a373", "#e5bd3f"),
	@("office_worker", "#5d6870", "#24292f", "#d6a373", "#6f8393"),
	@("streamer", "#c26c74", "#2b2527", "#d8a17b", "#ffc4d6"),
	@("metro_commuter", "#6b7280", "#3b302b", "#c49167", "#2f5d45")
)
$characterManifest = @()
$characterDirections = @("down", "up", "left", "right")
for ($i = 0; $i -lt $characters.Count; $i++) {
	$frames = [ordered]@{}
	for ($directionIndex = 0; $directionIndex -lt $characterDirections.Count; $directionIndex++) {
		$direction = $characterDirections[$directionIndex]
		$idleRow = $directionIndex * 2
		$walkRow = $idleRow + 1
		Draw-Character $characterAtlas $i $idleRow $characters[$i][1] $characters[$i][2] $characters[$i][3] $characters[$i][4] $direction $false
		Draw-Character $characterAtlas $i $walkRow $characters[$i][1] $characters[$i][2] $characters[$i][3] $characters[$i][4] $direction $true
		$frames["${direction}_idle"] = @{ x = $i * 32; y = $idleRow * 32; w = 32; h = 32 }
		$frames["${direction}_walk"] = @{ x = $i * 32; y = $walkRow * 32; w = 32; h = 32 }
	}
	$characterManifest += [ordered]@{ name = $characters[$i][0]; frames = $frames }
}
$characterAtlas.Save((Join-Path $spritesDir "characters_atlas.png"), [System.Drawing.Imaging.ImageFormat]::Png)
$characterAtlas.Dispose()

$iconAtlas = New-Bitmap 128 32
$icons = @("money", "energy", "stress", "rent", "weather", "work", "delivery", "stream")
$iconManifest = @()
for ($i = 0; $i -lt $icons.Count; $i++) {
	$x = $i * 16
	Fill-Rect $iconAtlas ($x + 2) 2 12 12 "#f3dca2"
	Stroke-Rect $iconAtlas ($x + 2) 2 12 12 "#7f5d3c"
	switch ($icons[$i]) {
		"money" { Fill-Rect $iconAtlas ($x + 5) 5 6 2 "#2f5d45"; Fill-Rect $iconAtlas ($x + 5) 9 6 2 "#2f5d45" }
		"energy" { Fill-Rect $iconAtlas ($x + 7) 4 3 8 "#e5bd3f"; Fill-Rect $iconAtlas ($x + 5) 8 7 2 "#e5bd3f" }
		"stress" { Fill-Rect $iconAtlas ($x + 5) 5 7 2 "#8a4b42"; Fill-Rect $iconAtlas ($x + 7) 8 3 4 "#8a4b42" }
		"rent" { Fill-Rect $iconAtlas ($x + 4) 6 8 6 "#8e6d58"; Fill-Rect $iconAtlas ($x + 6) 9 4 3 "#493c37" }
		"weather" { Fill-Rect $iconAtlas ($x + 4) 6 8 3 "#53666f"; Fill-Rect $iconAtlas ($x + 5) 10 1 3 "#7d96a6"; Fill-Rect $iconAtlas ($x + 9) 10 1 3 "#7d96a6" }
		"work" { Fill-Rect $iconAtlas ($x + 4) 6 8 6 "#697985"; Fill-Rect $iconAtlas ($x + 6) 4 4 2 "#697985" }
		"delivery" { Fill-Rect $iconAtlas ($x + 3) 8 10 3 "#e5bd3f"; Fill-Rect $iconAtlas ($x + 4) 11 2 2 "#26313d"; Fill-Rect $iconAtlas ($x + 10) 11 2 2 "#26313d" }
		"stream" { Fill-Rect $iconAtlas ($x + 5) 5 6 6 "#ffc4d6"; Fill-Rect $iconAtlas ($x + 7) 7 2 2 "#806f7d" }
	}
	$iconManifest += [ordered]@{ name = $icons[$i]; x = $x; y = 0; w = 16; h = 16 }
}
$iconAtlas.Save((Join-Path $uiDir "hud_icons.png"), [System.Drawing.Imaging.ImageFormat]::Png)
$iconAtlas.Dispose()

$manifest = [ordered]@{
	palette = [ordered]@{
		warm_gray = "#737267"
		muted_blue = "#536577"
		faded_green = "#6d8d83"
		tungsten_yellow = "#efc36f"
		rainy_asphalt = "#4a4f55"
		aged_concrete = "#8a806a"
		media_neon = "#ffc4d6"
		delivery_yellow = "#e5bd3f"
	}
	atlases = [ordered]@{
		tiles = "res://assets/tiles/urban_life_tileset.png"
		props = "res://assets/sprites/urban_props_atlas.png"
		characters = "res://assets/sprites/characters_atlas.png"
		icons = "res://assets/ui/hud_icons.png"
	}
	tile_regions = $tileManifest
	prop_regions = $propManifest
	character_regions = $characterManifest
	icon_regions = $iconManifest
	usage_notes = @(
		"Use nearest-neighbor filtering and 1x/2x scale only.",
		"Keep neon accents sparse; use tungsten yellow and rainy blue as the primary mood colors.",
		"These assets are intentionally atlas-based so city_map, apartment, office, delivery station, media company, HUD, and NPCs can share them."
	)
}

$manifestJson = $manifest | ConvertTo-Json -Depth 8
[System.IO.File]::WriteAllText((Join-Path $artDir "asset_manifest.json"), $manifestJson, [System.Text.Encoding]::UTF8)

$guide = @"
# Shanghai Urban Life Art Assets

Generated by ``scripts/tools/generate_pixel_art_assets.ps1``.

## Atlases

- ``res://assets/tiles/urban_life_tileset.png``: reusable 16x16 ground/wall tiles for street, apartment, office, metro, delivery station, and media company.
- ``res://assets/sprites/urban_props_atlas.png``: 32x32 props including scooters, rider bags, vending machine, AC unit, laundry rack, signs, ring light, camera, boxes, desk, bed, fridge, and rent notice.
- ``res://assets/sprites/characters_atlas.png``: 32x32 character sprite bases for player, landlord, shopkeeper, drifter girl, delivery rider, office worker, streamer, and metro commuter. Rows are down idle/walk, up idle/walk, left idle/walk, and right idle/walk.
- ``res://assets/ui/hud_icons.png``: compact 16x16 HUD icons for money, energy, stress, rent, weather, work, delivery, and stream.

## Art Direction

The batch follows the project-local art director skill: grounded modern Shanghai, warm gray, muted blue, faded green, tungsten yellow, rainy asphalt, aged concrete, sparse neon, top-down readability, and lived-in economic pressure.

## Reuse Strategy

Prefer reusing the same atlas regions across scenes:

- Rental room: aged floor, warm wall, bed, fridge, rent notice, laundry rack.
- Street: old concrete, wet asphalt, alley patch, scooters, vending machine, utility pole, AC unit.
- Restaurant and delivery loop: restaurant wall, food sign, rider bag, scooter.
- Office: office tile, office desk, muted blue windows.
- Media company: media floor/wall, ring light, camera, product boxes, streamer sprite.
- HUD: use icons only if/when the HUD switches from text-only to icon-assisted status.
"@
[System.IO.File]::WriteAllText((Join-Path $artDir "ART_ASSET_GUIDE.md"), $guide, [System.Text.Encoding]::UTF8)

Write-Host "Generated pixel art assets under $Root\assets"
