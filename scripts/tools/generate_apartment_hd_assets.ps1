param(
	[string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
)

$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

$TileSize = 64
$PropSize = 128

function New-Bitmap {
	param([int]$Width, [int]$Height)
	$bitmap = New-Object System.Drawing.Bitmap $Width, $Height, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
	$bitmap.SetResolution(192, 192)
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
	param($Bitmap, [int]$X, [int]$Y, [int]$W, [int]$H, [string]$Color, [int]$Thickness = 2)
	for ($i = 0; $i -lt $Thickness; $i++) {
		Fill-Rect $Bitmap ($X + $i) ($Y + $i) ($W - $i * 2) 1 $Color
		Fill-Rect $Bitmap ($X + $i) ($Y + $H - 1 - $i) ($W - $i * 2) 1 $Color
		Fill-Rect $Bitmap ($X + $i) ($Y + $i) 1 ($H - $i * 2) $Color
		Fill-Rect $Bitmap ($X + $W - 1 - $i) ($Y + $i) 1 ($H - $i * 2) $Color
	}
}

function Draw-LineRect {
	param($Bitmap, [int]$X1, [int]$Y1, [int]$X2, [int]$Y2, [string]$Color, [int]$Thickness = 2)
	$graphics = [System.Drawing.Graphics]::FromImage($Bitmap)
	$graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::None
	$graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
	$pen = New-Object System.Drawing.Pen (Color-Hex $Color), $Thickness
	try {
		$graphics.DrawLine($pen, $X1, $Y1, $X2, $Y2)
	} finally {
		$pen.Dispose()
		$graphics.Dispose()
	}
}

function Fill-TilePattern {
	param($Bitmap, [int]$Col, [int]$Row, [string]$Base, [string]$Accent, [string]$Dark)
	$x0 = $Col * $TileSize
	$y0 = $Row * $TileSize
	$baseColor = Color-Hex $Base
	$accentColor = Color-Hex $Accent
	$darkColor = Color-Hex $Dark
	for ($y = 0; $y -lt $TileSize; $y++) {
		for ($x = 0; $x -lt $TileSize; $x++) {
			$color = $baseColor
			if ((($x * 3 + $y * 5) % 31 -eq 0) -or (($x + $y) % 29 -eq 0)) {
				$color = $accentColor
			}
			if ((($x * 7 + $y * 11) % 97 -eq 0)) {
				$color = $darkColor
			}
			Set-PixelSafe $Bitmap ($x0 + $x) ($y0 + $y) $color
		}
	}
}

function Draw-FloorTile {
	param($Bitmap, [int]$Col, [int]$Row, [string]$Base, [string]$Accent, [string]$Line)
	Fill-TilePattern $Bitmap $Col $Row $Base $Accent "#6f5a48"
	$x = $Col * $TileSize
	$y = $Row * $TileSize
	Fill-Rect $Bitmap $x ($y + 31) $TileSize 2 $Line
	Fill-Rect $Bitmap ($x + 31) $y 2 $TileSize $Line
}

function Draw-WallTile {
	param($Bitmap, [int]$Col, [int]$Row, [string]$Base, [string]$Accent)
	Fill-TilePattern $Bitmap $Col $Row $Base $Accent "#615241"
	$x = $Col * $TileSize
	$y = $Row * $TileSize
	Fill-Rect $Bitmap $x ($y + 54) $TileSize 10 "#6c5a48"
	Fill-Rect $Bitmap $x ($y + 52) $TileSize 2 "#493c33"
}

function Draw-TileAtlas {
	param($Bitmap)
	Draw-FloorTile $Bitmap 0 0 "#8f8068" "#a08e73" "#746858"
	Draw-FloorTile $Bitmap 1 0 "#8b765d" "#9b886f" "#6b5b49"
	Draw-FloorTile $Bitmap 2 0 "#78624b" "#8d755b" "#5f4d3d"
	Draw-FloorTile $Bitmap 3 0 "#71675b" "#82776b" "#575047"
	Draw-FloorTile $Bitmap 4 0 "#758078" "#8a948c" "#5e6963"
	Draw-FloorTile $Bitmap 5 0 "#6f766f" "#848b82" "#535c58"
	Draw-FloorTile $Bitmap 6 0 "#7a6758" "#927967" "#604f44"
	Draw-FloorTile $Bitmap 7 0 "#524b45" "#62584f" "#3b3531"

	Draw-WallTile $Bitmap 0 1 "#7d6e5b" "#927f66"
	Draw-WallTile $Bitmap 1 1 "#77634f" "#8b765f"
	Draw-WallTile $Bitmap 2 1 "#68705f" "#7c846f"
	Draw-WallTile $Bitmap 3 1 "#6d6259" "#82756a"
	Draw-WallTile $Bitmap 4 1 "#5d7180" "#7691a0"
	Draw-WallTile $Bitmap 5 1 "#624a35" "#7a5a3f"
	Draw-WallTile $Bitmap 6 1 "#75665b" "#8c7a6d"
	Draw-WallTile $Bitmap 7 1 "#495366" "#5d6b82"

	Draw-FloorTile $Bitmap 0 2 "#59696e" "#6e7e82" "#405056"
	Draw-FloorTile $Bitmap 1 2 "#63736d" "#78897f" "#4b5952"
	Draw-FloorTile $Bitmap 2 2 "#505a54" "#667067" "#3d463f"
	Draw-FloorTile $Bitmap 3 2 "#8a7965" "#a08c72" "#6b5c4b"
	Draw-FloorTile $Bitmap 4 2 "#6d5b4b" "#826b55" "#514338"
	Draw-FloorTile $Bitmap 5 2 "#6d6a60" "#807d72" "#515047"
	Draw-FloorTile $Bitmap 6 2 "#594f46" "#6a5e53" "#403933"
	Draw-FloorTile $Bitmap 7 2 "#262b34" "#343b46" "#191d24"

	for ($col = 0; $col -lt 8; $col++) {
		$x = $col * $TileSize
		$y = 3 * $TileSize
		Fill-Rect $Bitmap $x $y $TileSize $TileSize "#00000000"
	}
	Fill-Rect $Bitmap 4 (3 * $TileSize + 16) 56 24 "#00000033"
	Fill-Rect $Bitmap ($TileSize + 8) (3 * $TileSize + 8) 48 48 "#4f6b7a55"
	Fill-Rect $Bitmap ($TileSize * 2 + 18) (3 * $TileSize + 8) 28 48 "#3d302866"
	Draw-LineRect $Bitmap ($TileSize * 3 + 8) (3 * $TileSize + 14) ($TileSize * 3 + 56) (3 * $TileSize + 46) "#b7a57d" 3
	Fill-Rect $Bitmap ($TileSize * 4 + 6) (3 * $TileSize + 20) 52 8 "#d8c8a0"
	Fill-Rect $Bitmap ($TileSize * 4 + 8) (3 * $TileSize + 30) 14 18 "#bdd3e0"
	Fill-Rect $Bitmap ($TileSize * 4 + 28) (3 * $TileSize + 30) 14 18 "#e08772"
	Fill-Rect $Bitmap ($TileSize * 5 + 8) (3 * $TileSize + 8) 48 48 "#2c3440"
	Stroke-Rect $Bitmap ($TileSize * 5 + 8) (3 * $TileSize + 8) 48 48 "#56636c" 3
	Fill-Rect $Bitmap ($TileSize * 5 + 14) (3 * $TileSize + 14) 16 36 "#9ec2cf"
	Fill-Rect $Bitmap ($TileSize * 5 + 34) (3 * $TileSize + 14) 16 36 "#f0ca7d"
	Fill-Rect $Bitmap ($TileSize * 6 + 10) (3 * $TileSize + 8) 44 46 "#6b4e38"
	Stroke-Rect $Bitmap ($TileSize * 6 + 10) (3 * $TileSize + 8) 44 46 "#3c3028" 4
	Fill-Rect $Bitmap ($TileSize * 6 + 40) (3 * $TileSize + 30) 5 5 "#d8b46f"
	Fill-Rect $Bitmap ($TileSize * 7 + 8) (3 * $TileSize + 10) 48 40 "#8f8068"
	Stroke-Rect $Bitmap ($TileSize * 7 + 8) (3 * $TileSize + 10) 48 40 "#6c5a48" 3
	Fill-Rect $Bitmap ($TileSize * 7 + 18) (3 * $TileSize + 20) 28 3 "#5c4d43"
	Fill-Rect $Bitmap ($TileSize * 7 + 18) (3 * $TileSize + 30) 20 3 "#5c4d43"
}

function Clear-PropCell {
	param($Bitmap, [int]$Col, [int]$Row)
	Fill-Rect $Bitmap ($Col * $PropSize) ($Row * $PropSize) $PropSize $PropSize "#00000000"
}

function Draw-BedProp {
	param($Bitmap, [int]$Col, [int]$Row)
	$x = $Col * $PropSize
	$y = $Row * $PropSize
	Clear-PropCell $Bitmap $Col $Row
	Fill-Rect $Bitmap ($x + 14) ($y + 30) 94 72 "#4f3f38"
	Stroke-Rect $Bitmap ($x + 14) ($y + 30) 94 72 "#2f2926" 4
	Fill-Rect $Bitmap ($x + 22) ($y + 38) 78 54 "#b45c62"
	Fill-Rect $Bitmap ($x + 28) ($y + 42) 30 22 "#e3d3b8"
	Fill-Rect $Bitmap ($x + 64) ($y + 44) 28 42 "#944c56"
	Fill-Rect $Bitmap ($x + 18) ($y + 100) 84 8 "#332b28"
}

function Draw-DeskProp {
	param($Bitmap, [int]$Col, [int]$Row)
	$x = $Col * $PropSize
	$y = $Row * $PropSize
	Clear-PropCell $Bitmap $Col $Row
	Fill-Rect $Bitmap ($x + 14) ($y + 54) 100 44 "#624a35"
	Stroke-Rect $Bitmap ($x + 14) ($y + 54) 100 44 "#34291f" 4
	Fill-Rect $Bitmap ($x + 46) ($y + 22) 42 30 "#26323d"
	Fill-Rect $Bitmap ($x + 50) ($y + 26) 34 16 "#9fc6d0"
	Fill-Rect $Bitmap ($x + 88) ($y + 62) 12 24 "#f1d379"
	Fill-Rect $Bitmap ($x + 26) ($y + 66) 34 8 "#d8c8a0"
	Fill-Rect $Bitmap ($x + 24) ($y + 98) 8 18 "#3d3028"
	Fill-Rect $Bitmap ($x + 96) ($y + 98) 8 18 "#3d3028"
}

function Draw-FridgeProp {
	param($Bitmap, [int]$Col, [int]$Row)
	$x = $Col * $PropSize
	$y = $Row * $PropSize
	Clear-PropCell $Bitmap $Col $Row
	Fill-Rect $Bitmap ($x + 40) ($y + 14) 50 98 "#d7ded5"
	Stroke-Rect $Bitmap ($x + 40) ($y + 14) 50 98 "#6f7c78" 4
	Fill-Rect $Bitmap ($x + 44) ($y + 50) 42 3 "#aeb9b4"
	Fill-Rect $Bitmap ($x + 80) ($y + 62) 4 28 "#5d6864"
	Fill-Rect $Bitmap ($x + 50) ($y + 20) 12 8 "#bdd3e0"
	Fill-Rect $Bitmap ($x + 64) ($y + 94) 14 8 "#e2d0a4"
}

function Draw-NoticeProp {
	param($Bitmap, [int]$Col, [int]$Row)
	$x = $Col * $PropSize
	$y = $Row * $PropSize
	Clear-PropCell $Bitmap $Col $Row
	Fill-Rect $Bitmap ($x + 30) ($y + 28) 66 72 "#efe0b2"
	Stroke-Rect $Bitmap ($x + 30) ($y + 28) 66 72 "#8a6c42" 4
	Fill-Rect $Bitmap ($x + 46) ($y + 42) 34 6 "#8a4b42"
	Fill-Rect $Bitmap ($x + 42) ($y + 58) 42 4 "#6c5a48"
	Fill-Rect $Bitmap ($x + 42) ($y + 72) 28 4 "#6c5a48"
	Fill-Rect $Bitmap ($x + 56) ($y + 14) 16 18 "#c76b6d"
}

function Draw-LaundryProp {
	param($Bitmap, [int]$Col, [int]$Row)
	$x = $Col * $PropSize
	$y = $Row * $PropSize
	Clear-PropCell $Bitmap $Col $Row
	Fill-Rect $Bitmap ($x + 14) ($y + 34) 100 6 "#d8c8a0"
	Fill-Rect $Bitmap ($x + 20) ($y + 42) 20 40 "#bdd3e0"
	Fill-Rect $Bitmap ($x + 50) ($y + 42) 22 42 "#e08772"
	Fill-Rect $Bitmap ($x + 82) ($y + 42) 18 38 "#f2d77b"
	Fill-Rect $Bitmap ($x + 20) ($y + 82) 6 32 "#6c5a48"
	Fill-Rect $Bitmap ($x + 100) ($y + 82) 6 32 "#6c5a48"
	Draw-LineRect $Bitmap ($x + 20) ($y + 112) ($x + 54) ($y + 84) "#6c5a48" 4
	Draw-LineRect $Bitmap ($x + 104) ($y + 112) ($x + 74) ($y + 84) "#6c5a48" 4
}

function Draw-ShoeRackProp {
	param($Bitmap, [int]$Col, [int]$Row)
	$x = $Col * $PropSize
	$y = $Row * $PropSize
	Clear-PropCell $Bitmap $Col $Row
	Fill-Rect $Bitmap ($x + 18) ($y + 42) 92 48 "#58483e"
	Stroke-Rect $Bitmap ($x + 18) ($y + 42) 92 48 "#352c28" 4
	Fill-Rect $Bitmap ($x + 24) ($y + 58) 80 4 "#2f2926"
	Fill-Rect $Bitmap ($x + 28) ($y + 70) 22 10 "#333942"
	Fill-Rect $Bitmap ($x + 56) ($y + 70) 22 10 "#6b4e38"
	Fill-Rect $Bitmap ($x + 82) ($y + 70) 18 10 "#4d635f"
}

function Draw-BoxProp {
	param($Bitmap, [int]$Col, [int]$Row)
	$x = $Col * $PropSize
	$y = $Row * $PropSize
	Clear-PropCell $Bitmap $Col $Row
	Fill-Rect $Bitmap ($x + 20) ($y + 62) 40 40 "#d0a45d"
	Stroke-Rect $Bitmap ($x + 20) ($y + 62) 40 40 "#75563a" 4
	Fill-Rect $Bitmap ($x + 64) ($y + 40) 44 62 "#b98f55"
	Stroke-Rect $Bitmap ($x + 64) ($y + 40) 44 62 "#75563a" 4
	Fill-Rect $Bitmap ($x + 32) ($y + 64) 4 36 "#8a6c42"
	Fill-Rect $Bitmap ($x + 76) ($y + 42) 4 58 "#8a6c42"
}

function Draw-WindowProp {
	param($Bitmap, [int]$Col, [int]$Row)
	$x = $Col * $PropSize
	$y = $Row * $PropSize
	Clear-PropCell $Bitmap $Col $Row
	Fill-Rect $Bitmap ($x + 18) ($y + 28) 92 52 "#2d3b48"
	Stroke-Rect $Bitmap ($x + 18) ($y + 28) 92 52 "#596878" 5
	Fill-Rect $Bitmap ($x + 28) ($y + 38) 32 32 "#9ec2cf"
	Fill-Rect $Bitmap ($x + 68) ($y + 38) 32 32 "#f0ca7d"
	Fill-Rect $Bitmap ($x + 62) ($y + 30) 4 48 "#41505d"
	Fill-Rect $Bitmap ($x + 14) ($y + 84) 100 12 "#6b4e38"
}

function Draw-SinkProp {
	param($Bitmap, [int]$Col, [int]$Row)
	$x = $Col * $PropSize
	$y = $Row * $PropSize
	Clear-PropCell $Bitmap $Col $Row
	Fill-Rect $Bitmap ($x + 16) ($y + 56) 96 40 "#63736d"
	Stroke-Rect $Bitmap ($x + 16) ($y + 56) 96 40 "#3f4b46" 4
	Fill-Rect $Bitmap ($x + 34) ($y + 64) 32 20 "#b8d8c4"
	Stroke-Rect $Bitmap ($x + 34) ($y + 64) 32 20 "#6d8d83" 3
	Fill-Rect $Bitmap ($x + 74) ($y + 64) 20 10 "#d8c886"
	Fill-Rect $Bitmap ($x + 50) ($y + 42) 8 18 "#5d6864"
	Fill-Rect $Bitmap ($x + 50) ($y + 40) 22 6 "#5d6864"
}

function Draw-DoorProp {
	param($Bitmap, [int]$Col, [int]$Row)
	$x = $Col * $PropSize
	$y = $Row * $PropSize
	Clear-PropCell $Bitmap $Col $Row
	Fill-Rect $Bitmap ($x + 38) ($y + 18) 54 94 "#6b4e38"
	Stroke-Rect $Bitmap ($x + 38) ($y + 18) 54 94 "#3c3028" 5
	Fill-Rect $Bitmap ($x + 78) ($y + 64) 8 8 "#d8b46f"
	Fill-Rect $Bitmap ($x + 46) ($y + 30) 28 60 "#79563d"
}

function Draw-RugProp {
	param($Bitmap, [int]$Col, [int]$Row)
	$x = $Col * $PropSize
	$y = $Row * $PropSize
	Clear-PropCell $Bitmap $Col $Row
	Fill-Rect $Bitmap ($x + 22) ($y + 42) 84 48 "#8a4b42"
	Stroke-Rect $Bitmap ($x + 22) ($y + 42) 84 48 "#5c3532" 4
	Fill-Rect $Bitmap ($x + 34) ($y + 54) 60 6 "#d8b46f"
	Fill-Rect $Bitmap ($x + 34) ($y + 72) 60 6 "#d8b46f"
}

function Draw-PropsAtlas {
	param($Bitmap)
	Draw-BedProp $Bitmap 0 0
	Draw-DeskProp $Bitmap 1 0
	Draw-FridgeProp $Bitmap 2 0
	Draw-NoticeProp $Bitmap 3 0
	Draw-LaundryProp $Bitmap 0 1
	Draw-ShoeRackProp $Bitmap 1 1
	Draw-BoxProp $Bitmap 2 1
	Draw-WindowProp $Bitmap 3 1
	Draw-SinkProp $Bitmap 0 2
	Draw-DoorProp $Bitmap 1 2
	Draw-RugProp $Bitmap 2 2
}

function Copy-Cell {
	param($Source, $Dest, [int]$SrcCol, [int]$SrcRow, [int]$DestX, [int]$DestY, [int]$CellSize)
	$graphics = [System.Drawing.Graphics]::FromImage($Dest)
	$graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
	$graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
	try {
		$srcRect = New-Object System.Drawing.Rectangle ($SrcCol * $CellSize), ($SrcRow * $CellSize), $CellSize, $CellSize
		$dstRect = New-Object System.Drawing.Rectangle $DestX, $DestY, $CellSize, $CellSize
		$graphics.DrawImage($Source, $dstRect, $srcRect, [System.Drawing.GraphicsUnit]::Pixel)
	} finally {
		$graphics.Dispose()
	}
}

function Draw-Preview {
	param($Preview, $Tiles, $Props)
	Fill-Rect $Preview 0 0 $Preview.Width $Preview.Height "#17191f"
	for ($row = 0; $row -lt 7; $row++) {
		for ($col = 0; $col -lt 9; $col++) {
			Copy-Cell $Tiles $Preview 0 0 (224 + $col * $TileSize) (192 + $row * $TileSize) $TileSize
		}
	}
	for ($col = 0; $col -lt 9; $col++) {
		Copy-Cell $Tiles $Preview 1 1 (224 + $col * $TileSize) 128 $TileSize
	}
	for ($row = 0; $row -lt 7; $row++) {
		Copy-Cell $Tiles $Preview 7 0 160 (192 + $row * $TileSize) $TileSize
		Copy-Cell $Tiles $Preview 7 0 800 (192 + $row * $TileSize) $TileSize
	}
	Copy-Cell $Tiles $Preview 5 3 288 128 $TileSize
	Copy-Cell $Tiles $Preview 5 3 672 128 $TileSize
	Copy-Cell $Props $Preview 0 0 224 256 $PropSize
	Copy-Cell $Props $Preview 1 0 576 224 $PropSize
	Copy-Cell $Props $Preview 2 0 672 384 $PropSize
	Copy-Cell $Props $Preview 3 0 448 224 $PropSize
	Copy-Cell $Props $Preview 0 1 256 480 $PropSize
	Copy-Cell $Props $Preview 1 1 576 480 $PropSize
	Copy-Cell $Props $Preview 1 2 448 512 $PropSize
}

$tilesDir = Join-Path $Root "assets\tiles"
$spritesDir = Join-Path $Root "assets\sprites"
$artDir = Join-Path $Root "assets\art"
New-Item -ItemType Directory -Force $tilesDir, $spritesDir, $artDir | Out-Null

$tileAtlas = New-Bitmap 512 256
$propAtlas = New-Bitmap 512 384
$preview = New-Bitmap 1024 768

try {
	Draw-TileAtlas $tileAtlas
	Draw-PropsAtlas $propAtlas
	Draw-Preview $preview $tileAtlas $propAtlas

	$tileAtlas.Save((Join-Path $tilesDir "apartment_hd_tileset.png"), [System.Drawing.Imaging.ImageFormat]::Png)
	$propAtlas.Save((Join-Path $spritesDir "apartment_hd_props.png"), [System.Drawing.Imaging.ImageFormat]::Png)
	$preview.Save((Join-Path $artDir "apartment_hd_tileset_preview.png"), [System.Drawing.Imaging.ImageFormat]::Png)
} finally {
	$tileAtlas.Dispose()
	$propAtlas.Dispose()
	$preview.Dispose()
}

Write-Host "Generated apartment HD assets."
