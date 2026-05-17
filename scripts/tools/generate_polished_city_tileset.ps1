param(
	[string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path,
	[int]$TileSize = 64
)

$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

$tilesDir = Join-Path $Root "assets\tiles"
$artDir = Join-Path $Root "assets\art"
New-Item -ItemType Directory -Force $tilesDir, $artDir | Out-Null

$atlasPath = Join-Path $tilesDir "polished_city_tileset_64.png"
$tileSetPath = Join-Path $tilesDir "polished_city_tileset_64.tres"
$previewPath = Join-Path $artDir "polished_city_tileset_64_preview.png"

$TileNames = @(
	"grass", "grass_detail", "pavement", "sidewalk_h", "sidewalk_v", "sidewalk_corner", "curb_h", "curb_v",
	"asphalt", "road_v", "road_h", "intersection", "lane_v", "lane_h", "wet_asphalt", "road_shadow",
	"crosswalk_h", "crosswalk_v", "round_nw", "round_ne", "round_sw", "round_se", "puddle", "manhole",
	"res_roof", "res_wall", "shop_roof", "shop_wall", "office_roof", "office_wall", "glass_tower", "media_wall",
	"res_door", "storefront", "office_door", "clinic_front", "metro_entry", "tree", "street_lamp", "scooter",
	"market_front", "agency_front", "delivery_front", "talent_wall", "building_shadow", "window_wall", "roof_ac", "river_water"
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
	try {
		$Graphics.FillRectangle($brush, $Rect)
	} finally {
		$brush.Dispose()
	}
}

function Stroke {
	param($Graphics, [System.Drawing.Rectangle]$Rect, [string]$Color, [float]$Width = 2)
	$pen = New-Object System.Drawing.Pen (Color-Hex $Color), $Width
	try {
		$Graphics.DrawRectangle($pen, $Rect)
	} finally {
		$pen.Dispose()
	}
}

function Line {
	param($Graphics, [int]$X1, [int]$Y1, [int]$X2, [int]$Y2, [string]$Color, [float]$Width = 2)
	$pen = New-Object System.Drawing.Pen (Color-Hex $Color), $Width
	$pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
	$pen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
	try {
		$Graphics.DrawLine($pen, $X1, $Y1, $X2, $Y2)
	} finally {
		$pen.Dispose()
	}
}

function Ellipse {
	param($Graphics, [System.Drawing.Rectangle]$Rect, [string]$Color)
	$brush = New-Object System.Drawing.SolidBrush (Color-Hex $Color)
	try {
		$Graphics.FillEllipse($brush, $Rect)
	} finally {
		$brush.Dispose()
	}
}

function Draw-TextureDots {
	param($Graphics, [System.Drawing.Rectangle]$Rect, [string]$Color, [int]$Step = 13)
	for ($y = $Rect.Top + 4; $y -lt $Rect.Bottom; $y += $Step) {
		for ($x = $Rect.Left + 4; $x -lt $Rect.Right; $x += $Step) {
			if ((($x * 7 + $y * 11) % 5) -eq 0) {
				Fill $Graphics (New-Object System.Drawing.Rectangle $x, $y, 2, 2) $Color
			}
		}
	}
}

function Draw-Ground {
	param($Graphics, [System.Drawing.Rectangle]$Rect, [string]$Base, [string]$Dot, [string]$Accent)
	Fill $Graphics $Rect $Base
	Draw-TextureDots $Graphics $Rect $Dot 11
	Line $Graphics ($Rect.Left + 8) ($Rect.Top + 48) ($Rect.Left + 30) ($Rect.Top + 42) $Accent 1
	Line $Graphics ($Rect.Left + 38) ($Rect.Top + 18) ($Rect.Left + 54) ($Rect.Top + 22) $Accent 1
}

function Draw-PavementGrid {
	param($Graphics, [System.Drawing.Rectangle]$Rect, [string]$Base)
	Fill $Graphics $Rect $Base
	for ($i = 0; $i -le 64; $i += 16) {
		Line $Graphics ($Rect.Left + $i) $Rect.Top ($Rect.Left + $i) $Rect.Bottom "#cfc7b2" 1
		Line $Graphics $Rect.Left ($Rect.Top + $i) $Rect.Right ($Rect.Top + $i) "#cfc7b2" 1
	}
	Draw-TextureDots $Graphics $Rect "#b7ad99" 17
}

function Draw-RoadBase {
	param($Graphics, [System.Drawing.Rectangle]$Rect, [string]$Base = "#3d4648")
	Fill $Graphics $Rect $Base
	Draw-TextureDots $Graphics $Rect "#536064" 12
	Line $Graphics ($Rect.Left + 3) ($Rect.Top + 61) ($Rect.Right - 3) ($Rect.Top + 61) "#2f383a" 2
}

function Draw-BuildingBase {
	param($Graphics, [System.Drawing.Rectangle]$Rect, [string]$Body, [string]$Trim, [string]$Light)
	Fill $Graphics $Rect $Body
	Fill $Graphics (New-Object System.Drawing.Rectangle $Rect.Left, $Rect.Top, 64, 10) $Trim
	Stroke $Graphics (New-Object System.Drawing.Rectangle $Rect.Left, $Rect.Top, 63, 63) "#2f302e" 2
	for ($y = 18; $y -le 44; $y += 18) {
		for ($x = 10; $x -le 42; $x += 24) {
			Fill $Graphics (New-Object System.Drawing.Rectangle ($Rect.Left + $x), ($Rect.Top + $y), 13, 10) $Light
			Fill $Graphics (New-Object System.Drawing.Rectangle ($Rect.Left + $x + 6), ($Rect.Top + $y), 1, 10) "#364246"
		}
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
				"grass" { Draw-Ground $graphics $r "#718d5a" "#86a06a" "#5f7c4b" }
				"grass_detail" { Draw-Ground $graphics $r "#78965f" "#9bb67b" "#607d4b"; Ellipse $graphics (New-Object System.Drawing.Rectangle ($r.Left + 36), ($r.Top + 10), 18, 10) "#d8d2b5" }
				"pavement" { Draw-PavementGrid $graphics $r "#d8d0bb" }
				"sidewalk_h" { Draw-PavementGrid $graphics $r "#d7cfba"; Fill $graphics (New-Object System.Drawing.Rectangle $r.Left, ($r.Top + 54), 64, 10) "#b7a890" }
				"sidewalk_v" { Draw-PavementGrid $graphics $r "#d7cfba"; Fill $graphics (New-Object System.Drawing.Rectangle ($r.Left + 54), $r.Top, 10, 64) "#b7a890" }
				"sidewalk_corner" { Draw-PavementGrid $graphics $r "#d7cfba"; Fill $graphics (New-Object System.Drawing.Rectangle $r.Left, ($r.Top + 54), 64, 10) "#b7a890"; Fill $graphics (New-Object System.Drawing.Rectangle ($r.Left + 54), $r.Top, 10, 64) "#b7a890" }
				"curb_h" { Draw-PavementGrid $graphics $r "#d7cfba"; Fill $graphics (New-Object System.Drawing.Rectangle $r.Left, ($r.Top + 48), 64, 6) "#f0e6c8"; Fill $graphics (New-Object System.Drawing.Rectangle $r.Left, ($r.Top + 54), 64, 10) "#525b5c" }
				"curb_v" { Draw-PavementGrid $graphics $r "#d7cfba"; Fill $graphics (New-Object System.Drawing.Rectangle ($r.Left + 48), $r.Top, 6, 64) "#f0e6c8"; Fill $graphics (New-Object System.Drawing.Rectangle ($r.Left + 54), $r.Top, 10, 64) "#525b5c" }
				"asphalt" { Draw-RoadBase $graphics $r }
				"road_v" { Draw-RoadBase $graphics $r; Line $graphics ($r.Left + 32) ($r.Top + 8) ($r.Left + 32) ($r.Top + 24) "#d9b24b" 4; Line $graphics ($r.Left + 32) ($r.Top + 40) ($r.Left + 32) ($r.Top + 56) "#d9b24b" 4 }
				"road_h" { Draw-RoadBase $graphics $r; Line $graphics ($r.Left + 8) ($r.Top + 32) ($r.Left + 24) ($r.Top + 32) "#d9b24b" 4; Line $graphics ($r.Left + 40) ($r.Top + 32) ($r.Left + 56) ($r.Top + 32) "#d9b24b" 4 }
				"intersection" { Draw-RoadBase $graphics $r; Line $graphics ($r.Left + 32) ($r.Top + 3) ($r.Left + 32) ($r.Bottom - 3) "#d9b24b" 3; Line $graphics ($r.Left + 3) ($r.Top + 32) ($r.Right - 3) ($r.Top + 32) "#d9b24b" 3 }
				"lane_v" { Draw-RoadBase $graphics $r; Line $graphics ($r.Left + 32) ($r.Top + 0) ($r.Left + 32) ($r.Bottom) "#e0b84f" 4 }
				"lane_h" { Draw-RoadBase $graphics $r; Line $graphics ($r.Left + 0) ($r.Top + 32) ($r.Right) ($r.Top + 32) "#e0b84f" 4 }
				"wet_asphalt" { Draw-RoadBase $graphics $r "#384346"; Ellipse $graphics (New-Object System.Drawing.Rectangle ($r.Left + 12), ($r.Top + 38), 32, 12) "#7ba9b2"; Ellipse $graphics (New-Object System.Drawing.Rectangle ($r.Left + 42), ($r.Top + 14), 12, 6) "#8cb7c2" }
				"road_shadow" { Draw-RoadBase $graphics $r "#30393c"; Fill $graphics (New-Object System.Drawing.Rectangle $r.Left, $r.Top, 64, 64) "#22000000" }
				"crosswalk_h" { Draw-RoadBase $graphics $r; for ($x = 8; $x -lt 58; $x += 12) { Fill $graphics (New-Object System.Drawing.Rectangle ($r.Left + $x), ($r.Top + 18), 7, 28) "#f2d56e" } }
				"crosswalk_v" { Draw-RoadBase $graphics $r; for ($y = 8; $y -lt 58; $y += 12) { Fill $graphics (New-Object System.Drawing.Rectangle ($r.Left + 18), ($r.Top + $y), 28, 7) "#f2d56e" } }
				"round_nw" { Draw-RoadBase $graphics $r; Ellipse $graphics (New-Object System.Drawing.Rectangle ($r.Left + 20), ($r.Top + 20), 84, 84) "#d9a943"; Ellipse $graphics (New-Object System.Drawing.Rectangle ($r.Left + 28), ($r.Top + 28), 68, 68) "#3d4648" }
				"round_ne" { Draw-RoadBase $graphics $r; Ellipse $graphics (New-Object System.Drawing.Rectangle ($r.Left - 40), ($r.Top + 20), 84, 84) "#d9a943"; Ellipse $graphics (New-Object System.Drawing.Rectangle ($r.Left - 32), ($r.Top + 28), 68, 68) "#3d4648" }
				"round_sw" { Draw-RoadBase $graphics $r; Ellipse $graphics (New-Object System.Drawing.Rectangle ($r.Left + 20), ($r.Top - 40), 84, 84) "#d9a943"; Ellipse $graphics (New-Object System.Drawing.Rectangle ($r.Left + 28), ($r.Top - 32), 68, 68) "#3d4648" }
				"round_se" { Draw-RoadBase $graphics $r; Ellipse $graphics (New-Object System.Drawing.Rectangle ($r.Left - 40), ($r.Top - 40), 84, 84) "#d9a943"; Ellipse $graphics (New-Object System.Drawing.Rectangle ($r.Left - 32), ($r.Top - 32), 68, 68) "#3d4648" }
				"puddle" { Draw-RoadBase $graphics $r "#384346"; Ellipse $graphics (New-Object System.Drawing.Rectangle ($r.Left + 10), ($r.Top + 28), 44, 18) "#7eb3be"; Ellipse $graphics (New-Object System.Drawing.Rectangle ($r.Left + 28), ($r.Top + 23), 16, 6) "#a3d4db" }
				"manhole" { Draw-PavementGrid $graphics $r "#d3cbb8"; Ellipse $graphics (New-Object System.Drawing.Rectangle ($r.Left + 18), ($r.Top + 18), 28, 28) "#746c5f"; Ellipse $graphics (New-Object System.Drawing.Rectangle ($r.Left + 23), ($r.Top + 23), 18, 18) "#9a907e" }
				"res_roof" { Draw-BuildingBase $graphics $r "#84624f" "#5a4038" "#efc36f" }
				"res_wall" { Draw-BuildingBase $graphics $r "#9a755f" "#6a4f45" "#f0d28a" }
				"shop_roof" { Draw-BuildingBase $graphics $r "#a45d45" "#793d36" "#ffe0a3"; Fill $graphics (New-Object System.Drawing.Rectangle ($r.Left + 4), ($r.Top + 12), 56, 8) "#f2d78d" }
				"shop_wall" { Draw-BuildingBase $graphics $r "#806b52" "#5b4638" "#f0c77b"; Fill $graphics (New-Object System.Drawing.Rectangle ($r.Left + 8), ($r.Top + 42), 48, 12) "#e9c777" }
				"office_roof" { Draw-BuildingBase $graphics $r "#697985" "#3f4d5d" "#c7e7ff" }
				"office_wall" { Draw-BuildingBase $graphics $r "#7d8c93" "#53636f" "#d9ecf2" }
				"glass_tower" { Draw-BuildingBase $graphics $r "#6f8aa0" "#4c6072" "#c7e7ff"; Fill $graphics (New-Object System.Drawing.Rectangle ($r.Left + 18), ($r.Top + 4), 28, 56) "#8fb1c2" }
				"media_wall" { Draw-BuildingBase $graphics $r "#7b647f" "#58445f" "#ffc4d6" }
				"res_door" { Draw-BuildingBase $graphics $r "#9a755f" "#6a4f45" "#efc36f"; Fill $graphics (New-Object System.Drawing.Rectangle ($r.Left + 24), ($r.Top + 35), 16, 26) "#2f2d2b" }
				"storefront" { Draw-BuildingBase $graphics $r "#806b52" "#5b4638" "#f0c77b"; Fill $graphics (New-Object System.Drawing.Rectangle ($r.Left + 10), ($r.Top + 28), 44, 24) "#26313d"; Fill $graphics (New-Object System.Drawing.Rectangle ($r.Left + 14), ($r.Top + 32), 36, 10) "#d8eef2" }
				"office_door" { Draw-BuildingBase $graphics $r "#697985" "#3f4d5d" "#c7e7ff"; Fill $graphics (New-Object System.Drawing.Rectangle ($r.Left + 20), ($r.Top + 32), 24, 28) "#2d3c4b" }
				"clinic_front" { Draw-BuildingBase $graphics $r "#6d8d83" "#3d635f" "#d8fff0"; Fill $graphics (New-Object System.Drawing.Rectangle ($r.Left + 28), ($r.Top + 18), 8, 28) "#c76b6d"; Fill $graphics (New-Object System.Drawing.Rectangle ($r.Left + 18), ($r.Top + 28), 28, 8) "#c76b6d" }
				"metro_entry" { Draw-BuildingBase $graphics $r "#4d5d70" "#2f3d4f" "#a9d7ff"; Fill $graphics (New-Object System.Drawing.Rectangle ($r.Left + 12), ($r.Top + 18), 40, 12) "#a9d7ff"; Fill $graphics (New-Object System.Drawing.Rectangle ($r.Left + 22), ($r.Top + 34), 20, 24) "#1f2a33" }
				"tree" { Draw-Ground $graphics $r "#718d5a" "#86a06a" "#5f7c4b"; Fill $graphics (New-Object System.Drawing.Rectangle ($r.Left + 29), ($r.Top + 34), 8, 22) "#6b4b32"; Ellipse $graphics (New-Object System.Drawing.Rectangle ($r.Left + 12), ($r.Top + 4), 40, 44) "#5f9f4d"; Ellipse $graphics (New-Object System.Drawing.Rectangle ($r.Left + 20), ($r.Top + 0), 36, 38) "#86b84f" }
				"street_lamp" { Draw-PavementGrid $graphics $r "#d7cfba"; Line $graphics ($r.Left + 32) ($r.Top + 12) ($r.Left + 32) ($r.Top + 54) "#384044" 4; Ellipse $graphics (New-Object System.Drawing.Rectangle ($r.Left + 23), ($r.Top + 8), 18, 8) "#f1d27b" }
				"scooter" { Draw-PavementGrid $graphics $r "#d7cfba"; Fill $graphics (New-Object System.Drawing.Rectangle ($r.Left + 14), ($r.Top + 32), 34, 9) "#e3b737"; Ellipse $graphics (New-Object System.Drawing.Rectangle ($r.Left + 12), ($r.Top + 40), 8, 8) "#28323b"; Ellipse $graphics (New-Object System.Drawing.Rectangle ($r.Left + 42), ($r.Top + 40), 8, 8) "#28323b" }
				"market_front" { Draw-BuildingBase $graphics $r "#6f7653" "#4d5738" "#f0c77b"; Fill $graphics (New-Object System.Drawing.Rectangle ($r.Left + 8), ($r.Top + 12), 48, 8) "#f0c77b" }
				"agency_front" { Draw-BuildingBase $graphics $r "#806b52" "#5b4638" "#f0c77b"; Fill $graphics (New-Object System.Drawing.Rectangle ($r.Left + 10), ($r.Top + 16), 44, 9) "#efe0b2" }
				"delivery_front" { Draw-BuildingBase $graphics $r "#6f7653" "#4d5738" "#f3cf6b"; Fill $graphics (New-Object System.Drawing.Rectangle ($r.Left + 16), ($r.Top + 38), 32, 12) "#f1c232" }
				"talent_wall" { Draw-BuildingBase $graphics $r "#7d8588" "#56636c" "#ffe2a1" }
				"building_shadow" { Fill $graphics $r "#00000000"; Fill $graphics (New-Object System.Drawing.Rectangle ($r.Left + 4), ($r.Top + 48), 56, 12) "#33000000" }
				"window_wall" { Draw-BuildingBase $graphics $r "#7d8588" "#56636c" "#c7e7ff"; for ($y = 14; $y -le 48; $y += 12) { Line $graphics ($r.Left + 8) ($r.Top + $y) ($r.Left + 56) ($r.Top + $y) "#a9c8d6" 2 } }
				"roof_ac" { Draw-BuildingBase $graphics $r "#697985" "#3f4d5d" "#c7e7ff"; Fill $graphics (New-Object System.Drawing.Rectangle ($r.Left + 24), ($r.Top + 18), 22, 14) "#d4ddd8"; Line $graphics ($r.Left + 27) ($r.Top + 25) ($r.Left + 43) ($r.Top + 25) "#71807b" 2 }
				"river_water" {
					Fill $graphics $r "#405f72"
					Draw-TextureDots $graphics $r "#5d7f8f" 14
					Line $graphics ($r.Left + 8) ($r.Top + 18) ($r.Left + 56) ($r.Top + 12) "#8fb5c4" 2
					Line $graphics ($r.Left + 4) ($r.Top + 40) ($r.Left + 48) ($r.Top + 34) "#6f9aaa" 2
					Ellipse $graphics (New-Object System.Drawing.Rectangle ($r.Left + 18), ($r.Top + 26), 26, 8) "#87b6c6"
				}
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
			$pen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(170, 255, 223, 130)), 2
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
} finally {
	$atlas.Dispose()
}

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add('[gd_resource type="TileSet" format=3 uid="uid://cxoa3us8uk6ao"]')
$lines.Add('')
$lines.Add('[ext_resource type="Texture2D" path="res://assets/tiles/polished_city_tileset_64.png" id="1_tiles"]')
$lines.Add('')
$lines.Add('[sub_resource type="TileSetAtlasSource" id="TileSetAtlasSource_polished_city"]')
$lines.Add('texture = ExtResource("1_tiles")')
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
$lines.Add('sources/0 = SubResource("TileSetAtlasSource_polished_city")')

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($tileSetPath, ($lines -join [Environment]::NewLine) + [Environment]::NewLine, $utf8NoBom)

Write-Output "atlas=$atlasPath"
Write-Output "tileset=$tileSetPath"
Write-Output "preview=$previewPath"
Write-Output "tiles=$($TileNames.Count)"
Write-Output "grid=${Columns}x${Rows}"
