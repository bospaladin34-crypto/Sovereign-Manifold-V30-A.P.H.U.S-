$baseDir = "c:\sovereign_manifold_v31"
$vFiles = Get-ChildItem -Path "$baseDir\01_l0_rust\src\" -Filter "*.rs" | Where-Object {
    $n = $_.Name
    if ($n -match "^v(\d+)") {
        $num = [int]$matches[1]
        $num -ge 33 -and $num -le 72
    } else {
        $false
    }
}
Write-Host "Scanning $($vFiles.Count) files..."
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
