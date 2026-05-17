param(
	[string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).Path
)

$ErrorActionPreference = "Stop"

$tilesPng = Join-Path $Root "assets\art\image2\godot\apartment_tileset_v1.png"
$propsPng = Join-Path $Root "assets\art\image2\godot\apartment_props_v1.png"
$tilesTres = Join-Path $Root "assets\art\image2\godot\apartment_tileset_v1.tres"

if (-not (Test-Path $tilesPng)) {
	throw "Missing Image2 apartment tileset: $tilesPng"
}

if (-not (Test-Path $propsPng)) {
	Write-Host "[warn] Missing Image2 apartment props. The room will keep using the current fallback props."
}

Add-Type -AssemblyName System.Drawing

$image = [System.Drawing.Image]::FromFile($tilesPng)
try {
	if ($image.Width -ne 512 -or $image.Height -ne 256) {
		throw "apartment_tileset_v1.png must be 512x256, got $($image.Width)x$($image.Height)."
	}
} finally {
	$image.Dispose()
}

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add('[gd_resource type="TileSet" load_steps=3 format=3]')
$lines.Add('')
$lines.Add('[ext_resource type="Texture2D" path="res://assets/art/image2/godot/apartment_tileset_v1.png" id="1_tiles"]')
$lines.Add('')
$lines.Add('[sub_resource type="TileSetAtlasSource" id="TileSetAtlasSource_image2_apartment_v1"]')
$lines.Add('texture = ExtResource("1_tiles")')
$lines.Add('texture_region_size = Vector2i(64, 64)')
for ($row = 0; $row -lt 4; $row++) {
	for ($col = 0; $col -lt 8; $col++) {
		$lines.Add("$($col):$($row)/0 = 0")
	}
}
$lines.Add('')
$lines.Add('[resource]')
$lines.Add('tile_size = Vector2i(64, 64)')
$lines.Add('sources/0 = SubResource("TileSetAtlasSource_image2_apartment_v1")')

$utf8NoBom = [System.Text.UTF8Encoding]::new($false)
[System.IO.File]::WriteAllLines($tilesTres, $lines, $utf8NoBom)

Write-Host "Created res://assets/art/image2/godot/apartment_tileset_v1.tres"
Write-Host "In Godot, open res://scenes/world/apartment_interior.tscn and set ApartmentTileMap.tile_set to this new TileSet when ready."

