# ==============================================================================
# ACT-Omega Net v74.0.0 — Lossless Repo JSONL Ledger Archiver & Tail Rotator
# Prevents tracked 03_vault/connectome/*.jsonl files from hitting GitHub/GitLab's
# 50 MB warning / 100 MB single-file push block while preserving 100% of full
# historical lines on E:\Sovereign_Manifold_SSD_Vault (+ .gz archives for R2).
# Primary Author & Principal Systems Architect: Donevin Frownfelter (@bospaladin34-crypto)
# ==============================================================================
param(
    [string]$RepoRoot = "C:\sovereign_manifold_v31",
    [string]$EVaultRoot = "E:\Sovereign_Manifold_SSD_Vault",
    [string]$EpochLabel = "v74_0_0_pre_stage_b"
)

$ErrorActionPreference = "Stop"
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

if (-not (Test-Path $EVaultRoot)) {
    throw "FAIL_CLOSED_EVAULT_UNMOUNTED: $EVaultRoot must be mounted before rotating repo JSONL ledgers so zero historical lines are ever lost."
}

$archiveDir = Join-Path $EVaultRoot "epoch_ledger_archives\$EpochLabel"
New-Item -ItemType Directory -Path $archiveDir -Force | Out-Null

function Get-BytesSha256Hex {
    param([byte[]]$Bytes)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        return ([System.BitConverter]::ToString($sha.ComputeHash($Bytes))).Replace("-", "").ToLowerInvariant()
    } finally {
        $sha.Dispose()
    }
}

function Compress-FileToGzip {
    param([string]$SourcePath, [string]$GzipPath)
    $inStream = [System.IO.File]::OpenRead($SourcePath)
    try {
        $outStream = [System.IO.File]::Create($GzipPath)
        try {
            $gzStream = New-Object System.IO.Compression.GZipStream($outStream, [System.IO.Compression.CompressionLevel]::Optimal)
            try {
                $inStream.CopyTo($gzStream)
            } finally {
                $gzStream.Dispose()
            }
        } finally {
            $outStream.Dispose()
        }
    } finally {
        $inStream.Dispose()
    }
}

$ledgerSpecs = @(
    @{
        RelPath   = "03_vault/connectome/message_bus_ledger_v4800.jsonl"
        KeepLines = 1500
        PrimaryE  = Join-Path $EVaultRoot "coordinator_bus\message_bus_ledger_v4800.jsonl"
    },
    @{
        RelPath   = "03_vault/connectome/aegis_autonomous_cron_ledger_v5700.jsonl"
        KeepLines = 800
        PrimaryE  = Join-Path $EVaultRoot "connectome\aegis_autonomous_cron_ledger_v5700.jsonl"
    },
    @{
        RelPath   = "03_vault/connectome/codegen_integration_manifest_v4800.jsonl"
        KeepLines = 800
        PrimaryE  = Join-Path $EVaultRoot "coordinator_bus\codegen_integration_manifest_v4800.jsonl"
    }
)

$rotatedRecords = New-Object System.Collections.Generic.List[object]

foreach ($spec in $ledgerSpecs) {
    $cFull = Join-Path $RepoRoot ($spec.RelPath -replace '/', '\')
    if (-not (Test-Path -LiteralPath $cFull -PathType Leaf)) {
        continue
    }

    $rawBytes = [System.IO.File]::ReadAllBytes($cFull)
    $leafName = Split-Path -Leaf $cFull
    $eSnapRaw = Join-Path $archiveDir $leafName
    $eSnapGz  = Join-Path $archiveDir "$leafName.gz"

    # 1. Preserve existing larger epoch archive on E:\ on idempotent re-runs; otherwise write full snapshot + GZip
    if ((Test-Path -LiteralPath $eSnapRaw -PathType Leaf) -and ((Get-Item -LiteralPath $eSnapRaw).Length -gt $rawBytes.Length)) {
        $preBytes = (Get-Item -LiteralPath $eSnapRaw).Length
        $preSha   = (Get-FileHash -LiteralPath $eSnapRaw -Algorithm SHA256).Hash.ToLowerInvariant()
        $origLinesCount = ([System.IO.File]::ReadAllLines($eSnapRaw, $utf8NoBom) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }).Count
        if (-not (Test-Path -LiteralPath $eSnapGz -PathType Leaf)) {
            Compress-FileToGzip -SourcePath $eSnapRaw -GzipPath $eSnapGz
        }
    } else {
        $preBytes = $rawBytes.Length
        $preSha   = Get-BytesSha256Hex -Bytes $rawBytes
        [System.IO.File]::WriteAllBytes($eSnapRaw, $rawBytes)
        $verifyESha = (Get-FileHash -LiteralPath $eSnapRaw -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($verifyESha -ne $preSha) {
            throw "ARCHIVE_SHA256_MISMATCH on $eSnapRaw ($verifyESha != $preSha)"
        }
        Compress-FileToGzip -SourcePath $eSnapRaw -GzipPath $eSnapGz
        $origLinesCount = -1
    }
    $gzItem = Get-Item -LiteralPath $eSnapGz
    $gzSha  = (Get-FileHash -LiteralPath $eSnapGz -Algorithm SHA256).Hash.ToLowerInvariant()

    # Ensure PrimaryE also exists (never truncate PrimaryE on E:\!)
    $primaryEParent = Split-Path -Parent $spec.PrimaryE
    if (-not (Test-Path $primaryEParent)) {
        New-Item -ItemType Directory -Path $primaryEParent -Force | Out-Null
    }
    if (-not (Test-Path -LiteralPath $spec.PrimaryE)) {
        Copy-Item -LiteralPath $eSnapRaw -Destination $spec.PrimaryE -Force
    }
    $primaryEBytes = (Get-Item -LiteralPath $spec.PrimaryE).Length

    # 2. Read non-empty valid lines and keep the recent tail
    $allLines = [System.IO.File]::ReadAllLines($cFull, $utf8NoBom) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    $totalLines = if ($origLinesCount -gt 0) { $origLinesCount } else { $allLines.Count }
    $keepN = [Math]::Min($spec.KeepLines, $allLines.Count)
    $tailLines = if ($allLines.Count -gt $keepN) {
        $allLines[($allLines.Count - $keepN)..($allLines.Count - 1)]
    } else {
        $allLines
    }

    # Validate retained lines parse as JSON
    foreach ($ln in $tailLines) {
        $null = $ln | ConvertFrom-Json
    }

    $tailText = ($tailLines -join "`n") + "`n"
    $tailBytesArr = $utf8NoBom.GetBytes($tailText)
    $postBytes = $tailBytesArr.Length
    $postSha   = Get-BytesSha256Hex -Bytes $tailBytesArr

    $tmpTarget = "$cFull.tmp_$([guid]::NewGuid().ToString('N'))"
    [System.IO.File]::WriteAllBytes($tmpTarget, $tailBytesArr)
    Move-Item -LiteralPath $tmpTarget -Destination $cFull -Force

    $rotatedRecords.Add([ordered]@{
        repo_path              = $spec.RelPath
        pre_rotation_bytes     = [int64]$preBytes
        pre_rotation_lines     = [int]$totalLines
        pre_rotation_sha256    = $preSha
        post_rotation_bytes    = [int64]$postBytes
        post_rotation_lines    = [int]$tailLines.Count
        post_rotation_sha256   = $postSha
        bytes_reclaimed_in_git = [int64]($preBytes - $postBytes)
        e_vault_full_ledger    = $spec.PrimaryE
        e_vault_full_bytes     = [int64]$primaryEBytes
        e_epoch_raw_archive    = $eSnapRaw
        e_epoch_gzip_archive   = $eSnapGz
        e_epoch_gzip_bytes     = [int64]$gzItem.Length
        e_epoch_gzip_sha256    = $gzSha
    })

    Write-Host ("[LEDGER-ROTATED] {0}: {1:N2} MB ({2} lines) -> {3:N2} MB ({4} lines) | E:\ full={5:N2} MB | gz={6:N2} MB" -f `
        $spec.RelPath, ($preBytes / 1MB), $totalLines, ($postBytes / 1MB), $tailLines.Count, ($primaryEBytes / 1MB), ($gzItem.Length / 1MB)) -ForegroundColor Green
}

$totalReclaimed = [int64]0
foreach ($rec in $rotatedRecords) {
    $totalReclaimed += [int64]$rec["bytes_reclaimed_in_git"]
}

$manifestObj = [ordered]@{
    schema                = "act_omega.jsonl_epoch_archive_chain.v1"
    epoch_label           = $EpochLabel
    rotated_at_utc        = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    e_archive_dir         = $archiveDir
    ledgers               = $rotatedRecords
    total_reclaimed_bytes = $totalReclaimed
}
$manifestJson = (($manifestObj | ConvertTo-Json -Depth 8) -replace "`r`n", "`n").TrimEnd("`n") + "`n"
$cManifest = Join-Path $RepoRoot "03_vault\connectome\jsonl_epoch_archive_chain_manifest.json"
$eManifest = Join-Path $EVaultRoot "connectome\jsonl_epoch_archive_chain_manifest.json"
$tmpM = "$cManifest.tmp_$([guid]::NewGuid().ToString('N'))"
[System.IO.File]::WriteAllText($tmpM, $manifestJson, $utf8NoBom)
Move-Item -LiteralPath $tmpM -Destination $cManifest -Force
Copy-Item -LiteralPath $cManifest -Destination $eManifest -Force
Write-Host ("[MANIFEST-SEALED] {0} (total_reclaimed_mb={1:N2})" -f $cManifest, ($manifestObj.total_reclaimed_bytes / 1MB)) -ForegroundColor Cyan
