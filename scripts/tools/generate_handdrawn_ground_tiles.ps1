param(
	[string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path,
	[int]$TileSize = 64
)

$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

$tilesDir = Join-Path $Root "assets\tiles"
$artDir = Join-Path $Root "assets\art"
New-Item -ItemType Directory -Force $tilesDir, $artDir | Out-Null

$atlasPath = Join-Path $tilesDir "handdrawn_ground_tiles_64.png"
$tileSetPath = Join-Path $tilesDir "handdrawn_ground_tiles_64.tres"
$previewPath = Join-Path $artDir "handdrawn_ground_tiles_64_preview.png"
$guidePath = Join-Path $artDir "HANDDRAWN_GROUND_TILESET_GUIDE.md"

$TileNames = @(
	"happy_grass",
	"grass_flowers",
	"grass_edge_n",
	"grass_edge_e",
	"grass_edge_s",
	"grass_edge_w",
	"grass_corner_ne",
	"grass_corner_sw",
	"warm_sidewalk",
	"sidewalk_cracked",
	"sidewalk_curb_n",
	"sidewalk_curb_e",
	"sidewalk_curb_s",
	"sidewalk_curb_w",
	"sidewalk_tree_well",
	"sidewalk_manhole",
	"soft_asphalt",
	"wet_asphalt",
	"road_h",
	"road_v",
	"road_cross",
	"road_corner_ne",
	"road_corner_sw",
	"crosswalk",
	"plane_tree",
	"small_tree",
	"shrub",
	"flower_box",
	"rain_puddle",
	"fallen_leaves",
	"bike_lane",
	"curb_ramp"
)

$Columns = 8
$Rows = [int][Math]::Ceiling($TileNames.Count / $Columns)

function Color-Hex {
	param([string]$Hex)
	$value = $Hex.TrimStart("#")
	$a = 255
	if ($value.Length -eq 8) {
		$a = [Convert]::ToInt32($value.Substring(0, 2), 16)
		$r = [Convert]::ToInt32($value.Substring(2, 2), 16)
		$g = [Convert]::ToInt32($value.Substring(4, 2), 16)
		$b = [Convert]::ToInt32($value.Substring(6, 2), 16)
	} else {
		$r = [Convert]::ToInt32($value.Substring(0, 2), 16)
		$g = [Convert]::ToInt32($value.Substring(2, 2), 16)
		$b = [Convert]::ToInt32($value.Substring(4, 2), 16)
	}
	return [System.Drawing.Color]::FromArgb($a, $r, $g, $b)
}

function Tile-Rect {
	param([int]$Index)
	$col = $Index % $Columns
	$row = [int][Math]::Floor($Index / $Columns)
	return New-Object System.Drawing.Rectangle ($col * $TileSize), ($row * $TileSize), $TileSize, $TileSize
}

function Fill {
	param($Graphics, [System.Drawing.Rectangle]$Rect, [string]$Color)
	$brush = New-Object System.Drawing.SolidBrush (Color-Hex $Color)
	try { $Graphics.FillRectangle($brush, $Rect) } finally { $brush.Dispose() }
}

function Ellipse {
	param($Graphics, [System.Drawing.Rectangle]$Rect, [string]$Color)
	$brush = New-Object System.Drawing.SolidBrush (Color-Hex $Color)
	try { $Graphics.FillEllipse($brush, $Rect) } finally { $brush.Dispose() }
}

function Line {
	param($Graphics, [int]$X1, [int]$Y1, [int]$X2, [int]$Y2, [string]$Color, [float]$Width = 2)
	$pen = New-Object System.Drawing.Pen (Color-Hex $Color), $Width
	$pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
	$pen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
	try { $Graphics.DrawLine($pen, $X1, $Y1, $X2, $Y2) } finally { $pen.Dispose() }
}

function Stroke {
	param($Graphics, [System.Drawing.Rectangle]$Rect, [string]$Color, [float]$Width = 2)
	$pen = New-Object System.Drawing.Pen (Color-Hex $Color), $Width
	try { $Graphics.DrawRectangle($pen, $Rect) } finally { $pen.Dispose() }
}

function Draw-Dots {
	param($Graphics, [System.Drawing.Rectangle]$Rect, [string]$Color, [int]$Step = 11, [int]$Size = 2)
	for ($y = $Rect.Top + 5; $y -lt $Rect.Bottom; $y += $Step) {
		for ($x = $Rect.Left + 5; $x -lt $Rect.Right; $x += $Step) {
			if ((($x * 5 + $y * 9) % 7) -lt 3) {
				Fill $Graphics (New-Object System.Drawing.Rectangle $x, $y, $Size, $Size) $Color
			}
		}
	}
}

function Draw-GrassBase {
	param($Graphics, [System.Drawing.Rectangle]$Rect, [string]$Base = "#7fa464")
	Fill $Graphics $Rect $Base
	Draw-Dots $Graphics $Rect "#9db978" 10 2
	Line $Graphics ($Rect.Left + 9) ($Rect.Top + 47) ($Rect.Left + 28) ($Rect.Top + 42) "#668a50" 1
	Line $Graphics ($Rect.Left + 36) ($Rect.Top + 19) ($Rect.Left + 53) ($Rect.Top + 23) "#668a50" 1
}

function Draw-SidewalkBase {
	param($Graphics, [System.Drawing.Rectangle]$Rect)
	Fill $Graphics $Rect "#d8ceb8"
	for ($i = 0; $i -le 64; $i += 16) {
		Line $Graphics ($Rect.Left + $i) $Rect.Top ($Rect.Left + $i) $Rect.Bottom "#bfb49d" 1
		Line $Graphics $Rect.Left ($Rect.Top + $i) $Rect.Right ($Rect.Top + $i) "#bfb49d" 1
	}
	Draw-Dots $Graphics $Rect "#aaa08c" 17 2
}

function Draw-RoadBase {
	param($Graphics, [System.Drawing.Rectangle]$Rect, [string]$Base = "#475154")
	Fill $Graphics $Rect $Base
	Draw-Dots $Graphics $Rect "#5a6669" 12 2
	Line $Graphics ($Rect.Left + 4) ($Rect.Top + 59) ($Rect.Right - 4) ($Rect.Top + 59) "#313a3d" 2
}

function Draw-RoundRect {
	param($Graphics, [System.Drawing.Rectangle]$Rect, [string]$Color)
	$brush = New-Object System.Drawing.SolidBrush (Color-Hex $Color)
	$path = New-Object System.Drawing.Drawing2D.GraphicsPath
	$r = 8
	$path.AddArc($Rect.Left, $Rect.Top, $r, $r, 180, 90)
	$path.AddArc($Rect.Right - $r, $Rect.Top, $r, $r, 270, 90)
	$path.AddArc($Rect.Right - $r, $Rect.Bottom - $r, $r, $r, 0, 90)
	$path.AddArc($Rect.Left, $Rect.Bottom - $r, $r, $r, 90, 90)
	$path.CloseFigure()
	try { $Graphics.FillPath($brush, $path) } finally { $brush.Dispose(); $path.Dispose() }
}

function Rect {
	param([int]$X, [int]$Y, [int]$W, [int]$H)
	return New-Object System.Drawing.Rectangle -ArgumentList $X, $Y, $W, $H
}

function Draw-Tree {
	param($Graphics, [System.Drawing.Rectangle]$Rect, [bool]$Large = $true)
	Draw-GrassBase $Graphics $Rect "#789b60"
	Fill $Graphics (New-Object System.Drawing.Rectangle ($Rect.Left + 29), ($Rect.Top + 34), 8, 22) "#76583f"
	if ($Large) {
		Ellipse $Graphics (New-Object System.Drawing.Rectangle ($Rect.Left + 8), ($Rect.Top + 5), 34, 34) "#5f8f54"
		Ellipse $Graphics (New-Object System.Drawing.Rectangle ($Rect.Left + 22), ($Rect.Top + 2), 34, 36) "#86ad5c"
		Ellipse $Graphics (New-Object System.Drawing.Rectangle ($Rect.Left + 16), ($Rect.Top + 20), 36, 28) "#6f9f57"
	} else {
		Ellipse $Graphics (New-Object System.Drawing.Rectangle ($Rect.Left + 18), ($Rect.Top + 12), 32, 31) "#7fac5b"
		Ellipse $Graphics (New-Object System.Drawing.Rectangle ($Rect.Left + 13), ($Rect.Top + 22), 23, 22) "#638f51"
	}
}

$atlas = New-Object System.Drawing.Bitmap ($Columns * $TileSize), ($Rows * $TileSize), ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
try {
	$atlas.SetResolution(192, 192)
	$graphics = [System.Drawing.Graphics]::FromImage($atlas)
	try {
		$graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
		$graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
		$graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
		$graphics.Clear([System.Drawing.Color]::Transparent)

		for ($i = 0; $i -lt $TileNames.Count; $i++) {
			$r = Tile-Rect $i
			switch ($TileNames[$i]) {
				"happy_grass" { Draw-GrassBase $graphics $r "#83a765" }
				"grass_flowers" { Draw-GrassBase $graphics $r "#86aa69"; Ellipse $graphics (Rect ($r.Left + 13) ($r.Top + 16) 4 4) "#f0d784"; Ellipse $graphics (Rect ($r.Left + 43) ($r.Top + 39) 4 4) "#e9b1a0"; Ellipse $graphics (Rect ($r.Left + 51) ($r.Top + 18) 3 3) "#f0d784" }
				"grass_edge_n" { Draw-SidewalkBase $graphics $r; Fill $graphics (Rect $r.Left $r.Top 64 22) "#83a765"; Draw-Dots $graphics (Rect $r.Left $r.Top 64 22) "#9db978" 10 2 }
				"grass_edge_e" { Draw-SidewalkBase $graphics $r; Fill $graphics (Rect ($r.Left + 42) $r.Top 22 64) "#83a765"; Draw-Dots $graphics (Rect ($r.Left + 42) $r.Top 22 64) "#9db978" 10 2 }
				"grass_edge_s" { Draw-SidewalkBase $graphics $r; Fill $graphics (Rect $r.Left ($r.Top + 42) 64 22) "#83a765"; Draw-Dots $graphics (Rect $r.Left ($r.Top + 42) 64 22) "#9db978" 10 2 }
				"grass_edge_w" { Draw-SidewalkBase $graphics $r; Fill $graphics (Rect $r.Left $r.Top 22 64) "#83a765"; Draw-Dots $graphics (Rect $r.Left $r.Top 22 64) "#9db978" 10 2 }
				"grass_corner_ne" { Draw-SidewalkBase $graphics $r; Fill $graphics (Rect ($r.Left + 36) $r.Top 28 28) "#83a765"; Ellipse $graphics (Rect ($r.Left + 34) ($r.Top - 8) 38 38) "#83a765" }
				"grass_corner_sw" { Draw-SidewalkBase $graphics $r; Fill $graphics (Rect $r.Left ($r.Top + 36) 28 28) "#83a765"; Ellipse $graphics (Rect ($r.Left - 8) ($r.Top + 34) 38 38) "#83a765" }
				"warm_sidewalk" { Draw-SidewalkBase $graphics $r }
				"sidewalk_cracked" { Draw-SidewalkBase $graphics $r; Line $graphics ($r.Left + 12) ($r.Top + 18) ($r.Left + 29) ($r.Top + 27) "#8f8675" 1; Line $graphics ($r.Left + 29) ($r.Top + 27) ($r.Left + 24) ($r.Top + 45) "#8f8675" 1; Line $graphics ($r.Left + 43) ($r.Top + 11) ($r.Left + 52) ($r.Top + 29) "#8f8675" 1 }
				"sidewalk_curb_n" { Draw-SidewalkBase $graphics $r; Fill $graphics (Rect $r.Left $r.Top 64 9) "#eee3c9"; Fill $graphics (Rect $r.Left ($r.Top + 9) 64 5) "#9c9382" }
				"sidewalk_curb_e" { Draw-SidewalkBase $graphics $r; Fill $graphics (Rect ($r.Left + 55) $r.Top 9 64) "#eee3c9"; Fill $graphics (Rect ($r.Left + 50) $r.Top 5 64) "#9c9382" }
				"sidewalk_curb_s" { Draw-SidewalkBase $graphics $r; Fill $graphics (Rect $r.Left ($r.Top + 55) 64 9) "#eee3c9"; Fill $graphics (Rect $r.Left ($r.Top + 50) 64 5) "#9c9382" }
				"sidewalk_curb_w" { Draw-SidewalkBase $graphics $r; Fill $graphics (Rect $r.Left $r.Top 9 64) "#eee3c9"; Fill $graphics (Rect ($r.Left + 9) $r.Top 5 64) "#9c9382" }
				"sidewalk_tree_well" { Draw-SidewalkBase $graphics $r; Draw-RoundRect $graphics (Rect ($r.Left + 16) ($r.Top + 14) 32 34) "#6d8054"; Stroke $graphics (Rect ($r.Left + 16) ($r.Top + 14) 32 34) "#7d735f" 2; Fill $graphics (Rect ($r.Left + 30) ($r.Top + 25) 5 20) "#76583f"; Ellipse $graphics (Rect ($r.Left + 20) ($r.Top + 8) 28 27) "#7fac5b" }
				"sidewalk_manhole" { Draw-SidewalkBase $graphics $r; Ellipse $graphics (Rect ($r.Left + 20) ($r.Top + 20) 24 24) "#746c5f"; Ellipse $graphics (Rect ($r.Left + 25) ($r.Top + 25) 14 14) "#9a907e"; Line $graphics ($r.Left + 23) ($r.Top + 32) ($r.Left + 41) ($r.Top + 32) "#5b554c" 1 }
				"soft_asphalt" { Draw-RoadBase $graphics $r "#495356" }
				"wet_asphalt" { Draw-RoadBase $graphics $r "#3e4b50"; Ellipse $graphics (Rect ($r.Left + 10) ($r.Top + 37) 34 11) "#7ba9b2"; Ellipse $graphics (Rect ($r.Left + 42) ($r.Top + 16) 12 5) "#91bac3" }
				"road_h" { Draw-RoadBase $graphics $r; Line $graphics ($r.Left + 8) ($r.Top + 32) ($r.Left + 24) ($r.Top + 32) "#d7bd68" 4; Line $graphics ($r.Left + 40) ($r.Top + 32) ($r.Left + 56) ($r.Top + 32) "#d7bd68" 4 }
				"road_v" { Draw-RoadBase $graphics $r; Line $graphics ($r.Left + 32) ($r.Top + 8) ($r.Left + 32) ($r.Top + 24) "#d7bd68" 4; Line $graphics ($r.Left + 32) ($r.Top + 40) ($r.Left + 32) ($r.Top + 56) "#d7bd68" 4 }
				"road_cross" { Draw-RoadBase $graphics $r; Line $graphics ($r.Left + 32) ($r.Top + 3) ($r.Left + 32) ($r.Bottom - 3) "#d7bd68" 3; Line $graphics ($r.Left + 3) ($r.Top + 32) ($r.Right - 3) ($r.Top + 32) "#d7bd68" 3 }
				"road_corner_ne" { Draw-RoadBase $graphics $r; Fill $graphics (Rect ($r.Left + 42) $r.Top 22 22) "#d8ceb8"; Line $graphics ($r.Left + 44) ($r.Top + 20) ($r.Left + 60) ($r.Top + 4) "#eee3c9" 3 }
				"road_corner_sw" { Draw-RoadBase $graphics $r; Fill $graphics (Rect $r.Left ($r.Top + 42) 22 22) "#d8ceb8"; Line $graphics ($r.Left + 4) ($r.Top + 60) ($r.Left + 20) ($r.Top + 44) "#eee3c9" 3 }
				"crosswalk" { Draw-RoadBase $graphics $r; for ($x = 8; $x -lt 58; $x += 12) { Fill $graphics (Rect ($r.Left + $x) ($r.Top + 17) 7 30) "#efe3b2" } }
				"plane_tree" { Draw-Tree $graphics $r $true }
				"small_tree" { Draw-Tree $graphics $r $false }
				"shrub" { Draw-GrassBase $graphics $r "#83a765"; Ellipse $graphics (Rect ($r.Left + 11) ($r.Top + 29) 18 16) "#668f55"; Ellipse $graphics (Rect ($r.Left + 26) ($r.Top + 24) 25 21) "#82a95d"; Ellipse $graphics (Rect ($r.Left + 42) ($r.Top + 34) 14 12) "#668f55" }
				"flower_box" { Draw-SidewalkBase $graphics $r; Draw-RoundRect $graphics (Rect ($r.Left + 12) ($r.Top + 32) 40 14) "#8a644c"; for ($x = 17; $x -le 45; $x += 7) { Ellipse $graphics (Rect ($r.Left + $x) ($r.Top + 24) 5 5) "#e9b1a0"; Line $graphics ($r.Left + $x + 2) ($r.Top + 29) ($r.Left + $x + 2) ($r.Top + 34) "#668f55" 1 } }
				"rain_puddle" { Draw-SidewalkBase $graphics $r; Ellipse $graphics (Rect ($r.Left + 10) ($r.Top + 30) 44 18) "#86b7c2"; Ellipse $graphics (Rect ($r.Left + 29) ($r.Top + 26) 15 6) "#bdd9dd" }
				"fallen_leaves" { Draw-GrassBase $graphics $r "#789b60"; for ($n = 0; $n -lt 9; $n++) { $x = $r.Left + (($n * 17 + 9) % 54); $y = $r.Top + (($n * 23 + 12) % 52); Ellipse $graphics (Rect $x $y 6 3) "#d0a14e" } }
				"bike_lane" { Fill $graphics $r "#557b70"; Draw-Dots $graphics $r "#6f9588" 12 2; Line $graphics ($r.Left + 32) ($r.Top + 6) ($r.Left + 32) ($r.Bottom - 6) "#d8e0ca" 2; Ellipse $graphics (Rect ($r.Left + 21) ($r.Top + 24) 8 8) "#d8e0ca"; Ellipse $graphics (Rect ($r.Left + 36) ($r.Top + 24) 8 8) "#d8e0ca"; Line $graphics ($r.Left + 25) ($r.Top + 28) ($r.Left + 40) ($r.Top + 28) "#d8e0ca" 2 }
				"curb_ramp" { Draw-SidewalkBase $graphics $r; Fill $graphics (Rect $r.Left ($r.Top + 50) 64 14) "#9c9382"; Draw-RoundRect $graphics (Rect ($r.Left + 20) ($r.Top + 40) 24 18) "#eee3c9"; Line $graphics ($r.Left + 24) ($r.Top + 47) ($r.Left + 40) ($r.Top + 47) "#c6bca5" 1 }
			}
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
			$pen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(180, 255, 240, 190)), 2
			try {
				for ($x = 0; $x -le $atlas.Width; $x += $TileSize) { $previewGraphics.DrawLine($pen, $x, 0, $x, $atlas.Height) }
				for ($y = 0; $y -le $atlas.Height; $y += $TileSize) { $previewGraphics.DrawLine($pen, 0, $y, $atlas.Width, $y) }
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
} finally {
	$atlas.Dispose()
}

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add('[gd_resource type="TileSet" format=3 uid="uid://b4xw7u5qd6ground"]')
$lines.Add('')
$lines.Add('[ext_resource type="Texture2D" path="res://assets/tiles/handdrawn_ground_tiles_64.png" id="1_ground"]')
$lines.Add('')
$lines.Add('[sub_resource type="TileSetAtlasSource" id="TileSetAtlasSource_handdrawn_ground"]')
$lines.Add('texture = ExtResource("1_ground")')
$lines.Add("texture_region_size = Vector2i($TileSize, $TileSize)")
for ($y = 0; $y -lt $Rows; $y++) {
	for ($x = 0; $x -lt $Columns; $x++) {
		$index = $y * $Columns + $x
		if ($index -lt $TileNames.Count) {
			$lines.Add("$x`:$y/0 = 0")
		}
	}
}
$lines.Add('')
$lines.Add('[resource]')
$lines.Add("tile_size = Vector2i($TileSize, $TileSize)")
$lines.Add('sources/0 = SubResource("TileSetAtlasSource_handdrawn_ground")')

$guide = @"
# Hand-Drawn Ground Tileset 64

Purpose: brighter hand-drawn ground resources for the current urban life-sim art direction.

Style target:
- Non-pixel, top-down readable, soft 2D cartoon rendering.
- Modern Shanghai sidewalk and street mood.
- Warmer and happier grass than the old rainy prototype, but still muted and lived-in.
- Tile edges remain grid-safe for map building.

Atlas:
- ``res://assets/tiles/handdrawn_ground_tiles_64.png``
- Tile size: 64 x 64
- Grid: $Columns x $Rows

Tiles:
$($TileNames | ForEach-Object { "- $_" } | Out-String)
Use:
- Roads and sidewalks: street blocks, delivery station routes, metro-adjacent plazas.
- Grass and trees: small community green patches, roadside plane trees, residential courtyards.
- Puddles, leaves, cracks: low-cost visual storytelling for humid Shanghai streets.

Current weakness:
- This is a generated production placeholder pack, not final Image2 paintover quality.
- Corners only cover the most common directions; full auto-tiling can be expanded later.
"@

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($tileSetPath, ($lines -join [Environment]::NewLine) + [Environment]::NewLine, $utf8NoBom)
[System.IO.File]::WriteAllText($guidePath, $guide, $utf8NoBom)

Write-Output "atlas=$atlasPath"
Write-Output "tileset=$tileSetPath"
Write-Output "preview=$previewPath"
Write-Output "guide=$guidePath"
Write-Output "tiles=$($TileNames.Count)"
