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

$tileImagePath = Join-Path $tilesDir "screenshot_road_tileset_64.png"
$tileSetPath = Join-Path $tilesDir "screenshot_road_tileset_64.tres"
$previewPath = Join-Path $artDir "screenshot_road_tileset_64_grid_preview.png"

Copy-Item -LiteralPath $sourcePath -Destination $tileImagePath -Force

$image = [System.Drawing.Image]::FromFile($sourcePath)
try {
	if ($image.Width % $TileSize -ne 0 -or $image.Height % $TileSize -ne 0) {
		throw "Source image size must be divisible by tile size $TileSize. Got $($image.Width)x$($image.Height)."
	}

	$columns = [int]($image.Width / $TileSize)
	$rows = [int]($image.Height / $TileSize)

	$preview = New-Object System.Drawing.Bitmap $image.Width, $image.Height, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
	try {
		$graphics = [System.Drawing.Graphics]::FromImage($preview)
		try {
			$graphics.DrawImage($image, 0, 0, $image.Width, $image.Height)
			$pen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(160, 255, 220, 80)), 2
			try {
				for ($x = 0; $x -le $image.Width; $x += $TileSize) {
					$graphics.DrawLine($pen, $x, 0, $x, $image.Height)
				}
				for ($y = 0; $y -le $image.Height; $y += $TileSize) {
					$graphics.DrawLine($pen, 0, $y, $image.Width, $y)
				}
			} finally {
				$pen.Dispose()
			}
		} finally {
			$graphics.Dispose()
		}
		$preview.Save($previewPath, [System.Drawing.Imaging.ImageFormat]::Png)
	} finally {
		$preview.Dispose()
	}

	$lines = New-Object System.Collections.Generic.List[string]
	$lines.Add('[gd_resource type="TileSet" format=3 uid="uid://dnqug6v28453x"]')
	$lines.Add('')
	$lines.Add('[ext_resource type="Texture2D" path="res://assets/tiles/screenshot_road_tileset_64.png" id="1_tiles"]')
	$lines.Add('')
	$lines.Add('[sub_resource type="TileSetAtlasSource" id="TileSetAtlasSource_screenshot_road"]')
	$lines.Add('texture = ExtResource("1_tiles")')
	$lines.Add("texture_region_size = Vector2i($TileSize, $TileSize)")
	for ($y = 0; $y -lt $rows; $y++) {
		for ($x = 0; $x -lt $columns; $x++) {
			$lines.Add("$x`:$y/0 = 0")
		}
	}
	$lines.Add('')
	$lines.Add('[resource]')
	$lines.Add("tile_size = Vector2i($TileSize, $TileSize)")
	$lines.Add('sources/0 = SubResource("TileSetAtlasSource_screenshot_road")')

	$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
	[System.IO.File]::WriteAllText($tileSetPath, ($lines -join [Environment]::NewLine) + [Environment]::NewLine, $utf8NoBom)

	Write-Output "tileset_image=$tileImagePath"
	Write-Output "tileset_resource=$tileSetPath"
	Write-Output "grid_preview=$previewPath"
	Write-Output "tile_count=$($columns * $rows)"
	Write-Output "tile_size=$TileSize"
} finally {
	$image.Dispose()
}
