param(
	[string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).Path
)

$ErrorActionPreference = "Stop"

$generator = Join-Path $Root "scripts\tools\generate_apartment_hd_assets.ps1"
if (-not (Test-Path $generator)) {
	throw "Base apartment asset generator not found: $generator"
}

& powershell -ExecutionPolicy Bypass -File $generator -Root $Root

$outputsDir = Join-Path $Root "assets\art\image2\outputs"
$godotDir = Join-Path $Root "assets\art\image2\godot"
New-Item -ItemType Directory -Force $outputsDir, $godotDir | Out-Null

function New-ConceptFallback {
	param(
		[string]$Source,
		[string]$Dest
	)

	Add-Type -AssemblyName System.Drawing

	$sourceImage = [System.Drawing.Image]::FromFile($Source)
	$canvas = New-Object System.Drawing.Bitmap 2048, 1152, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
	try {
		$canvas.SetResolution(192, 192)
		$graphics = [System.Drawing.Graphics]::FromImage($canvas)
		try {
			$graphics.Clear([System.Drawing.Color]::FromArgb(23, 25, 31))
			$graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
			$graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
			$destRect = New-Object System.Drawing.Rectangle 256, 0, 1536, 1152
			$srcRect = New-Object System.Drawing.Rectangle 0, 0, $sourceImage.Width, $sourceImage.Height
			$graphics.DrawImage($sourceImage, $destRect, $srcRect, [System.Drawing.GraphicsUnit]::Pixel)
		} finally {
			$graphics.Dispose()
		}

		$canvas.Save($Dest, [System.Drawing.Imaging.ImageFormat]::Png)
	} finally {
		$sourceImage.Dispose()
		$canvas.Dispose()
	}
}

$copies = @(
	@{
		Source = "assets\tiles\apartment_hd_tileset.png"
		Dest = "assets\art\image2\godot\apartment_tileset_v1.png"
	},
	@{
		Source = "assets\sprites\apartment_hd_props.png"
		Dest = "assets\art\image2\godot\apartment_props_v1.png"
	}
)

$conceptSource = Join-Path $Root "assets\art\apartment_hd_tileset_preview.png"
$conceptDest = Join-Path $Root "assets\art\image2\outputs\apartment_room_concept_v1.png"
if (-not (Test-Path $conceptSource)) {
	throw "Source asset missing: $conceptSource"
}
New-ConceptFallback -Source $conceptSource -Dest $conceptDest
Write-Output "generated=$conceptDest"

foreach ($copy in $copies) {
	$sourcePath = Join-Path $Root $copy.Source
	$destPath = Join-Path $Root $copy.Dest
	if (-not (Test-Path $sourcePath)) {
		throw "Source asset missing: $sourcePath"
	}
	Copy-Item -LiteralPath $sourcePath -Destination $destPath -Force
	Write-Output "generated=$destPath"
}

& powershell -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "validate_image2_assets.ps1") -Root $Root
& powershell -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "apply_apartment_image2_assets.ps1") -Root $Root
