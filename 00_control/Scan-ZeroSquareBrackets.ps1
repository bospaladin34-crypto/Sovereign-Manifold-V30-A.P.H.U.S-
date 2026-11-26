param(
    [string]$RepoRoot = ""
)

if (-not [string]::IsNullOrWhiteSpace($RepoRoot)) {
    if (-not (Test-Path -LiteralPath $RepoRoot -PathType Container)) {
        Write-Host "ZERO_BRACKET_ERROR: Explicit -RepoRoot directory does not exist: '$RepoRoot'" -ForegroundColor Red
        exit 1
    }
    $baseDir = (Resolve-Path -LiteralPath $RepoRoot).Path
} elseif (-not [string]::IsNullOrWhiteSpace($env:GITHUB_WORKSPACE) -and (Test-Path -LiteralPath $env:GITHUB_WORKSPACE -PathType Container)) {
    $baseDir = (Resolve-Path -LiteralPath $env:GITHUB_WORKSPACE).Path
} elseif (-not [string]::IsNullOrWhiteSpace($PSScriptRoot) -and (Test-Path -LiteralPath (Split-Path -Parent $PSScriptRoot) -PathType Container)) {
    $baseDir = (Resolve-Path -LiteralPath (Split-Path -Parent $PSScriptRoot)).Path
} else {
    Write-Host "ZERO_BRACKET_ERROR: Failed to resolve repository root from -RepoRoot, GITHUB_WORKSPACE, or PSScriptRoot." -ForegroundColor Red
    exit 1
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
