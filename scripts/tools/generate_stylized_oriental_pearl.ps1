param(
	[string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
)

$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

$uiDir = Join-Path $Root "assets\ui"
$artDir = Join-Path $Root "assets\art"
New-Item -ItemType Directory -Force $uiDir, $artDir | Out-Null

$assetPath = Join-Path $uiDir "dfmz_stylized.png"
$previewPath = Join-Path $artDir "dfmz_stylized_preview.png"

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

function New-Brush {
	param([string]$Color)
	return New-Object System.Drawing.SolidBrush (Color-Hex $Color)
}

function New-Pen {
	param([string]$Color, [float]$Width)
	$pen = New-Object System.Drawing.Pen (Color-Hex $Color), $Width
	$pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
	$pen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
	$pen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
	return $pen
}

function Fill-Rect {
	param($Graphics, [int]$X, [int]$Y, [int]$W, [int]$H, [string]$Color)
	$brush = New-Brush $Color
	try {
		$Graphics.FillRectangle($brush, $X, $Y, $W, $H)
	} finally {
		$brush.Dispose()
	}
}

function Fill-Ellipse {
	param($Graphics, [int]$X, [int]$Y, [int]$W, [int]$H, [string]$Color)
	$brush = New-Brush $Color
	try {
		$Graphics.FillEllipse($brush, $X, $Y, $W, $H)
	} finally {
		$brush.Dispose()
	}
}

function Fill-Ellipse-Gradient {
	param($Graphics, [int]$X, [int]$Y, [int]$W, [int]$H, [string]$TopColor, [string]$BottomColor)
	$rect = New-Object System.Drawing.Rectangle $X, $Y, $W, $H
	$brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush $rect, (Color-Hex $TopColor), (Color-Hex $BottomColor), 90
	try {
		$Graphics.FillEllipse($brush, $rect)
	} finally {
		$brush.Dispose()
	}
}

function Stroke-Ellipse {
	param($Graphics, [int]$X, [int]$Y, [int]$W, [int]$H, [string]$Color, [float]$Width)
	$pen = New-Pen $Color $Width
	try {
		$Graphics.DrawEllipse($pen, $X, $Y, $W, $H)
	} finally {
		$pen.Dispose()
	}
}

function Draw-Line {
	param($Graphics, [int]$X1, [int]$Y1, [int]$X2, [int]$Y2, [string]$Color, [float]$Width)
	$pen = New-Pen $Color $Width
	try {
		$Graphics.DrawLine($pen, $X1, $Y1, $X2, $Y2)
	} finally {
		$pen.Dispose()
	}
}

function Fill-Polygon {
	param($Graphics, [System.Drawing.Point[]]$Points, [string]$Color)
	$brush = New-Brush $Color
	try {
		$Graphics.FillPolygon($brush, $Points)
	} finally {
		$brush.Dispose()
	}
}

function Draw-Window-Band {
	param($Graphics, [int]$Y, [int]$Left, [int]$Right, [int]$Step)
	for ($x = $Left; $x -le $Right; $x += $Step) {
		Fill-Rect $Graphics $x $Y 10 16 "#c7e7ff"
		Fill-Rect $Graphics ($x + 2) ($Y + 2) 6 4 "#fff0b8"
	}
}

$width = 512
$height = 720
$bitmap = New-Object System.Drawing.Bitmap $width, $height, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
try {
	$bitmap.SetResolution(192, 192)
	$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
	try {
		$graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
		$graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
		$graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
		$graphics.Clear([System.Drawing.Color]::Transparent)

		Fill-Ellipse $graphics 122 664 268 34 "#33000000"

		Draw-Line $graphics 256 48 256 672 "#314652" 18
		Draw-Line $graphics 222 205 156 664 "#405b68" 14
		Draw-Line $graphics 290 205 356 664 "#405b68" 14
		Draw-Line $graphics 186 674 326 674 "#314652" 18

		Fill-Polygon $graphics @(
			(New-Object System.Drawing.Point 244, 12),
			(New-Object System.Drawing.Point 268, 12),
			(New-Object System.Drawing.Point 276, 84),
			(New-Object System.Drawing.Point 236, 84)
		) "#d9b46a"
		Fill-Polygon $graphics @(
			(New-Object System.Drawing.Point 250, 0),
			(New-Object System.Drawing.Point 262, 0),
			(New-Object System.Drawing.Point 268, 20),
			(New-Object System.Drawing.Point 244, 20)
		) "#f0cf82"
		Fill-Rect $graphics 226 80 60 74 "#8fb1c2"
		Fill-Rect $graphics 238 92 36 36 "#c7e7ff"
		Draw-Line $graphics 228 154 284 154 "#314652" 8

		Fill-Ellipse $graphics 154 154 204 204 "#273945"
		Fill-Ellipse-Gradient $graphics 168 168 176 176 "#a5c6d2" "#7797a7"
		Fill-Ellipse $graphics 196 202 120 86 "#c87578"
		Fill-Ellipse $graphics 224 226 60 42 "#efc36f"
		Stroke-Ellipse $graphics 168 168 176 176 "#405b68" 10
		Draw-Line $graphics 180 256 332 256 "#f0c77b" 5
		Draw-Window-Band $graphics 286 214 292 26

		Draw-Line $graphics 256 352 256 424 "#314652" 14
		Draw-Line $graphics 202 346 310 346 "#314652" 10
		Draw-Line $graphics 176 552 336 552 "#314652" 10

		Fill-Ellipse $graphics 96 396 320 214 "#273945"
		Fill-Ellipse-Gradient $graphics 114 412 284 178 "#a7c7d3" "#7d9daa"
		Fill-Ellipse $graphics 154 452 204 92 "#c87578"
		Fill-Ellipse $graphics 214 480 84 42 "#efc36f"
		Stroke-Ellipse $graphics 114 412 284 178 "#405b68" 12
		Draw-Line $graphics 128 502 384 502 "#f0c77b" 5
		Draw-Window-Band $graphics 532 174 328 28

		Fill-Rect $graphics 186 620 140 58 "#6f8795"
		Fill-Rect $graphics 172 672 168 24 "#4d5d70"
		for ($i = 0; $i -lt 6; $i++) {
			Fill-Rect $graphics (198 + $i * 20) 636 12 18 "#c7e7ff"
		}
		Fill-Rect $graphics 240 622 32 74 "#314652"

		Fill-Ellipse $graphics 202 180 44 18 "#d4edf3"
		Fill-Ellipse $graphics 282 432 72 24 "#d4edf3"
		Draw-Line $graphics 182 188 210 172 "#d4edf3" 3
		Draw-Line $graphics 310 440 348 420 "#d4edf3" 3
	} finally {
		$graphics.Dispose()
	}
	$bitmap.Save($assetPath, [System.Drawing.Imaging.ImageFormat]::Png)

	$preview = New-Object System.Drawing.Bitmap 560, 780, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
	try {
		$previewGraphics = [System.Drawing.Graphics]::FromImage($preview)
		try {
			$previewGraphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
			$previewGraphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
			$previewGraphics.Clear((Color-Hex "#26313d"))
			$previewGraphics.DrawImage($bitmap, 24, 30, $width, $height)
		} finally {
			$previewGraphics.Dispose()
		}
		$preview.Save($previewPath, [System.Drawing.Imaging.ImageFormat]::Png)
	} finally {
		$preview.Dispose()
	}
} finally {
	$bitmap.Dispose()
}

Write-Output "asset=$assetPath"
Write-Output "preview=$previewPath"
