param(
	[string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$spritesDir = Join-Path $Root "assets\sprites"
$artDir = Join-Path $Root "assets\art"
New-Item -ItemType Directory -Force $spritesDir, $artDir | Out-Null

$atlasPath = Join-Path $spritesDir "internet_cafe_props.png"
$hdPreviewPath = Join-Path $artDir "internet_cafe_props_hd_preview.png"
$previewPath = Join-Path $artDir "internet_cafe_props_preview.png"
$guidePath = Join-Path $artDir "INTERNET_CAFE_ASSET_GUIDE.md"

$tile = 64
$scale = 4
$cell = $tile * $scale
$columns = 8
$names = @(
	"gaming_pc",
	"messy_desk",
	"gaming_chair",
	"noodle_cup",
	"soda_can",
	"rgb_sign",
	"front_counter",
	"snack_shelf",
	"router_stack",
	"ashtray",
	"blue_wall_poster",
	"headset",
	"keyboard_mouse",
	"sleeping_user",
	"floor_cable",
	"exit_door"
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

function RectS { param([int]$X, [int]$Y, [int]$W, [int]$H) return New-Object System.Drawing.Rectangle -ArgumentList ($X * $scale), ($Y * $scale), ($W * $scale), ($H * $scale) }
function Pt { param([int]$X, [int]$Y) return New-Object System.Drawing.Point -ArgumentList ($X * $scale), ($Y * $scale) }
function F { param($G, [System.Drawing.Rectangle]$Rect, [string]$Color) $b = New-Object System.Drawing.SolidBrush (Color-Hex $Color); try { $G.FillRectangle($b, $Rect) } finally { $b.Dispose() } }
function E { param($G, [System.Drawing.Rectangle]$Rect, [string]$Color) $b = New-Object System.Drawing.SolidBrush (Color-Hex $Color); try { $G.FillEllipse($b, $Rect) } finally { $b.Dispose() } }
function L { param($G, [int]$X1, [int]$Y1, [int]$X2, [int]$Y2, [string]$Color, [float]$Width = 2) $p = New-Object System.Drawing.Pen (Color-Hex $Color), ($Width * $scale); $p.StartCap = [System.Drawing.Drawing2D.LineCap]::Round; $p.EndCap = [System.Drawing.Drawing2D.LineCap]::Round; try { $G.DrawLine($p, ($X1 * $scale), ($Y1 * $scale), ($X2 * $scale), ($Y2 * $scale)) } finally { $p.Dispose() } }
function S { param($G, [System.Drawing.Rectangle]$Rect, [string]$Color, [float]$Width = 2) $p = New-Object System.Drawing.Pen (Color-Hex $Color), ($Width * $scale); try { $G.DrawRectangle($p, $Rect) } finally { $p.Dispose() } }

function FillRound {
	param($G, [System.Drawing.Rectangle]$Rect, [string]$Fill, [string]$Stroke = "", [float]$Radius = 6, [float]$Width = 2)
	$path = New-Object System.Drawing.Drawing2D.GraphicsPath
	$r = [int]($Radius * $scale)
	$path.AddArc($Rect.Left, $Rect.Top, $r, $r, 180, 90)
	$path.AddArc($Rect.Right - $r, $Rect.Top, $r, $r, 270, 90)
	$path.AddArc($Rect.Right - $r, $Rect.Bottom - $r, $r, $r, 0, 90)
	$path.AddArc($Rect.Left, $Rect.Bottom - $r, $r, $r, 90, 90)
	$path.CloseFigure()
	$b = New-Object System.Drawing.SolidBrush (Color-Hex $Fill)
	try { $G.FillPath($b, $path) } finally { $b.Dispose() }
	if ($Stroke -ne "") {
		$p = New-Object System.Drawing.Pen (Color-Hex $Stroke), ($Width * $scale)
		try { $G.DrawPath($p, $path) } finally { $p.Dispose() }
	}
	$path.Dispose()
}

function Glow {
	param($G, [int]$X, [int]$Y, [int]$Radius, [string]$Color)
	for ($i = 3; $i -ge 1; $i--) {
		$alphaColor = $Color
		$rect = RectS ($X - $Radius * $i / 3) ($Y - $Radius * $i / 3) ($Radius * 2 * $i / 3) ($Radius * 2 * $i / 3)
		E $G $rect $alphaColor
	}
}

function LabelLine {
	param($G, [int]$X, [int]$Y, [int]$W, [string]$Color)
	L $G $X $Y ($X + $W) $Y $Color 1.4
}

function Draw-Screen {
	param($G, [int]$X, [int]$Y, [int]$W, [int]$H, [string]$Tint = "#69d5ff")
	FillRound $G (RectS $X $Y $W $H) "#101821" "#05080d" 3 1.8
	FillRound $G (RectS ($X + 3) ($Y + 3) ($W - 6) ($H - 6)) $Tint "#153040" 2 1
	L $G ($X + 6) ($Y + $H - 9) ($X + $W - 8) ($Y + 7) "#dbf8ff" 1.5
	LabelLine $G ($X + 7) ($Y + 8) 12 "#7dffb0"
	LabelLine $G ($X + 23) ($Y + 8) 10 "#d98ac7"
}

function Draw-Shadow {
	param($G, [int]$X, [int]$Y, [int]$W, [int]$H)
	FillRound $G (RectS ($X + 2) ($Y + 3) $W $H) "#22000000" "" 6 0
}

function Draw-Asset {
	param($G, [string]$Name)
	switch ($Name) {
		"gaming_pc" {
			Glow $G 30 28 30 "#3012386f"
			Draw-Shadow $G 7 14 43 30
			Draw-Screen $G 8 12 39 28 "#62d5ff"
			F $G (RectS 21 40 13 4) "#1c2730"; F $G (RectS 16 45 23 4) "#101820"
			FillRound $G (RectS 49 18 9 30) "#161e28" "#05080d" 3 1.5
			L $G 53 23 53 41 "#8fd8a8" 1.5; E $G (RectS 51 45 5 5) "#d98ac7"
			L $G 12 53 44 53 "#d98ac7" 1.5; L $G 12 56 36 56 "#8fd8a8" 1
		}
		"messy_desk" {
			Draw-Shadow $G 5 24 54 25
			FillRound $G (RectS 5 23 54 24) "#624737" "#201714" 4 2
			F $G (RectS 8 44 7 14) "#302119"; F $G (RectS 49 44 7 14) "#302119"
			Draw-Screen $G 12 13 17 14 "#5bbfee"
			F $G (RectS 34 15 15 8) "#d8c06f"; L $G 36 19 47 18 "#a9842f" 1
			F $G (RectS 18 32 30 7) "#202a35"; LabelLine $G 21 35 21 "#79c8e6"
			E $G (RectS 48 31 5 8) "#283542"; F $G (RectS 11 29 7 7) "#efe2bb"
		}
		"gaming_chair" {
			Draw-Shadow $G 18 10 30 48
			FillRound $G (RectS 20 8 25 39) "#20283a" "#080d14" 8 2
			FillRound $G (RectS 24 14 17 11) "#334b67" "#101820" 4 1
			L $G 25 31 40 31 "#6fb9d8" 2; L $G 27 36 38 36 "#d98ac7" 1.5
			FillRound $G (RectS 18 42 30 13) "#171e2b" "#070b10" 5 2
			L $G 32 54 32 61 "#0f151c" 2; L $G 22 61 42 61 "#0f151c" 2
		}
		"noodle_cup" {
			Draw-Shadow $G 22 19 22 28
			FillRound $G (RectS 24 20 18 25) "#efe2bb" "#5c4b3d" 4 1.8
			FillRound $G (RectS 22 16 22 7) "#c76b6d" "#5c3438" 3 1.2
			L $G 27 29 39 29 "#d7a84f" 2; L $G 28 35 38 34 "#d7a84f" 1.5
			L $G 32 14 36 9 "#f4f0dd" 1.2; L $G 38 14 41 10 "#f4f0dd" 1.2
		}
		"soda_can" {
			Draw-Shadow $G 24 19 16 30
			FillRound $G (RectS 25 18 14 28) "#61ba8e" "#173a2d" 4 1.8
			L $G 29 23 36 35 "#d8fff0" 2; L $G 28 40 36 40 "#24513e" 1.4
			E $G (RectS 27 16 10 3) "#a8e4c7"
		}
		"rgb_sign" {
			Glow $G 32 31 30 "#30204cff"
			Draw-Shadow $G 7 20 50 24
			FillRound $G (RectS 8 20 48 22) "#111926" "#05070d" 4 2
			L $G 14 31 24 31 "#6fb9d8" 3; L $G 28 31 38 31 "#d98ac7" 3; L $G 42 31 50 31 "#8fd8a8" 3
			LabelLine $G 15 25 32 "#44556a"
		}
		"front_counter" {
			Draw-Shadow $G 5 25 54 28
			FillRound $G (RectS 6 25 52 26) "#4d3832" "#1f1515" 5 2
			Draw-Screen $G 13 12 22 14 "#79c8e6"
			F $G (RectS 39 16 12 10) "#e8c879"; LabelLine $G 11 39 38 "#7c5f4b"
			F $G (RectS 12 50 40 5) "#2f2422"
		}
		"snack_shelf" {
			Draw-Shadow $G 14 8 36 52
			FillRound $G (RectS 14 8 36 50) "#3f3334" "#1c1517" 4 2
			for ($y = 18; $y -le 46; $y += 14) { L $G 18 $y 46 $y "#7d5d49" 2 }
			F $G (RectS 20 21 8 8) "#c76b6d"; F $G (RectS 32 21 10 7) "#d7a84f"
			F $G (RectS 21 35 9 8) "#7fc8a0"; F $G (RectS 35 35 8 8) "#b9e3ea"
			F $G (RectS 22 48 18 5) "#c68b47"
		}
		"router_stack" {
			Draw-Shadow $G 15 18 34 32
			for ($y = 18; $y -le 42; $y += 10) {
				FillRound $G (RectS 16 $y 32 7) "#202a35" "#0f151c" 2 1.3
				L $G 22 ($y + 3) 29 ($y + 3) "#8fd8a8" 1.8; L $G 35 ($y + 3) 42 ($y + 3) "#6fb9d8" 1.2
			}
			L $G 20 49 14 57 "#111820" 1.5; L $G 38 49 47 57 "#111820" 1.5
		}
		"ashtray" {
			Draw-Shadow $G 18 31 30 13
			E $G (RectS 18 29 29 14) "#899094"; E $G (RectS 23 31 19 8) "#4a5055"
			L $G 25 29 39 21 "#d8d0bb" 2; L $G 38 21 42 19 "#ffb077" 1.5
			S $G (RectS 18 29 29 14) "#343b42" 1.5
		}
		"blue_wall_poster" {
			Draw-Shadow $G 15 10 35 45
			FillRound $G (RectS 15 10 34 44) "#20314a" "#111820" 3 2
			F $G (RectS 20 16 24 11) "#6fb9d8"; L $G 22 35 43 35 "#d98ac7" 2
			LabelLine $G 22 42 14 "#9fd9ff"; LabelLine $G 22 46 18 "#9fd9ff"
		}
		"headset" {
			Glow $G 32 34 18 "#225bc4ff"
			L $G 21 31 43 31 "#202a35" 4
			E $G (RectS 16 28 12 17) "#293542"; E $G (RectS 36 28 12 17) "#293542"
			L $G 43 43 51 49 "#6fb9d8" 1.5; E $G (RectS 50 48 4 4) "#d98ac7"
		}
		"keyboard_mouse" {
			Draw-Shadow $G 13 31 43 13
			FillRound $G (RectS 14 31 31 10) "#222b35" "#0f151c" 2 1
			E $G (RectS 48 30 9 13) "#293542"
			for ($x = 18; $x -le 38; $x += 5) { L $G $x 35 ($x + 2) 35 "#6fb9d8" 0.8 }
			L $G 50 36 55 36 "#79c8e6" 0.8
		}
		"sleeping_user" {
			Draw-Shadow $G 11 29 44 16
			FillRound $G (RectS 12 28 42 14) "#3f3334" "#171111" 6 1.5
			E $G (RectS 18 18 15 15) "#c99b78"; F $G (RectS 30 24 18 12) "#476070"
			L $G 36 16 43 12 "#79c8e6" 2; LabelLine $G 42 10 8 "#79c8e6"
		}
		"floor_cable" {
			L $G 8 46 26 38 "#111820" 3; L $G 26 38 44 49 "#111820" 3; L $G 44 49 55 34 "#111820" 3
			L $G 12 50 30 42 "#36495a" 1; L $G 28 36 36 28 "#d98ac7" 1.2
			E $G (RectS 53 31 5 5) "#8fd8a8"
		}
		"exit_door" {
			Draw-Shadow $G 18 8 30 52
			FillRound $G (RectS 19 8 28 50) "#32414f" "#0f151c" 4 2
			F $G (RectS 23 14 20 13) "#6fb9d8"; L $G 25 24 41 16 "#d8f6ff" 1.2
			E $G (RectS 39 35 4 4) "#e8c879"; F $G (RectS 23 48 20 5) "#1a232d"
		}
	}
}

$hd = New-Object System.Drawing.Bitmap ($columns * $cell), ($rows * $cell), ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
try {
	$hd.SetResolution(192, 192)
	$g = [System.Drawing.Graphics]::FromImage($hd)
	try {
		$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
		$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
		$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
		$g.Clear([System.Drawing.Color]::Transparent)
		for ($i = 0; $i -lt $names.Count; $i++) {
			$state = $g.Save()
			$x = ($i % $columns) * $cell
			$y = [int][Math]::Floor($i / $columns) * $cell
			$g.TranslateTransform($x, $y)
			Draw-Asset $g $names[$i]
			$g.Restore($state)
		}
	} finally { $g.Dispose() }
	$hd.Save($hdPreviewPath, [System.Drawing.Imaging.ImageFormat]::Png)

	$atlas = New-Object System.Drawing.Bitmap ($columns * $tile), ($rows * $tile), ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
	try {
		$ag = [System.Drawing.Graphics]::FromImage($atlas)
		try {
			$ag.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
			$ag.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
			$ag.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
			$ag.Clear([System.Drawing.Color]::Transparent)
			$ag.DrawImage($hd, 0, 0, $atlas.Width, $atlas.Height)
		} finally { $ag.Dispose() }
		$atlas.Save($atlasPath, [System.Drawing.Imaging.ImageFormat]::Png)

		$preview = New-Object System.Drawing.Bitmap $atlas.Width, $atlas.Height, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
		try {
			$pg = [System.Drawing.Graphics]::FromImage($preview)
			try {
				$pg.DrawImage($atlas, 0, 0, $atlas.Width, $atlas.Height)
				$pen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(180, 120, 220, 255)), 2
				try {
					for ($x = 0; $x -le $atlas.Width; $x += $tile) { $pg.DrawLine($pen, $x, 0, $x, $atlas.Height) }
					for ($y = 0; $y -le $atlas.Height; $y += $tile) { $pg.DrawLine($pen, 0, $y, $atlas.Width, $y) }
				} finally { $pen.Dispose() }
			} finally { $pg.Dispose() }
			$preview.Save($previewPath, [System.Drawing.Imaging.ImageFormat]::Png)
		} finally { $preview.Dispose() }
	} finally { $atlas.Dispose() }
} finally { $hd.Dispose() }

$guide = @"
# Internet Cafe Props

Quality target:
- Production-upgraded hand-drawn props for a Steam-facing demo.
- 4x oversampled source rendering, downsampled to a game-ready 64px atlas.
- Richer shadows, RGB glow, screen reflections, worn plastic, desk clutter, snack details and cable mess.

Prompt source:
old Chinese internet cafe, top-down 2D indie game environment, hand-drawn cartoon style, RGB gaming computers, messy desks, instant noodle cups, dim blue lighting, urban youth culture, cozy but slightly depressing atmosphere, clean line art, simple shading, modular layout, game-ready environment, designed for Godot engine.

Files:
- ``res://assets/sprites/internet_cafe_props.png``
- ``res://assets/art/internet_cafe_props_preview.png``
- ``res://assets/art/internet_cafe_props_hd_preview.png``

Art direction:
- Old Chinese neighborhood internet cafe, not cyberpunk.
- Dim blue lighting, cheap furniture, youth escape energy.
- Cozy but slightly depressing, matching the Shanghai survival life-sim tone.
"@
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($guidePath, $guide, $utf8NoBom)

Write-Output "atlas=$atlasPath"
Write-Output "preview=$previewPath"
Write-Output "hd_preview=$hdPreviewPath"
Write-Output "guide=$guidePath"
Write-Output "props=$($names.Count)"


