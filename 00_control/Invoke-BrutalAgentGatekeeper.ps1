param(
    [switch]$HookStdin,
    [switch]$FullAudit,
    [switch]$StaticOnly,
    [switch]$CloudCiMode,
    [switch]$TestNegativeCloudflareInjection,
    [switch]$TestNegativePixelSerialInjection,
    [switch]$TestNegativeTelemetryKeyInjection,
    [string]$RepoPath = "",
    [string[]]$ExtraFilesToScan = @(),
    [string]$LeanOverridePath = ""
)

$ErrorActionPreference = "Stop"

$normalizedExtra = New-Object System.Collections.Generic.List[string]
foreach ($efRaw in $ExtraFilesToScan) {
    if ([string]::IsNullOrWhiteSpace($efRaw)) { continue }
    if (-not (Test-Path $efRaw -PathType Leaf) -and $efRaw -match ',') {
        foreach ($part in ($efRaw -split ',')) {
            $pTrim = $part.Trim()
            if (-not [string]::IsNullOrWhiteSpace($pTrim)) { $normalizedExtra.Add($pTrim) }
        }
    } else {
        $normalizedExtra.Add($efRaw.Trim())
    }
}
$ExtraFilesToScan = $normalizedExtra.ToArray()

# Dynamic $RepoRoot resolution: -RepoPath -> $env:GITHUB_WORKSPACE -> $PSScriptRoot\.. -> fallback
$RepoRoot = if ($RepoPath -and (Test-Path $RepoPath)) {
    (Resolve-Path $RepoPath).Path
} elseif ($env:GITHUB_WORKSPACE -and (Test-Path $env:GITHUB_WORKSPACE)) {
    (Resolve-Path $env:GITHUB_WORKSPACE).Path
} elseif ($PSScriptRoot -and (Test-Path (Split-Path -Parent $PSScriptRoot))) {
    (Resolve-Path (Split-Path -Parent $PSScriptRoot)).Path
} else {
    "C:\sovereign_manifold_v31"
}

if (-not (Test-Path $RepoRoot)) {
    $RepoRoot = "C:\sovereign_manifold_v31"
}

function Get-LiveLean4TheoremCount {
    param([string]$LeanPath)
    if (-not (Test-Path $LeanPath)) { return 0 }
    $txt = [System.IO.File]::ReadAllText($LeanPath)
    return ([regex]::Matches($txt, '(?m)^\s*theorem\s+')).Count
}

function Test-Lean4ThresholdCheck {
    param(
        [string]$LeanPath,
        [int]$ReportedCount = -1
    )
    $errs = New-Object System.Collections.Generic.List[string]
    if (-not (Test-Path $LeanPath)) {
        $errs.Add("LEAN4_MISSING: $LeanPath not found")
        return ,$errs
    }
    $leanText = [System.IO.File]::ReadAllText($LeanPath)
    $thmCount = ([regex]::Matches($leanText, '(?m)^\s*theorem\s+')).Count
    $sorryCount = ([regex]::Matches($leanText, '\bsorry\b')).Count
    $trivialEqCount = ([regex]::Matches($leanText, ':\s*(\w+)\s*=\s*\1\s*:=')).Count
    $trivialCommCount = ([regex]::Matches($leanText, '\(a\s+b\s*:\s*Nat\)\s*:\s*a\s*\+\s*b\s*=\s*b\s*\+\s*a')).Count
    if ($thmCount -lt 1027) {
        $errs.Add("LEAN4_COUNT_LOW: Found $thmCount theorems in $LeanPath (Req: >= 1027)")
    }
    if ($ReportedCount -ge 0 -and ($ReportedCount -lt 1027 -or $ReportedCount -ne $thmCount)) {
        $errs.Add("LEAN4_REPORTED_MISMATCH: Reported $ReportedCount theorems != live $thmCount (Req: >= 1027 and exact match)")
    }
    if ($sorryCount -gt 0) {
        $errs.Add("LEAN4_SORRY_FOUND: Found $sorryCount 'sorry' tokens (Req: 0)")
    }
    if (($trivialEqCount + $trivialCommCount) -gt 0) {
        $errs.Add("LEAN4_TRIVIAL_PADDING: Found $($trivialEqCount + $trivialCommCount) trivial arithmetic padding theorems (Req: 0)")
    }
    return ,$errs
}

function Test-CloudflareIdLeakScan {
    param(
        [string]$RootPath,
        [string[]]$ExtraFiles = @(),
        [string[]]$AdditionalRetiredSha256 = @()
    )
    $cfViolations = New-Object System.Collections.Generic.List[string]
    $cfIdsPath = if (Test-Path "C:\Users\Nbell\.act_omega_cloudflare_ids.json") {
        "C:\Users\Nbell\.act_omega_cloudflare_ids.json"
    } elseif ($env:USERPROFILE -and (Test-Path "$env:USERPROFILE\.act_omega_cloudflare_ids.json")) {
        "$env:USERPROFILE\.act_omega_cloudflare_ids.json"
    } else {
        $null
    }

    $activeVals = @{}
    $retiredHashes = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    $retiredPrefixes = New-Object System.Collections.Generic.List[string]
    foreach ($ah in $AdditionalRetiredSha256) {
        if (-not [string]::IsNullOrWhiteSpace($ah)) {
            [void]$retiredHashes.Add($ah.Trim().ToLowerInvariant())
        }
    }

    if ($cfIdsPath) {
        $cfCfg = Get-Content -Raw $cfIdsPath | ConvertFrom-Json
        $activeKeys = @("account_id","d1_database_id","hyperdrive_id","kv_id","vpc_anchor_id","vpc_deno_id","vpc_p10_id","vpc_p8_id")
        foreach ($k in $activeKeys) {
            $v = [string]$cfCfg.$k
            if (-not [string]::IsNullOrWhiteSpace($v) -and $v.Length -ge 16) {
                $activeVals[$k] = $v.Trim()
            }
        }
        foreach ($h in $cfCfg.retired_ids_sha256) {
            if (-not [string]::IsNullOrWhiteSpace([string]$h)) {
                [void]$retiredHashes.Add(([string]$h).Trim().ToLowerInvariant())
            }
        }
        foreach ($p in $cfCfg.retired_id_prefixes) {
            if (-not [string]::IsNullOrWhiteSpace([string]$p)) {
                $retiredPrefixes.Add(([string]$p).Trim().ToLowerInvariant())
            }
        }
    } elseif (-not $CloudCiMode) {
        $cfViolations.Add("CF_IDS_CONFIG_MISSING: External ~/.act_omega_cloudflare_ids.json not found")
    }

    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
    $uuidHexRegex = [regex]::new('(?i)\b(?:[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}|[0-9a-f]{32})\b')

    # 1. Enumerate all tracked repository files via git ls-files
    $trackedFiles = @(git -C $RootPath ls-files 2>$null)
    if ($LASTEXITCODE -ne 0 -or $trackedFiles.Count -eq 0) {
        $cfViolations.Add("CF_SCAN_GIT_LS_FILES_FAILED: Could not enumerate git ls-files at $RootPath")
        return ,$cfViolations
    }

    # 1a. Scan all tracked text files for every active CF ID value via git grep (zero secret values printed)
    foreach ($kv in $activeVals.GetEnumerator()) {
        $matchedFiles = @(git -C $RootPath grep -l -i -I -F -- $kv.Value 2>$null)
        if ($LASTEXITCODE -eq 0 -and $matchedFiles.Count -gt 0) {
            foreach ($mf in $matchedFiles) {
                $cfViolations.Add("CF_ACTIVE_ID_LEAK: Key '$($kv.Key)' matched in tracked file '$mf'")
            }
        }
    }

    # 1b. Extract all 32-hex and 36-char UUID candidate tokens across all tracked text files and check retired SHA-256 & prefixes
    $rawTokens = @(git -C $RootPath grep -h -I -o -E '\b([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}|[0-9a-fA-F]{32})\b' 2>$null)
    $uniqueTokens = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($t in $rawTokens) {
        if (-not [string]::IsNullOrWhiteSpace($t)) {
            [void]$uniqueTokens.Add($t.Trim().ToLowerInvariant())
        }
    }
    foreach ($tok in $uniqueTokens) {
        $hashHex = ([System.BitConverter]::ToString($sha256.ComputeHash($utf8NoBom.GetBytes($tok))) -replace '-', '').ToLowerInvariant()
        if ($retiredHashes.Contains($hashHex)) {
            $offFiles = @(git -C $RootPath grep -l -i -I -F -- $tok 2>$null)
            $cfViolations.Add("CF_RETIRED_ID_SHA256_LEAK: Retired CF ID sha256=$($hashHex.Substring(0,16))... found in tracked file(s): $($offFiles -join ', ')")
        } else {
            foreach ($pref in $retiredPrefixes) {
                if ($tok.StartsWith($pref)) {
                    $offFiles = @(git -C $RootPath grep -l -i -I -F -- $tok 2>$null)
                    $cfViolations.Add("CF_RETIRED_ID_PREFIX_LEAK: Retired CF ID prefix matched in tracked file(s): $($offFiles -join ', ')")
                }
            }
        }
    }

    # 1c. Scan ALL wrangler*.toml files in git ls-files for literal hex ID assignments
    $wranglerFiles = @($trackedFiles | Where-Object { $_ -match '(^|[/\\])wrangler[^/\\]*\.toml$' })
    foreach ($wfRel in $wranglerFiles) {
        $wfFull = Join-Path $RootPath $wfRel
        if (-not (Test-Path $wfFull)) { continue }
        $wfText = [System.IO.File]::ReadAllText($wfFull)
        if ($wfText -match '(?mi)^\s*account_id\s*=\s*"[0-9a-f]{32}"') {
            $cfViolations.Add("CF_WRANGLER_LITERAL_HEX_LEAK: $wfRel contains literal 32-hex account_id")
        }
        if ($wfText -match '(?mi)^\s*database_id\s*=\s*"[0-9a-f-]{36}"') {
            $cfViolations.Add("CF_WRANGLER_LITERAL_HEX_LEAK: $wfRel contains literal 36-char UUID database_id")
        }
        if ($wfText -match '(?mi)^\s*id\s*=\s*"[0-9a-f]{32}"') {
            $cfViolations.Add("CF_WRANGLER_LITERAL_HEX_LEAK: $wfRel contains literal 32-hex id")
        }
    }

    # 2. Scan untracked non-ignored files, built dist/docs/assets bundles, and ExtraFiles
    $candidatePaths = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    $extraSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    $skipBundleExts = @('.apk', '.exe', '.png', '.jpg', '.jpeg', '.gif', '.webp', '.ico', '.woff2')

    $untrackedFiles = @(git -C $RootPath ls-files --others --exclude-standard 2>$null)
    foreach ($ufRel in $untrackedFiles) {
        $ufFull = Join-Path $RootPath ($ufRel -replace '/', '\')
        if (Test-Path $ufFull -PathType Leaf) { [void]$candidatePaths.Add($ufFull) }
    }
    foreach ($bundleDir in @(
        "$RootPath\05_hud_cockpit\dist",
        "$RootPath\02_l2_orchestration\hud\dist",
        "$RootPath\docs",
        "$RootPath\assets"
    )) {
        if (Test-Path $bundleDir) {
            Get-ChildItem -Path $bundleDir -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
                if ($_.Extension -notin $skipBundleExts) {
                    [void]$candidatePaths.Add($_.FullName)
                }
            }
        }
    }
    foreach ($ef in $ExtraFiles) {
        if ($ef -and (Test-Path $ef -PathType Leaf)) {
            [void]$candidatePaths.Add($ef)
            [void]$extraSet.Add($ef)
        }
    }

    foreach ($cp in $candidatePaths) {
        $item = Get-Item $cp -ErrorAction SilentlyContinue
        if (-not $item -or $item.Length -gt 20MB) { continue }
        $isExtra = $extraSet.Contains($cp)
        if (-not $isExtra -and ($item.Extension -in $skipBundleExts)) { continue }
        $cpText = [System.IO.File]::ReadAllText($cp)
        foreach ($kv in $activeVals.GetEnumerator()) {
            if ($cpText.IndexOf($kv.Value, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
                $cfViolations.Add("CF_ACTIVE_ID_LEAK: Key '$($kv.Key)' matched in '$cp'")
            }
        }
        $cpSeen = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
        foreach ($m in $uuidHexRegex.Matches($cpText)) {
            $tok = $m.Value.ToLowerInvariant()
            if (-not $cpSeen.Add($tok)) { continue }
            $hashHex = ([System.BitConverter]::ToString($sha256.ComputeHash($utf8NoBom.GetBytes($tok))) -replace '-', '').ToLowerInvariant()
            if ($retiredHashes.Contains($hashHex)) {
                $cfViolations.Add("CF_RETIRED_ID_SHA256_LEAK: Retired CF ID sha256=$($hashHex.Substring(0,16))... found in '$cp'")
            } else {
                foreach ($pref in $retiredPrefixes) {
                    if ($tok.StartsWith($pref)) {
                        $cfViolations.Add("CF_RETIRED_ID_PREFIX_LEAK: Retired CF ID prefix matched in '$cp'")
                    }
                }
            }
        }
        if ($isExtra -or ($item.Name -match '^wrangler[^/\\]*\.toml$')) {
            if ($cpText -match '(?mi)^\s*account_id\s*=\s*"[0-9a-f]{32}"') {
                $cfViolations.Add("CF_WRANGLER_LITERAL_HEX_LEAK: $cp contains literal 32-hex account_id")
            }
            if ($cpText -match '(?mi)^\s*database_id\s*=\s*"[0-9a-f-]{36}"') {
                $cfViolations.Add("CF_WRANGLER_LITERAL_HEX_LEAK: $cp contains literal 36-char UUID database_id")
            }
            if ($cpText -match '(?mi)^\s*id\s*=\s*"[0-9a-f]{32}"') {
                $cfViolations.Add("CF_WRANGLER_LITERAL_HEX_LEAK: $cp contains literal 32-hex id")
            }
        }
    }

    return ,$cfViolations
}

function Test-PixelSerialLeakScan {
    param(
        [string]$RootPath,
        [string[]]$ExtraFiles = @(),
        [string[]]$AdditionalRetiredSha256 = @()
    )
    $pxViolations = New-Object System.Collections.Generic.List[string]
    $adbCfgPath = if (Test-Path "C:\Users\Nbell\.act_omega_adb_devices.json") {
        "C:\Users\Nbell\.act_omega_adb_devices.json"
    } elseif ($env:USERPROFILE -and (Test-Path "$env:USERPROFILE\.act_omega_adb_devices.json")) {
        "$env:USERPROFILE\.act_omega_adb_devices.json"
    } else {
        $null
    }

    $activeSerials = @{}
    $retiredHashes = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($ah in $AdditionalRetiredSha256) {
        if (-not [string]::IsNullOrWhiteSpace($ah)) {
            [void]$retiredHashes.Add($ah.Trim().ToLowerInvariant())
        }
    }

    if ($adbCfgPath) {
        $adbCfg = Get-Content -Raw $adbCfgPath | ConvertFrom-Json
        foreach ($role in @("pixel10", "pixel8")) {
            $s = if ($adbCfg.$role -and $adbCfg.$role.serial) { ([string]$adbCfg.$role.serial).Trim() } else { "" }
            if ($s.Length -ge 8) {
                $activeSerials[$role] = $s
            }
        }
        if ($adbCfg.retired_serials_sha256) {
            foreach ($rh in $adbCfg.retired_serials_sha256) {
                if (-not [string]::IsNullOrWhiteSpace([string]$rh)) {
                    [void]$retiredHashes.Add(([string]$rh).Trim().ToLowerInvariant())
                }
            }
        }
    } elseif (-not $CloudCiMode) {
        $pxViolations.Add("ADB_DEVICES_CONFIG_MISSING: External ~/.act_omega_adb_devices.json not found")
    }

    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
    try {
        # 1. Scan ALL tracked files (including binary files via -a) for active Pixel serials
        foreach ($kv in $activeSerials.GetEnumerator()) {
            $matchedFiles = @(git -C $RootPath grep -a -l -F -- $kv.Value 2>$null)
            if ($LASTEXITCODE -eq 0 -and $matchedFiles.Count -gt 0) {
                foreach ($mf in $matchedFiles) {
                    $pxViolations.Add("PIXEL_ACTIVE_SERIAL_LEAK: Role '$($kv.Key)' serial matched in tracked file '$mf'")
                }
            }
        }

        # 2. Scan retired SHA-256 hashes across tracked text files (alphanumeric serial-like tokens 10..20 chars)
        $retArr = [string[]]@($retiredHashes)
        if ($retiredHashes.Count -gt 0) {
            if (-not ('SovereignBatchShaMatcher' -as [type])) {
                Add-Type -TypeDefinition @"
using System;
using System.Collections.Generic;
using System.Security.Cryptography;
using System.Text;
using System.Text.RegularExpressions;
public static class SovereignBatchShaMatcher {
    private static readonly Regex TokenRx = new Regex(@"\b[0-9A-Za-z]{10,20}\b", RegexOptions.Compiled);
    public static List<string> FindMatches(string[] tokens, string[] retiredHashesHex) {
        var retSet = new HashSet<string>(retiredHashesHex, StringComparer.OrdinalIgnoreCase);
        var seen = new HashSet<string>(StringComparer.Ordinal);
        var hits = new List<string>();
        using (var sha = SHA256.Create()) {
            foreach (var raw in tokens) {
                if (string.IsNullOrEmpty(raw)) continue;
                var tok = raw.Trim();
                if (!seen.Add(tok)) continue;
                var hash = sha.ComputeHash(Encoding.UTF8.GetBytes(tok));
                var sb = new StringBuilder(64);
                for (int i = 0; i < hash.Length; i++) sb.Append(hash[i].ToString("x2"));
                var hHex = sb.ToString();
                if (retSet.Contains(hHex)) {
                    hits.Add(tok + "|" + hHex);
                }
            }
        }
        return hits;
    }
    public static List<string> FindMatchesInText(string content, string[] retiredHashesHex) {
        var retSet = new HashSet<string>(retiredHashesHex, StringComparer.OrdinalIgnoreCase);
        var seen = new HashSet<string>(StringComparer.Ordinal);
        var hits = new List<string>();
        if (string.IsNullOrEmpty(content)) return hits;
        using (var sha = SHA256.Create()) {
            foreach (Match m in TokenRx.Matches(content)) {
                var tok = m.Value;
                if (!seen.Add(tok)) continue;
                var hash = sha.ComputeHash(Encoding.UTF8.GetBytes(tok));
                var sb = new StringBuilder(64);
                for (int i = 0; i < hash.Length; i++) sb.Append(hash[i].ToString("x2"));
                var hHex = sb.ToString();
                if (retSet.Contains(hHex)) {
                    hits.Add(tok + "|" + hHex);
                }
            }
        }
        return hits;
    }
}
"@
            }
            $candTokens = @(git -C $RootPath grep -h -I -o -E '\b[0-9A-Za-z]{10,20}\b' 2>$null)
            $hits = [SovereignBatchShaMatcher]::FindMatches($candTokens, $retArr)
            foreach ($hit in $hits) {
                $parts = $hit.Split('|', 2)
                $tok = $parts[0]
                $hHex = $parts[1]
                $offFiles = @(git -C $RootPath grep -l -I -F -- $tok 2>$null)
                $pxViolations.Add("PIXEL_RETIRED_SERIAL_SHA256_LEAK: Retired serial sha256=$($hHex.Substring(0,16))... found in tracked file(s): $($offFiles -join ', ')")
            }
        }

        # 3. Scan untracked non-ignored files, built dist/docs/assets bundles, and ExtraFiles (active + retired SHA-256)
        $candidatePaths = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
        $extraSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
        $skipBundleExts = @('.apk', '.exe', '.png', '.jpg', '.jpeg', '.gif', '.webp', '.ico', '.woff2')

        $untrackedFiles = @(git -C $RootPath ls-files --others --exclude-standard 2>$null)
        foreach ($ufRel in $untrackedFiles) {
            $ufFull = Join-Path $RootPath ($ufRel -replace '/', '\')
            if (Test-Path $ufFull -PathType Leaf) { [void]$candidatePaths.Add($ufFull) }
        }
        foreach ($bundleDir in @(
            "$RootPath\05_hud_cockpit\dist",
            "$RootPath\02_l2_orchestration\hud\dist",
            "$RootPath\docs",
            "$RootPath\assets"
        )) {
            if (Test-Path $bundleDir) {
                Get-ChildItem -Path $bundleDir -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
                    if ($_.Extension -notin $skipBundleExts) {
                        [void]$candidatePaths.Add($_.FullName)
                    }
                }
            }
        }
        foreach ($ef in $ExtraFiles) {
            if ($ef -and (Test-Path $ef -PathType Leaf)) {
                [void]$candidatePaths.Add($ef)
                [void]$extraSet.Add($ef)
            }
        }

        foreach ($cp in $candidatePaths) {
            $item = Get-Item $cp -ErrorAction SilentlyContinue
            if (-not $item -or $item.Length -gt 20MB) { continue }
            $isExtra = $extraSet.Contains($cp)
            if (-not $isExtra -and ($item.Extension -in $skipBundleExts)) { continue }
            $cpText = [System.IO.File]::ReadAllText($cp)
            foreach ($kv in $activeSerials.GetEnumerator()) {
                if ($cpText.IndexOf($kv.Value, [System.StringComparison]::Ordinal) -ge 0) {
                    $pxViolations.Add("PIXEL_ACTIVE_SERIAL_LEAK: Role '$($kv.Key)' serial matched in '$cp'")
                }
            }
            if ($retiredHashes.Count -gt 0) {
                $cpHits = [SovereignBatchShaMatcher]::FindMatchesInText($cpText, $retArr)
                foreach ($hit in $cpHits) {
                    $parts = $hit.Split('|', 2)
                    $hHex = $parts[1]
                    $pxViolations.Add("PIXEL_RETIRED_SERIAL_SHA256_LEAK: Retired serial sha256=$($hHex.Substring(0,16))... found in '$cp'")
                }
            }
        }
    } finally {
        $sha256.Dispose()
    }

    return ,$pxViolations
}

function Get-GitPathsNullDelimited {
    param(
        [Parameter(Mandatory = $true)][string]$RootPath,
        [string[]]$GitArgs
    )
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "git"
    $psi.Arguments = "-c core.quotepath=false -C `"$RootPath`" " + ($GitArgs -join " ")
    $psi.UseShellExecute = $false
    $psi.RedirectStandardInput = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.CreateNoWindow = $true
    $proc = [System.Diagnostics.Process]::Start($psi)
    try {
        $proc.StandardInput.Close()
        $errTask = $proc.StandardError.ReadToEndAsync()
        $ms = New-Object System.IO.MemoryStream
        $proc.StandardOutput.BaseStream.CopyTo($ms)
        $proc.WaitForExit()
        [void]$errTask.Wait(1000)
        if ($proc.ExitCode -ne 0) {
            return @()
        }
        $rawBytes = $ms.ToArray()
        $utf8 = [System.Text.UTF8Encoding]::new($false)
        $paths = New-Object System.Collections.Generic.List[string]
        $start = 0
        for ($i = 0; $i -lt $rawBytes.Length; $i++) {
            if ($rawBytes[$i] -eq 0) {
                if ($i -gt $start) {
                    $paths.Add($utf8.GetString($rawBytes, $start, $i - $start))
                }
                $start = $i + 1
            }
        }
        if ($start -lt $rawBytes.Length) {
            $paths.Add($utf8.GetString($rawBytes, $start, $rawBytes.Length - $start))
        }
        return $paths.ToArray()
    } finally {
        $proc.Dispose()
    }
}

function Test-SovereignKeyLeakScan {
    param(
        [string]$RootPath,
        [string[]]$ExtraFiles = @(),
        [string]$OperatorKeyOverridePath = "",
        [string]$TelemetryKeyOverridePath = "",
        [string]$SyntheticOperatorKeyForSelfTest = "",
        [string]$SyntheticTelemetryKeyForSelfTest = ""
    )
    $secViolations = New-Object System.Collections.Generic.List[string]
    $retiredLiteral = "SOVEREIGN" + "-LOQ15-4200"

    $opKey = ""
    if (-not [string]::IsNullOrEmpty($SyntheticOperatorKeyForSelfTest)) {
        if ($SyntheticOperatorKeyForSelfTest.Trim().Length -lt 24) {
            $secViolations.Add("OPERATOR_KEY_MISSING: Synthetic operator test key is shorter than 24 characters")
        } else {
            $opKey = $SyntheticOperatorKeyForSelfTest.Trim()
        }
    } else {
        $opKeyPath = if ($OperatorKeyOverridePath) {
            $OperatorKeyOverridePath
        } elseif (Test-Path "C:\Users\Nbell\.act_omega_operator_vault_key") {
            "C:\Users\Nbell\.act_omega_operator_vault_key"
        } elseif ($env:USERPROFILE -and (Test-Path "$env:USERPROFILE\.act_omega_operator_vault_key")) {
            "$env:USERPROFILE\.act_omega_operator_vault_key"
        } else {
            ""
        }
        if (-not $opKeyPath -or -not (Test-Path $opKeyPath -PathType Leaf)) {
            if (-not $CloudCiMode) {
                $secViolations.Add("OPERATOR_KEY_MISSING: External operator vault key file not found")
            }
        } else {
            $opKey = ([System.IO.File]::ReadAllText($opKeyPath)).Trim()
            if ($opKey.Length -lt 24) {
                $secViolations.Add("OPERATOR_KEY_MISSING: External operator vault key is shorter than 24 characters")
                $opKey = ""
            }
        }
    }

    $telKey = ""
    if (-not [string]::IsNullOrEmpty($SyntheticTelemetryKeyForSelfTest)) {
        if ($SyntheticTelemetryKeyForSelfTest.Trim().Length -lt 24) {
            $secViolations.Add("TELEMETRY_KEY_MISSING: Synthetic telemetry test key is shorter than 24 characters")
        } else {
            $telKey = $SyntheticTelemetryKeyForSelfTest.Trim()
        }
    } else {
        $telKeyPath = if ($TelemetryKeyOverridePath) {
            $TelemetryKeyOverridePath
        } elseif (Test-Path "C:\Users\Nbell\.act_omega_telemetry_ingest_key") {
            "C:\Users\Nbell\.act_omega_telemetry_ingest_key"
        } elseif ($env:USERPROFILE -and (Test-Path "$env:USERPROFILE\.act_omega_telemetry_ingest_key")) {
            "$env:USERPROFILE\.act_omega_telemetry_ingest_key"
        } else {
            ""
        }
        if (-not $telKeyPath -or -not (Test-Path $telKeyPath -PathType Leaf)) {
            if (-not $CloudCiMode) {
                $secViolations.Add("TELEMETRY_KEY_MISSING: External telemetry ingest key file not found")
            }
        } else {
            $telKey = ([System.IO.File]::ReadAllText($telKeyPath)).Trim()
            if ($telKey.Length -lt 24) {
                $secViolations.Add("TELEMETRY_KEY_MISSING: External telemetry ingest key is shorter than 24 characters")
                $telKey = ""
            }
        }
    }

    $slot2BackupPath = "F:\ACT_OMEGA_IMMUTABLE_EPOCH_ARCHIVES\YUBIKEY_ROOT_OF_TRUST_BACKUP\SLOT2_HMAC_SHARED_SECRET_FOR_KEY2_CLONING.txt"
    $slot2SecretHex = ""
    if (Test-Path $slot2BackupPath) {
        $m = [regex]::Match((Get-Content $slot2BackupPath -Raw), '(?m)^[0-9a-fA-F]{40}\r?$')
        if ($m.Success) { $slot2SecretHex = $m.Value.Trim() }
    }

    $secretSpecs = New-Object System.Collections.Generic.List[object]
    $secretSpecs.Add([pscustomobject]@{ Code = "SECRET_LEAK_RETIRED"; Label = "Retired passkey literal"; Value = $retiredLiteral; IgnoreCase = $false })
    if ($opKey.Length -ge 24) {
        $secretSpecs.Add([pscustomobject]@{ Code = "SECRET_LEAK_ACTIVE"; Label = "Active external operator key"; Value = $opKey; IgnoreCase = $false })
    }
    if ($telKey.Length -ge 24) {
        $secretSpecs.Add([pscustomobject]@{ Code = "SECRET_LEAK_TELEMETRY_KEY"; Label = "Active external telemetry ingest key"; Value = $telKey; IgnoreCase = $false })
    }
    if ($slot2SecretHex.Length -eq 40) {
        $secretSpecs.Add([pscustomobject]@{ Code = "SECRET_LEAK_YUBIKEY_SLOT2"; Label = "YubiKey Slot-2 shared secret"; Value = $slot2SecretHex; IgnoreCase = $true })
    }

    # 1. Enumerate tracked & untracked files via git ls-files -z (ZERO secrets in CLI args!)
    $trackedRel = @(Get-GitPathsNullDelimited -RootPath $RootPath -GitArgs @("ls-files", "-z"))
    if ($trackedRel.Count -eq 0) {
        $secViolations.Add("SECRET_SCAN_GIT_LS_FILES_FAILED: Could not enumerate git ls-files -z at $RootPath")
        return ,$secViolations
    }
    $untrackedRel = @(Get-GitPathsNullDelimited -RootPath $RootPath -GitArgs @("ls-files", "--others", "--exclude-standard", "-z"))

    $extraCandidates = New-Object System.Collections.Generic.List[string]
    foreach ($bundleDir in @(
        "$RootPath\05_hud_cockpit\dist",
        "$RootPath\02_l2_orchestration\hud\dist",
        "$RootPath\docs",
        "$RootPath\assets"
    )) {
        if (Test-Path $bundleDir) {
            Get-ChildItem -Path $bundleDir -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
                if ($_.Extension -notin @('.apk', '.exe', '.png', '.jpg', '.ico', '.woff2')) {
                    $extraCandidates.Add($_.FullName)
                }
            }
        }
    }
    foreach ($ef in $ExtraFiles) {
        if ($ef) {
            $extraCandidates.Add($ef)
        }
    }

    # 2. Build deduplicated path list & scan 100% of files in-process via parallel FileStream byte scanner
    if (-not ('SovereignByteStreamScanner' -as [type])) {
        Add-Type -TypeDefinition @"
using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.IO;
using System.Threading.Tasks;
public static class SovereignByteStreamScanner {
    public static string[][] BuildScanCandidates(
        string rootPath,
        string[] trackedRel,
        string[] untrackedRel,
        string[] extraPaths
    ) {
        var paths = new List<string>(trackedRel.Length + untrackedRel.Length + extraPaths.Length);
        var labels = new List<string>(trackedRel.Length + untrackedRel.Length + extraPaths.Length);
        var seen = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

        for (int i = 0; i < trackedRel.Length; i++) {
            string rel = trackedRel[i];
            if (string.IsNullOrWhiteSpace(rel)) continue;
            string full = Path.Combine(rootPath, rel.Replace('/', '\\'));
            if (!File.Exists(full)) continue;
            if (seen.Add(full)) {
                paths.Add(full);
                labels.Add("tracked file '" + rel + "'");
            }
        }
        for (int i = 0; i < untrackedRel.Length; i++) {
            string rel = untrackedRel[i];
            if (string.IsNullOrWhiteSpace(rel)) continue;
            string full = Path.Combine(rootPath, rel.Replace('/', '\\'));
            if (!File.Exists(full)) continue;
            if (seen.Add(full)) {
                paths.Add(full);
                labels.Add(full);
            }
        }
        for (int i = 0; i < extraPaths.Length; i++) {
            string full = extraPaths[i];
            if (string.IsNullOrWhiteSpace(full)) continue;
            if (!File.Exists(full)) continue;
            if (seen.Add(full)) {
                paths.Add(full);
                labels.Add(full);
            }
        }
        return new string[][] { paths.ToArray(), labels.ToArray() };
    }

    private static int IndexOfBytes(byte[] haystack, int haystackLen, byte[] needle) {
        int nLen = needle.Length;
        if (nLen == 0 || haystackLen < nLen) return -1;
        byte first = needle[0];
        int lastOffset = nLen - 1;
        byte last = needle[lastOffset];
        int limit = haystackLen - nLen;
        for (int i = 0; i <= limit; i++) {
            if (haystack[i] != first || haystack[i + lastOffset] != last) continue;
            bool match = true;
            for (int j = 1; j < lastOffset; j++) {
                if (haystack[i + j] != needle[j]) { match = false; break; }
            }
            if (match) return i;
        }
        return -1;
    }

    public static List<string> ScanFiles(
        string[] filePaths,
        string[] displayLabels,
        byte[][] needlesExact,
        byte[][] needlesLower,
        bool[] ignoreCaseAscii,
        string[] codes,
        string[] labels
    ) {
        var hits = new List<string>();
        int specCount = needlesExact.Length;
        if (specCount == 0 || filePaths.Length == 0) return hits;

        int maxLen = 0;
        bool needLower = false;
        for (int k = 0; k < specCount; k++) {
            if (needlesExact[k].Length > maxLen) maxLen = needlesExact[k].Length;
            if (ignoreCaseAscii[k]) needLower = true;
        }
        int overlap = Math.Max(0, maxLen - 1);
        const int ChunkSize = 65536;
        object hitsLock = new object();

        Parallel.ForEach(
            Partitioner.Create(0, filePaths.Length),
            new ParallelOptions { MaxDegreeOfParallelism = Math.Min(8, Environment.ProcessorCount) },
            range => {
                byte[] buf = new byte[overlap + ChunkSize];
                byte[] lowerBuf = needLower ? new byte[overlap + ChunkSize] : null;
                bool[] matchedSpec = new bool[specCount];
                for (int fIdx = range.Item1; fIdx < range.Item2; fIdx++) {
                    string path = filePaths[fIdx];
                    string disp = displayLabels[fIdx];
                    Array.Clear(matchedSpec, 0, specCount);
                    try {
                        using (var fs = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.ReadWrite, ChunkSize, FileOptions.SequentialScan)) {
                            int carry = 0;
                            while (true) {
                                int bytesRead = fs.Read(buf, carry, ChunkSize);
                                if (bytesRead <= 0) break;
                                int validLen = carry + bytesRead;
                                if (needLower) {
                                    for (int i = 0; i < validLen; i++) {
                                        byte b = buf[i];
                                        lowerBuf[i] = (b >= 0x41 && b <= 0x5A) ? (byte)(b + 0x20) : b;
                                    }
                                }
                                for (int k = 0; k < specCount; k++) {
                                    if (matchedSpec[k]) continue;
                                    byte[] targetBuf = ignoreCaseAscii[k] ? lowerBuf : buf;
                                    byte[] needle = ignoreCaseAscii[k] ? needlesLower[k] : needlesExact[k];
                                    if (IndexOfBytes(targetBuf, validLen, needle) >= 0) {
                                        matchedSpec[k] = true;
                                        string msg = codes[k] + ": " + labels[k] + " found in " + disp;
                                        lock (hitsLock) { hits.Add(msg); }
                                    }
                                }
                                if (overlap > 0 && validLen > overlap) {
                                    Buffer.BlockCopy(buf, validLen - overlap, buf, 0, overlap);
                                    carry = overlap;
                                } else if (overlap > 0) {
                                    carry = validLen;
                                } else {
                                    carry = 0;
                                }
                            }
                        }
                    } catch (Exception ex) {
                        string errMsg = "SECRET_SCAN_READ_ERROR: Could not read " + disp + " (" + ex.Message + ")";
                        lock (hitsLock) { hits.Add(errMsg); }
                    }
                }
            }
        );
        return hits;
    }
}
"@ -Language CSharp -IgnoreWarnings
    }

    $candidates = [SovereignByteStreamScanner]::BuildScanCandidates(
        $RootPath,
        [string[]]$trackedRel,
        [string[]]$untrackedRel,
        [string[]]$extraCandidates.ToArray()
    )
    $scanPathsArr = [string[]]$candidates[0]
    $scanLabelsArr = [string[]]$candidates[1]

    $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
    $needlesExact = New-Object 'byte[][]' $secretSpecs.Count
    $needlesLower = New-Object 'byte[][]' $secretSpecs.Count
    $ignoreCaseArr = New-Object 'bool[]' $secretSpecs.Count
    $codesArr = New-Object 'string[]' $secretSpecs.Count
    $labelsArr = New-Object 'string[]' $secretSpecs.Count
    for ($k = 0; $k -lt $secretSpecs.Count; $k++) {
        $sp = $secretSpecs[$k]
        $needlesExact[$k] = $utf8NoBom.GetBytes([string]$sp.Value)
        $needlesLower[$k] = $utf8NoBom.GetBytes(([string]$sp.Value).ToLowerInvariant())
        $ignoreCaseArr[$k] = [bool]$sp.IgnoreCase
        $codesArr[$k] = [string]$sp.Code
        $labelsArr[$k] = [string]$sp.Label
    }

    $scanHits = [SovereignByteStreamScanner]::ScanFiles(
        $scanPathsArr,
        $scanLabelsArr,
        $needlesExact,
        $needlesLower,
        $ignoreCaseArr,
        $codesArr,
        $labelsArr
    )
    foreach ($sh in $scanHits) {
        $secViolations.Add($sh)
    }

    return ,$secViolations
}

if (-not ('SovereignRustAuditLexer' -as [type])) {
    Add-Type -TypeDefinition @"
using System;
using System.Text;
public static class SovereignRustAuditLexer {
    private static bool IsWordChar(char c) {
        return (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z') || (c >= '0' && c <= '9') || c == '_';
    }
    private static void AppendSpaceIfNeeded(StringBuilder sb, string rawText, int nextIdx, int contentEnd) {
        if (sb.Length == 0) return;
        char last = sb[sb.Length - 1];
        if (last == ' ' || last == '\t') return;
        if (nextIdx < contentEnd) {
            char nxt = rawText[nextIdx];
            if (nxt == ' ' || nxt == '\t') return;
        }
        sb.Append(' ');
    }
    public static string[] ComputeViews(string rawText) {
        if (string.IsNullOrEmpty(rawText)) return new string[] { "", "" };
        var displaySb = new StringBuilder(rawText.Length);
        var d1Sb = new StringBuilder(rawText.Length);
        var lineDisplay = new StringBuilder(256);
        var lineD1 = new StringBuilder(256);
        bool inString = false;
        int rawHashes = -1;
        int blockCommentDepth = 0;
        int pos = 0;
        int totalLen = rawText.Length;

        while (pos <= totalLen) {
            int lineEnd = rawText.IndexOf('\n', pos);
            int nextPos;
            int contentEnd;
            if (lineEnd >= 0) {
                contentEnd = (lineEnd > pos && rawText[lineEnd - 1] == '\r') ? lineEnd - 1 : lineEnd;
                nextPos = lineEnd + 1;
            } else {
                contentEnd = totalLen;
                nextPos = totalLen + 1;
            }

            lineDisplay.Clear();
            lineD1.Clear();
            bool hasNonWhitespaceCode = false;
            int i = pos;

            while (i < contentEnd) {
                if (blockCommentDepth > 0) {
                    int segStart = i;
                    while (i < contentEnd && blockCommentDepth > 0) {
                        if (i + 1 < contentEnd && rawText[i] == '/' && rawText[i + 1] == '*') {
                            blockCommentDepth++;
                            i += 2;
                        } else if (i + 1 < contentEnd && rawText[i] == '*' && rawText[i + 1] == '/') {
                            blockCommentDepth--;
                            i += 2;
                        } else {
                            i++;
                        }
                    }
                    int segLen = i - segStart;
                    AppendSpaceIfNeeded(lineDisplay, rawText, i, contentEnd);
                    string segStr = rawText.Substring(segStart, segLen);
                    if (segStr.IndexOf("HISTORICAL_PRE_V7322", StringComparison.OrdinalIgnoreCase) >= 0) {
                        AppendSpaceIfNeeded(lineD1, rawText, i, contentEnd);
                    } else {
                        lineD1.Append(rawText, segStart, segLen);
                    }
                    continue;
                }

                char ch = rawText[i];
                if (rawHashes >= 0) {
                    hasNonWhitespaceCode = true;
                    if (ch == '"') {
                        bool matched = (i + rawHashes) < contentEnd;
                        if (matched) {
                            for (int h = 1; h <= rawHashes; h++) {
                                if (rawText[i + h] != '#') { matched = false; break; }
                            }
                        }
                        if (matched) {
                            int spanLen = 1 + rawHashes;
                            lineDisplay.Append(rawText, i, spanLen);
                            lineD1.Append(rawText, i, spanLen);
                            i += spanLen;
                            rawHashes = -1;
                            continue;
                        }
                    }
                    lineDisplay.Append(ch);
                    lineD1.Append(ch);
                    i++;
                    continue;
                }
                if (inString) {
                    hasNonWhitespaceCode = true;
                    if (ch == '\\') {
                        int spanLen = (i + 1 < contentEnd) ? 2 : 1;
                        lineDisplay.Append(rawText, i, spanLen);
                        lineD1.Append(rawText, i, spanLen);
                        i += spanLen;
                        continue;
                    }
                    if (ch == '"') {
                        inString = false;
                    }
                    lineDisplay.Append(ch);
                    lineD1.Append(ch);
                    i++;
                    continue;
                }
                if (ch == '/' && (i + 1 < contentEnd) && rawText[i + 1] == '/') {
                    int cmtLen = contentEnd - i;
                    string commentPart = rawText.Substring(i, cmtLen);
                    if (commentPart.IndexOf("HISTORICAL_PRE_V7322", StringComparison.OrdinalIgnoreCase) < 0) {
                        lineD1.Append(rawText, i, cmtLen);
                    }
                    break;
                }
                if (ch == '/' && (i + 1 < contentEnd) && rawText[i + 1] == '*') {
                    int segStart = i;
                    blockCommentDepth = 1;
                    i += 2;
                    while (i < contentEnd && blockCommentDepth > 0) {
                        if (i + 1 < contentEnd && rawText[i] == '/' && rawText[i + 1] == '*') {
                            blockCommentDepth++;
                            i += 2;
                        } else if (i + 1 < contentEnd && rawText[i] == '*' && rawText[i + 1] == '/') {
                            blockCommentDepth--;
                            i += 2;
                        } else {
                            i++;
                        }
                    }
                    int segLen = i - segStart;
                    AppendSpaceIfNeeded(lineDisplay, rawText, i, contentEnd);
                    string segStr = rawText.Substring(segStart, segLen);
                    if (segStr.IndexOf("HISTORICAL_PRE_V7322", StringComparison.OrdinalIgnoreCase) >= 0) {
                        AppendSpaceIfNeeded(lineD1, rawText, i, contentEnd);
                    } else {
                        lineD1.Append(rawText, segStart, segLen);
                    }
                    continue;
                }
                if (ch == '\'') {
                    if ((i + 2 < contentEnd) && rawText[i + 1] != '\\' && rawText[i + 1] != '\'' && rawText[i + 2] == '\'') {
                        hasNonWhitespaceCode = true;
                        lineDisplay.Append(rawText, i, 3);
                        lineD1.Append(rawText, i, 3);
                        i += 3;
                        continue;
                    }
                    if ((i + 2 < contentEnd) && rawText[i + 1] == '\\') {
                        int k = i + 3;
                        int limit = Math.Min(contentEnd, i + 16);
                        bool closed = false;
                        while (k < limit) {
                            char kc = rawText[k];
                            if (kc == '\'') { closed = true; break; }
                            if (kc == ' ' || kc == '\t' || kc == ';') { break; }
                            k++;
                        }
                        if (closed) {
                            hasNonWhitespaceCode = true;
                            int spanLen = (k + 1) - i;
                            lineDisplay.Append(rawText, i, spanLen);
                            lineD1.Append(rawText, i, spanLen);
                            i = k + 1;
                            continue;
                        }
                    }
                    hasNonWhitespaceCode = true;
                    lineDisplay.Append(ch);
                    lineD1.Append(ch);
                    i++;
                    continue;
                }
                if (ch == 'r' || ((ch == 'b' || ch == 'c') && (i + 1 < contentEnd) && rawText[i + 1] == 'r')) {
                    bool prevWord = (i > pos) && IsWordChar(rawText[i - 1]);
                    if (!prevWord) {
                        int rPos = (ch == 'r') ? i : i + 1;
                        int scan = rPos + 1;
                        int hashes = 0;
                        while (scan < contentEnd && rawText[scan] == '#') {
                            hashes++;
                            scan++;
                        }
                        if (scan < contentEnd && rawText[scan] == '"') {
                            hasNonWhitespaceCode = true;
                            int spanLen = (scan + 1) - i;
                            lineDisplay.Append(rawText, i, spanLen);
                            lineD1.Append(rawText, i, spanLen);
                            rawHashes = hashes;
                            i = scan + 1;
                            continue;
                        }
                    }
                }
                if (ch == '"') {
                    hasNonWhitespaceCode = true;
                    inString = true;
                    lineDisplay.Append(ch);
                    lineD1.Append(ch);
                    i++;
                    continue;
                }
                if (ch != ' ' && ch != '\t') {
                    hasNonWhitespaceCode = true;
                }
                lineDisplay.Append(ch);
                lineD1.Append(ch);
                i++;
            }

            if (hasNonWhitespaceCode) {
                displaySb.Append(lineDisplay);
                d1Sb.Append(lineD1);
            }
            displaySb.Append('\n');
            d1Sb.Append('\n');
            if (lineEnd < 0) break;
            pos = nextPos;
        }
        return new string[] { displaySb.ToString(), d1Sb.ToString() };
    }
}
"@ -Language CSharp -IgnoreWarnings
}

function Get-RustAuditTextViews {
    param([string]$RawText)
    $res = [SovereignRustAuditLexer]::ComputeViews($RawText)
    return [PSCustomObject]@{
        DisplayText = $res[0]
        D1Text      = $res[1]
    }
}

function Get-E8zPluckerPocHash {
    param([string]$E8zPath)
    if (-not (Test-Path -LiteralPath $E8zPath -PathType Leaf)) { return "" }
    $rawE8z = [System.IO.File]::ReadAllBytes($E8zPath)
    if ($rawE8z.Length -lt 2080 * 64) { return "" }
    $rawEnergies = New-Object double[] 2080
    $minE = [double]::PositiveInfinity
    $maxE = [double]::NegativeInfinity
    for ($idx = 0; $idx -lt 2080; $idx++) {
        $baseOff = $idx * 64
        $sumSq = 0.0
        $sumDiff = 0.0
        for ($b = 0; $b -lt 64; $b++) {
            $centered = ($rawE8z[$baseOff + $b] - 127.5) / 127.5
            $sumSq += $centered * $centered
            if ($b -gt 0) {
                $sumDiff += [Math]::Abs($rawE8z[$baseOff + $b] - $rawE8z[$baseOff + $b - 1]) / 255.0
            }
        }
        $rms = [Math]::Sqrt($sumSq / 64.0)
        $tv = $sumDiff / 63.0
        $bm = (($rawE8z[$baseOff + ($idx % 64)] -bxor $rawE8z[$baseOff + (($idx * 7 + 13) % 64)]) -band 0xff) / 255.0
        $energy = 0.45 * $rms + 0.35 * $tv + 0.20 * $bm
        $rawEnergies[$idx] = $energy
        if ($energy -lt $minE) { $minE = $energy }
        if ($energy -gt $maxE) { $maxE = $energy }
    }
    $span = [Math]::Max(1e-6, $maxE - $minE)
    $maxSafe = [Math]::Max(1e-6, $maxE)
    $normE8z = New-Object double[] 2080
    for ($idx = 0; $idx -lt 2080; $idx++) {
        $normE8z[$idx] = [Math]::Max(0.05 * ($rawEnergies[$idx] / $maxSafe), ($rawEnergies[$idx] - $minE) / $span)
    }
    [uint32]$crc = 0x5348345AL
    for ($i = 0; $i -lt 704; $i++) {
        $ia = ($i * 6) % 2080
        $ib = ($ia + 44) % 2080
        $pab = $normE8z[$ia] * $normE8z[($ib + 5) % 2080] - $normE8z[($ia + 1) % 2080] * $normE8z[($ib + 4) % 2080] + $normE8z[($ia + 2) % 2080] * $normE8z[($ib + 3) % 2080] + $normE8z[($ia + 3) % 2080] * $normE8z[($ib + 2) % 2080] - $normE8z[($ia + 4) % 2080] * $normE8z[($ib + 1) % 2080] + $normE8z[($ia + 5) % 2080] * $normE8z[$ib]
        [int32]$trunc = [Math]::Truncate($pab * 10000.0)
        [uint32]$pluckerWord = [BitConverter]::ToUInt32([BitConverter]::GetBytes($trunc), 0)
        [uint64]$prod = ([uint64]($crc -bxor $pluckerWord)) * ([uint64]0x01000193)
        $crc = [uint32]($prod -band ([uint64]4294967295))
    }
    return ("0x{0:X6}_PLUCKER_POS_QED" -f ($crc -band 0xFFFFFF))
}

function Run-StaticGatekeeperChecks {
    $failures = New-Object System.Collections.Generic.List[string]

    # 1. Zero-Square-Bracket L0 Rust Check (v33..v99+)
    $vFiles = Get-ChildItem -Path "$RepoRoot\01_l0_rust\src\v*.rs" -File | Where-Object { $_.Name -match '^v(3[3-9]|[4-9][0-9])_' }
    foreach ($vf in $vFiles) {
        $text = [System.IO.File]::ReadAllText($vf.FullName)
        $bCount = ([regex]::Matches($text, '[\[\]]')).Count
        if ($bCount -gt 0) {
            $failures.Add("L0_RUST_BRACKET_VIOLATION: $($vf.Name) contains $bCount square brackets (Req: 0)")
        }
    }

    # 2. Substantive Lean 4 & Vault/L0 Mirror Parity Check (Live >= 1010)
    $leanVault = if ($LeanOverridePath) { $LeanOverridePath } else { "$RepoRoot\03_vault\lean4\SovereignManifoldTheorems.lean" }
    $leanL0 = "$RepoRoot\01_l0_rust\lean4\SovereignManifoldTheorems.lean"
    if (-not (Test-Path $leanVault) -or -not (Test-Path $leanL0)) {
        $failures.Add("LEAN4_MISSING: SovereignManifoldTheorems.lean missing in 03_vault or 01_l0_rust")
    } else {
        if (-not $LeanOverridePath) {
            $h1 = (Get-FileHash $leanVault -Algorithm SHA256).Hash
            $h2 = (Get-FileHash $leanL0 -Algorithm SHA256).Hash
            if ($h1 -ne $h2) {
                $failures.Add("LEAN4_MIRROR_DRIFT: 03_vault/lean4 ($($h1.Substring(0,12))) != 01_l0_rust/lean4 ($($h2.Substring(0,12)))")
            }
        }
        $leanErrs = Test-Lean4ThresholdCheck -LeanPath $leanVault
        foreach ($le in $leanErrs) {
            $failures.Add($le)
        }
    }

    # 3. HUD & Mobile Source Mirror Lockstep Check
    $hud1 = "$RepoRoot\05_hud_cockpit\src\App.tsx"
    $hud2 = "$RepoRoot\02_l2_orchestration\hud\src\App.tsx"
    if ((Get-FileHash $hud1 -Algorithm SHA256).Hash -ne (Get-FileHash $hud2 -Algorithm SHA256).Hash) {
        $failures.Add("HUD_MIRROR_DRIFT: 05_hud_cockpit/src/App.tsx != 02_l2_orchestration/hud/src/App.tsx")
    }
    $ktRoot = "$RepoRoot\04_edge_silicon\pixel10_ndk_app\MainActivity.kt"
    $kt1 = "$RepoRoot\04_edge_silicon\pixel10_ndk_app\app\src\main\java\com\actomega\manifold\MainActivity.kt"
    $kt2 = "$RepoRoot\04_edge_silicon\pixel10_ndk_app\src\main\java\com\actomega\manifold\MainActivity.kt"
    $hKt1 = (Get-FileHash $kt1 -Algorithm SHA256).Hash
    $hKt2 = (Get-FileHash $kt2 -Algorithm SHA256).Hash
    $hKtR = if (Test-Path $ktRoot) { (Get-FileHash $ktRoot -Algorithm SHA256).Hash } else { "" }
    if (($hKt1 -ne $hKt2) -or ($hKtR -and ($hKt1 -ne $hKtR))) {
        $failures.Add("MOBILE_MIRROR_DRIFT: 3-way MainActivity.kt SHA-256 mismatch")
    }
    $stagingKt = "$RepoRoot\03_vault\config\MainActivity.kt.staging"
    $stagingTracked = @(git -C $RepoRoot ls-files "03_vault/config/MainActivity.kt.staging" 2>$null)
    if ((Test-Path $stagingKt) -or $stagingTracked.Count -gt 0) {
        $failures.Add("STAGING_MAINACTIVITY_PRESENT: 03_vault/config/MainActivity.kt.staging must be deleted")
    }
    $androidXmls = @(
        "$RepoRoot\04_edge_silicon\pixel10_ndk_app\app\src\main\res\values\strings.xml",
        "$RepoRoot\04_edge_silicon\pixel10_ndk_app\src\main\res\values\strings.xml",
        "$RepoRoot\04_edge_silicon\pixel10_ndk_app\app\src\main\AndroidManifest.xml",
        "$RepoRoot\04_edge_silicon\pixel10_ndk_app\src\main\AndroidManifest.xml"
    )
    foreach ($ax in $androidXmls) {
        if (Test-Path $ax) {
            $axTxt = [System.IO.File]::ReadAllText($ax)
            if ($axTxt -match 'v72\.2\.0|CHAIN 368|995/995') {
                $failures.Add("ANDROID_XML_STALE_STAMP: Stale v72.2.0 / CHAIN 368 / 995/995 in $ax")
            }
        }
    }
    $staleDisplayPattern = '\b(?:\d{1,4}|\d{1,3},\d{3})\s*/\s*1,?010\b|(?<!\d)/1,?010\b|\b1,?010\s+(?:Lean\s+4\s+|Formal\s+)?(?:QED|Theorems)\b|CHAIN\s+368'
    $staleD1TablePattern = '(?i)(?:\b10[- ]tables?\b|\b10/10\s+D1\s+Tables?\b|\b10\s+D1\s+Tables?\b|\\?"?(?:tables_count|d1_tables_synced|cloudflare_d1_tables)\\?"?\s*:\s*10\b|v44_operationalized_research_shards|v44_multiturn_discourse_memory|(?<!\w)act_omega_d1_vault(?!_v7322(?!\w)))'

    foreach ($ktPath in @($ktRoot, $kt1, $kt2)) {
        if ($ktPath -and (Test-Path $ktPath -PathType Leaf)) {
            $ktTxt = [System.IO.File]::ReadAllText($ktPath)
            $ktCode = [regex]::Replace($ktTxt, '(?m)^\s*//.*$', '')
            if (($ktCode -match '/1010\b|1,010/1,010\s+(?:Lean\s+4\s+)?QED|CHAIN 368') -or ($ktCode -match $staleDisplayPattern)) {
                $failures.Add("ANDROID_KOTLIN_STALE_STAMP: Static /1010, 1,010/1,010 QED, or CHAIN 368 literal in $ktPath")
            }
            $ktD1 = [regex]::Match($ktCode, $staleD1TablePattern)
            if ($ktD1.Success) {
                $failures.Add("ANDROID_KOTLIN_STALE_D1_TABLE: Matched '$($ktD1.Value)' in $ktPath")
            }
        }
    }

    # 3b. C# Tray/HUD Parity, Extended Stale-Stamp Scan (HUD, C#, Haskell, HTML/Wiki, L0 Rust) & Multi-Target Mirror Parity
    $csTray = "$RepoRoot\00_control\Win11_Native_Tray_HUD\SovereignTrayAndHud.cs"
    $csRoot = "$RepoRoot\00_control\SovereignCockpitHUD.cs"
    if (-not (Test-Path $csTray) -or -not (Test-Path $csRoot)) {
        $failures.Add("CSHARP_HUD_MISSING: SovereignTrayAndHud.cs or SovereignCockpitHUD.cs missing")
    } elseif ((Get-FileHash $csTray -Algorithm SHA256).Hash -ne (Get-FileHash $csRoot -Algorithm SHA256).Hash) {
        $failures.Add("CSHARP_HUD_MIRROR_DRIFT: SovereignTrayAndHud.cs != SovereignCockpitHUD.cs")
    }

    $staleScanFiles = New-Object System.Collections.Generic.List[string]
    $staleScanSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($sf in @(
        "$RepoRoot\05_hud_cockpit\src\App.tsx",
        "$RepoRoot\02_l2_orchestration\hud\src\App.tsx",
        "$RepoRoot\00_control\SovereignCockpitHUD.cs",
        "$RepoRoot\00_control\Win11_Native_Tray_HUD\SovereignTrayAndHud.cs",
        "$RepoRoot\00_control\Win11_Native_Tray_HUD\VesperArachneSwarmDroneOverlay.cs",
        "$RepoRoot\06_algebraic_haskell\src\Main.hs",
        "$RepoRoot\06_algebraic_haskell\src\Sovereign\Codegen\ZeroBracketRustAndLean4.hs",
        "$RepoRoot\00_control\Sovereign-Lifecycle.ps1",
        "$RepoRoot\CITATION.cff",
        "$RepoRoot\.zenodo.json",
        "$RepoRoot\index.html",
        "$RepoRoot\hud.html",
        "$RepoRoot\docs\index.html",
        "$RepoRoot\docs\hud.html",
        "$RepoRoot\05_hud_cockpit\index.html",
        "$RepoRoot\02_l2_orchestration\hud\index.html",
        "$RepoRoot\05_hud_cockpit\dist\index.html",
        "$RepoRoot\02_l2_orchestration\hud\dist\index.html",
        "$RepoRoot\05_hud_cockpit\public\act_omega_hud_gemini_win11_m3_redesign_template.html",
        "$RepoRoot\02_l2_orchestration\hud\public\act_omega_hud_gemini_win11_m3_redesign_template.html",
        "$RepoRoot\05_hud_cockpit\dist\act_omega_hud_gemini_win11_m3_redesign_template.html",
        "$RepoRoot\02_l2_orchestration\hud\dist\act_omega_hud_gemini_win11_m3_redesign_template.html",
        "$RepoRoot\docs\act_omega_hud_gemini_win11_m3_redesign_template.html",
        "$RepoRoot\llms.txt",
        "$RepoRoot\docs\llms.txt",
        "$RepoRoot\05_hud_cockpit\public\llms.txt",
        "$RepoRoot\05_hud_cockpit\dist\llms.txt",
        "$RepoRoot\02_l2_orchestration\hud\public\llms.txt",
        "$RepoRoot\02_l2_orchestration\hud\dist\llms.txt",
        "$RepoRoot\manifest.webmanifest",
        "$RepoRoot\docs\manifest.webmanifest",
        "$RepoRoot\05_hud_cockpit\public\manifest.webmanifest",
        "$RepoRoot\05_hud_cockpit\dist\manifest.webmanifest",
        "$RepoRoot\02_l2_orchestration\hud\public\manifest.webmanifest",
        "$RepoRoot\02_l2_orchestration\hud\dist\manifest.webmanifest",
        "$RepoRoot\wiki.html",
        "$RepoRoot\docs\wiki.html",
        "$RepoRoot\05_hud_cockpit\public\wiki.html",
        "$RepoRoot\05_hud_cockpit\dist\wiki.html",
        "$RepoRoot\02_l2_orchestration\hud\public\wiki.html",
        "$RepoRoot\02_l2_orchestration\hud\dist\wiki.html"
    )) {
        if ($staleScanSet.Add($sf)) { $staleScanFiles.Add($sf) }
    }

    foreach ($assetDir in @(
        "$RepoRoot\05_hud_cockpit\dist\assets",
        "$RepoRoot\02_l2_orchestration\hud\dist\assets",
        "$RepoRoot\docs\assets",
        "$RepoRoot\assets"
    )) {
        if (Test-Path $assetDir) {
            Get-ChildItem -Path $assetDir -Filter "*.js" -File -ErrorAction SilentlyContinue | ForEach-Object {
                if ($staleScanSet.Add($_.FullName)) { $staleScanFiles.Add($_.FullName) }
            }
        }
    }

    $extraJsonFiles = New-Object System.Collections.Generic.List[string]
    foreach ($ef in $ExtraFilesToScan) {
        if ($ef -and (Test-Path $ef -PathType Leaf)) {
            if ([System.IO.Path]::GetExtension($ef) -ieq '.json') {
                $extraJsonFiles.Add($ef)
            }
            if ([System.IO.Path]::GetFileName($ef) -notmatch '^telemetry_snapshot.*\.json$') {
                if ($staleScanSet.Add($ef)) { $staleScanFiles.Add($ef) }
            }
        }
    }

    foreach ($scanPath in $staleScanFiles) {
        if (-not (Test-Path $scanPath -PathType Leaf)) {
            $failures.Add("STALE_SCAN_FILE_MISSING: Expected artifact $scanPath not found")
            continue
        }
        $scanTxt = [System.IO.File]::ReadAllText($scanPath)
        if ($scanPath.EndsWith('.rs', [System.StringComparison]::OrdinalIgnoreCase)) {
            $rvScan = Get-RustAuditTextViews -RawText $scanTxt
            $displayTxt = $rvScan.DisplayText
            $d1Txt = $rvScan.D1Text
        } else {
            $displayTxt = $scanTxt
            $d1Txt = $scanTxt
        }
        $sm = [regex]::Match($displayTxt, $staleDisplayPattern)
        if ($sm.Success) {
            $failures.Add("STALE_DISPLAY_STAMP: Matched '$($sm.Value)' in $scanPath")
        }
        $dm = [regex]::Match($d1Txt, $staleD1TablePattern)
        if ($dm.Success) {
            $failures.Add("STALE_D1_TABLE_COUNT: Matched '$($dm.Value)' in $scanPath")
        }
    }

    $allRustSrcFiles = @(Get-ChildItem -Path "$RepoRoot\01_l0_rust\src" -Filter "*.rs" -Recurse -File | Sort-Object FullName)
    $displayAuditSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($dp in @(
        "$RepoRoot\01_l0_rust\src\bin\v31_swarm.rs",
        "$RepoRoot\01_l0_rust\src\v31_swarm.rs",
        "$RepoRoot\01_l0_rust\src\v72_2_sh_xi_sparse_moe_chatml_sft_and_rag.rs"
    )) { [void]$displayAuditSet.Add($dp) }

    foreach ($rsFile in $allRustSrcFiles) {
        $rsRaw = [System.IO.File]::ReadAllText($rsFile.FullName)
        # String-literal-aware line lexer: preserves "https://..." / \" while stripping inline // comments for DisplayText and retaining un-annotated inline // comments for D1Text
        $rvRs = Get-RustAuditTextViews -RawText $rsRaw
        if ($displayAuditSet.Contains($rsFile.FullName)) {
            $rm = [regex]::Match($rvRs.DisplayText, $staleDisplayPattern)
            if ($rm.Success) {
                $failures.Add("L0_RUST_STALE_DISPLAY_STAMP: Matched '$($rm.Value)' in active Rust code of $($rsFile.FullName)")
            }
        }
        $dmRs = [regex]::Match($rvRs.D1Text, $staleD1TablePattern)
        if ($dmRs.Success) {
            $failures.Add("L0_RUST_STALE_D1_TABLE_COUNT: Matched '$($dmRs.Value)' in active Rust code of $($rsFile.FullName)")
        }
    }

    # 6-way Mirror Parity & JSON Validity for wiki.html, llms.txt, manifest.webmanifest, and telemetry_snapshot.json
    $testSnapshotJson = {
        param([string]$FullPath, [string]$Label)
        $snapRaw = [System.IO.File]::ReadAllText($FullPath)
        if ([string]::IsNullOrWhiteSpace($snapRaw)) {
            $failures.Add("TELEMETRY_SNAPSHOT_EMPTY_JSON: $Label is empty or whitespace")
            return
        }
        if ($snapRaw -match 'HRoT-5C-NFC') {
            $failures.Add("TELEMETRY_SNAPSHOT_CORRUPT_TOKEN: Unquoted HRoT-5C-NFC found in $Label")
        }
        try {
            $snapObj = $snapRaw | ConvertFrom-Json
            if ($null -eq $snapObj) {
                $failures.Add("TELEMETRY_SNAPSHOT_NULL_JSON: $Label parsed to null via ConvertFrom-Json")
            }
        } catch {
            $failures.Add("TELEMETRY_SNAPSHOT_INVALID_JSON: $Label failed ConvertFrom-Json ($($_.Exception.Message))")
        }
    }

    foreach ($mirrorRelGroup in @(
        @("wiki.html", "docs\wiki.html", "05_hud_cockpit\public\wiki.html", "05_hud_cockpit\dist\wiki.html", "02_l2_orchestration\hud\public\wiki.html", "02_l2_orchestration\hud\dist\wiki.html"),
        @("llms.txt", "docs\llms.txt", "05_hud_cockpit\public\llms.txt", "05_hud_cockpit\dist\llms.txt", "02_l2_orchestration\hud\public\llms.txt", "02_l2_orchestration\hud\dist\llms.txt"),
        @("manifest.webmanifest", "docs\manifest.webmanifest", "05_hud_cockpit\public\manifest.webmanifest", "05_hud_cockpit\dist\manifest.webmanifest", "02_l2_orchestration\hud\public\manifest.webmanifest", "02_l2_orchestration\hud\dist\manifest.webmanifest"),
        @("telemetry_snapshot.json", "docs\telemetry_snapshot.json", "05_hud_cockpit\public\telemetry_snapshot.json", "05_hud_cockpit\dist\telemetry_snapshot.json", "02_l2_orchestration\hud\public\telemetry_snapshot.json", "02_l2_orchestration\hud\dist\telemetry_snapshot.json")
    )) {
        $baseHash = $null
        foreach ($relP in $mirrorRelGroup) {
            $fullP = Join-Path $RepoRoot $relP
            if (-not (Test-Path $fullP -PathType Leaf)) {
                $failures.Add("MIRROR_FILE_MISSING: $relP not found")
                continue
            }
            $curHash = (Get-FileHash $fullP -Algorithm SHA256).Hash
            if (-not $baseHash) { $baseHash = $curHash }
            elseif ($curHash -ne $baseHash) {
                $failures.Add("MIRROR_PARITY_DRIFT: $relP SHA-256 differs from $($mirrorRelGroup[0])")
            }
            if ($relP.EndsWith("telemetry_snapshot.json")) {
                & $testSnapshotJson $fullP $relP
            }
        }
    }
    foreach ($ej in $extraJsonFiles) {
        & $testSnapshotJson $ej $ej
    }

    # 3a. Single Canonical Cloudflare Edge Worker Check (B9: zero duplicate root worker)
    $workerRoot = "$RepoRoot\worker_vpc_shadow_v3700.js"
    $workerEdge = "$RepoRoot\00_control\cloudflare_edge\worker_vpc_shadow_v3700.js"
    if (Test-Path $workerRoot) {
        $failures.Add("CLOUDFLARE_DUPLICATE_ROOT_WORKER: Duplicate root worker_vpc_shadow_v3700.js must not exist (B9)")
    }
    if (-not (Test-Path $workerEdge)) {
        $failures.Add("CLOUDFLARE_WORKER_MISSING: Canonical worker_vpc_shadow_v3700.js missing at 00_control/cloudflare_edge")
    }

    # 4. Constitutional Context & Agent/Rule Global/Workspace Lockstep
    $gWork = "$RepoRoot\GEMINI.md"
    $gUser1 = "C:\Users\Nbell\.gemini\GEMINI.md"
    $gUser2 = "C:\Users\Nbell\.gemini\AGENTS.md"
    if ((Test-Path $gWork) -and (Test-Path $gUser1) -and (Test-Path $gUser2)) {
        $hw = (Get-FileHash $gWork -Algorithm SHA256).Hash
        $hu1 = (Get-FileHash $gUser1 -Algorithm SHA256).Hash
        $hu2 = (Get-FileHash $gUser2 -Algorithm SHA256).Hash
        if (($hw -ne $hu1) -or ($hw -ne $hu2)) {
            $failures.Add("CONSTITUTION_DRIFT: GEMINI.md / AGENTS.md out of sync between workspace and ~/.gemini")
        }
    }
    $agentFiles = Get-ChildItem -Path "$RepoRoot\.agents\agents\*.md" -File
    if ($agentFiles.Count -lt 10) {
        $failures.Add("AGENT_ROSTER_INCOMPLETE: Found $($agentFiles.Count) agents in .agents/agents (Req: >= 10)")
    }
    $ruleFiles = Get-ChildItem -Path "$RepoRoot\.agents\rules\*.md" -File
    if ($ruleFiles.Count -lt 6) {
        $failures.Add("RULE_ROSTER_INCOMPLETE: Found $($ruleFiles.Count) rules in .agents/rules (Req: >= 6)")
    }

    # Guard host user directory comparison so CI does not report false mirror drift
    $globalConfigBase = if (Test-Path "C:\Users\Nbell\.gemini\config") {
        "C:\Users\Nbell\.gemini\config"
    } elseif ($env:USERPROFILE -and (Test-Path "$env:USERPROFILE\.gemini\config")) {
        "$env:USERPROFILE\.gemini\config"
    } else {
        $null
    }

    if ($globalConfigBase) {
        foreach ($af in $agentFiles) {
            $globalAf = "$globalConfigBase\agents\$($af.Name)"
            if (-not (Test-Path $globalAf) -or ((Get-FileHash $af.FullName -Algorithm SHA256).Hash -ne (Get-FileHash $globalAf -Algorithm SHA256).Hash)) {
                $failures.Add("AGENT_MIRROR_DRIFT: $($af.Name) out of sync with ~/.gemini/config/agents")
            }
        }
        foreach ($rf in $ruleFiles) {
            $globalRf = "$globalConfigBase\rules\$($rf.Name)"
            if (-not (Test-Path $globalRf) -or ((Get-FileHash $rf.FullName -Algorithm SHA256).Hash -ne (Get-FileHash $globalRf -Algorithm SHA256).Hash)) {
                $failures.Add("RULE_MIRROR_DRIFT: $($rf.Name) out of sync with ~/.gemini/config/rules")
            }
        }
    }

    # 4a. YAML Frontmatter Escape Check (no raw backslashes like E:\ inside double-quoted YAML frontmatter)
    foreach ($mdCust in @(Get-ChildItem "$RepoRoot\.agents\rules\*.md", "$RepoRoot\.agents\agents\*.md", "$RepoRoot\.agents\skills\*\*.md" -ErrorAction SilentlyContinue)) {
        $mdRaw = [System.IO.File]::ReadAllText($mdCust.FullName)
        if ($mdRaw -match '(?s)^---\r?\n(.*?)\r?\n---') {
            if ($Matches[1] -match '\\') {
                $failures.Add("YAML_FRONTMATTER_ESCAPE: $($mdCust.Name) contains a backslash in YAML frontmatter (use E: or forward slashes)")
            }
        }
    }

    # 4b. .zenodo.json & CITATION.cff Authorship (Donevin Frownfelter) & Viazovska Citation Lockstep
    foreach ($citePath in @("$RepoRoot\.zenodo.json", "$RepoRoot\CITATION.cff")) {
        if (-not (Test-Path $citePath)) {
            $failures.Add("CITATION_FILE_MISSING: $citePath not found")
        } else {
            $citeRaw = [System.IO.File]::ReadAllText($citePath)
            if (($citeRaw -notmatch 'Frownfelter') -or ($citeRaw -notmatch 'Donevin')) {
                $failures.Add("AUTHORSHIP_DRIFT: $citePath missing Primary Author Donevin Frownfelter")
            }
            if (($citeRaw -match 'Bell,\s*Nicholas') -or ($citeRaw -match 'Nicholas\s+Bell') -or ($citeRaw -match 'Garlock,\s*Richard')) {
                $failures.Add("AUTHORSHIP_CONTAMINATION: $citePath contains retired OS username attribution (Bell/Garlock)")
            }
            if ($citeRaw -notmatch '10\.4007/annals\.2017\.185\.3\.7') {
                $failures.Add("CITATION_MISSING_VIAZOVSKA: $citePath missing Maryna S. Viazovska E8 citation (10.4007/annals.2017.185.3.7)")
            }
        }
    }

    # 5. Zero-Secret Leak Check (Fail-Closed git ls-files + Untracked/Dist Scan for Operator Key, Telemetry Key, Retired Passkey & Slot-2)
    $secViolations = Test-SovereignKeyLeakScan -RootPath $RepoRoot -ExtraFiles $ExtraFilesToScan
    foreach ($sv in $secViolations) {
        $failures.Add($sv)
    }

    # 6. HTML External Crawler SSR Pre-Population & Asset Bundle Verification
    $htmlFiles = @(
        "$RepoRoot\index.html",
        "$RepoRoot\hud.html",
        "$RepoRoot\docs\index.html",
        "$RepoRoot\docs\hud.html",
        "$RepoRoot\05_hud_cockpit\dist\index.html",
        "$RepoRoot\02_l2_orchestration\hud\dist\index.html"
    )
    foreach ($hf in $htmlFiles) {
        if (-not (Test-Path $hf)) {
            $failures.Add("HTML_MISSING: $hf not found")
            continue
        }
        $hContent = [System.IO.File]::ReadAllText($hf)
        if ($hContent -notmatch 'data-sovereign-ssr="v(56|60|61|62|63|68|69|70|71|72|73|74|75)(\.[0-9]+)*"') {
            $failures.Add("HTML_SSR_MISSING: $hf missing data-sovereign-ssr attribute")
        }
        $bundleMatches = [regex]::Matches($hContent, '(?i)(?:\./)?assets/(index-[^"''\s>]+\.js)')
        if ($bundleMatches.Count -eq 0) {
            $failures.Add("HTML_JS_BUNDLE_REF_MISSING: No assets/index-*.js script found in $hf")
        } else {
            foreach ($bm in $bundleMatches) {
                $bName = $bm.Groups[1].Value
                $rootAsset = "$RepoRoot\assets\$bName"
                $docsAsset = "$RepoRoot\docs\assets\$bName"
                $l2DistAsset = "$RepoRoot\02_l2_orchestration\hud\dist\assets\$bName"
                if (-not (Test-Path $rootAsset)) {
                    $failures.Add("JS_BUNDLE_MISSING_ROOT: $bName referenced in $hf missing at $rootAsset")
                }
                if (-not (Test-Path $docsAsset)) {
                    $failures.Add("JS_BUNDLE_MISSING_DOCS: $bName referenced in $hf missing at $docsAsset")
                }
                if (-not (Test-Path $l2DistAsset)) {
                    $failures.Add("JS_BUNDLE_MISSING_L2_DIST: $bName referenced in $hf missing at $l2DistAsset")
                }
                if ($hf -like "*\dist\*") {
                    $distAsset = "$RepoRoot\05_hud_cockpit\dist\assets\$bName"
                    if (-not (Test-Path $distAsset)) {
                        $failures.Add("JS_BUNDLE_MISSING_DIST: $bName referenced in $hf missing at $distAsset")
                    }
                }
            }
        }
    }

    # 7. Google Search Console Verification Certificate Invariant (7 Target Paths, 53 Bytes, Exact SHA-256)
    $gscExpectedHash = "0241DC5EDED053A96317C9C8FF34F4DCF12C069F88B8D92636D5D795EC176B3D"
    $gscTargets = @(
        "$RepoRoot\05_hud_cockpit\public\google6edc0affb12d0455.html",
        "$RepoRoot\02_l2_orchestration\hud\public\google6edc0affb12d0455.html",
        "$RepoRoot\05_hud_cockpit\dist\google6edc0affb12d0455.html",
        "$RepoRoot\02_l2_orchestration\hud\dist\google6edc0affb12d0455.html",
        "$RepoRoot\docs\google6edc0affb12d0455.html",
        "$RepoRoot\google6edc0affb12d0455.html"
    )
    if (Test-Path "E:\Sovereign_Manifold_SSD_Vault") {
        $gscTargets += "E:\Sovereign_Manifold_SSD_Vault\google6edc0affb12d0455.html"
    }
    foreach ($gt in $gscTargets) {
        if (-not (Test-Path $gt)) {
            $failures.Add("GSC_CERT_MISSING: $gt not found")
            continue
        }
        $item = Get-Item $gt
        if ($item.Length -ne 53) {
            $failures.Add("GSC_CERT_BAD_LENGTH: $gt length is $($item.Length) bytes (Req: 53)")
        }
        $h = (Get-FileHash $gt -Algorithm SHA256).Hash
        if ($h -ne $gscExpectedHash) {
            $failures.Add("GSC_CERT_HASH_MISMATCH: $gt SHA256=$h (Req: $gscExpectedHash)")
        }
    }

    # 8. Repo-Wide git ls-files Cloudflare ID Leak & Wrangler Hex Assignment Scan (Item #5)
    $cfViolations = Test-CloudflareIdLeakScan -RootPath $RepoRoot -ExtraFiles $ExtraFilesToScan
    foreach ($cfv in $cfViolations) {
        $failures.Add($cfv)
    }

    # 9. Repo-Wide Pixel ADB Serial Leak Scan (Item #10c)
    $pxViolations = Test-PixelSerialLeakScan -RootPath $RepoRoot -ExtraFiles $ExtraFilesToScan
    foreach ($pxv in $pxViolations) {
        $failures.Add($pxv)
    }

    # 10. External HMAC-Signed Lean 4 Verification Receipt Gate (Item #13)
    $leanReceiptVerifier = "$RepoRoot\00_control\Verify-Lean4IndependentReceipt.ps1"
    if (-not (Test-Path $leanReceiptVerifier)) {
        $failures.Add("LEAN4_RECEIPT_VERIFIER_MISSING: $leanReceiptVerifier not found")
    } elseif ($CloudCiMode -and [string]::IsNullOrWhiteSpace($env:ACT_OMEGA_OPERATOR_KEY) -and -not (Test-Path "C:\Users\Nbell\.act_omega_operator_vault_key") -and -not ($env:USERPROFILE -and (Test-Path "$env:USERPROFILE\.act_omega_operator_vault_key"))) {
        $leanRecPath = "$RepoRoot\03_vault\receipts\lean4_compiler_verification_receipt.json"
        if (-not (Test-Path $leanRecPath)) {
            $failures.Add("LEAN4_RECEIPT_MISSING: $leanRecPath not found")
        } else {
            $lrObj = Get-Content -Raw $leanRecPath | ConvertFrom-Json
            $liveLeanSha = (Get-FileHash "$RepoRoot\03_vault\lean4\SovereignManifoldTheorems.lean" -Algorithm SHA256).Hash.ToLowerInvariant()
            if (([string]$lrObj.lean_sha256).ToLowerInvariant() -ne $liveLeanSha -or [int]$lrObj.theorem_count -lt 1027 -or [int]$lrObj.sorry_count -ne 0 -or [int]$lrObj.axiom_count -ne 0) {
                $failures.Add("LEAN4_RECEIPT_DRIFT_CI: Receipt lean_sha256/theorem_count mismatch against SovereignManifoldTheorems.lean")
            }
        }
    } else {
        try {
            $vOut = (& powershell -InputFormat None -NoProfile -ExecutionPolicy Bypass -File $leanReceiptVerifier -VerifyOnly -RepoRoot $RepoRoot 2>&1) -join " "
            if ($LASTEXITCODE -ne 0) {
                $failures.Add("LEAN4_HMAC_RECEIPT_INVALID: $vOut")
            }
        } catch {
            $failures.Add("LEAN4_HMAC_RECEIPT_ERROR: $($_.Exception.Message)")
        }
    }

    return ,$failures
}

if ($HookStdin) {
    $ErrorActionPreference = "SilentlyContinue"
    $rawInput = ""
    try {
        if (-not ('SovereignHookStdinReader' -as [type])) {
            Add-Type -TypeDefinition @"
using System;
using System.Diagnostics;
using System.IO;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;
public static class SovereignHookStdinReader {
    private const int STD_INPUT_HANDLE = -10;
    private const uint FILE_TYPE_DISK = 1;
    private const uint FILE_TYPE_PIPE = 3;

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern IntPtr GetStdHandle(int nStdHandle);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern uint GetFileType(IntPtr hFile);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool PeekNamedPipe(
        IntPtr hNamedPipe,
        IntPtr lpBuffer,
        uint nBufferSize,
        IntPtr lpBytesRead,
        out uint lpTotalBytesAvail,
        IntPtr lpBytesLeftThisMessage
    );

    private static bool IsIncompleteJsonObject(MemoryStream ms) {
        if (ms.Length == 0) return false;
        string s = Encoding.UTF8.GetString(ms.ToArray());
        if (s.Length > 0 && s[0] == '\uFEFF') {
            s = s.Substring(1);
        }
        s = s.Trim();
        if (s.Length == 0 || s[0] != '{') return false;
        if (!s.EndsWith("}")) return true;
        int depth = 0;
        bool inStr = false;
        bool esc = false;
        for (int i = 0; i < s.Length; i++) {
            char c = s[i];
            if (inStr) {
                if (esc) {
                    esc = false;
                } else if (c == '\\') {
                    esc = true;
                } else if (c == '"') {
                    inStr = false;
                }
            } else {
                if (c == '"') {
                    inStr = true;
                } else if (c == '{') {
                    depth++;
                } else if (c == '}') {
                    depth--;
                }
            }
        }
        return inStr || depth != 0;
    }

    public static string ReadHookStdin(int timeoutMs) {
        if (!Console.IsInputRedirected) return "";
        IntPtr hIn = GetStdHandle(STD_INPUT_HANDLE);
        if (hIn == IntPtr.Zero || hIn == new IntPtr(-1)) return "";
        uint fType = GetFileType(hIn);
        if (fType == FILE_TYPE_DISK) {
            using (var sr = new StreamReader(Console.OpenStandardInput(), Encoding.UTF8, true, 4096, true)) {
                return sr.ReadToEnd();
            }
        }
        if (fType != FILE_TYPE_PIPE) return "";

        var ms = new MemoryStream();
        Stream stdin = Console.OpenStandardInput();
        byte[] buf = new byte[65536];
        var sw = Stopwatch.StartNew();
        long lastDataMs = 0;
        const int incompleteIdleSettleMs = 150;
        while (true) {
            uint avail = 0;
            bool ok = PeekNamedPipe(hIn, IntPtr.Zero, 0, IntPtr.Zero, out avail, IntPtr.Zero);
            if (ok && avail > 0) {
                int toRead = (int)Math.Min(avail, (uint)buf.Length);
                int n = stdin.Read(buf, 0, toRead);
                if (n > 0) {
                    ms.Write(buf, 0, n);
                    lastDataMs = sw.ElapsedMilliseconds;
                }
                continue;
            }
            if (!ok) {
                break;
            }
            if (ms.Length > 0) {
                if (IsIncompleteJsonObject(ms)) {
                    if (sw.ElapsedMilliseconds >= timeoutMs || (sw.ElapsedMilliseconds - lastDataMs) >= incompleteIdleSettleMs) {
                        break;
                    }
                    Thread.Sleep(20);
                    continue;
                }
                Thread.Sleep(30);
                uint availAfter = 0;
                bool okAfter = PeekNamedPipe(hIn, IntPtr.Zero, 0, IntPtr.Zero, out availAfter, IntPtr.Zero);
                if (okAfter && availAfter > 0) {
                    continue;
                }
                break;
            }
            if (sw.ElapsedMilliseconds >= timeoutMs) {
                break;
            }
            Thread.Sleep(20);
        }
        if (ms.Length == 0) return "";
        string txt = Encoding.UTF8.GetString(ms.ToArray());
        if (txt.Length > 0 && txt[0] == '\uFEFF') {
            txt = txt.Substring(1);
        }
        return txt;
    }
}
"@ -Language CSharp -IgnoreWarnings
        }
        $rawInput = [SovereignHookStdinReader]::ReadHookStdin(1500)
    } catch {}
    $ErrorActionPreference = "Stop"

    if ([string]::IsNullOrWhiteSpace($rawInput) -or ($rawInput -notmatch '(?s)\bgit(?:\.exe)?\b.*\b(commit|push)\b')) {
        Write-Output '{"decision":"allow"}'
        exit 0
    }

    $payload = $null
    try {
        $payload = $rawInput | ConvertFrom-Json
    } catch {
        $payload = $null
    }

    if ($null -eq $payload) {
        if ($rawInput -match '(?s)\bgit(?:\.exe)?\b.*\b(commit|push)\b') {
            $errObj = @{
                decision = "deny"
                reason   = "BRUTAL GATEKEEPER BLOCKED: Malformed or truncated hook JSON payload on git commit/push."
            } | ConvertTo-Json -Compress
            Write-Output $errObj
            exit 0
        }
        Write-Output '{"decision":"allow"}'
        exit 0
    }

    $toolName = if ($payload.toolCall) { [string]$payload.toolCall.name } else { "" }
    $cmdLine = if ($payload.toolCall -and $payload.toolCall.args) { [string]$payload.toolCall.args.CommandLine } else { "" }
    if ($toolName -eq "run_command" -and $cmdLine -match '\bgit(?:\.exe)?(?:\s+(?:(?:-[Cc]|--git-dir|--work-tree|--namespace|--super-prefix|--config-env)(?:\s+(?:"[^"]*"|''[^'']*''|[^\s"''])+|=(?:"[^"]*"|''[^'']*''|[^\s"''])+)|--(?!(?:git-dir|work-tree|namespace|super-prefix|config-env)(?:\s|=))(?:"[^"]*"|''[^'']*''|[^\s"''])+|-(?![Cc](?:\s|=)|-)(?:"[^"]*"|''[^'']*''|[^\s"''])+))*\s+(commit|push)\b') {
        try {
            $violations = Run-StaticGatekeeperChecks
            if ($violations.Count -gt 0) {
                $reasonStr = "BRUTAL GATEKEEPER BLOCKED COMMIT/PUSH: " + ($violations -join " | ")
                $outObj = @{
                    decision = "deny"
                    reason   = $reasonStr
                } | ConvertTo-Json -Compress
                Write-Output $outObj
                exit 0
            }
        } catch {
            $errObj = @{
                decision = "deny"
                reason   = "BRUTAL GATEKEEPER ERROR: $($_.Exception.Message)"
            } | ConvertTo-Json -Compress
            Write-Output $errObj
            exit 0
        }
    }

    Write-Output '{"decision":"allow"}'
    exit 0
}

# Negative-Injection Self-Test Mode (Item #5 CF ID leak + Item #6 1,009-theorem threshold)
if ($TestNegativeCloudflareInjection) {
    Write-Host "==========================================================================" -ForegroundColor Cyan
    Write-Host "   ACT-OMEGA GATEKEEPER: NEGATIVE-INJECTION VERIFICATION (ITEMS #5 & #6)  " -ForegroundColor Cyan
    Write-Host "==========================================================================" -ForegroundColor Cyan
    $negFailures = 0

    # Baseline clean CF scan must pass with 0 violations
    $cleanViolations = Test-CloudflareIdLeakScan -RootPath $RepoRoot
    if ($cleanViolations.Count -ne 0) {
        Write-Host "  [NEG-TEST BASELINE] [FAIL] Tracked repo already has CF violations: $($cleanViolations -join '; ')" -ForegroundColor Red
        exit 1
    }
    Write-Host "  [NEG-TEST 1/5 CLEAN]     [PASS] Repo-wide git ls-files CF scan = 0 leaks" -ForegroundColor Green

    $tmpNegDir = Join-Path ([System.IO.Path]::GetTempPath()) "act_omega_m3_neg_$([System.Diagnostics.Process]::GetCurrentProcess().Id)"
    New-Item -ItemType Directory -Force -Path $tmpNegDir | Out-Null
    try {
        $cfIdsFile = "C:\Users\Nbell\.act_omega_cloudflare_ids.json"
        $cfData = Get-Content -Raw $cfIdsFile | ConvertFrom-Json

        # Test 2: Inject active CF ID into temp fixture -> MUST FAIL
        $fActive = Join-Path $tmpNegDir "injected_active_cf.txt"
        [System.IO.File]::WriteAllText($fActive, "leaked_d1 = `"$($cfData.d1_database_id)`"`n")
        $vActive = Test-CloudflareIdLeakScan -RootPath $RepoRoot -ExtraFiles @($fActive)
        if ($vActive.Count -gt 0 -and ($vActive -join " ") -match "CF_ACTIVE_ID_LEAK") {
            Write-Host "  [NEG-TEST 2/5 ACTIVE CF] [PASS] Scanner caught injected active CF ID ($($vActive[0]))" -ForegroundColor Green
        } else {
            Write-Host "  [NEG-TEST 2/5 ACTIVE CF] [FAIL] Scanner missed injected active CF ID" -ForegroundColor Red
            $negFailures++
        }

        # Test 3: Inject literal hex ID into temp wrangler.toml fixture -> MUST FAIL
        $fWrangler = Join-Path $tmpNegDir "wrangler.toml"
        [System.IO.File]::WriteAllText($fWrangler, "account_id = `"0123456789abcdef0123456789abcdef`"`ndatabase_id = `"11111111-2222-3333-4444-555555555555`"`n")
        $vWrangler = Test-CloudflareIdLeakScan -RootPath $RepoRoot -ExtraFiles @($fWrangler)
        if ($vWrangler.Count -gt 0 -and ($vWrangler -join " ") -match "CF_WRANGLER_LITERAL_HEX_LEAK") {
            Write-Host "  [NEG-TEST 3/5 WRANGLER]  [PASS] Scanner caught literal hex assignment ($($vWrangler[0]))" -ForegroundColor Green
        } else {
            Write-Host "  [NEG-TEST 3/5 WRANGLER]  [FAIL] Scanner missed literal hex assignment" -ForegroundColor Red
            $negFailures++
        }

        # Test 4: Inject retired SHA-256 token (runtime-assembled synthetic UUID + its SHA-256 digest) -> MUST FAIL
        $synUuid = ("dead" + "beef-") + ("1234-" + "5678-") + ("9abc-" + "def012345678")
        $sha = [System.Security.Cryptography.SHA256]::Create()
        $synHash = ([System.BitConverter]::ToString($sha.ComputeHash([System.Text.UTF8Encoding]::new($false).GetBytes($synUuid))) -replace '-', '').ToLowerInvariant()
        $fRetired = Join-Path $tmpNegDir "injected_retired_cf.txt"
        [System.IO.File]::WriteAllText($fRetired, "retired_token = $synUuid`n")
        $vRetired = Test-CloudflareIdLeakScan -RootPath $RepoRoot -ExtraFiles @($fRetired) -AdditionalRetiredSha256 @($synHash)
        if ($vRetired.Count -gt 0 -and ($vRetired -join " ") -match "CF_RETIRED_ID_SHA256_LEAK") {
            Write-Host "  [NEG-TEST 4/5 RETIRED]   [PASS] Scanner caught retired SHA-256 token ($($vRetired[0]))" -ForegroundColor Green
        } else {
            Write-Host "  [NEG-TEST 4/5 RETIRED]   [FAIL] Scanner missed retired SHA-256 token" -ForegroundColor Red
            $negFailures++
        }

        # Test 5: (live - 1)-theorem Lean 4 negative fixture -> MUST FAIL, live (>= 1,027) -> MUST PASS
        $liveThmCntNeg = Get-LiveLean4TheoremCount -LeanPath "$RepoRoot\03_vault\lean4\SovereignManifoldTheorems.lean"
        $belowFloorCnt = [Math]::Max(1, $liveThmCntNeg - 1)
        $fLeanLow = Join-Path $tmpNegDir "SovereignManifoldTheorems_$belowFloorCnt.lean"
        $sb = New-Object System.Text.StringBuilder
        for ($i = 1; $i -le $belowFloorCnt; $i++) {
            [void]$sb.AppendLine("theorem neg_ps_fixture_$i : True := by trivial")
        }
        [System.IO.File]::WriteAllText($fLeanLow, $sb.ToString())
        $vLeanLow = Test-Lean4ThresholdCheck -LeanPath $fLeanLow
        $vLeanLive = Test-Lean4ThresholdCheck -LeanPath "$RepoRoot\03_vault\lean4\SovereignManifoldTheorems.lean" -ReportedCount $liveThmCntNeg
        $vLeanMismatch = Test-Lean4ThresholdCheck -LeanPath "$RepoRoot\03_vault\lean4\SovereignManifoldTheorems.lean" -ReportedCount $belowFloorCnt
        if ($liveThmCntNeg -ge 1027 -and $vLeanLow.Count -gt 0 -and $vLeanMismatch.Count -gt 0 -and $vLeanLive.Count -eq 0) {
            Write-Host "  [NEG-TEST 5/5 LEAN $belowFloorCnt] [PASS] $belowFloorCnt-theorem fixture rejected ($($vLeanLow[0])) | $belowFloorCnt-report rejected | $liveThmCntNeg live passed" -ForegroundColor Green
        } else {
            Write-Host "  [NEG-TEST 5/5 LEAN $belowFloorCnt] [FAIL] Lean threshold negative check failed (live=$liveThmCntNeg lowErrs=$($vLeanLow.Count) misErrs=$($vLeanMismatch.Count) liveErrs=$($vLeanLive.Count))" -ForegroundColor Red
            $negFailures++
        }
    } finally {
        Remove-Item $tmpNegDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    if ($negFailures -gt 0) {
        Write-Host "  [NEGATIVE-INJECTION SUITE: FAILED ($negFailures)]" -ForegroundColor Red
        exit 1
    }
    Write-Host "  [NEGATIVE-INJECTION SUITE: PASSED (5/5)]" -ForegroundColor Green
    exit 0
}

# Negative-Injection Self-Test Mode for Item #10c (Pixel ADB Serial Leak Scan)
if ($TestNegativePixelSerialInjection) {
    Write-Host "==========================================================================" -ForegroundColor Cyan
    Write-Host "   ACT-OMEGA GATEKEEPER: PIXEL SERIAL NEGATIVE-INJECTION VERIFY (ITEM #10)" -ForegroundColor Cyan
    Write-Host "==========================================================================" -ForegroundColor Cyan
    $pxNegFailures = 0

    $cleanPx = Test-PixelSerialLeakScan -RootPath $RepoRoot
    if ($cleanPx.Count -ne 0) {
        Write-Host "  [PX-NEG 1/4 CLEAN]       [FAIL] Tracked repo still has Pixel serial leaks: $($cleanPx -join '; ')" -ForegroundColor Red
        exit 1
    }
    Write-Host "  [PX-NEG 1/4 CLEAN]       [PASS] Repo-wide git ls-files Pixel serial scan = 0 leaks" -ForegroundColor Green

    $tmpPxDir = Join-Path ([System.IO.Path]::GetTempPath()) "act_omega_m4_pxneg_$([System.Diagnostics.Process]::GetCurrentProcess().Id)"
    New-Item -ItemType Directory -Force -Path $tmpPxDir | Out-Null
    try {
        $adbCfg = Get-Content -Raw "C:\Users\Nbell\.act_omega_adb_devices.json" | ConvertFrom-Json

        # Test 2: Inject active Pixel 10 serial into temp fixture -> MUST FAIL
        $fP10 = Join-Path $tmpPxDir "injected_p10.txt"
        [System.IO.File]::WriteAllText($fP10, "adb -s $($adbCfg.pixel10.serial) shell id`n")
        $vP10 = Test-PixelSerialLeakScan -RootPath $RepoRoot -ExtraFiles @($fP10)
        if ($vP10.Count -gt 0 -and ($vP10 -join " ") -match "PIXEL_ACTIVE_SERIAL_LEAK") {
            Write-Host "  [PX-NEG 2/4 ACTIVE P10]  [PASS] Scanner caught injected Pixel 10 serial ($($vP10[0]))" -ForegroundColor Green
        } else {
            Write-Host "  [PX-NEG 2/4 ACTIVE P10]  [FAIL] Scanner missed injected Pixel 10 serial" -ForegroundColor Red
            $pxNegFailures++
        }

        # Test 3: Inject active Pixel 8 serial into temp fixture -> MUST FAIL
        $fP8 = Join-Path $tmpPxDir "injected_p8.txt"
        [System.IO.File]::WriteAllText($fP8, "device_serial=$($adbCfg.pixel8.serial)`n")
        $vP8 = Test-PixelSerialLeakScan -RootPath $RepoRoot -ExtraFiles @($fP8)
        if ($vP8.Count -gt 0 -and ($vP8 -join " ") -match "PIXEL_ACTIVE_SERIAL_LEAK") {
            Write-Host "  [PX-NEG 3/4 ACTIVE P8]   [PASS] Scanner caught injected Pixel 8 serial ($($vP8[0]))" -ForegroundColor Green
        } else {
            Write-Host "  [PX-NEG 3/4 ACTIVE P8]   [FAIL] Scanner missed injected Pixel 8 serial" -ForegroundColor Red
            $pxNegFailures++
        }

        # Test 4: Inject synthetic retired serial + its SHA-256 -> MUST FAIL
        $synSer = ("99ZZ" + "0ABCD") + "12345"
        $sha = [System.Security.Cryptography.SHA256]::Create()
        $synHash = ([System.BitConverter]::ToString($sha.ComputeHash([System.Text.UTF8Encoding]::new($false).GetBytes($synSer))) -replace '-', '').ToLowerInvariant()
        $sha.Dispose()
        $fRet = Join-Path $tmpPxDir "injected_retired_px.txt"
        [System.IO.File]::WriteAllText($fRet, "old_serial = $synSer`n")
        $vRet = Test-PixelSerialLeakScan -RootPath $RepoRoot -ExtraFiles @($fRet) -AdditionalRetiredSha256 @($synHash)
        if ($vRet.Count -gt 0 -and ($vRet -join " ") -match "PIXEL_RETIRED_SERIAL_SHA256_LEAK") {
            Write-Host "  [PX-NEG 4/4 RETIRED]     [PASS] Scanner caught retired serial SHA-256 ($($vRet[0]))" -ForegroundColor Green
        } else {
            Write-Host "  [PX-NEG 4/4 RETIRED]     [FAIL] Scanner missed retired serial SHA-256" -ForegroundColor Red
            $pxNegFailures++
        }
    } finally {
        Remove-Item $tmpPxDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    if ($pxNegFailures -gt 0) {
        Write-Host "  [PIXEL SERIAL NEGATIVE-INJECTION SUITE: FAILED ($pxNegFailures)]" -ForegroundColor Red
        exit 1
    }
    Write-Host "  [PIXEL SERIAL NEGATIVE-INJECTION SUITE: PASSED (4/4)]" -ForegroundColor Green
    exit 0
}

# Negative-Injection Self-Test Mode for Telemetry & Operator Secret Keys (R3 / R7)
if ($TestNegativeTelemetryKeyInjection) {
    Write-Host "==========================================================================" -ForegroundColor Cyan
    Write-Host "   ACT-OMEGA GATEKEEPER: TELEMETRY/OPERATOR KEY NEGATIVE-INJECTION VERIFY " -ForegroundColor Cyan
    Write-Host "==========================================================================" -ForegroundColor Cyan
    $secNegFailures = 0

    $cleanSec = Test-SovereignKeyLeakScan -RootPath $RepoRoot
    if ($cleanSec.Count -ne 0) {
        Write-Host "  [KEY-NEG 1/5 CLEAN]      [FAIL] Repo already has key leak / missing key violation: $($cleanSec -join '; ')" -ForegroundColor Red
        exit 1
    }
    Write-Host "  [KEY-NEG 1/5 CLEAN]      [PASS] Repo-wide git ls-files -z + in-process stream scan = 0 leaks" -ForegroundColor Green

    $tmpKeyDir = Join-Path ([System.IO.Path]::GetTempPath()) "act_omega_m4_keyneg_$([System.Diagnostics.Process]::GetCurrentProcess().Id)"
    New-Item -ItemType Directory -Force -Path $tmpKeyDir | Out-Null
    $synTelKey = ""
    $synOpKey = ""
    $liveOpKey = ""
    $liveTelKey = ""
    $liveSlot2 = ""
    try {
        $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
        $randBytes1 = New-Object byte[] 16
        $randBytes2 = New-Object byte[] 16
        $rng.GetBytes($randBytes1)
        $rng.GetBytes($randBytes2)
        $rng.Dispose()
        $synTelKey = "SYNTH_TEL_DISPOSABLE_" + ([BitConverter]::ToString($randBytes1)).Replace("-", "")
        $synOpKey = "SYNTH_OP_DISPOSABLE_" + ([BitConverter]::ToString($randBytes2)).Replace("-", "")

        # Test 2: Inject disposable synthetic telemetry key into temp fixture -> MUST FAIL
        $fTel = Join-Path $tmpKeyDir "injected_telemetry_key.txt"
        [System.IO.File]::WriteAllText($fTel, "X-Sovereign-Telemetry-Key=$synTelKey`n")
        $vTel = Test-SovereignKeyLeakScan -RootPath $RepoRoot -ExtraFiles @($fTel) -SyntheticOperatorKeyForSelfTest $synOpKey -SyntheticTelemetryKeyForSelfTest $synTelKey
        if ($vTel.Count -gt 0 -and ($vTel -join " ") -match "SECRET_LEAK_TELEMETRY_KEY") {
            Write-Host "  [KEY-NEG 2/5 TELEMETRY]  [PASS] Scanner caught synthetic telemetry key ($($vTel[0]))" -ForegroundColor Green
        } else {
            Write-Host "  [KEY-NEG 2/5 TELEMETRY]  [FAIL] Scanner missed synthetic telemetry key" -ForegroundColor Red
            $secNegFailures++
        }

        # Test 3: Inject disposable synthetic operator key into temp fixture -> MUST FAIL
        $fOp = Join-Path $tmpKeyDir "injected_operator_key.txt"
        [System.IO.File]::WriteAllText($fOp, "X-Sovereign-Operator-Key=$synOpKey`n")
        $vOp = Test-SovereignKeyLeakScan -RootPath $RepoRoot -ExtraFiles @($fOp) -SyntheticOperatorKeyForSelfTest $synOpKey -SyntheticTelemetryKeyForSelfTest $synTelKey
        if ($vOp.Count -gt 0 -and ($vOp -join " ") -match "SECRET_LEAK_ACTIVE") {
            Write-Host "  [KEY-NEG 3/5 OPERATOR]   [PASS] Scanner caught synthetic operator key ($($vOp[0]))" -ForegroundColor Green
        } else {
            Write-Host "  [KEY-NEG 3/5 OPERATOR]   [FAIL] Scanner missed synthetic operator key" -ForegroundColor Red
            $secNegFailures++
        }

        # Test 4: Inject retired passkey literal into temp fixture -> MUST FAIL
        $fRet = Join-Path $tmpKeyDir "injected_retired_passkey.txt"
        [System.IO.File]::WriteAllText($fRet, "legacy=" + "SOVEREIGN" + "-LOQ15-4200`n")
        $vRet = Test-SovereignKeyLeakScan -RootPath $RepoRoot -ExtraFiles @($fRet) -SyntheticOperatorKeyForSelfTest $synOpKey -SyntheticTelemetryKeyForSelfTest $synTelKey
        if ($vRet.Count -gt 0 -and ($vRet -join " ") -match "SECRET_LEAK_RETIRED") {
            Write-Host "  [KEY-NEG 4/5 RETIRED]    [PASS] Scanner caught injected retired passkey ($($vRet[0]))" -ForegroundColor Green
        } else {
            Write-Host "  [KEY-NEG 4/5 RETIRED]    [FAIL] Scanner missed injected retired passkey" -ForegroundColor Red
            $secNegFailures++
        }

        # Test 5: Missing telemetry key path -> MUST FAIL CLOSED
        $vMiss = Test-SovereignKeyLeakScan -RootPath $RepoRoot -TelemetryKeyOverridePath (Join-Path $tmpKeyDir "nonexistent_telemetry_key") -SyntheticOperatorKeyForSelfTest $synOpKey
        if ($vMiss.Count -gt 0 -and ($vMiss -join " ") -match "TELEMETRY_KEY_MISSING") {
            Write-Host "  [KEY-NEG 5/5 FAIL-CLOSE] [PASS] Scanner failed closed when telemetry key file missing ($($vMiss[0]))" -ForegroundColor Green
        } else {
            Write-Host "  [KEY-NEG 5/5 FAIL-CLOSE] [FAIL] Scanner did not fail closed on missing telemetry key" -ForegroundColor Red
            $secNegFailures++
        }

        # Live Hygiene Assertion: Verify ZERO live key bytes in Win32_Process.CommandLine or %TEMP%
        if (Test-Path "C:\Users\Nbell\.act_omega_operator_vault_key") {
            $liveOpKey = ([System.IO.File]::ReadAllText("C:\Users\Nbell\.act_omega_operator_vault_key")).Trim()
        }
        if (Test-Path "C:\Users\Nbell\.act_omega_telemetry_ingest_key") {
            $liveTelKey = ([System.IO.File]::ReadAllText("C:\Users\Nbell\.act_omega_telemetry_ingest_key")).Trim()
        }
        $slot2Path = "F:\ACT_OMEGA_IMMUTABLE_EPOCH_ARCHIVES\YUBIKEY_ROOT_OF_TRUST_BACKUP\SLOT2_HMAC_SHARED_SECRET_FOR_KEY2_CLONING.txt"
        if (Test-Path $slot2Path) {
            $sm = [regex]::Match((Get-Content $slot2Path -Raw), '(?m)^[0-9a-fA-F]{40}\r?$')
            if ($sm.Success) { $liveSlot2 = $sm.Value.Trim() }
        }

        $procLeaks = 0
        $procs = Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Select-Object ProcessId, Name, CommandLine
        foreach ($pr in $procs) {
            $cmd = [string]$pr.CommandLine
            if ([string]::IsNullOrEmpty($cmd)) { continue }
            if (($liveOpKey.Length -ge 24 -and $cmd.IndexOf($liveOpKey, [System.StringComparison]::Ordinal) -ge 0) -or
                ($liveTelKey.Length -ge 24 -and $cmd.IndexOf($liveTelKey, [System.StringComparison]::Ordinal) -ge 0) -or
                ($liveSlot2.Length -eq 40 -and $cmd.IndexOf($liveSlot2, [System.StringComparison]::OrdinalIgnoreCase) -ge 0)) {
                $procLeaks++
            }
        }

        $tempLeaks = 0
        $tempRoot = [System.IO.Path]::GetTempPath()
        $tempCandidates = @()
        if (Test-Path $tmpKeyDir) {
            $tempCandidates += @(Get-ChildItem -Path $tmpKeyDir -Recurse -File -ErrorAction SilentlyContinue)
        }
        $tempCandidates += @(Get-ChildItem -Path $tempRoot -Filter "act_omega_*" -Recurse -File -ErrorAction SilentlyContinue)
        foreach ($tf in $tempCandidates) {
            try {
                $txt = [System.IO.File]::ReadAllText($tf.FullName)
                if (($liveOpKey.Length -ge 24 -and $txt.IndexOf($liveOpKey, [System.StringComparison]::Ordinal) -ge 0) -or
                    ($liveTelKey.Length -ge 24 -and $txt.IndexOf($liveTelKey, [System.StringComparison]::Ordinal) -ge 0) -or
                    ($liveSlot2.Length -eq 40 -and $txt.IndexOf($liveSlot2, [System.StringComparison]::OrdinalIgnoreCase) -ge 0)) {
                    $tempLeaks++
                }
            } catch {}
        }

        if ($procLeaks -eq 0 -and $tempLeaks -eq 0) {
            Write-Host "  [KEY-NEG HYGIENE]        [PASS] 0 live key bytes in Win32_Process.CommandLine and %TEMP%" -ForegroundColor Green
        } else {
            Write-Host "  [KEY-NEG HYGIENE]        [FAIL] procLeaks=$procLeaks tempLeaks=$tempLeaks" -ForegroundColor Red
            $secNegFailures++
        }
    } finally {
        $synTelKey = ""
        $synOpKey = ""
        $liveOpKey = ""
        $liveTelKey = ""
        $liveSlot2 = ""
        Remove-Item $tmpKeyDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    if ($secNegFailures -gt 0) {
        Write-Host "  [KEY NEGATIVE-INJECTION SUITE: FAILED ($secNegFailures)]" -ForegroundColor Red
        exit 1
    }
    Write-Host "  [KEY NEGATIVE-INJECTION SUITE: PASSED (5/5 + HYGIENE)]" -ForegroundColor Green
    exit 0
}

# Default to -StaticOnly when invoked without switches
if (-not $HookStdin -and -not $FullAudit -and -not $StaticOnly -and -not $TestNegativeCloudflareInjection -and -not $TestNegativePixelSerialInjection -and -not $TestNegativeTelemetryKeyInjection) {
    $StaticOnly = $true
}

if ($StaticOnly) {
    Write-Host "==========================================================================" -ForegroundColor Cyan
    Write-Host "   ACT-OMEGA BRUTAL AGENT GATEKEEPER: STATIC INVARIANTS AUDIT             " -ForegroundColor Cyan
    Write-Host "==========================================================================" -ForegroundColor Cyan

    $failures = Run-StaticGatekeeperChecks
    if ($failures.Count -eq 0) {
        Write-Host "  [STATIC INVARIANTS] [PASS] All 10 Static Invariants Verified (Zero-Bracket, Lean4+HMAC, Mirrors+Stamps, Secrets+CF+PixelSerials=0, Agents/Rules, SSR & Bundles, GSC Lock)" -ForegroundColor Green
        Write-Host "==========================================================================" -ForegroundColor Cyan
        Write-Host "  [BRUTAL GATEKEEPER RESULT: PASSED (All 10 Static Invariants Verified)]" -ForegroundColor Green
        exit 0
    } else {
        foreach ($f in $failures) {
            Write-Host "  [STATIC FAIL] $f" -ForegroundColor Red
        }
        Write-Host "==========================================================================" -ForegroundColor Cyan
        Write-Host "  [BRUTAL GATEKEEPER RESULT: FAILED ($($failures.Count) VIOLATIONS)]" -ForegroundColor Red
        exit 1
    }
}

if ($FullAudit) {
    Write-Host "==========================================================================" -ForegroundColor Cyan
    Write-Host "   ACT-OMEGA BRUTAL AGENT GATEKEEPER: 13-POINT ARCHITECTURAL AUDIT        " -ForegroundColor Cyan
    Write-Host "==========================================================================" -ForegroundColor Cyan

    $liveLeanCount = Get-LiveLean4TheoremCount -LeanPath "$RepoRoot\03_vault\lean4\SovereignManifoldTheorems.lean"
    $failures = Run-StaticGatekeeperChecks
    if ($failures.Count -eq 0) {
        Write-Host "  [1-10 STATIC INVARIANTS][PASS] Zero-Bracket(v33..v74+)=0 | Lean4=$liveLeanCount(>=1027, HMAC=OK) | HUD/Mobile/Agent Mirrors=LOCKED | Secrets/CF/PixelSerials=0 | SSR & Bundles=VERIFIED | GSC 7-Mirror=LOCKED" -ForegroundColor Green
    } else {
        foreach ($f in $failures) {
            Write-Host "  [STATIC FAIL] $f" -ForegroundColor Red
        }
    }

    # 6. Live Lean 4 Compiler Verification
    $leanExe = if (Test-Path "C:\Users\Nbell\.elan\bin\lean.exe") { "C:\Users\Nbell\.elan\bin\lean.exe" } elseif (Get-Command lean -ErrorAction SilentlyContinue) { (Get-Command lean).Source } else { $null }
    if ($leanExe) {
        & $leanExe "$RepoRoot\03_vault\lean4\SovereignManifoldTheorems.lean" 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  [6 LEAN 4 COMPILER]     [PASS] lean.exe verified 03_vault/lean4/SovereignManifoldTheorems.lean (EXIT:0)" -ForegroundColor Green
        } else {
            $failures.Add("LEAN4_COMPILER_FAIL: lean.exe exited with $LASTEXITCODE")
            Write-Host "  [6 LEAN 4 COMPILER]     [FAIL] lean.exe exited with $LASTEXITCODE" -ForegroundColor Red
        }
    } else {
        $failures.Add("LEAN4_COMPILER_MISSING: lean.exe not found")
        Write-Host "  [6 LEAN 4 COMPILER]     [FAIL] lean.exe not found" -ForegroundColor Red
    }

    # 7. Live Plucker 12/12 .e8z Measurement Probe
    try {
        $t92 = Invoke-RestMethod -Uri "http://127.0.0.1:8097/api/v1/v49/tool_92_amplituhedron_9loop_hexagon_plucker" -TimeoutSec 15
        if ($t92.plucker_inner_product_p_ab -ne 0 -and $t92.proof_attestation -match "MEASURED") {
            Write-Host "  [7 PLUCKER 12/12 .E8Z]  [PASS] Pab=$($t92.plucker_inner_product_p_ab) | Attestation=$($t92.proof_attestation)" -ForegroundColor Green
        } else {
            $failures.Add("PLUCKER_AUDIT_FAIL: Unexpected Tool 92 response")
            Write-Host "  [7 PLUCKER 12/12 .E8Z]  [FAIL] Unexpected Tool 92 response" -ForegroundColor Red
        }
    } catch {
        $failures.Add("PLUCKER_PROBE_ERR: $_")
        Write-Host "  [7 PLUCKER 12/12 .E8Z]  [FAIL] $_" -ForegroundColor Red
    }

    # Load external operator key once for authenticated -FullAudit probes
    $auditOpKey = if ($env:ACT_OMEGA_OPERATOR_KEY) {
        $env:ACT_OMEGA_OPERATOR_KEY.Trim()
    } elseif (Test-Path "C:\Users\Nbell\.act_omega_operator_vault_key") {
        ([System.IO.File]::ReadAllText("C:\Users\Nbell\.act_omega_operator_vault_key")).Trim()
    } else {
        ""
    }
    $auditOpHdrs = @{}
    if ($auditOpKey.Length -ge 24) {
        $auditOpHdrs["X-Sovereign-Operator-Key"] = $auditOpKey
    }

    # 8. Live v44 Lease Release Jitter & .e8z PoC Probe
    try {
        $e8zPath = "$RepoRoot\00_control\weights\sovereign_harmonic_iv_v5000.e8z"
        $pocHash = Get-E8zPluckerPocHash -E8zPath $e8zPath
        if ([string]::IsNullOrWhiteSpace($pocHash)) {
            throw "UNMEASURED/OFFLINE: Failed to compute 2,080-CL .e8z poc_hash from $e8zPath"
        }
        $v44 = Invoke-RestMethod -Uri "http://127.0.0.1:8097/api/v1/worksteal/webgpu_lease?action=release&worker_id=gatekeeper_audit&poc_hash=$pocHash" -Headers $auditOpHdrs -TimeoutSec 15
        if (([double]$v44.cadence_jitter_us -gt 0.0) -and ($v44.poc_verified -eq $true)) {
            Write-Host "  [8 V44 RELEASE JITTER]  [PASS] Measured Release Jitter=$($v44.cadence_jitter_us) us (> 0.0) | poc_verified=True" -ForegroundColor Green
        } else {
            $failures.Add("V44_RELEASE_JITTER_OR_POC_FAIL: jitter=$($v44.cadence_jitter_us) poc_verified=$($v44.poc_verified)")
            Write-Host "  [8 V44 RELEASE JITTER]  [FAIL] jitter=$($v44.cadence_jitter_us) poc_verified=$($v44.poc_verified)" -ForegroundColor Red
        }
    } catch {
        $failures.Add("V44_PROBE_ERR: $_")
        Write-Host "  [8 V44 RELEASE JITTER]  [FAIL] $_" -ForegroundColor Red
    }

    # 9. Live Operator Header Gate & ?key= Rejection Probe (HTTP 403 on ?key= / ?%6bey=)
    try {
        if ($auditOpKey.Length -lt 24) {
            throw "Operator key missing (< 24 chars)"
        }
        $qStatus = 0
        try {
            $qWeb = Invoke-WebRequest -Uri "http://127.0.0.1:8097/api/v1/auth/operator_vault_gate?key=$auditOpKey" -UseBasicParsing -TimeoutSec 15
            $qStatus = [int]$qWeb.StatusCode
        } catch [System.Net.WebException] {
            if ($_.Exception.Response) { $qStatus = [int]$_.Exception.Response.StatusCode }
        }
        $qEncStatus = 0
        try {
            $qEncWeb = Invoke-WebRequest -Uri "http://127.0.0.1:8097/api/v1/auth/operator_vault_gate?%6bey=test" -Headers $auditOpHdrs -UseBasicParsing -TimeoutSec 15
            $qEncStatus = [int]$qEncWeb.StatusCode
        } catch [System.Net.WebException] {
            if ($_.Exception.Response) { $qEncStatus = [int]$_.Exception.Response.StatusCode }
        }
        $hResp = Invoke-RestMethod -Uri "http://127.0.0.1:8097/api/v1/auth/operator_vault_gate" -Headers $auditOpHdrs -TimeoutSec 15
        if ($qStatus -eq 403 -and $qEncStatus -eq 403 -and $hResp.authorized -eq $true) {
            Write-Host "  [9 OPERATOR AUTH GATE]  [PASS] QueryParam(?key= & ?%6bey=)=403 | Header(X-Sovereign-Operator-Key)=AUTHORIZED" -ForegroundColor Green
        } else {
            $failures.Add("AUTH_GATE_FAIL: QueryStatus=$qStatus EncQueryStatus=$qEncStatus HeaderAuthorized=$($hResp.authorized)")
            Write-Host "  [9 OPERATOR AUTH GATE]  [FAIL] QueryStatus=$qStatus EncQueryStatus=$qEncStatus HeaderAuthorized=$($hResp.authorized)" -ForegroundColor Red
        }
    } catch {
        $failures.Add("AUTH_PROBE_ERR: $_")
        Write-Host "  [9 OPERATOR AUTH GATE]  [FAIL] $_" -ForegroundColor Red
    }

    # 10. Live Coordinator Bus & E:\ Write-Back Probe
    try {
        $bus = Invoke-RestMethod -Uri "http://127.0.0.1:8097/api/v1/coordinator/message_bus?source_module=BrutalGatekeeper&topic=GATEKEEPER_AUDIT&payload_summary=Verify_Bus_And_E_Vault" -TimeoutSec 15
        if ($bus.e_drive_mounted -eq $true -and $bus.ledger_measured_bytes -gt 0) {
            Write-Host "  [10 COORDINATOR & E:\]  [PASS] E_Mounted=True | LedgerBytes=$($bus.ledger_measured_bytes) | Envelopes=$($bus.total_envelopes_logged)" -ForegroundColor Green
        } else {
            $failures.Add("COORDINATOR_BUS_FAIL: E_Mounted=$($bus.e_drive_mounted)")
            Write-Host "  [10 COORDINATOR & E:\]  [FAIL] Coordinator Bus check failed" -ForegroundColor Red
        }
    } catch {
        $failures.Add("COORDINATOR_PROBE_ERR: $_")
        Write-Host "  [10 COORDINATOR & E:\]  [FAIL] $_" -ForegroundColor Red
    }

    # 11. Live Google Search Console Certificate HTTP Endpoints Probe (:8097 & :5173)
    try {
        $r8097 = (Invoke-WebRequest -Uri "http://127.0.0.1:8097/google6edc0affb12d0455.html" -UseBasicParsing -TimeoutSec 15).Content
        $r5173 = (Invoke-WebRequest -Uri "http://127.0.0.1:5173/google6edc0affb12d0455.html" -UseBasicParsing -TimeoutSec 15).Content
        $expectedBody = "google-site-verification: google6edc0affb12d0455.html"
        if ($r8097.Trim() -eq $expectedBody -and $r5173.Trim() -eq $expectedBody) {
            Write-Host "  [11 GSC HTTP ENDPOINTS] [PASS] :8097 & :5173 returned exact 53-byte GSC token" -ForegroundColor Green
        } else {
            $failures.Add("GSC_HTTP_BODY_MISMATCH: 8097_len=$($r8097.Length) 5173_len=$($r5173.Length)")
            Write-Host "  [11 GSC HTTP ENDPOINTS] [FAIL] Body mismatch on :8097 or :5173" -ForegroundColor Red
        }
    } catch {
        $failures.Add("GSC_HTTP_PROBE_ERR: $_")
        Write-Host "  [11 GSC HTTP ENDPOINTS] [FAIL] $_" -ForegroundColor Red
    }

    # 12. Live YubiKey Point-of-Origin Hardware Attestation Probe (F1: Dynamic allowed_signers FIDO2 Fingerprint)
    try {
        $yk = Invoke-RestMethod -Uri "http://127.0.0.1:8097/api/v1/auth/yubikey_point_of_origin" -TimeoutSec 15
        $expectedFp = $null
        $allowedSignersPath = "C:\Users\Nbell\.ssh\allowed_signers"
        $fallbackPubPath = "C:\Users\Nbell\.ssh\id_ed25519_sk_act_omega.pub"
        $sshKeygenExe = (Get-Command ssh-keygen.exe -ErrorAction SilentlyContinue).Source
        if (-not $sshKeygenExe -and (Test-Path "C:\Windows\System32\OpenSSH\ssh-keygen.exe")) {
            $sshKeygenExe = "C:\Windows\System32\OpenSSH\ssh-keygen.exe"
        }
        if ($sshKeygenExe -and (Test-Path $allowedSignersPath)) {
            $firstLine = (Get-Content $allowedSignersPath | Where-Object { $_.Trim() -and -not $_.Trim().StartsWith("#") } | Select-Object -First 1)
            if ($firstLine -match '(sk-ssh-\S+|ssh-\S+)\s+([A-Za-z0-9+/=]+)') {
                $tmpPub = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "act_omega_fido2_check_$([System.Diagnostics.Process]::GetCurrentProcess().Id).pub")
                [System.IO.File]::WriteAllText($tmpPub, "$($Matches[1]) $($Matches[2])`n")
                try {
                    $kgOut = (& $sshKeygenExe -lf $tmpPub 2>&1) -join " "
                    if ($kgOut -match '(SHA256:[A-Za-z0-9+/=]+)') { $expectedFp = $Matches[1] }
                } finally {
                    Remove-Item $tmpPub -Force -ErrorAction SilentlyContinue
                }
            }
        }
        if (-not $expectedFp -and $sshKeygenExe -and (Test-Path $fallbackPubPath)) {
            $kgOut2 = (& $sshKeygenExe -lf $fallbackPubPath 2>&1) -join " "
            if ($kgOut2 -match '(SHA256:[A-Za-z0-9+/=]+)') { $expectedFp = $Matches[1] }
        }

        $fpMatch = ($expectedFp -and ($expectedFp -match '^SHA256:') -and ($yk.fido2_fingerprint -eq $expectedFp))
        if ($fpMatch -and $yk.yubikey_present -eq $true -and $yk.yubikey_serial -gt 0 -and $yk.canonical_seed_verified -eq $true) {
            Write-Host "  [12 YUBIKEY 5C NFC HROT][PASS] Serial=$($yk.yubikey_serial) (FW $($yk.firmware_version)) | Slot2_HMAC=$($yk.slot2_hmac_sha1_response.Substring(0,12))... | Dynamic FIDO2=$($yk.fido2_fingerprint)" -ForegroundColor Green
        } elseif ($fpMatch -and $yk.allowed_signers_bytes -gt 0) {
            Write-Host "  [12 YUBIKEY 5C NFC HROT][PASS] Dynamic FIDO2 Configured ($($yk.fido2_fingerprint)) | Status=$($yk.status)" -ForegroundColor Green
        } else {
            $failures.Add("YUBIKEY_HROT_FAIL: Status=$($yk.status) Serial=$($yk.yubikey_serial) FP=$($yk.fido2_fingerprint) ExpectedFP=$expectedFp")
            Write-Host "  [12 YUBIKEY 5C NFC HROT][FAIL] Status=$($yk.status) ExpectedFP=$expectedFp" -ForegroundColor Red
        }
    } catch {
        $failures.Add("YUBIKEY_PROBE_ERR: $_")
        Write-Host "  [12 YUBIKEY 5C NFC HROT][FAIL] $_" -ForegroundColor Red
    }

    # 13. Live CHAIN 292 / 300 / 308 / 312 / 316 / 350 / 362 / 368 Master Certification & Honest Gates Probe
    try {
        $opHdrs = @{}
        if (Test-Path "C:\Users\Nbell\.act_omega_operator_vault_key") {
            $okVal = (Get-Content "C:\Users\Nbell\.act_omega_operator_vault_key" -Raw).Trim()
            if ($okVal.Length -ge 24) { $opHdrs["X-Sovereign-Operator-Key"] = $okVal }
        }
        $c292 = Invoke-RestMethod -Uri "http://127.0.0.1:8097/api/v1/chain292/master_certification" -Headers $opHdrs -TimeoutSec 20
        $c300 = Invoke-RestMethod -Uri "http://127.0.0.1:8097/api/v1/chain300/master_certification" -Headers $opHdrs -TimeoutSec 20
        $c308 = Invoke-RestMethod -Uri "http://127.0.0.1:8097/api/v1/chain308/master_certification" -Headers $opHdrs -TimeoutSec 20
        $c312 = Invoke-RestMethod -Uri "http://127.0.0.1:8097/api/v1/chain312/master_certification" -Headers $opHdrs -TimeoutSec 20
        $c316 = Invoke-RestMethod -Uri "http://127.0.0.1:8097/api/v1/chain316/master_certification" -Headers $opHdrs -TimeoutSec 20
        $c350 = Invoke-RestMethod -Uri "http://127.0.0.1:8097/api/v1/chain350/master_certification" -Headers $opHdrs -TimeoutSec 120
        $c362 = Invoke-RestMethod -Uri "http://127.0.0.1:8097/api/v1/chain362/master_certification" -Method Post -Body '{}' -ContentType 'application/json' -Headers $opHdrs -TimeoutSec 180
        $c368 = Invoke-RestMethod -Uri "http://127.0.0.1:8097/api/v1/chain368/master_certification" -Method Post -Body '{}' -ContentType 'application/json' -Headers $opHdrs -TimeoutSec 240
        $c418 = Invoke-RestMethod -Uri "http://127.0.0.1:8097/api/v1/chain418/master_certification" -Headers $opHdrs -TimeoutSec 60
        $toolsCount = if ($c300.tools_verified) { $c300.tools_verified } else { $c300.total_chain_tools }
        $thmCount = if ($c300.lean4_theorems_qed) { $c300.lean4_theorems_qed } else { $c300.lean4_qed_theorems }
        $c308Tools = if ($c308.tools_verified) { $c308.tools_verified } else { $c308.total_tools }
        $c312Tools = if ($c312.tools_verified) { $c312.tools_verified } else { $c312.total_tools }
        $c316Tools = if ($c316.tools_verified) { $c316.tools_verified } else { $c316.total_tools }
        $c350HonestOk = ($c350.status -in @("MEASURED", "UNMEASURED/OFFLINE")) -and ($c350.total_tools -eq 350) -and ($liveLeanCount -ge 1027) -and ($c350.lean4_theorems_qed -ge 1027) -and ($c350.lean4_theorems_qed -eq $liveLeanCount)
        $c362HonestOk = (
            ($c362.status -in @("MEASURED", "UNMEASURED/OFFLINE")) -and
            ($c362.gate_1_corpus_and_minhash.surviving_eval500_overlaps -eq 0) -and
            ($c362.gate_1_corpus_and_minhash.duckdb_materialized -eq $true) -and
            ($c362.gate_2_bpe16k_tokenizer.vocab_size -eq 16384) -and
            ($c362.gate_3_matryoshka_and_gradcheck.net2wider_and_gradcheck_passed -eq $true) -and
            ($c362.gate_4_rtx3050_cuda_pretrain.ptx_loaded -eq $true) -and
            ([double]$c362.gate_4_rtx3050_cuda_pretrain.val_bpb_768d -lt [double]$c362.gate_4_rtx3050_cuda_pretrain.val_bpb_384d) -and
            ($c362.gate_6_lean4_formal_proofs.vault_l0_sha256_synced -eq $true) -and
            ($c362.gate_6_lean4_formal_proofs.theorem_count -ge 1027) -and
            ($c362.gate_6_lean4_formal_proofs.theorem_count -eq $liveLeanCount)
        )
        $c368HonestOk = (
            ($c368.status -in @("MEASURED", "UNMEASURED/OFFLINE")) -and
            ($c368.gate_1_shell2_sparse_moe.passed -eq $true) -and
            ([double]$c368.gate_1_shell2_sparse_moe.step0_max_abs_diff -eq 0.0) -and
            ([double]$c368.gate_1_shell2_sparse_moe.val_bpb_3shell_moe -lt [double]$c368.gate_1_shell2_sparse_moe.val_bpb_768d) -and
            ($c368.gate_2_masked_chatml_sft.passed -eq $true) -and
            ([double]$c368.gate_2_masked_chatml_sft.prompt_grad_norm -eq 0.0) -and
            ($c368.gate_2_masked_chatml_sft.rweval500_overlap -eq 0) -and
            ($c368.gate_3_wgsl_rag_and_trisilicon.passed -eq $true) -and
            ($c368.gate_6_lean4_formal_proofs.passed -eq $true) -and
            ($c368.gate_6_lean4_formal_proofs.theorem_count -ge 1027) -and
            ($c368.gate_6_lean4_formal_proofs.theorem_count -eq $liveLeanCount)
        )
        $c418Ok = (
            ($c418.core_and_formal_ok -eq $true) -and
            ($c418.tools_total -eq 418) -and
            ($c418.mcp_tools_total -eq 70) -and
            ($c418.lean_sorry_count -eq 0) -and
            ($c418.lean4_theorems_qed -ge 1027) -and
            ($c418.lean4_theorems_qed -eq $liveLeanCount)
        )
        if ($c292.status -eq "CHAIN_292_MASTER_CERTIFIED_OK" -and $c292.all_gates_passed -eq $true -and $c292.gates_passed -eq 12 -and $c300.status -match "CHAIN_300" -and $toolsCount -eq 300 -and $thmCount -ge 1027 -and $thmCount -eq $liveLeanCount -and $c308.status -eq "MEASURED" -and $c308Tools -eq 308 -and $c312.status -eq "MEASURED" -and $c312Tools -eq 312 -and $c316.status -eq "MEASURED" -and $c316Tools -eq 316 -and $c350HonestOk -and $c362HonestOk -and $c368HonestOk -and $c418Ok) {
            Write-Host "  [13 CHAIN 292..418]     [PASS] CHAIN292=$($c292.status) (12/12) | C350=$($c350.status) | C362=$($c362.status)(QED=$($c362.gate_6_lean4_formal_proofs.theorem_count)) | C368=$($c368.status)(QED=$($c368.gate_6_lean4_formal_proofs.theorem_count)) | C418=$($c418.status)(Tools=$($c418.tools_total),MCP=$($c418.mcp_tools_total))" -ForegroundColor Green
        } else {
            $failures.Add("CHAIN_CERT_AUDIT_FAIL: C292=$($c292.status) C300=$($c300.status) C308=$($c308.status) C312=$($c312.status) C316=$($c316.status) C350=$($c350.status) C362=$($c362.status) C368=$($c368.status) C418=$($c418.status)")
            Write-Host "  [13 CHAIN 292..418]     [FAIL] C292=$($c292.status) C350=$($c350.status) C362=$($c362.status) C368=$($c368.status) C418=$($c418.status)" -ForegroundColor Red
        }
    } catch {
        $failures.Add("CHAIN_CERT_PROBE_ERR: $_")
        Write-Host "  [13 CHAIN 292..368]     [FAIL] $_" -ForegroundColor Red
    }

    Write-Host "==========================================================================" -ForegroundColor Cyan
    if ($failures.Count -gt 0) {
        Write-Host "  [BRUTAL GATEKEEPER RESULT: FAILED ($($failures.Count) VIOLATIONS)]" -ForegroundColor Red
        exit 1
    } else {
        Write-Host "  [BRUTAL GATEKEEPER RESULT: PASSED (13/13 INVARIANTS VERIFIED)]" -ForegroundColor Green
        exit 0
    }
}
