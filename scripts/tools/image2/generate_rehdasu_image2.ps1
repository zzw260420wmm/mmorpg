param(
	[Parameter(Mandatory = $true)]
	[string]$Prompt,

	[Parameter(Mandatory = $true)]
	[string]$OutFile,

	[string]$ApiKey = $env:OPENAI_API_KEY,
	[string]$Endpoint = "https://rehdasu.cn/v1/images/generations",
	[string]$Model = "gpt-image-2",
	[string]$OutputFormat = "png"
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($ApiKey)) {
	throw "OPENAI_API_KEY is missing. Set it in the environment or pass -ApiKey."
}

$outDirectory = Split-Path -Parent $OutFile
if (-not [string]::IsNullOrWhiteSpace($outDirectory)) {
	New-Item -ItemType Directory -Force $outDirectory | Out-Null
}

$tempDirectory = Join-Path (Get-Location) "tmp\image2"
New-Item -ItemType Directory -Force $tempDirectory | Out-Null

$requestPath = Join-Path $tempDirectory "rehdasu_image2_request.json"
$responsePath = Join-Path $tempDirectory "rehdasu_image2_response.json"

$payload = @{
	model = $Model
	prompt = $Prompt
	output_format = $OutputFormat
} | ConvertTo-Json -Depth 8 -Compress

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($requestPath, $payload, $utf8NoBom)

& curl.exe -sS -X POST $Endpoint `
	-H "Authorization: Bearer $ApiKey" `
	-H "Content-Type: application/json" `
	--data-binary "@$requestPath" `
	-o $responsePath

$responseText = [System.IO.File]::ReadAllText($responsePath, [System.Text.Encoding]::UTF8)
try {
	$response = $responseText | ConvertFrom-Json
} catch {
	Write-Output $responseText
	throw "Image2 response was not valid JSON."
}

if (-not $response.data -or -not $response.data[0].b64_json) {
	Write-Output $responseText
	throw "Image2 response did not contain data[0].b64_json."
}

[System.IO.File]::WriteAllBytes($OutFile, [Convert]::FromBase64String($response.data[0].b64_json))

Add-Type -AssemblyName System.Drawing
$image = [System.Drawing.Image]::FromFile($OutFile)
try {
	Write-Output "saved=$OutFile"
	Write-Output "size=$($image.Width)x$($image.Height)"
} finally {
	$image.Dispose()
}
