$v49File = "C:\sovereign_manifold_v31\01_l0_rust\src\v49_muse_clean_and_chain100_synthesis.rs"
$bytes = [System.IO.File]::ReadAllBytes($v49File)
$openBrackets = ($bytes | Where-Object { $_ -eq 91 }).Length
$closeBrackets = ($bytes | Where-Object { $_ -eq 93 }).Length
$total = $openBrackets + $closeBrackets
Write-Host "File: $v49File"
Write-Host "Length: $($bytes.Length) bytes"
Write-Host "Open [ (0x5B): $openBrackets"
Write-Host "Close ] (0x5D): $closeBrackets"
Write-Host "Total: $total"
if ($total -eq 0) {
    Write-Host "ZERO BRACKETS VERIFIED: PASS" -ForegroundColor Green
    exit 0
} else {
    Write-Host "BRACKET VIOLATION: FAIL ($total brackets found)" -ForegroundColor Red
    exit 1
}
