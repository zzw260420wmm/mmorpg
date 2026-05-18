param(
	[string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
)

$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

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

function New-Bitmap {
	param([int]$Width, [int]$Height)
	$bitmap = New-Object System.Drawing.Bitmap $Width, $Height, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
	$bitmap.SetResolution(96, 96)
	return $bitmap
}

function Brush {
	param([string]$Color)
	return New-Object System.Drawing.SolidBrush (Color-Hex $Color)
}

function Pen-Hex {
	param([string]$Color, [float]$Width = 2.0)
	return New-Object System.Drawing.Pen (Color-Hex $Color), $Width
}

function Fill-RoundRect {
	param($G, [float]$X, [float]$Y, [float]$W, [float]$H, [float]$R, [string]$Color)
	$path = New-Object System.Drawing.Drawing2D.GraphicsPath
	$d = $R * 2
	$path.AddArc($X, $Y, $d, $d, 180, 90)
	$path.AddArc($X + $W - $d, $Y, $d, $d, 270, 90)
	$path.AddArc($X + $W - $d, $Y + $H - $d, $d, $d, 0, 90)
	$path.AddArc($X, $Y + $H - $d, $d, $d, 90, 90)
	$path.CloseFigure()
	$b = Brush $Color
	$G.FillPath($b, $path)
	$b.Dispose()
	$path.Dispose()
}

function Stroke-RoundRect {
	param($G, [float]$X, [float]$Y, [float]$W, [float]$H, [float]$R, [string]$Color, [float]$Width = 2.0)
	$path = New-Object System.Drawing.Drawing2D.GraphicsPath
	$d = $R * 2
	$path.AddArc($X, $Y, $d, $d, 180, 90)
	$path.AddArc($X + $W - $d, $Y, $d, $d, 270, 90)
	$path.AddArc($X + $W - $d, $Y + $H - $d, $d, $d, 0, 90)
	$path.AddArc($X, $Y + $H - $d, $d, $d, 90, 90)
	$path.CloseFigure()
	$p = Pen-Hex $Color $Width
	$G.DrawPath($p, $path)
	$p.Dispose()
	$path.Dispose()
}

function Fill-Poly {
	param($G, [System.Drawing.PointF[]]$Points, [string]$Color)
	$b = Brush $Color
	$G.FillPolygon($b, $Points)
	$b.Dispose()
}

function Draw-Window {
	param($G, [float]$X, [float]$Y, [float]$W, [float]$H, [string]$Light, [string]$Ink)
	Fill-RoundRect $G $X $Y $W $H 3 $Light
	Stroke-RoundRect $G $X $Y $W $H 3 $Ink 1.2
	$p = Pen-Hex "#382f2c66" 1.0
	$G.DrawLine($p, $X + $W * 0.5, $Y + 2, $X + $W * 0.5, $Y + $H - 2)
	$p.Dispose()
}

function Draw-Sign {
	param($G, [float]$X, [float]$Y, [float]$W, [string]$Color, [string]$Ink)
	Fill-RoundRect $G $X $Y $W 13 5 $Color
	Stroke-RoundRect $G $X $Y $W 13 5 $Ink 1.4
	$p = Pen-Hex "#3a302966" 1.2
	$G.DrawLine($p, $X + 9, $Y + 6, $X + $W - 9, $Y + 6)
	$p.Dispose()
}

function Draw-Awning {
	param($G, [float]$X, [float]$Y, [float]$W, [string]$A, [string]$B, [string]$Ink)
	$count = 6
	$seg = $W / $count
	for ($i = 0; $i -lt $count; $i++) {
		$c = if ($i % 2 -eq 0) { $A } else { $B }
		Fill-RoundRect $G ($X + $i * $seg) $Y ($seg + 1) 14 4 $c
	}
	$p = Pen-Hex $Ink 1.4
	$G.DrawLine($p, $X, $Y + 13, $X + $W, $Y + 13)
	$p.Dispose()
}

function Draw-BaseBuilding {
	param($G, [float]$X, [float]$Y, [float]$W, [float]$H, [string]$Body, [string]$Roof, [string]$Ink)
	Fill-RoundRect $G ($X + 6) ($Y + 9) $W $H 12 "#16000000"
	Fill-RoundRect $G $X $Y $W $H 11 $Body
	Stroke-RoundRect $G $X $Y $W $H 11 $Ink 2.2
	Fill-RoundRect $G ($X + 6) ($Y + 6) ($W - 12) 22 8 $Roof
	Stroke-RoundRect $G ($X + 6) ($Y + 6) ($W - 12) 22 8 $Ink 1.5
	$p = Pen-Hex "#fff0c040" 2.0
	$G.DrawLine($p, $X + 14, $Y + 32, $X + $W - 14, $Y + 29)
	$p.Dispose()
}

function Draw-Door {
	param($G, [float]$X, [float]$Y, [string]$Ink, [string]$Light = "#efc36f")
	Fill-RoundRect $G $X $Y 28 30 7 "#2f2d2b"
	Stroke-RoundRect $G $X $Y 28 30 7 $Ink 1.5
	Draw-Window $G ($X + 6) ($Y + 6) 16 8 $Light $Ink
	$b = Brush "#d8b46f"
	$G.FillEllipse($b, $X + 21, $Y + 17, 3, 3)
	$b.Dispose()
}

function Draw-BuildingCell {
	param($G, [int]$Col, [int]$Row, [hashtable]$B)
	$cellW = 192
	$cellH = 128
	$x = $Col * $cellW
	$y = $Row * $cellH
	$ox = $x + 18
	$oy = $y + 15
	$ink = "#312826aa"
	Draw-BaseBuilding $G $ox $oy 156 92 $B.body $B.roof $ink
	Draw-Sign $G ($ox + 18) ($oy + 10) 72 $B.sign $ink

	switch ($B.kind) {
		"shanghai_lane" {
			for ($i = 0; $i -lt 4; $i++) { Draw-Window $G ($ox + 18 + $i * 30) ($oy + 39) 18 14 $B.light $ink }
			Draw-Door $G ($ox + 63) ($oy + 61) $ink $B.light
			$p = Pen-Hex "#5c4d43" 2.0
			for ($i = 0; $i -lt 4; $i++) { $G.DrawLine($p, $ox + 12 + $i * 24, $oy + 82, $ox + 28 + $i * 24, $oy + 75) }
			$p.Dispose()
		}
		"shanghai_store" {
			Draw-Awning $G ($ox + 18) ($oy + 31) 120 "#f2d78d" "#3f806f" $ink
			Draw-Door $G ($ox + 105) ($oy + 58) $ink $B.light
			for ($i = 0; $i -lt 3; $i++) { Draw-Window $G ($ox + 18 + $i * 28) ($oy + 56) 20 14 $B.light $ink }
		}
		"shanghai_office" {
			for ($r = 0; $r -lt 3; $r++) {
				for ($c = 0; $c -lt 4; $c++) { Draw-Window $G ($ox + 19 + $c * 29) ($oy + 34 + $r * 18) 18 11 $B.light $ink }
			}
			Draw-Door $G ($ox + 64) ($oy + 60) $ink $B.light
		}
		"beijing_hutong" {
			Fill-RoundRect $G ($ox + 10) ($oy + 31) 136 16 5 "#4b4b48"
			Stroke-RoundRect $G ($ox + 10) ($oy + 31) 136 16 5 $ink 1.3
			Draw-Door $G ($ox + 63) ($oy + 58) $ink "#d24f45"
			Draw-Window $G ($ox + 24) ($oy + 57) 20 17 "#d6c69a" $ink
			Draw-Window $G ($ox + 112) ($oy + 57) 20 17 "#d6c69a" $ink
		}
		"guangzhou_qilou" {
			Draw-Awning $G ($ox + 14) ($oy + 29) 128 "#e8c879" "#8e6d58" $ink
			for ($i = 0; $i -lt 4; $i++) {
				Fill-RoundRect $G ($ox + 24 + $i * 30) ($oy + 57) 9 37 4 "#f0e3bf"
				Stroke-RoundRect $G ($ox + 24 + $i * 30) ($oy + 57) 9 37 4 $ink 1.1
			}
			Draw-Door $G ($ox + 103) ($oy + 61) $ink $B.light
		}
		"shenzhen_tech" {
			Fill-RoundRect $G ($ox + 26) ($oy + 26) 104 68 9 "#6f8795"
			Stroke-RoundRect $G ($ox + 26) ($oy + 26) 104 68 9 $ink 1.6
			for ($i = 0; $i -lt 5; $i++) { Draw-Window $G ($ox + 36 + $i * 17) ($oy + 42) 10 36 "#c7e7ff" $ink }
			Draw-Door $G ($ox + 64) ($oy + 66) $ink "#a9d7ff"
		}
		"chengdu_eatery" {
			Draw-Awning $G ($ox + 18) ($oy + 32) 120 "#a93f3a" "#f2d78d" $ink
			Draw-Door $G ($ox + 101) ($oy + 60) $ink "#ffe0a3"
			for ($i = 0; $i -lt 3; $i++) { Draw-Window $G ($ox + 18 + $i * 27) ($oy + 58) 18 15 "#ffe0a3" $ink }
			$ellipseBrush = Brush "#c94f44"
			$G.FillEllipse($ellipseBrush, $ox + 30, $oy + 82, 12, 8)
			$ellipseBrush.Dispose()
		}
		"hangzhou_waterside" {
			Fill-Poly $G ([System.Drawing.PointF[]]@(
				[System.Drawing.PointF]::new($ox + 9, $oy + 35),
				[System.Drawing.PointF]::new($ox + 78, $oy + 12),
				[System.Drawing.PointF]::new($ox + 147, $oy + 35)
			)) "#52615d"
			$p = Pen-Hex $ink 2.0
			$G.DrawLine($p, $ox + 9, $oy + 35, $ox + 78, $oy + 12)
			$G.DrawLine($p, $ox + 78, $oy + 12, $ox + 147, $oy + 35)
			$p.Dispose()
			for ($i = 0; $i -lt 3; $i++) { Draw-Window $G ($ox + 28 + $i * 35) ($oy + 53) 20 15 "#d8fff0" $ink }
			Draw-Door $G ($ox + 64) ($oy + 64) $ink "#d8fff0"
		}
		"chongqing_slope" {
			Fill-RoundRect $G ($ox + 5) ($oy + 72) 146 14 4 "#5c5149"
			for ($i = 0; $i -lt 4; $i++) { Draw-Window $G ($ox + 20 + $i * 28) ($oy + 42) 18 14 $B.light $ink }
			Draw-Door $G ($ox + 99) ($oy + 61) $ink $B.light
			$p = Pen-Hex "#d8b46f" 2.0
			$G.DrawLine($p, $ox + 14, $oy + 91, $ox + 137, $oy + 72)
			$p.Dispose()
		}
		"wuhan_riverside" {
			for ($i = 0; $i -lt 5; $i++) { Draw-Window $G ($ox + 18 + $i * 25) ($oy + 41) 16 13 "#d8fff0" $ink }
			Draw-Door $G ($ox + 64) ($oy + 63) $ink "#d8fff0"
			$p = Pen-Hex "#a9d7ff" 3.0
			$G.DrawLine($p, $ox + 16, $oy + 93, $ox + 141, $oy + 93)
			$G.DrawLine($p, $ox + 26, $oy + 100, $ox + 132, $oy + 100)
			$p.Dispose()
		}
		"nanjing_plane_tree" {
			for ($i = 0; $i -lt 4; $i++) { Draw-Window $G ($ox + 21 + $i * 28) ($oy + 43) 18 13 "#e8c879" $ink }
			Draw-Door $G ($ox + 64) ($oy + 63) $ink "#e8c879"
			$treeBrush = Brush "#6f8b55"
			$G.FillEllipse($treeBrush, $ox + 7, $oy + 57, 28, 28)
			$G.FillEllipse($treeBrush, $ox + 124, $oy + 52, 30, 30)
			$treeBrush.Dispose()
		}
	}
}

$spritesDir = Join-Path $Root "assets\sprites"
$artDir = Join-Path $Root "assets\art"
$briefDir = Join-Path $Root "assets\art\image2\briefs"
New-Item -ItemType Directory -Force $spritesDir, $artDir, $briefDir | Out-Null

$buildings = @(
	@{ id = "shanghai_lane_house"; city = "Shanghai"; kind = "shanghai_lane"; body = "#8e6d58"; roof = "#6d5046"; sign = "#efc36f"; light = "#efc36f"; note = "old lane rental house with laundry wires" },
	@{ id = "shanghai_convenience_store"; city = "Shanghai"; kind = "shanghai_store"; body = "#6d8d83"; roof = "#3d635f"; sign = "#f5d37b"; light = "#f5d37b"; note = "chain convenience store in humid night street" },
	@{ id = "shanghai_office_tower"; city = "Shanghai"; kind = "shanghai_office"; body = "#697985"; roof = "#3f4d5d"; sign = "#c7e7ff"; light = "#c7e7ff"; note = "glass office block, restrained Lujiazui pressure" },
	@{ id = "beijing_hutong_courtyard"; city = "Beijing"; kind = "beijing_hutong"; body = "#8d7560"; roof = "#4b4b48"; sign = "#d24f45"; light = "#d6c69a"; note = "hutong courtyard facade with gray roof and red door" },
	@{ id = "guangzhou_qilou_shop"; city = "Guangzhou"; kind = "guangzhou_qilou"; body = "#b08a65"; roof = "#7b5c48"; sign = "#e8c879"; light = "#ffe0a3"; note = "arcade qilou shop house with columns" },
	@{ id = "shenzhen_tech_park"; city = "Shenzhen"; kind = "shenzhen_tech"; body = "#7f9caf"; roof = "#536577"; sign = "#a9d7ff"; light = "#c7e7ff"; note = "startup tech park glass block" },
	@{ id = "chengdu_noodle_shop"; city = "Chengdu"; kind = "chengdu_eatery"; body = "#a45d45"; roof = "#793d36"; sign = "#f2d78d"; light = "#ffe0a3"; note = "warm noodle shop, low pressure but crowded" },
	@{ id = "hangzhou_waterside_house"; city = "Hangzhou"; kind = "hangzhou_waterside"; body = "#d5d0bd"; roof = "#52615d"; sign = "#d8fff0"; light = "#d8fff0"; note = "waterside white-wall dark-roof building" },
	@{ id = "chongqing_slope_apartment"; city = "Chongqing"; kind = "chongqing_slope"; body = "#806b52"; roof = "#5b4638"; sign = "#f0c77b"; light = "#f0c77b"; note = "slope-side apartment with stepped road" },
	@{ id = "wuhan_riverside_market"; city = "Wuhan"; kind = "wuhan_riverside"; body = "#6d8d83"; roof = "#4d665f"; sign = "#d8fff0"; light = "#d8fff0"; note = "riverside market near humid embankment" },
	@{ id = "nanjing_plane_tree_block"; city = "Nanjing"; kind = "nanjing_plane_tree"; body = "#8a806a"; roof = "#61584f"; sign = "#e8c879"; light = "#e8c879"; note = "older block shaded by plane trees" },
	@{ id = "shanghai_media_company"; city = "Shanghai"; kind = "shanghai_office"; body = "#7b647f"; roof = "#58445f"; sign = "#ffc4d6"; light = "#ffc4d6"; note = "media company with restrained warm pink light" }
)

$cols = 4
$cellW = 192
$cellH = 128
$rows = [Math]::Ceiling($buildings.Count / $cols)
$atlas = New-Bitmap ($cols * $cellW) ($rows * $cellH)
$g = [System.Drawing.Graphics]::FromImage($atlas)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
$g.Clear([System.Drawing.Color]::FromArgb(0, 0, 0, 0))

$manifest = @()
for ($i = 0; $i -lt $buildings.Count; $i++) {
	$col = $i % $cols
	$row = [Math]::Floor($i / $cols)
	Draw-BuildingCell $g $col $row $buildings[$i]
	$manifest += [ordered]@{
		id = $buildings[$i].id
		city = $buildings[$i].city
		x = $col * $cellW
		y = $row * $cellH
		w = $cellW
		h = $cellH
		note = $buildings[$i].note
	}
}

$atlasPath = Join-Path $spritesDir "cartoon_buildings_atlas.png"
$atlas.Save($atlasPath, [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose()
$atlas.Dispose()

$manifestPath = Join-Path $artDir "cartoon_buildings_manifest.json"
$manifestDoc = [ordered]@{
	style = "non-pixel 2D hand-drawn cartoon buildings, clean line art, simple cel shading, transparent background"
	cell_size = @{ w = $cellW; h = $cellH }
	buildings = $manifest
}
[System.IO.File]::WriteAllText($manifestPath, ($manifestDoc | ConvertTo-Json -Depth 5), [System.Text.Encoding]::UTF8)

$brief = @"
# Multi-City Cartoon Building Pack

Purpose: reusable non-pixel building sprites for future city maps.

Style: 2D hand-drawn cartoon, transparent background, clean line art, simple cel shading, grounded Chinese urban life, restrained colors, no cyberpunk overload.

Atlas: ``res://assets/sprites/cartoon_buildings_atlas.png``

Cells are 192x128. Buildings keep a readable top-down/front hybrid silhouette suitable for life-sim maps.

## Included Cities

- Shanghai: lane rental house, convenience store, office tower, media company.
- Beijing: hutong courtyard facade.
- Guangzhou: qilou shop house.
- Shenzhen: tech park office.
- Chengdu: warm noodle shop.
- Hangzhou: waterside white-wall house.
- Chongqing: slope-side apartment.
- Wuhan: riverside market.
- Nanjing: plane-tree older block.

## Prompt Direction

non-pixel 2D hand-drawn cartoon building sprite, Chinese city-specific architecture, top-down life-sim readability, clean line art, simple cel shading, transparent background, restrained warm gray and muted blue palette, lived-in urban details, no fantasy, no sci-fi, no cyberpunk, no over-rendered realism
"@
[System.IO.File]::WriteAllText((Join-Path $briefDir "04_multi_city_building_pack.md"), $brief, [System.Text.Encoding]::UTF8)

Write-Host "Generated cartoon building atlas: $atlasPath"
