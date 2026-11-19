<#
.SYNOPSIS
  Copies MacroSets into your WoW AddOns folders so it's ready to test.

.DESCRIPTION
  Installs to Retail (_retail_), WoW Forever (_forever_), or both. The WoW root
  folder is remembered in deploy.config.json next to this script.

  Development files (tests, CI, lint config, deploy scripts) are skipped.
  Saved macro sets live in the WTF folder and are not touched.

.EXAMPLE
  .\deploy.ps1                       # copy to Retail and Forever (default)
  .\deploy.ps1 -Flavor Retail        # copy to Retail only
  .\deploy.ps1 -Link                 # junction instead: the game always sees your latest edits
  .\deploy.ps1 -WowPath "D:\Games\World of Warcraft"   # set/override the WoW root folder
#>
param(
    [ValidateSet('Both', 'Retail', 'Forever')]
    [string]$Flavor = 'Both',
    [string]$WowPath,
    [switch]$Link
)

$ErrorActionPreference = 'Stop'
$AddonName  = 'MacroSets'
$ProjectDir = $PSScriptRoot
$ConfigFile = Join-Path $ProjectDir 'deploy.config.json'

# Files and folders that are part of the project but not the addon.
$ExcludeFiles = @('.gitignore', '.luacheckrc', 'deploy.ps1', 'deploy.cmd', 'deploy.config.json', 'update.sh', 'user stories.md')
$ExcludeDirs  = @('.git', '.github', '.vscode', 'Tests')

$FlavorFolders = @{ Retail = '_retail_'; Forever = '_forever_' }

# 1. Work out the WoW root folder (the one containing _retail_ and _forever_).
if (-not $WowPath -and (Test-Path $ConfigFile)) {
    $WowPath = (Get-Content $ConfigFile -Raw | ConvertFrom-Json).WowPath
}
if (-not $WowPath) {
    $WowPath = 'C:\Program Files (x86)\World of Warcraft'
}
$WowPath = $WowPath.Trim('"').TrimEnd('\')
if (-not (Test-Path $WowPath)) {
    $WowPath = (Read-Host 'Paste your World of Warcraft folder (the one containing _retail_)').Trim('"').TrimEnd('\')
}
if (-not (Test-Path $WowPath)) { throw "Not a folder: $WowPath" }
@{ WowPath = $WowPath } | ConvertTo-Json | Set-Content $ConfigFile
Write-Host "World of Warcraft: $WowPath"

$flavors = if ($Flavor -eq 'Both') { @('Retail', 'Forever') } else { @($Flavor) }

foreach ($name in $flavors) {
    $flavorDir = Join-Path $WowPath $FlavorFolders[$name]
    if (-not (Test-Path $flavorDir)) {
        Write-Warning "$name is not installed ($flavorDir not found). Skipping."
        continue
    }

    $addOns = Join-Path $flavorDir 'Interface\AddOns'
    New-Item -ItemType Directory -Force -Path $addOns | Out-Null
    $target = Join-Path $addOns $AddonName
    $existing = Get-Item $target -ErrorAction SilentlyContinue

    if ($Link) {
        if ($existing) {
            if ($existing.LinkType) { $existing.Delete() } else { Remove-Item $target -Recurse -Force }
        }
        New-Item -ItemType Junction -Path $target -Target $ProjectDir | Out-Null
        Write-Host "${name}: linked $target -> $ProjectDir"
    } else {
        if ($existing -and $existing.LinkType) { $existing.Delete() }
        robocopy $ProjectDir $target /MIR /NFL /NDL /NJH /NJS /NP /XF $ExcludeFiles /XD $ExcludeDirs | Out-Null
        if ($LASTEXITCODE -ge 8) { throw "robocopy failed with code $LASTEXITCODE" }
        Write-Host "${name}: copied to $target"
    }
}

Write-Host 'Type /reload in game (or restart) to pick up changes.'
# robocopy returns 1 when files were copied; don't pass that on as a failure.
exit 0
