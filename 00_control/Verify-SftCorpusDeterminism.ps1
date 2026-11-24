param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
    [switch]$AllowCommittedDrift
)

$ErrorActionPreference = 'Stop'

function Get-Sha256Lower([byte[]]$Bytes) {
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $hash = $sha.ComputeHash($Bytes)
        return ([System.BitConverter]::ToString($hash)).Replace('-', '').ToLowerInvariant()
    } finally {
        $sha.Dispose()
    }
}

function Get-ByteDiffCount([byte[]]$A, [byte[]]$B) {
    $minLen = [Math]::Min($A.Length, $B.Length)
    $diff = [Math]::Abs($A.Length - $B.Length)
    for ($i = 0; $i -lt $minLen; $i++) {
        if ($A[$i] -ne $B[$i]) {
            $diff++
        }
    }
    return $diff
}

$genScriptRel = '00_control/generate_sft_corpus.mjs'
$genScriptPath = Join-Path $RepoRoot $genScriptRel
$committedCorpusRel = '03_vault/corpus/sh_xi_sourced_multiturn_sft_v1.jsonl'
$committedCorpusPath = Join-Path $RepoRoot $committedCorpusRel
$eval500Rel = '03_vault/connectome/sh_xi_rw_eval_500_sealed.jsonl'
$eval500Path = Join-Path $RepoRoot $eval500Rel
$sftManifestPath = Join-Path $RepoRoot '03_vault/connectome/sh_xi_week2_chatml_sft_manifest.json'
$receiptOutPath = Join-Path $RepoRoot '03_vault/receipts/d1_sft_generator_run_and_diff_receipt.json'
$eVaultCorpusPath = 'E:\Sovereign_Manifold_SSD_Vault\training_corpus\sh_xi_sourced_multiturn_sft_v1.jsonl'

if (-not (Test-Path $genScriptPath)) { throw "Missing $genScriptPath" }
if (-not (Test-Path $committedCorpusPath)) { throw "Missing $committedCorpusPath" }

$genText = [System.IO.File]::ReadAllText($genScriptPath, [System.Text.Encoding]::UTF8)
$specMatches = [regex]::Matches($genText, "rel:\s*'([^']+)'")
if ($specMatches.Count -eq 0) {
    throw "Failed to parse SOURCE_SPECS from $genScriptPath"
}
$sourceSpecs = @()
foreach ($m in $specMatches) {
    $sourceSpecs += $m.Groups[1].Value
}

$sourceRecords = @()
foreach ($rel in $sourceSpecs) {
    $abs = Join-Path $RepoRoot $rel
    if (-not (Test-Path $abs)) { throw "Missing SOURCE_SPECS file: $abs" }
    $raw = [System.IO.File]::ReadAllBytes($abs)
    $sourceRecords += [ordered]@{
        source_path = $rel
        bytes = $raw.Length
        sha256 = (Get-Sha256Lower $raw)
    }
}

$committedBytes = [System.IO.File]::ReadAllBytes($committedCorpusPath)
$committedSha = Get-Sha256Lower $committedBytes

$eBackupBytes = $null
if (Test-Path $eVaultCorpusPath) {
    $eBackupBytes = [System.IO.File]::ReadAllBytes($eVaultCorpusPath)
}

$tmpRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('sft_determinism_' + [guid]::NewGuid().ToString('N'))
$tmpRun1 = Join-Path $tmpRoot 'run1'
$tmpRun2 = Join-Path $tmpRoot 'run2'
$tmpNeg = Join-Path $tmpRoot 'neg'

function Populate-TempWorkspace([string]$TargetDir) {
    $copyList = @($genScriptRel)
    if (Test-Path $eval500Path) { $copyList += $eval500Rel }
    $copyList += $sourceSpecs
    foreach ($rel in $copyList) {
        $src = Join-Path $RepoRoot $rel
        $dst = Join-Path $TargetDir $rel
        $parent = Split-Path $dst -Parent
        if (-not (Test-Path $parent)) {
            $null = New-Item -ItemType Directory -Force -Path $parent
        }
        Copy-Item -Path $src -Destination $dst -Force
    }
}

$origLoc = (Get-Location).Path
try {
    Populate-TempWorkspace $tmpRun1
    Populate-TempWorkspace $tmpRun2
    Populate-TempWorkspace $tmpNeg

    Set-Location $tmpRun1
    $run1Log = (& node $genScriptRel 2>&1) -join "`n"
    if ($LASTEXITCODE -ne 0) { throw "generate_sft_corpus.mjs run1 failed: $run1Log" }
    $run1CorpusBytes = [System.IO.File]::ReadAllBytes((Join-Path $tmpRun1 $committedCorpusRel))
    $run1Sha = Get-Sha256Lower $run1CorpusBytes
    $run1Receipt = Get-Content (Join-Path $tmpRun1 '03_vault/corpus/sh_xi_sft_generator_receipt.json') -Raw | ConvertFrom-Json

    Set-Location $tmpRun2
    $run2Log = (& node $genScriptRel 2>&1) -join "`n"
    if ($LASTEXITCODE -ne 0) { throw "generate_sft_corpus.mjs run2 failed: $run2Log" }
    $run2CorpusBytes = [System.IO.File]::ReadAllBytes((Join-Path $tmpRun2 $committedCorpusRel))
    $run2Sha = Get-Sha256Lower $run2CorpusBytes

    $committedVsFreshDiff = Get-ByteDiffCount $committedBytes $run1CorpusBytes
    $committedVsFreshExact = ($committedVsFreshDiff -eq 0) -and ($committedSha -eq $run1Sha)
    $repeatDiff = Get-ByteDiffCount $run1CorpusBytes $run2CorpusBytes
    $repeatExact = ($repeatDiff -eq 0) -and ($run1Sha -eq $run2Sha)

    # Negative 1-byte source perturbation test on crates/omega_sec_manifold/src/lib.rs
    $negTargetRel = 'crates/omega_sec_manifold/src/lib.rs'
    $negTargetPath = Join-Path $tmpNeg $negTargetRel
    $negSrcBytes = [System.IO.File]::ReadAllBytes($negTargetPath)
    if ($negSrcBytes.Length -lt 10) { throw "Perturbation target too short: $negTargetPath" }
    # Flip 1 byte in comment header (byte 2: '!' -> '?') keeping identical file length
    $negSrcBytes[2] = [byte]([char]'?')
    [System.IO.File]::WriteAllBytes($negTargetPath, $negSrcBytes)

    Set-Location $tmpNeg
    $negLog = (& node $genScriptRel 2>&1) -join "`n"
    if ($LASTEXITCODE -ne 0) { throw "generate_sft_corpus.mjs neg failed: $negLog" }
    $negCorpusBytes = [System.IO.File]::ReadAllBytes((Join-Path $tmpNeg $committedCorpusRel))
    $negSha = Get-Sha256Lower $negCorpusBytes
    $negVsFreshDiff = Get-ByteDiffCount $run1CorpusBytes $negCorpusBytes
    $negShaChanged = ($negSha -ne $run1Sha)
    $negPassed = $negShaChanged -and ($negVsFreshDiff -gt 0)

    $loaderJaccard = $null
    if (Test-Path $sftManifestPath) {
        $sftMan = Get-Content $sftManifestPath -Raw | ConvertFrom-Json
        $loaderJaccard = $sftMan.max_pairwise_5gram_jaccard
    }

    $overallPassed = $repeatExact -and $negPassed -and ($committedVsFreshExact -or $AllowCommittedDrift)

    $receipt = [ordered]@{
        schema = 'ACT-Omega-SFT-Determinism-Receipt-v73.2.4'
        generated_at_utc = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
        generator_script = $genScriptRel
        committed_corpus_path = $committedCorpusRel
        committed_corpus_bytes = $committedBytes.Length
        committed_corpus_sha256 = $committedSha
        fresh_run_bytes = $run1CorpusBytes.Length
        fresh_run_sha256 = $run1Sha
        fresh_run2_bytes = $run2CorpusBytes.Length
        fresh_run2_sha256 = $run2Sha
        committed_vs_fresh_diff_bytes = $committedVsFreshDiff
        committed_vs_fresh_exact_match = $committedVsFreshExact
        repeat_run_diff_bytes = $repeatDiff
        repeat_run_exact_match = $repeatExact
        dialogues_emitted = $run1Receipt.dialogues_emitted
        unique_turns_emitted = $run1Receipt.unique_turns_emitted
        generator_max_pairwise_5gram_jaccard = $run1Receipt.max_pairwise_5gram_jaccard
        loader_manifest_max_pairwise_5gram_jaccard = $loaderJaccard
        negative_perturbation_test = [ordered]@{
            target_source = $negTargetRel
            perturbation_bytes = 1
            perturbation_description = '1-byte comment header flip (byte[2] ! -> ?) in isolated temp workspace'
            perturbed_output_bytes = $negCorpusBytes.Length
            perturbed_output_sha256 = $negSha
            sha256_changed_vs_fresh = $negShaChanged
            diff_bytes_vs_fresh = $negVsFreshDiff
            passed = $negPassed
        }
        source_specs_checked = $sourceRecords
        status = if ($overallPassed) { 'MEASURED' } else { 'UNMEASURED/OFFLINE' }
        overall_passed = $overallPassed
    }

    $receiptDir = Split-Path $receiptOutPath -Parent
    if (-not (Test-Path $receiptDir)) {
        $null = New-Item -ItemType Directory -Force -Path $receiptDir
    }
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    $receiptNorm = ((($receipt | ConvertTo-Json -Depth 8) -replace "`r`n", "`n" -replace "`r", "`n").TrimEnd("`n") + "`n")
    [System.IO.File]::WriteAllText($receiptOutPath, $receiptNorm, $utf8NoBom)

    Write-Output ("[SFT-DETERMINISM] committed_vs_fresh_diff_bytes={0} repeat_run_diff_bytes={1} neg_diff_bytes={2} neg_sha_changed={3} status={4}" -f `
        $committedVsFreshDiff, $repeatDiff, $negVsFreshDiff, $negShaChanged, $receipt.status)

    if (-not $overallPassed) {
        throw "SFT determinism verification failed: committed_vs_fresh_exact_match=$committedVsFreshExact repeat_run_exact_match=$repeatExact neg_passed=$negPassed"
    }
} finally {
    Set-Location $origLoc
    if ($null -ne $eBackupBytes) {
        [System.IO.File]::WriteAllBytes($eVaultCorpusPath, $eBackupBytes)
    }
    if (Test-Path $tmpRoot) {
        Remove-Item -Path $tmpRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}
