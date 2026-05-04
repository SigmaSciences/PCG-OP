# Build every test project under tests\check-* via the delphi-msbuild skill.
# Skeleton only (M0). Implementation lands in M2 once the first .dproj exists.
[CmdletBinding()]
param(
    [ValidateSet('Debug','Release')] [string] $Config = 'Debug',
    [ValidateSet('Win32','Win64')]   [string] $Platform = 'Win64',
    [switch] $Clean
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$skill    = Join-Path $env:USERPROFILE '.claude\skills\delphi-msbuild\scripts\build-delphi-msbuild.ps1'

if (-not (Test-Path $skill)) {
    throw "delphi-msbuild skill not found at $skill"
}

$projects = Get-ChildItem -Path (Join-Path $repoRoot 'tests') -Recurse -Filter '*.dproj' -ErrorAction SilentlyContinue
if (-not $projects) {
    Write-Host 'No .dproj files yet — nothing to build.'
    return
}

foreach ($proj in $projects) {
    Write-Host "==> Building $($proj.Name) [$Platform / $Config]"
    if ($Clean) {
        & $skill -Project $proj.FullName -Config $Config -Clean
    } else {
        & $skill -Project $proj.FullName -Config $Config
    }
    if ($LASTEXITCODE -ne 0) { throw "Build failed: $($proj.FullName)" }
}

Write-Host 'All builds succeeded.'
