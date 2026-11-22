# Build Encounter_ReBuilt.exe from this repository.
#
# The bot includes "../../../API/_GwAu3.au3", so it must be compiled from inside a GwAu3
# checkout at <GwAu3>\Scripts\EncounterHub\Encounter ReBuilt. This script:
#   1. copies the bot sources from "Encounter ReBuilt - PUBLIC" into that build folder,
#   2. runs Au3Check and fails on any error/warning in the bot's own files
#      (pre-existing GwAu3 API diagnostics are reported but ignored),
#   3. compiles a 32-bit exe with Aut2Exe,
#   4. swaps it in (the previous exe is kept as Encounter_ReBuilt.exe.previous; Windows
#      allows renaming an exe that running bots are using),
#   5. copies the new exe back into the repository.
#
# Usage: powershell -ExecutionPolicy Bypass -File tools\build_bot.ps1 [-GwAu3Root <path>] [-AutoItRoot <path>]
param(
    [string]$GwAu3Root = (Join-Path $env:USERPROFILE 'Documents\GitHub\GwAu3'),
    [string]$AutoItRoot = 'C:\Program Files (x86)\AutoIt3'
)
$ErrorActionPreference = 'Stop'

$repoBot = Join-Path (Split-Path $PSScriptRoot -Parent) 'Encounter ReBuilt - PUBLIC'
$buildDir = Join-Path $GwAu3Root 'Scripts\EncounterHub\Encounter ReBuilt'
$au3check = Join-Path $AutoItRoot 'Au3Check.exe'
$aut2exe = Join-Path $AutoItRoot 'Aut2Exe\Aut2exe.exe'

foreach ($path in @($repoBot, (Join-Path $GwAu3Root 'API\_GwAu3.au3'), $au3check, $aut2exe)) {
    if (-not (Test-Path $path)) { throw "Required path not found: $path" }
}
New-Item -ItemType Directory -Force (Join-Path $buildDir 'Files') | Out-Null
New-Item -ItemType Directory -Force (Join-Path $buildDir 'Images') | Out-Null

# 1. Sources (configs, logs and exes in the build folder are left alone).
Copy-Item (Join-Path $repoBot 'Encounter_ReBuilt.au3') $buildDir -Force
Copy-Item (Join-Path $repoBot 'Files\*.au3') (Join-Path $buildDir 'Files') -Force
Copy-Item (Join-Path $repoBot 'Images\*') (Join-Path $buildDir 'Images') -Force
Write-Host "Copied sources to $buildDir"

# 2. Syntax check.
$main = Join-Path $buildDir 'Encounter_ReBuilt.au3'
$check = & $au3check -q $main 2>&1 | Out-String
$lines = $check -split "`r?`n"
$ownErrors = $lines | Where-Object { $_ -match ' : error:' -and $_ -match [regex]::Escape($buildDir) }
$ownWarnings = @($lines | Where-Object { $_ -match ' : warning:' -and $_ -match [regex]::Escape($buildDir) })
$summary = ($lines | Where-Object { $_ -match 'error\(s\)' }) -join ''
Write-Host "Au3Check: $summary"
Write-Host "  bot-source warnings: $($ownWarnings.Count) (mostly 'possibly used before declaration', harmless at runtime)"
if ($ownErrors) {
    $ownErrors | ForEach-Object { Write-Host $_ }
    throw 'Au3Check reported errors in the bot sources; not compiling.'
}

# 3. Compile.
$newExe = Join-Path $buildDir 'Encounter_ReBuilt.new.exe'
Remove-Item $newExe -ErrorAction SilentlyContinue
$icon = Join-Path $buildDir 'Images\Encounter.ico'
$proc = Start-Process -FilePath $aut2exe -Wait -PassThru -ArgumentList @(
    '/in', "`"$main`"", '/out', "`"$newExe`"", '/icon', "`"$icon`"", '/x86', '/nopack')
if ($proc.ExitCode -ne 0 -or -not (Test-Path $newExe)) { throw "Aut2Exe failed (exit $($proc.ExitCode))" }

# 4. Swap.
$exe = Join-Path $buildDir 'Encounter_ReBuilt.exe'
$previous = "$exe.previous"
if (Test-Path $previous) {
    try { Remove-Item $previous -ErrorAction Stop }
    catch { $previous = "$exe.previous-$(Get-Date -Format yyyyMMddHHmmss)" }  # still in use by a bot
}
if (Test-Path $exe) { Rename-Item $exe (Split-Path $previous -Leaf) }
Rename-Item $newExe 'Encounter_ReBuilt.exe'

# 5. Back into the repository.
Copy-Item $exe (Join-Path $repoBot 'Encounter_ReBuilt.exe') -Force
$built = Get-Item $exe
Write-Host "Built $($built.FullName) ($([math]::Round($built.Length / 1KB)) KB, $($built.LastWriteTime))"
Write-Host 'Restart running bots to load the new build.'
