# Run every built test executable and diff its stdout against the matching
# fixture in test-data\expected\. Skeleton only (M0).
[CmdletBinding()]
param(
    [ValidateSet('Debug','Release')] [string] $Config = 'Debug',
    [ValidateSet('Win32','Win64')]   [string] $Platform = 'Win64',
    [switch] $SkipBuild
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot

if (-not $SkipBuild) {
    & (Join-Path $PSScriptRoot 'build-all.ps1') -Config $Config -Platform $Platform
    if ($LASTEXITCODE -ne 0) { throw 'Build step failed.' }
}

$expectedDir = Join-Path $repoRoot 'test-data\expected'
$actualDir   = Join-Path $repoRoot 'test-data\actual'

if (Test-Path $actualDir) { Remove-Item -Recurse -Force $actualDir }
New-Item -ItemType Directory -Path $actualDir | Out-Null

$testDirs = Get-ChildItem -Path (Join-Path $repoRoot 'tests') -Directory -Filter 'check-*' -ErrorAction SilentlyContinue
if (-not $testDirs) {
    Write-Host 'No tests\check-* projects yet — nothing to run.'
    return
}

$failed = New-Object System.Collections.Generic.List[string]

foreach ($t in $testDirs) {
    $exeName = ($t.Name -replace '-', '_') + '.exe'
    $exePath = Join-Path $t.FullName "$Platform\$Config\$exeName"
    if (-not (Test-Path $exePath)) {
        Write-Warning "Missing exe: $exePath"
        $failed.Add($t.Name)
        continue
    }
    $outFile      = Join-Path $actualDir   "$($t.Name).out"
    $expectedFile = Join-Path $expectedDir "$($t.Name).out"
    & $exePath | Set-Content -Path $outFile -Encoding ascii
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[FAIL] $($t.Name) - exe exit code $LASTEXITCODE"
        $failed.Add($t.Name)
        continue
    }

    if (-not (Test-Path $expectedFile)) {
        # Fixture-less projects (e.g. pcg32_unique / pcg64_unique whose
        # output depends on the engine's memory address). Just confirm
        # the binary ran and produced non-empty output.
        if ((Get-Item $outFile).Length -gt 0) {
            Write-Host "[RUN ] $($t.Name) (no fixture; produced output)"
        } else {
            Write-Host "[FAIL] $($t.Name) (no fixture; empty output)"
            $failed.Add($t.Name)
        }
        continue
    }

    $exp = (Get-Content -Raw $expectedFile) -replace "`r`n","`n"
    $act = (Get-Content -Raw $outFile)      -replace "`r`n","`n"
    if ($exp -ceq $act) {
        Write-Host "[ OK ] $($t.Name)"
    } else {
        Write-Host "[FAIL] $($t.Name)"
        $failed.Add($t.Name)
    }
}

if ($failed.Count -gt 0) {
    Write-Host ''
    Write-Host "Failures: $($failed -join ', ')"
    exit 1
}
Write-Host ''
Write-Host 'All conformance tests passed.'
