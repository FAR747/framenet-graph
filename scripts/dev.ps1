[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$EnvFile = '.env'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
if (-not [System.IO.Path]::IsPathRooted($EnvFile)) {
    $EnvFile = Join-Path $projectRoot $EnvFile
}
if (-not (Test-Path -LiteralPath $EnvFile -PathType Leaf)) {
    throw "Configuration file not found: $EnvFile. Copy .env.example to .env first."
}

# Parse literal values without executing PowerShell or expanding environment variables.
$configuration = @{}
$lineNumber = 0
foreach ($line in Get-Content -LiteralPath $EnvFile) {
    $lineNumber++
    $entry = $line.Trim()
    if (-not $entry -or $entry.StartsWith('#')) {
        continue
    }
    if ($entry -notmatch '^(WOW_PATH|WOW_CLIENT)\s*=(.*)$') {
        throw "Invalid configuration entry at line $lineNumber. Expected WOW_PATH or WOW_CLIENT."
    }

    $key = $Matches[1]
    $value = $Matches[2].Trim()
    if ($value.Length -ge 2) {
        if (($value.StartsWith('"') -and $value.EndsWith('"')) -or
            ($value.StartsWith("'") -and $value.EndsWith("'"))) {
            $value = $value.Substring(1, $value.Length - 2)
        }
    }
    if ($configuration.ContainsKey($key)) {
        throw "Duplicate configuration key at line ${lineNumber}: $key."
    }
    $configuration[$key] = $value
}

foreach ($key in @('WOW_PATH', 'WOW_CLIENT')) {
    if (-not $configuration.ContainsKey($key) -or [string]::IsNullOrWhiteSpace($configuration[$key])) {
        throw "Missing configuration value: $key."
    }
}
if (-not [System.IO.Path]::IsPathRooted($configuration.WOW_PATH)) {
    throw 'WOW_PATH must be an absolute installation path.'
}
if ($configuration.WOW_CLIENT -cnotin @('_forever_', '_retail_')) {
    throw 'WOW_CLIENT must be _forever_ or _retail_.'
}

$clientPath = Join-Path $configuration.WOW_PATH $configuration.WOW_CLIENT
$addonsPath = Join-Path $clientPath 'Interface\AddOns'
if (-not (Test-Path -LiteralPath $addonsPath -PathType Container)) {
    throw "Client AddOns directory not found: $addonsPath. Check WOW_PATH and WOW_CLIENT."
}
$destination = Join-Path $addonsPath 'FrameNetGraph'

# Explicit runtime roots keep configuration and development tools out of the game.
$files = @('FrameNetGraph.toc', 'LICENSE')
foreach ($directory in @('Core', 'UI', 'Libs')) {
    $sourceDirectory = Join-Path $projectRoot $directory
    foreach ($file in Get-ChildItem -LiteralPath $sourceDirectory -File -Recurse) {
        if ($file.Name -ne '.gitkeep') {
            $files += $file.FullName.Substring($projectRoot.Length + 1)
        }
    }
}

# Validate the complete manifest before writing anything to the destination.
foreach ($file in $files) {
    if (-not (Test-Path -LiteralPath (Join-Path $projectRoot $file) -PathType Leaf)) {
        throw "Deployment source file not found: $file."
    }
}
foreach ($line in Get-Content -LiteralPath (Join-Path $projectRoot 'FrameNetGraph.toc')) {
    $entry = $line.Trim().Replace('/', '\')
    if ($entry -and -not $entry.StartsWith('#') -and $entry -notin $files) {
        throw "TOC references a file outside the deployment manifest: $entry."
    }
}

if ($PSCmdlet.ShouldProcess($destination, "Copy $($files.Count) addon files")) {
    foreach ($file in $files) {
        $target = Join-Path $destination $file
        $targetDirectory = [System.IO.Path]::GetDirectoryName($target)
        [System.IO.Directory]::CreateDirectory($targetDirectory) | Out-Null
        Copy-Item -LiteralPath (Join-Path $projectRoot $file) -Destination $target -Force
    }
    Write-Output "Deployed $($files.Count) files to $destination"
}
