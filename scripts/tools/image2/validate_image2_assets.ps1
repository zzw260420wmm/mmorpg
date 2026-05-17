param(
	[string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).Path,
	[string]$ManifestPath = "assets\art\image2\image2_asset_manifest.json"
)

$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

$fullManifestPath = Join-Path $Root $ManifestPath
if (-not (Test-Path $fullManifestPath)) {
	throw "Manifest not found: $fullManifestPath"
}

$manifest = Get-Content $fullManifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
$failed = $false

foreach ($asset in $manifest.assets) {
	$relativePath = $asset.output_path -replace "^res://", ""
	$separator = [System.IO.Path]::DirectorySeparatorChar
	$localPath = Join-Path $Root ($relativePath -replace "/", $separator)
	if (-not (Test-Path $localPath)) {
		Write-Host "[missing] $($asset.id) -> $($asset.output_path)"
		continue
	}

	$image = [System.Drawing.Image]::FromFile($localPath)
	try {
		$actual = "$($image.Width)x$($image.Height)"
		$expected = "$($asset.target_width)x$($asset.target_height)"
		if ($image.Width -ne [int]$asset.target_width -or $image.Height -ne [int]$asset.target_height) {
			Write-Host "[size mismatch] $($asset.id) expected $expected got $actual"
			$failed = $true
		} else {
			Write-Host "[ok] $($asset.id) $actual"
		}
	} finally {
		$image.Dispose()
	}
}

if ($failed) {
	exit 1
}
