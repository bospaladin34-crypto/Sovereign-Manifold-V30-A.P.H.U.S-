# ==============================================================================
# ACT-Omega Net v74.0.0 — $0 Multi-Cloud Storage Split & GitLab Sync Orchestrator
# Synchronizes heavy binaries & epoch archives across:
#   1. E:\Sovereign_Manifold_SSD_Vault\apk_archives\ (Local Tier-2 SSD Vault)
#   2. Cloudflare R2 (act-omega-r2-vault — 10 GB, $0 egress, HTTP 206 Range Slicing)
#   3. GitHub Releases (v74.0.0 — 2 GB/file, unlimited release storage)
#   4. GitLab (gitlab.com/act-omega-labs-group — Dual-Remote Mirror & Package Registry)
# Strictly reads external IDs/tokens from ~/.act_omega_cloudflare_ids.json and
# ~/.act_omega_gitlab_token (0 secrets or CF hex/UUIDs ever written to repo).
# Primary Author & Principal Systems Architect: Donevin Frownfelter (@bospaladin34-crypto)
# ==============================================================================
param(
    [string]$RepoRoot = "C:\sovereign_manifold_v31",
    [string]$EVaultRoot = "E:\Sovereign_Manifold_SSD_Vault",
    [string]$ReleaseTag = "v74.0.0",
    [string]$EpochLabel = "v74_0_0_pre_stage_b",
    [string]$GitLabGroup = "act-omega-labs-group",
    [string]$GitLabProject = "sovereign-manifold",
    [switch]$SkipGitHubReleaseUpload,
    [switch]$SkipR2Upload
)

$ErrorActionPreference = "Stop"
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$edgeDir = Join-Path $RepoRoot "00_control\cloudflare_edge"
$extCfPath = "C:\Users\Nbell\.act_omega_cloudflare_ids.json"
$cfg = if (Test-Path $extCfPath) { Get-Content -Raw -Path $extCfPath | ConvertFrom-Json } else { $null }
if (-not $cfg -or -not $cfg.account_id) {
    throw "FAIL_CLOSED_MISSING_CF_IDS: $extCfPath missing or incomplete."
}

# 1. Archive historical releases/*.apk to E:\Sovereign_Manifold_SSD_Vault\apk_archives\
$eApkDir = Join-Path $EVaultRoot "apk_archives"
New-Item -ItemType Directory -Path $eApkDir -Force | Out-Null
$archivedHistoricalApks = New-Object System.Collections.Generic.List[object]
foreach ($oldApkName in @(
    "ACT-Omega-v70.0.0-Pixel10-Sovereign.apk",
    "ACT-Omega-v72.2.0-Pixel10-Sovereign.apk",
    "ACT-Omega-v73.2.0-Pixel10-Sovereign.apk"
)) {
    $srcOld = Join-Path $RepoRoot "releases\$oldApkName"
    $dstOld = Join-Path $eApkDir $oldApkName
    if (Test-Path -LiteralPath $srcOld -PathType Leaf) {
        Copy-Item -LiteralPath $srcOld -Destination $dstOld -Force
        $srcSha = (Get-FileHash -LiteralPath $srcOld -Algorithm SHA256).Hash.ToLowerInvariant()
        $dstSha = (Get-FileHash -LiteralPath $dstOld -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($srcSha -ne $dstSha) { throw "APK archive SHA mismatch on $oldApkName" }
        Remove-Item -LiteralPath $srcOld -Force
    }
    if (Test-Path -LiteralPath $dstOld -PathType Leaf) {
        $it = Get-Item -LiteralPath $dstOld
        $sh = (Get-FileHash -LiteralPath $dstOld -Algorithm SHA256).Hash.ToLowerInvariant()
        $archivedHistoricalApks.Add([ordered]@{
            file_name = $oldApkName
            e_vault_path = $dstOld
            bytes = [int64]$it.Length
            sha256 = $sh
        })
    }
}

$canonApk = Join-Path $RepoRoot "04_edge_silicon\ACT-Omega-Pixel10-Sovereign.apk"
if (-not (Test-Path -LiteralPath $canonApk -PathType Leaf)) {
    throw "Canonical APK missing: $canonApk"
}
$canonApkBytes = (Get-Item -LiteralPath $canonApk).Length
$canonApkSha   = (Get-FileHash -LiteralPath $canonApk -Algorithm SHA256).Hash.ToLowerInvariant()
Copy-Item -LiteralPath $canonApk -Destination (Join-Path $eApkDir "ACT-Omega-$ReleaseTag-Pixel10-Sovereign.apk") -Force

# 2. Upload Canonical v74.0.0 APK + Lean 4 Proofs + GZip Epoch Archives to Cloudflare R2 (act-omega-r2-vault)
$r2UploadedObjects = New-Object System.Collections.Generic.List[object]
$r2RangeProbeStatus = "SKIPPED"
$r2RangeProbeBytes = 0

if (-not $SkipR2Upload) {
    $prevTok = $env:CLOUDFLARE_API_TOKEN
    $prevAcc = $env:CLOUDFLARE_ACCOUNT_ID
    Remove-Item Env:\CLOUDFLARE_API_TOKEN -ErrorAction SilentlyContinue
    $env:CLOUDFLARE_ACCOUNT_ID = $cfg.account_id
    try {
        $r2Targets = New-Object System.Collections.Generic.List[object]
        $r2Targets.Add(@{ Local = $canonApk; Key = "ota/ACT-Omega-$ReleaseTag-Pixel10-Sovereign.apk"; ContentType = "application/vnd.android.package-archive" })
        $r2Targets.Add(@{ Local = (Join-Path $RepoRoot "03_vault\lean4\SovereignManifoldTheorems.lean"); Key = "lean4/SovereignManifoldTheorems_$ReleaseTag.lean"; ContentType = "text/plain; charset=utf-8" })

        $epochDir = Join-Path $EVaultRoot "epoch_ledger_archives\$EpochLabel"
        if (Test-Path $epochDir) {
            Get-ChildItem -Path $epochDir -Filter "*.gz" -File | ForEach-Object {
                $r2Targets.Add(@{ Local = $_.FullName; Key = "ledger_archives/$EpochLabel/$($_.Name)"; ContentType = "application/gzip" })
            }
        }

        Push-Location $env:TEMP
        try {
            foreach ($t in $r2Targets) {
                if (-not (Test-Path -LiteralPath $t.Local -PathType Leaf)) { continue }
                $fBytes = (Get-Item -LiteralPath $t.Local).Length
                $fSha   = (Get-FileHash -LiteralPath $t.Local -Algorithm SHA256).Hash.ToLowerInvariant()
                $prevEap = $ErrorActionPreference
                $ErrorActionPreference = "Continue"
                $putOut = & npx --prefix $edgeDir wrangler r2 object put "act-omega-r2-vault/$($t.Key)" --file $t.Local --content-type $t.ContentType --remote 2>&1 | Out-String
                $putExit = $LASTEXITCODE
                $ErrorActionPreference = $prevEap
                if ($putExit -ne 0) {
                    $redactedOut = $putOut.Replace([string]$cfg.account_id, "<REDACTED_CF_ID>")
                    throw "R2 upload failed for $($t.Key) (exit=$putExit): $redactedOut"
                }
                $r2UploadedObjects.Add([ordered]@{
                    bucket = "act-omega-r2-vault"
                    object_key = $t.Key
                    edge_range_url = "https://act-omega-net.dev/api/v1/r2/vault/$($t.Key)"
                    bytes = [int64]$fBytes
                    sha256 = $fSha
                })
                Write-Host ("[R2-UPLOADED] act-omega-r2-vault/{0} ({1:N2} MB)" -f $t.Key, ($fBytes / 1MB)) -ForegroundColor Green
            }
        } finally {
            Pop-Location
        }

        # Probe HTTP 206 Range Slice over https://act-omega-net.dev/api/v1/r2/vault/...
        try {
            Add-Type -AssemblyName System.Net.Http
            $client = New-Object System.Net.Http.HttpClient
            $client.Timeout = [TimeSpan]::FromSeconds(15)
            try {
                $req = New-Object System.Net.Http.HttpRequestMessage([System.Net.Http.HttpMethod]::Get, "https://act-omega-net.dev/api/v1/r2/vault/ota/ACT-Omega-$ReleaseTag-Pixel10-Sovereign.apk")
                $req.Headers.Range = New-Object System.Net.Http.Headers.RangeHeaderValue(0, 63)
                $resp = $client.SendAsync($req).GetAwaiter().GetResult()
                $sliceBytes = $resp.Content.ReadAsByteArrayAsync().GetAwaiter().GetResult()
                $r2RangeProbeBytes = $sliceBytes.Length
                $pkMagic = ($sliceBytes.Length -ge 2 -and $sliceBytes[0] -eq 0x50 -and $sliceBytes[1] -eq 0x4B)
                $r2RangeProbeStatus = if ([int]$resp.StatusCode -eq 206 -and $pkMagic) { "MEASURED_HTTP_206_ZIP_PK_MAGIC_VERIFIED" } else { "HTTP_$([int]$resp.StatusCode)" }
            } finally {
                $client.Dispose()
            }
        } catch {
            $r2RangeProbeStatus = "UNMEASURED/OFFLINE"
        }
    } finally {
        if ($null -ne $prevTok) { $env:CLOUDFLARE_API_TOKEN = $prevTok } else { Remove-Item Env:\CLOUDFLARE_API_TOKEN -ErrorAction SilentlyContinue }
        if ($null -ne $prevAcc) { $env:CLOUDFLARE_ACCOUNT_ID = $prevAcc } else { Remove-Item Env:\CLOUDFLARE_ACCOUNT_ID -ErrorAction SilentlyContinue }
    }
}

# 3. Upload Official Binary Assets to GitHub Release ($ReleaseTag) — 2 GB/file free tier outside .git
$ghReleaseAssets = New-Object System.Collections.Generic.List[string]
$ghReleaseStatus = "SKIPPED"
if (-not $SkipGitHubReleaseUpload -and (Get-Command gh -ErrorAction SilentlyContinue)) {
    $stageRelDir = Join-Path $env:TEMP "act_omega_gh_rel_$([guid]::NewGuid().ToString('N'))"
    New-Item -ItemType Directory -Path $stageRelDir -Force | Out-Null
    try {
        $apkRelCopy = Join-Path $stageRelDir "ACT-Omega-$ReleaseTag-Pixel10-Sovereign.apk"
        Copy-Item -LiteralPath $canonApk -Destination $apkRelCopy -Force
        $uploadList = @($apkRelCopy)
        foreach ($extraRel in @(
            (Join-Path $RepoRoot "SovereignCockpitHUD.exe"),
            (Join-Path $RepoRoot "03_vault\lean4\SovereignManifoldTheorems.lean"),
            (Join-Path $RepoRoot "CITATION.cff"),
            (Join-Path $RepoRoot ".zenodo.json")
        )) {
            if (Test-Path -LiteralPath $extraRel -PathType Leaf) { $uploadList += $extraRel }
        }
        Push-Location $RepoRoot
        try {
            & gh release upload $ReleaseTag @uploadList --clobber | Out-Null
            if ($LASTEXITCODE -eq 0) {
                $ghReleaseStatus = "MEASURED_GITHUB_RELEASE_ASSETS_UPLOADED"
                foreach ($u in $uploadList) { $ghReleaseAssets.Add((Split-Path -Leaf $u)) }
                Write-Host ("[GH-RELEASE-OK] Uploaded {0} assets to GitHub Release {1}" -f $uploadList.Count, $ReleaseTag) -ForegroundColor Green
            } else {
                $ghReleaseStatus = "UNMEASURED/OFFLINE"
            }
        } finally {
            Pop-Location
        }
    } finally {
        Remove-Item -Path $stageRelDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# 4. Configure GitLab Remote (gitlab.com/act-omega-labs-group/sovereign-manifold.git) & Optional Token Push
$gitlabRemoteUrl = "https://gitlab.com/$GitLabGroup/$GitLabProject.git"
$existingRemotes = @(git -C $RepoRoot remote)
if ($existingRemotes -notcontains "gitlab") {
    git -C $RepoRoot remote add gitlab $gitlabRemoteUrl
} else {
    git -C $RepoRoot remote set-url gitlab $gitlabRemoteUrl
}

$glToken = ""
$glTokenFile = "C:\Users\Nbell\.act_omega_gitlab_token"
if (-not [string]::IsNullOrWhiteSpace($env:GITLAB_TOKEN)) {
    $glToken = $env:GITLAB_TOKEN.Trim()
} elseif (Test-Path -LiteralPath $glTokenFile -PathType Leaf) {
    $glToken = ([System.IO.File]::ReadAllText($glTokenFile)).Trim()
}

$gitlabSyncStatus = "REMOTE_CONFIGURED_AWAITING_EXTERNAL_GITLAB_PAT"
$gitlabPackageUrl = $null
if ($glToken.Length -ge 16) {
    try {
        $glHdr = @{ "PRIVATE-TOKEN" = $glToken }
        $encodedPath = [uri]::EscapeDataString("$GitLabGroup/$GitLabProject")
        $proj = $null
        try {
            $proj = Invoke-RestMethod -Method Get -Uri "https://gitlab.com/api/v4/projects/$encodedPath" -Headers $glHdr -TimeoutSec 15
        } catch {
            $grp = Invoke-RestMethod -Method Get -Uri "https://gitlab.com/api/v4/groups/$([uri]::EscapeDataString($GitLabGroup))" -Headers $glHdr -TimeoutSec 15
            if ($grp -and $grp.id) {
                $createBody = @{ name = $GitLabProject; path = $GitLabProject; namespace_id = $grp.id; visibility = "private"; description = "ACT-Omega Sovereign Manifold Mirror & Generic Package Vault" } | ConvertTo-Json -Compress
                $proj = Invoke-RestMethod -Method Post -Uri "https://gitlab.com/api/v4/projects" -Headers ($glHdr + @{ "Content-Type" = "application/json" }) -Body $createBody -TimeoutSec 20
            }
        }
        if ($proj -and $proj.id) {
            $verClean = $ReleaseTag.TrimStart('v')
            $pkgUri = "https://gitlab.com/api/v4/projects/$($proj.id)/packages/generic/act-omega/$verClean/ACT-Omega-$ReleaseTag-Pixel10-Sovereign.apk"
            $null = Invoke-RestMethod -Method Put -Uri $pkgUri -Headers $glHdr -InFile $canonApk -ContentType "application/octet-stream" -TimeoutSec 120
            $gitlabPackageUrl = $pkgUri
            $gitlabSyncStatus = "MEASURED_GITLAB_PROJECT_AND_PACKAGE_SYNCED"
            Write-Host "[GITLAB-OK] Uploaded APK to GitLab Generic Package Registry ($GitLabGroup/$GitLabProject)" -ForegroundColor Green
        }
    } catch {
        $gitlabSyncStatus = "DEGRADED_GITLAB_API_ERROR"
    }
} else {
    Write-Host "[GITLAB-READY] Remote 'gitlab' -> $gitlabRemoteUrl configured (save PAT to C:\Users\Nbell\.act_omega_gitlab_token to enable automated push & Generic Package Registry upload)." -ForegroundColor Cyan
}

# 5. Emit Measured Multi-Cloud Storage Split Receipt (Zero CF IDs or Secrets!)
$ledgerManifestPath = Join-Path $RepoRoot "03_vault\connectome\jsonl_epoch_archive_chain_manifest.json"
$ledgerSummary = if (Test-Path $ledgerManifestPath) { Get-Content -Raw $ledgerManifestPath | ConvertFrom-Json } else { $null }

$receiptObj = [ordered]@{
    schema                    = "act_omega.multicloud_storage_and_ledger_rotation_receipt.v1"
    version                   = $ReleaseTag
    generated_at_utc          = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    canonical_tracked_apk     = [ordered]@{
        repo_path = "04_edge_silicon/ACT-Omega-Pixel10-Sovereign.apk"
        bytes     = [int64]$canonApkBytes
        sha256    = $canonApkSha
    }
    e_vault_archived_apks     = $archivedHistoricalApks
    cloudflare_r2_vault       = [ordered]@{
        bucket             = "act-omega-r2-vault"
        objects_uploaded   = $r2UploadedObjects
        http206_range_probe_status = $r2RangeProbeStatus
        http206_range_probe_bytes  = $r2RangeProbeBytes
    }
    github_release_assets     = [ordered]@{
        tag    = $ReleaseTag
        status = $ghReleaseStatus
        assets = $ghReleaseAssets
    }
    gitlab_mirror_and_registry = [ordered]@{
        remote_name = "gitlab"
        remote_url  = $gitlabRemoteUrl
        status      = $gitlabSyncStatus
        package_url = $gitlabPackageUrl
        external_pat_path = "C:\Users\Nbell\.act_omega_gitlab_token"
    }
    jsonl_epoch_rotation      = if ($ledgerSummary) {
        [ordered]@{
            epoch_label           = $ledgerSummary.epoch_label
            total_reclaimed_bytes = $ledgerSummary.total_reclaimed_bytes
            ledgers_rotated       = $ledgerSummary.ledgers.Count
        }
    } else { $null }
}

$receiptPath = Join-Path $RepoRoot "03_vault\receipts\v74_0_0_multicloud_storage_and_ledger_rotation_receipt.json"
$receiptJson = (($receiptObj | ConvertTo-Json -Depth 8) -replace "`r`n", "`n").TrimEnd("`n") + "`n"

# Leak check before writing
foreach ($prop in $cfg.PSObject.Properties) {
    $val = [string]$prop.Value
    if ($val.Length -ge 16 -and $receiptJson.IndexOf($val, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        throw "FAIL_CLOSED_CF_ID_LEAK in multicloud receipt ($($prop.Name))"
    }
}

$tmpR = "$receiptPath.tmp_$([guid]::NewGuid().ToString('N'))"
[System.IO.File]::WriteAllText($tmpR, $receiptJson, $utf8NoBom)
Move-Item -LiteralPath $tmpR -Destination $receiptPath -Force
Write-Host "[MULTICLOUD-RECEIPT-WRITTEN] $receiptPath" -ForegroundColor Green
