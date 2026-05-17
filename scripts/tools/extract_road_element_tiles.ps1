param(
	[string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path,
	[string]$Source = "assets\ui\9Byok-H1rlLE0FIZxokJ_.png",
	[int]$TileSize = 64
)

$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

$sourcePath = Join-Path $Root $Source
if (-not (Test-Path $sourcePath)) {
	throw "Source image not found: $sourcePath"
}

$tilesDir = Join-Path $Root "assets\tiles"
$artDir = Join-Path $Root "assets\art"
New-Item -ItemType Directory -Force $tilesDir, $artDir | Out-Null

$atlasPath = Join-Path $tilesDir "extracted_road_elements_64.png"
$tileSetPath = Join-Path $tilesDir "extracted_road_elements_64.tres"
$previewPath = Join-Path $artDir "extracted_road_elements_64_preview.png"

$tiles = @(
	@{ Name = "road_asphalt"; X = 474; Y = 172; W = 64; H = 64 },
	@{ Name = "road_dark"; X = 710; Y = 160; W = 64; H = 64 },
	@{ Name = "lane_vertical"; X = 488; Y = 78; W = 64; H = 64 },
	@{ Name = "lane_horizontal"; X = 28; Y = 488; W = 64; H = 64 },
	@{ Name = "diagonal_road_left"; X = 92; Y = 150; W = 96; H = 96 },
	@{ Name = "diagonal_road_right"; X = 830; Y = 150; W = 96; H = 96 },
	@{ Name = "road_edge_left"; X = 388; Y = 306; W = 64; H = 64 },
	@{ Name = "road_edge_right"; X = 594; Y = 306; W = 64; H = 64 },

	@{ Name = "roundabout_nw"; X = 420; Y = 420; W = 128; H = 128 },
	@{ Name = "roundabout_ne"; X = 500; Y = 420; W = 128; H = 128 },
	@{ Name = "roundabout_sw"; X = 420; Y = 500; W = 128; H = 128 },
	@{ Name = "roundabout_se"; X = 500; Y = 500; W = 128; H = 128 },
	@{ Name = "crosswalk_horizontal"; X = 184; Y = 468; W = 96; H = 64 },
	@{ Name = "crosswalk_vertical"; X = 474; Y = 272; W = 96; H = 96 },
	@{ Name = "crosswalk_diagonal_a"; X = 640; Y = 314; W = 96; H = 96 },
	@{ Name = "crosswalk_diagonal_b"; X = 306; Y = 636; W = 96; H = 96 },

	@{ Name = "sidewalk_straight"; X = 740; Y = 386; W = 64; H = 64 },
	@{ Name = "sidewalk_vertical"; X = 520; Y = 0; W = 64; H = 64 },
	@{ Name = "sidewalk_corner"; X = 660; Y = 284; W = 96; H = 96 },
	@{ Name = "curb_corner"; X = 572; Y = 358; W = 96; H = 96 },
	@{ Name = "pavement_square"; X = 602; Y = 0; W = 64; H = 64 },
	@{ Name = "pavement_grass_edge"; X = 694; Y = 56; W = 96; H = 96 },
	@{ Name = "grass_clean"; X = 718; Y = 78; W = 64; H = 64 },
	@{ Name = "grass_rocks"; X = 704; Y = 106; W = 96; H = 96 },

	@{ Name = "tree_large"; X = 692; Y = 660; W = 160; H = 160 },
	@{ Name = "tree_small"; X = 58; Y = 660; W = 128; H = 128 },
	@{ Name = "tree_shadow"; X = 788; Y = 230; W = 128; H = 128 },
	@{ Name = "grass_tree_base"; X = 796; Y = 382; W = 128; H = 128 },
	@{ Name = "puddle_large"; X = 136; Y = 194; W = 96; H = 96 },
	@{ Name = "puddle_small"; X = 836; Y = 706; W = 96; H = 96 },
	@{ Name = "manhole"; X = 580; Y = 358; W = 80; H = 80 },
	@{ Name = "street_lamp"; X = 398; Y = 138; W = 96; H = 96 },

	@{ Name = "building_corner_a"; X = 96; Y = 852; W = 160; H = 160 },
	@{ Name = "building_corner_b"; X = 768; Y = 850; W = 160; H = 160 },
	@{ Name = "building_wall_a"; X = 168; Y = 0; W = 128; H = 128 },
	@{ Name = "building_wall_b"; X = 704; Y = 0; W = 128; H = 128 },
	@{ Name = "sidewalk_with_shadow"; X = 0; Y = 380; W = 128; H = 96 },
	@{ Name = "grass_island"; X = 0; Y = 210; W = 128; H = 128 },
	@{ Name = "road_mark_arrow_like"; X = 488; Y = 704; W = 96; H = 96 },
	@{ Name = "lane_dash_diagonal"; X = 722; Y = 646; W = 96; H = 96 },

	@{ Name = "road_corner_nw"; X = 348; Y = 276; W = 128; H = 128 },
	@{ Name = "road_corner_ne"; X = 560; Y = 276; W = 128; H = 128 },
	@{ Name = "road_corner_sw"; X = 348; Y = 596; W = 128; H = 128 },
	@{ Name = "road_corner_se"; X = 560; Y = 596; W = 128; H = 128 },
	@{ Name = "wide_asphalt"; X = 470; Y = 610; W = 64; H = 64 },
	@{ Name = "sidewalk_steps"; X = 590; Y = 792; W = 96; H = 96 },
	@{ Name = "grass_sidewalk_mix"; X = 792; Y = 500; W = 128; H = 128 },
	@{ Name = "road_paint_detail"; X = 906; Y = 500; W = 96; H = 96 }
)

$columns = 8
$rows = [int][Math]::Ceiling($tiles.Count / $columns)
$atlas = New-Object System.Drawing.Bitmap ($columns * $TileSize), ($rows * $TileSize), ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$sourceImage = [System.Drawing.Image]::FromFile($sourcePath)

try {
	$atlas.SetResolution(192, 192)
	$graphics = [System.Drawing.Graphics]::FromImage($atlas)
	try {
		$graphics.Clear([System.Drawing.Color]::Transparent)
		$graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
		$graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half

		for ($i = 0; $i -lt $tiles.Count; $i++) {
			$tile = $tiles[$i]
			$col = $i % $columns
			$row = [int][Math]::Floor($i / $columns)
			$srcRect = New-Object System.Drawing.Rectangle $tile.X, $tile.Y, $tile.W, $tile.H
			$dstRect = New-Object System.Drawing.Rectangle ($col * $TileSize), ($row * $TileSize), $TileSize, $TileSize
			$graphics.DrawImage($sourceImage, $dstRect, $srcRect, [System.Drawing.GraphicsUnit]::Pixel)
		}
	} finally {
		$graphics.Dispose()
	}

	$atlas.Save($atlasPath, [System.Drawing.Imaging.ImageFormat]::Png)

	$preview = New-Object System.Drawing.Bitmap $atlas.Width, $atlas.Height, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
	try {
		$previewGraphics = [System.Drawing.Graphics]::FromImage($preview)
		try {
			$previewGraphics.DrawImage($atlas, 0, 0, $atlas.Width, $atlas.Height)
			$pen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(180, 255, 220, 80)), 2
			try {
				for ($x = 0; $x -le $atlas.Width; $x += $TileSize) {
					$previewGraphics.DrawLine($pen, $x, 0, $x, $atlas.Height)
				}
				for ($y = 0; $y -le $atlas.Height; $y += $TileSize) {
					$previewGraphics.DrawLine($pen, 0, $y, $atlas.Width, $y)
				}
			} finally {
				$pen.Dispose()
			}
		} finally {
			$previewGraphics.Dispose()
		}
		$preview.Save($previewPath, [System.Drawing.Imaging.ImageFormat]::Png)
	} finally {
		$preview.Dispose()
	}

	$lines = New-Object System.Collections.Generic.List[string]
	$lines.Add('[gd_resource type="TileSet" format=3 uid="uid://c4ignabjgakp8"]')
	$lines.Add('')
	$lines.Add('[ext_resource type="Texture2D" path="res://assets/tiles/extracted_road_elements_64.png" id="1_tiles"]')
	$lines.Add('')
	$lines.Add('[sub_resource type="TileSetAtlasSource" id="TileSetAtlasSource_extracted_road_elements"]')
	$lines.Add('texture = ExtResource("1_tiles")')
	$lines.Add("texture_region_size = Vector2i($TileSize, $TileSize)")
	for ($y = 0; $y -lt $rows; $y++) {
		for ($x = 0; $x -lt $columns; $x++) {
			$index = $y * $columns + $x
			if ($index -lt $tiles.Count) {
				$lines.Add("$x`:$y/0 = 0")
			}
		}
	}
	$lines.Add('')
	$lines.Add('[resource]')
	$lines.Add("tile_size = Vector2i($TileSize, $TileSize)")
	$lines.Add('sources/0 = SubResource("TileSetAtlasSource_extracted_road_elements")')

	$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
	[System.IO.File]::WriteAllText($tileSetPath, ($lines -join [Environment]::NewLine) + [Environment]::NewLine, $utf8NoBom)

	Write-Output "atlas=$atlasPath"
	Write-Output "tileset=$tileSetPath"
	Write-Output "preview=$previewPath"
	Write-Output "tiles=$($tiles.Count)"
	Write-Output "grid=${columns}x${rows}"
} finally {
	$sourceImage.Dispose()
	$atlas.Dispose()
}
