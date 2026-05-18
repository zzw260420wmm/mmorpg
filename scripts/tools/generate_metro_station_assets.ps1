param(
	[string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$spritesDir = Join-Path $Root "assets\sprites"
$artDir = Join-Path $Root "assets\art"
New-Item -ItemType Directory -Force $spritesDir, $artDir | Out-Null

$atlasPath = Join-Path $spritesDir "metro_station_props.png"
$previewPath = Join-Path $artDir "metro_station_props_preview.png"
$guidePath = Join-Path $artDir "METRO_STATION_ASSET_GUIDE.md"
$size = 64
$columns = 8
$names = @(
	"ticket_machine",
	"ticket_gate_open",
	"ticket_gate_closed",
	"info_kiosk",
	"exit_sign",
	"line_sign",
	"ad_lightbox",
	"warning_sign",
	"pillar",
	"trash_bin",
	"tactile_straight",
	"tactile_turn",
	"platform_door",
	"ceiling_light",
	"rail_barrier",
	"floor_arrow"
)
$rows = [int][Math]::Ceiling($names.Count / $columns)

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

function Rect {
	param([int]$X, [int]$Y, [int]$W, [int]$H)
	return New-Object System.Drawing.Rectangle -ArgumentList $X, $Y, $W, $H
}

function Fill {
	param($G, [System.Drawing.Rectangle]$Rect, [string]$Color)
	$brush = New-Object System.Drawing.SolidBrush (Color-Hex $Color)
	try { $G.FillRectangle($brush, $Rect) } finally { $brush.Dispose() }
}

function Ellipse {
	param($G, [System.Drawing.Rectangle]$Rect, [string]$Color)
	$brush = New-Object System.Drawing.SolidBrush (Color-Hex $Color)
	try { $G.FillEllipse($brush, $Rect) } finally { $brush.Dispose() }
}

function Line {
	param($G, [int]$X1, [int]$Y1, [int]$X2, [int]$Y2, [string]$Color, [float]$Width = 2)
	$pen = New-Object System.Drawing.Pen (Color-Hex $Color), $Width
	$pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
	$pen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
	try { $G.DrawLine($pen, $X1, $Y1, $X2, $Y2) } finally { $pen.Dispose() }
}

function Stroke {
	param($G, [System.Drawing.Rectangle]$Rect, [string]$Color, [float]$Width = 2)
	$pen = New-Object System.Drawing.Pen (Color-Hex $Color), $Width
	try { $G.DrawRectangle($pen, $Rect) } finally { $pen.Dispose() }
}

function TileRect {
	param([int]$Index)
	return Rect (($Index % $columns) * $size) ([int][Math]::Floor($Index / $columns) * $size) $size $size
}

$atlas = New-Object System.Drawing.Bitmap ($columns * $size), ($rows * $size), ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
try {
	$atlas.SetResolution(192, 192)
	$g = [System.Drawing.Graphics]::FromImage($atlas)
	try {
		$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
		$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
		$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
		$g.Clear([System.Drawing.Color]::Transparent)
		for ($i = 0; $i -lt $names.Count; $i++) {
			$r = TileRect $i
			switch ($names[$i]) {
				"ticket_machine" {
					Fill $g (Rect ($r.Left + 12) ($r.Top + 6) 40 54) "#8f9ca2"; Stroke $g (Rect ($r.Left + 12) ($r.Top + 6) 40 54) "#1f2a33" 2
					Fill $g (Rect ($r.Left + 17) ($r.Top + 13) 30 8) "#26313d"; Fill $g (Rect ($r.Left + 19) ($r.Top + 28) 24 17) "#9fd9e7"
					Line $g ($r.Left + 22) ($r.Top + 36) ($r.Left + 40) ($r.Top + 30) "#d8f6ff" 2
					Fill $g (Rect ($r.Left + 23) ($r.Top + 50) 18 5) "#344a50"; Fill $g (Rect ($r.Left + 45) ($r.Top + 42) 4 9) "#7fc8a0"
				}
				"ticket_gate_open" {
					Fill $g (Rect ($r.Left + 21) ($r.Top + 8) 16 48) "#9ba8ad"; Stroke $g (Rect ($r.Left + 21) ($r.Top + 8) 16 48) "#1f2a33" 2
					Fill $g (Rect ($r.Left + 24) ($r.Top + 13) 10 8) "#7fc8a0"; Line $g ($r.Left + 16) ($r.Top + 35) ($r.Left + 6) ($r.Top + 48) "#c76b6d" 4
					Line $g ($r.Left + 42) ($r.Top + 35) ($r.Left + 55) ($r.Top + 49) "#c76b6d" 4
					Fill $g (Rect ($r.Left + 25) ($r.Top + 47) 8 5) "#67c37d"
				}
				"ticket_gate_closed" {
					Fill $g (Rect ($r.Left + 21) ($r.Top + 8) 16 48) "#9ba8ad"; Stroke $g (Rect ($r.Left + 21) ($r.Top + 8) 16 48) "#1f2a33" 2
					Fill $g (Rect ($r.Left + 24) ($r.Top + 13) 10 8) "#9fd9e7"; Line $g ($r.Left + 11) ($r.Top + 35) ($r.Left + 47) ($r.Top + 35) "#c76b6d" 5
					Fill $g (Rect ($r.Left + 25) ($r.Top + 47) 8 5) "#c76b6d"
				}
				"info_kiosk" {
					Fill $g (Rect ($r.Left + 19) ($r.Top + 5) 26 54) "#aeb7b9"; Stroke $g (Rect ($r.Left + 19) ($r.Top + 5) 26 54) "#1f2a33" 2
					Fill $g (Rect ($r.Left + 22) ($r.Top + 11) 20 26) "#9fd9e7"; Line $g ($r.Left + 26) ($r.Top + 32) ($r.Left + 39) ($r.Top + 17) "#d8f6ff" 2
					Ellipse $g (Rect ($r.Left + 29) ($r.Top + 44) 6 6) "#e8c879"
				}
				"exit_sign" {
					Fill $g (Rect ($r.Left + 6) ($r.Top + 18) 52 24) "#26313d"; Stroke $g (Rect ($r.Left + 6) ($r.Top + 18) 52 24) "#111820" 2
					Fill $g (Rect ($r.Left + 36) ($r.Top + 23) 14 14) "#7fc86f"; Line $g ($r.Left + 12) ($r.Top + 30) ($r.Left + 27) ($r.Top + 30) "#d8eef2" 4
					Line $g ($r.Left + 15) ($r.Top + 27) ($r.Left + 11) ($r.Top + 30) "#d8eef2" 3; Line $g ($r.Left + 15) ($r.Top + 33) ($r.Left + 11) ($r.Top + 30) "#d8eef2" 3
				}
				"line_sign" {
					Fill $g (Rect ($r.Left + 4) ($r.Top + 18) 56 24) "#26313d"; Stroke $g (Rect ($r.Left + 4) ($r.Top + 18) 56 24) "#111820" 2
					Fill $g (Rect ($r.Left + 27) ($r.Top + 23) 12 14) "#c76b6d"; Fill $g (Rect ($r.Left + 43) ($r.Top + 23) 7 14) "#7fc86f"
					Line $g ($r.Left + 10) ($r.Top + 30) ($r.Left + 23) ($r.Top + 30) "#d8eef2" 3; Line $g ($r.Left + 50) ($r.Top + 30) ($r.Left + 58) ($r.Top + 30) "#d8eef2" 3
				}
				"ad_lightbox" {
					Fill $g (Rect ($r.Left + 8) ($r.Top + 12) 48 36) "#26313d"; Stroke $g (Rect ($r.Left + 8) ($r.Top + 12) 48 36) "#111820" 2
					Fill $g (Rect ($r.Left + 13) ($r.Top + 17) 38 26) "#b9e3ea"; Line $g ($r.Left + 18) ($r.Top + 36) ($r.Left + 43) ($r.Top + 22) "#f5fbff" 2
				}
				"warning_sign" {
					Fill $g (Rect ($r.Left + 20) ($r.Top + 12) 24 38) "#efe2bb"; Stroke $g (Rect ($r.Left + 20) ($r.Top + 12) 24 38) "#6e6260" 2
					Line $g ($r.Left + 27) ($r.Top + 20) ($r.Left + 37) ($r.Top + 40) "#c76b6d" 3; Line $g ($r.Left + 37) ($r.Top + 20) ($r.Left + 27) ($r.Top + 40) "#c76b6d" 3
				}
				"pillar" {
					Fill $g (Rect ($r.Left + 19) ($r.Top + 4) 26 56) "#b9c5c7"; Stroke $g (Rect ($r.Left + 19) ($r.Top + 4) 26 56) "#5c6870" 2
					Fill $g (Rect ($r.Left + 19) ($r.Top + 43) 26 8) "#89a7b0"; Ellipse $g (Rect ($r.Left + 19) ($r.Top + 1) 26 8) "#d5dee0"
				}
				"trash_bin" {
					Fill $g (Rect ($r.Left + 21) ($r.Top + 14) 22 40) "#c4cfcb"; Stroke $g (Rect ($r.Left + 21) ($r.Top + 14) 22 40) "#1f2a33" 2
					Fill $g (Rect ($r.Left + 24) ($r.Top + 23) 16 4) "#6d8d83"; Line $g ($r.Left + 27) ($r.Top + 43) ($r.Left + 36) ($r.Top + 34) "#5ba56b" 2
				}
				"tactile_straight" {
					Fill $g $r "#e6bd47"; for ($y = 8; $y -lt 60; $y += 12) { Line $g ($r.Left + 8) ($r.Top + $y) ($r.Right - 8) ($r.Top + $y) "#b58f25" 2 }
				}
				"tactile_turn" {
					Fill $g $r "#e6bd47"; for ($y = 8; $y -lt 60; $y += 12) { Line $g ($r.Left + 8) ($r.Top + $y) ($r.Left + 32) ($r.Top + $y) "#b58f25" 2 }
					for ($x = 32; $x -lt 60; $x += 12) { Line $g ($r.Left + $x) ($r.Top + 32) ($r.Left + $x) ($r.Bottom - 8) "#b58f25" 2 }
				}
				"platform_door" {
					Fill $g $r "#cddadd"; Stroke $g $r "#344a50" 2; Fill $g (Rect ($r.Left + 6) ($r.Top + 8) 52 32) "#9fd9e7"; Line $g ($r.Left + 32) ($r.Top + 6) ($r.Left + 32) ($r.Bottom - 6) "#344a50" 2
				}
				"ceiling_light" {
					Fill $g (Rect ($r.Left + 8) ($r.Top + 24) 48 14) "#f6edc9"; Stroke $g (Rect ($r.Left + 8) ($r.Top + 24) 48 14) "#1f2a33" 2
					Line $g ($r.Left + 13) ($r.Top + 31) ($r.Left + 51) ($r.Top + 31) "#fff7ce" 4
				}
				"rail_barrier" {
					for ($x = 10; $x -lt 58; $x += 14) { Line $g ($r.Left + $x) ($r.Top + 18) ($r.Left + $x) ($r.Top + 51) "#7d8790" 3 }
					Line $g ($r.Left + 6) ($r.Top + 22) ($r.Right - 6) ($r.Top + 22) "#c2c8c9" 3; Line $g ($r.Left + 6) ($r.Top + 42) ($r.Right - 6) ($r.Top + 42) "#c2c8c9" 3
				}
				"floor_arrow" {
					Line $g ($r.Left + 32) ($r.Top + 12) ($r.Left + 32) ($r.Top + 45) "#e6bd47" 5
					Line $g ($r.Left + 20) ($r.Top + 35) ($r.Left + 32) ($r.Top + 48) "#e6bd47" 5; Line $g ($r.Left + 44) ($r.Top + 35) ($r.Left + 32) ($r.Top + 48) "#e6bd47" 5
				}
			}
		}
	} finally {
		$g.Dispose()
	}
	$atlas.Save($atlasPath, [System.Drawing.Imaging.ImageFormat]::Png)

	$preview = New-Object System.Drawing.Bitmap $atlas.Width, $atlas.Height, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
	try {
		$pg = [System.Drawing.Graphics]::FromImage($preview)
		try {
			$pg.DrawImage($atlas, 0, 0, $atlas.Width, $atlas.Height)
			$pen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(180, 255, 240, 190)), 2
			try {
				for ($x = 0; $x -le $atlas.Width; $x += $size) { $pg.DrawLine($pen, $x, 0, $x, $atlas.Height) }
				for ($y = 0; $y -le $atlas.Height; $y += $size) { $pg.DrawLine($pen, 0, $y, $atlas.Width, $y) }
			} finally { $pen.Dispose() }
		} finally { $pg.Dispose() }
		$preview.Save($previewPath, [System.Drawing.Imaging.ImageFormat]::Png)
	} finally { $preview.Dispose() }
} finally {
	$atlas.Dispose()
}

$guide = @"
# Metro Station Props

Reference source:
- `res://assets/URBDua1zhMxMyU5wqdr3M.png`

Generated gameplay props:
- ticket machines
- ticket gates
- information kiosk
- exit and line signs
- ad lightboxes
- pillars
- trash bin
- tactile paving
- platform doors
- ceiling lights
- rail barrier
- floor arrows

Art direction:
- Hand-drawn 2D, top-down readable.
- Muted blue-gray station palette with warm yellow tactile paving.
- Grounded Shanghai metro interior, not sci-fi or cyberpunk.
"@
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($guidePath, $guide, $utf8NoBom)

Write-Output "atlas=$atlasPath"
Write-Output "preview=$previewPath"
Write-Output "guide=$guidePath"
Write-Output "props=$($names.Count)"
