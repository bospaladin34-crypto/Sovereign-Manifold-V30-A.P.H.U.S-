$baseDir = "c:\sovereign_manifold_v31"
$manifest = Get-Content "$baseDir\00_control\weights\sovereign_harmonic_weights_manifest.json" -Raw | ConvertFrom-Json
foreach ($prop in $manifest.artifacts.PSObject.Properties) {
    $key = $prop.Name
    $val = $prop.Value
    $fullPath = Join-Path $baseDir $val.relative_path
    if (Test-Path $fullPath) {
        $bytes = [System.IO.File]::ReadAllBytes($fullPath)
        $actualMagic = if ($bytes.Length -ge 4) {
            "0x{0:X8}" -f [System.BitConverter]::ToUInt32($bytes, 0)
        } else { "N/A" }
        Write-Host ("{0,-32} : Expected {1,-10} Actual {2}" -f $key, $val.magic, $actualMagic)
    } else {
        Write-Host ("{0,-32} : FILE NOT FOUND" -f $key) -ForegroundColor Red
    }
}
