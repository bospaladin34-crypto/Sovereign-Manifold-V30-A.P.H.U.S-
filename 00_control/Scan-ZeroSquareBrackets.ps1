param(
    [string]$RepoRoot = ""
)

$baseDir = if ($RepoRoot -and (Test-Path $RepoRoot)) {
    (Resolve-Path $RepoRoot).Path
} elseif ($env:GITHUB_WORKSPACE -and (Test-Path $env:GITHUB_WORKSPACE)) {
    (Resolve-Path $env:GITHUB_WORKSPACE).Path
} elseif ($PSScriptRoot -and (Test-Path (Split-Path -Parent $PSScriptRoot))) {
    (Resolve-Path (Split-Path -Parent $PSScriptRoot)).Path
} else {
    "C:\sovereign_manifold_v31"
}

$srcDir = Join-Path $baseDir "01_l0_rust\src"
if (-not (Test-Path $srcDir)) {
    Write-Host "ZERO_BRACKET_ERROR: Source directory not found at $srcDir" -ForegroundColor Red
    exit 1
}

$vFiles = @(Get-ChildItem -Path $srcDir -Filter "*.rs" -File | Where-Object {
    $n = $_.Name
    if ($n -match "^v(\d+)") {
        $num = [int]$matches[1]
        $num -ge 33 -and $num -le 99
    } else {
        $false
    }
})

if ($vFiles.Count -eq 0) {
    Write-Host "ZERO_BRACKET_ERROR: Found 0 matching v33..v99 .rs files in $srcDir" -ForegroundColor Red
    exit 1
}

Write-Host "Scanning $($vFiles.Count) files in $srcDir..."
$bracketViolations = @()
foreach ($vf in $vFiles) {
    $content = Get-Content -Path $vf.FullName
    $lineIdx = 0
    foreach ($line in $content) {
        $lineIdx++
        if ($line -match "\[|\]") {
            $bracketViolations += "$($vf.Name):$lineIdx : $line"
        }
    }
}
if ($bracketViolations.Count -eq 0) {
    Write-Host "ZERO_BRACKET_PASS: All $($vFiles.Count) files have exactly 0 square brackets!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "VIOLATIONS ($($bracketViolations.Count)):" -ForegroundColor Red
    $bracketViolations | Select-Object -First 20 | ForEach-Object { Write-Host "   $_" -ForegroundColor DarkRed }
    exit 1
}
