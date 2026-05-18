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

function New-Brush {
	param([string]$Color)
	return New-Object System.Drawing.SolidBrush (Color-Hex $Color)
}

function Fill-Ellipse {
	param($Graphics, [float]$X, [float]$Y, [float]$W, [float]$H, [string]$Color)
	$brush = New-Brush $Color
	$Graphics.FillEllipse($brush, $X, $Y, $W, $H)
	$brush.Dispose()
}

function Fill-RoundRect {
	param($Graphics, [float]$X, [float]$Y, [float]$W, [float]$H, [float]$R, [string]$Color)
	$path = New-Object System.Drawing.Drawing2D.GraphicsPath
	$diameter = $R * 2
	$path.AddArc($X, $Y, $diameter, $diameter, 180, 90)
	$path.AddArc($X + $W - $diameter, $Y, $diameter, $diameter, 270, 90)
	$path.AddArc($X + $W - $diameter, $Y + $H - $diameter, $diameter, $diameter, 0, 90)
	$path.AddArc($X, $Y + $H - $diameter, $diameter, $diameter, 90, 90)
	$path.CloseFigure()
	$brush = New-Brush $Color
	$Graphics.FillPath($brush, $path)
	$brush.Dispose()
	$path.Dispose()
}

function Stroke-RoundRect {
	param($Graphics, [float]$X, [float]$Y, [float]$W, [float]$H, [float]$R, [string]$Color, [float]$Width = 2.0)
	$path = New-Object System.Drawing.Drawing2D.GraphicsPath
	$diameter = $R * 2
	$path.AddArc($X, $Y, $diameter, $diameter, 180, 90)
	$path.AddArc($X + $W - $diameter, $Y, $diameter, $diameter, 270, 90)
	$path.AddArc($X + $W - $diameter, $Y + $H - $diameter, $diameter, $diameter, 0, 90)
	$path.AddArc($X, $Y + $H - $diameter, $diameter, $diameter, 90, 90)
	$path.CloseFigure()
	$pen = New-Object System.Drawing.Pen (Color-Hex $Color), $Width
	$Graphics.DrawPath($pen, $path)
	$pen.Dispose()
	$path.Dispose()
}

function Fill-Polygon {
	param($Graphics, [System.Drawing.PointF[]]$Points, [string]$Color)
	$brush = New-Brush $Color
	$Graphics.FillPolygon($brush, $Points)
	$brush.Dispose()
}

function Draw-Limb {
	param($Graphics, [float]$X, [float]$Y, [float]$W, [float]$H, [string]$Color)
	Fill-RoundRect $Graphics $X $Y $W $H 4 $Color
}

function Draw-Bag {
	param($Graphics, [float]$X, [float]$Y, [string]$Color, [string]$Ink)
	Fill-RoundRect $Graphics $X $Y 10 15 3 $Color
	Stroke-RoundRect $Graphics $X $Y 10 15 3 $Ink 1.4
}

function Draw-CharacterCell {
	param(
		$Graphics,
		[int]$Col,
		[int]$Row,
		[hashtable]$C,
		[string]$Direction,
		[bool]$Walking
	)
	$cell = 64
	$x = $Col * $cell
	$y = $Row * $cell
	$cx = $x + 32
	$bob = 0
	if ($Walking) { $bob = 1.5 }
	$step = 0
	if ($Walking) { $step = 3 }
	$ink = "#312826"
	$skin = $C.skin
	$hair = $C.hair
	$shirt = $C.shirt
	$pants = $C.pants
	$accent = $C.accent

	Fill-Ellipse $Graphics ($cx - 15) ($y + 49) 30 8 "#36000000"
	Draw-Limb $Graphics ($cx - 10 - $step) ($y + 39 + $bob) 7 14 $pants
	Draw-Limb $Graphics ($cx + 3 + $step) ($y + 39 - $bob) 7 14 $pants
	Fill-Ellipse $Graphics ($cx - 12 - $step) ($y + 51 + $bob) 11 5 "#26313d"
	Fill-Ellipse $Graphics ($cx + 1 + $step) ($y + 51 - $bob) 11 5 "#26313d"

	Fill-RoundRect $Graphics ($cx - 14) ($y + 25) 28 20 8 $shirt
	Stroke-RoundRect $Graphics ($cx - 14) ($y + 25) 28 20 8 $ink 1.7
	Draw-Limb $Graphics ($cx - 20) ($y + 28 + $step) 7 17 $shirt
	Draw-Limb $Graphics ($cx + 13) ($y + 28 - $step) 7 17 $shirt
	Fill-Ellipse $Graphics ($cx - 21) ($y + 43 + $step) 7 5 $skin
	Fill-Ellipse $Graphics ($cx + 14) ($y + 43 - $step) 7 5 $skin

	if ($Direction -eq "up") {
		Fill-Ellipse $Graphics ($cx - 12) ($y + 11) 24 18 $skin
		Fill-RoundRect $Graphics ($cx - 13) ($y + 7) 26 17 9 $hair
		Fill-RoundRect $Graphics ($cx - 9) ($y + 18) 18 8 4 $hair
	} elseif ($Direction -eq "left") {
		Fill-Ellipse $Graphics ($cx - 13) ($y + 11) 24 18 $skin
		Fill-RoundRect $Graphics ($cx - 13) ($y + 7) 24 14 8 $hair
		Fill-Ellipse $Graphics ($cx - 10) ($y + 19) 2.5 2.5 $ink
	} elseif ($Direction -eq "right") {
		Fill-Ellipse $Graphics ($cx - 11) ($y + 11) 24 18 $skin
		Fill-RoundRect $Graphics ($cx - 11) ($y + 7) 24 14 8 $hair
		Fill-Ellipse $Graphics ($cx + 8) ($y + 19) 2.5 2.5 $ink
	} else {
		Fill-Ellipse $Graphics ($cx - 12) ($y + 11) 24 18 $skin
		Fill-RoundRect $Graphics ($cx - 13) ($y + 7) 26 12 8 $hair
		Fill-Ellipse $Graphics ($cx - 6) ($y + 20) 2.4 2.4 $ink
		Fill-Ellipse $Graphics ($cx + 4) ($y + 20) 2.4 2.4 $ink
		$mouthPen = New-Object System.Drawing.Pen (Color-Hex "#9d6e5a"), 1.2
		$Graphics.DrawArc($mouthPen, $cx - 4, $y + 22, 8, 5, 15, 150)
		$mouthPen.Dispose()
	}
	Stroke-RoundRect $Graphics ($cx - 13) ($y + 7) 26 22 10 $ink 1.5

	switch ($C.kind) {
		"player_grad" {
			Draw-Bag $Graphics ($cx + 11) ($y + 31) "#8f7654" $ink
			Fill-RoundRect $Graphics ($cx - 10) ($y + 27) 20 5 2 "#6f8aa2"
		}
		"landlord" {
			Fill-RoundRect $Graphics ($cx + 12) ($y + 29) 7 11 3 "#b68b55"
			Fill-Ellipse $Graphics ($cx + 15) ($y + 39) 4 4 "#d8b46f"
		}
		"shopkeeper" {
			Fill-RoundRect $Graphics ($cx - 11) ($y + 27) 22 6 2 "#d8c886"
			Fill-RoundRect $Graphics ($cx + 7) ($y + 36) 7 6 2 "#f3dca2"
		}
		"drifter_girl" {
			Draw-Bag $Graphics ($cx - 22) ($y + 31) "#d8b46f" $ink
			Fill-RoundRect $Graphics ($cx - 11) ($y + 8) 22 5 3 "#3b2430"
		}
		"delivery_rider" {
			Fill-RoundRect $Graphics ($cx - 13) ($y + 7) 26 8 4 "#e5bd3f"
			Stroke-RoundRect $Graphics ($cx - 13) ($y + 7) 26 8 4 $ink 1.2
			Draw-Bag $Graphics ($cx + 13) ($y + 28) "#e5bd3f" $ink
		}
		"office_worker" {
			Fill-Polygon $Graphics ([System.Drawing.PointF[]]@(
				[System.Drawing.PointF]::new($cx - 4, $y + 26),
				[System.Drawing.PointF]::new($cx + 4, $y + 26),
				[System.Drawing.PointF]::new($cx + 1, $y + 40),
				[System.Drawing.PointF]::new($cx - 1, $y + 40)
			)) "#d6d0bd"
			Fill-RoundRect $Graphics ($cx - 23) ($y + 37) 10 12 3 "#4b3d34"
		}
		"streamer" {
			Fill-RoundRect $Graphics ($cx - 10) ($y + 27) 20 5 2 "#ffc4d6"
			Fill-Ellipse $Graphics ($cx + 14) ($y + 18) 5 5 "#ffe0e8"
		}
		"metro_commuter" {
			Draw-Bag $Graphics ($cx + 11) ($y + 31) "#2f5d45" $ink
		}
	}
	if ($accent -ne "") {
		Fill-Ellipse $Graphics ($cx + 12) ($y + 15) 4 4 $accent
	}
}

$spritesDir = Join-Path $Root "assets\sprites"
$artDir = Join-Path $Root "assets\art"
$refDir = Join-Path $Root "assets\art\image2\references"
New-Item -ItemType Directory -Force $spritesDir, $artDir, $refDir | Out-Null

$atlas = New-Bitmap 512 512
$g = [System.Drawing.Graphics]::FromImage($atlas)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
$g.Clear([System.Drawing.Color]::FromArgb(0, 0, 0, 0))

$characters = @(
	@{ kind = "player_grad"; shirt = "#4f6f88"; hair = "#2b2527"; skin = "#d7a778"; pants = "#46515a"; accent = "" },
	@{ kind = "landlord"; shirt = "#8d7560"; hair = "#3a3029"; skin = "#c49167"; pants = "#564940"; accent = "#b68b55" },
	@{ kind = "shopkeeper"; shirt = "#3f806f"; hair = "#25262b"; skin = "#d6a373"; pants = "#46515a"; accent = "" },
	@{ kind = "drifter_girl"; shirt = "#c55b70"; hair = "#241b22"; skin = "#d8a17b"; pants = "#4d515d"; accent = "#d8b46f" },
	@{ kind = "delivery_rider"; shirt = "#d9b63e"; hair = "#26313d"; skin = "#d6a373"; pants = "#4b4d45"; accent = "#e5bd3f" },
	@{ kind = "office_worker"; shirt = "#5d6870"; hair = "#24292f"; skin = "#d6a373"; pants = "#3f4650"; accent = "#6f8393" },
	@{ kind = "streamer"; shirt = "#c26c74"; hair = "#2b2527"; skin = "#d8a17b"; pants = "#4f4650"; accent = "#ffc4d6" },
	@{ kind = "metro_commuter"; shirt = "#6b7280"; hair = "#3b302b"; skin = "#c49167"; pants = "#3f4650"; accent = "#2f5d45" }
)
$directions = @("down", "up", "left", "right")
for ($i = 0; $i -lt $characters.Count; $i++) {
	for ($directionIndex = 0; $directionIndex -lt $directions.Count; $directionIndex++) {
		$idleRow = $directionIndex * 2
		$walkRow = $idleRow + 1
		Draw-CharacterCell $g $i $idleRow $characters[$i] $directions[$directionIndex] $false
		Draw-CharacterCell $g $i $walkRow $characters[$i] $directions[$directionIndex] $true
	}
}

$out = Join-Path $spritesDir "characters_atlas.png"
$atlas.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose()
$atlas.Dispose()

Copy-Item $out (Join-Path $refDir "characters_atlas.png") -Force
Write-Host "Generated cartoon character atlas: $out"
