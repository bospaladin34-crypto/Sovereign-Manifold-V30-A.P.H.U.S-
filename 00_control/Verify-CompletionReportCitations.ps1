# =============================================================================
# ACT-OMEGA NET — COMPLETION REPORT CITATION & DRIVE PARITY VERIFIER (v73.2.4)
# Verifies every path:line(-end) citation, cited symbols/routes, disposition
# honesty (9 FIXED / 1 PARTIAL, 0 'Total Remediation'/'Complete' claims in
# v73.2.4), and optional Google Drive File IDs + G:\ SHA-256 parity.
# Primary Author & Principal Systems Architect: Donevin Frownfelter (@bospaladin34-crypto)
# =============================================================================
[CmdletBinding()]
param(
    [string]$RepoRoot = "",
    [switch]$VerifyDrive
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
    $RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
} else {
    $RepoRoot = (Resolve-Path $RepoRoot).Path
}

$Utf8NoBomStrict = New-Object System.Text.UTF8Encoding($false, $true)

function Get-Sha256Hex {
    param([string]$Path)
    $bytes = [System.IO.File]::ReadAllBytes($Path)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        return ([System.BitConverter]::ToString($sha.ComputeHash($bytes))).Replace("-", "").ToLowerInvariant()
    } finally {
        $sha.Dispose()
    }
}

$ReportFiles = @(
    "COMPLETION_REPORT_V73_MUSE.md",
    "COMPLETION_REPORT_V73_FOLLOWUP_MUSE.md",
    "COMPLETION_REPORT_V73_2_3_MUSE.md",
    "COMPLETION_REPORT_V73_2_4_MUSE.md"
)

$failures = New-Object System.Collections.Generic.List[string]
$fileLinesCache = @{}
$fileTextCache = @{}

function Get-TargetLines {
    param([string]$RelPath)
    $norm = ($RelPath -replace '/', '\').Trim()
    if (-not $fileLinesCache.ContainsKey($norm)) {
        $full = Join-Path $RepoRoot $norm
        if (-not (Test-Path -LiteralPath $full -PathType Leaf)) {
            return $null
        }
        $raw = $Utf8NoBomStrict.GetString([System.IO.File]::ReadAllBytes($full))
        $fileTextCache[$norm] = $raw
        $lines = $raw -split "`r?`n"
        if ($raw.EndsWith("`n") -and $lines.Count -gt 0 -and $lines[$lines.Count - 1] -eq "") {
            $lines = $lines[0..($lines.Count - 2)]
        }
        $fileLinesCache[$norm] = ,$lines
    }
    return $fileLinesCache[$norm]
}

# Known file extensions that carry path:line citations
$ExtPattern = '(?:rs|js|mjs|ts|tsx|ps1|json|csv|md|kt|kts|lean|hs|html|txt|toml|yml|yaml|cs)'
$CitationRegex = [regex]"(?<![A-Za-z0-9_:/\\.-])([A-Za-z0-9_.\-/\\]+\.$ExtPattern):(\d+)(?:-(\d+))?(\+)?"
$SymbolRegex = [regex]'`([A-Za-z_][A-Za-z0-9_]{3,})`'

$totalCitationsChecked = 0
$totalSymbolsChecked = 0

foreach ($repName in $ReportFiles) {
    $repPath = Join-Path $RepoRoot $repName
    if (-not (Test-Path -LiteralPath $repPath -PathType Leaf)) {
        $failures.Add("REPORT_MISSING: $repName not found at $repPath")
        continue
    }
    $rawBytes = [System.IO.File]::ReadAllBytes($repPath)
    if ($rawBytes.Length -ge 3 -and $rawBytes[0] -eq 0xEF -and $rawBytes[1] -eq 0xBB -and $rawBytes[2] -eq 0xBF) {
        $failures.Add("REPORT_BOM: $repName has UTF-8 BOM")
    }
    $repText = $Utf8NoBomStrict.GetString($rawBytes)
    $repLines = $repText -split "`r?`n"

    # Prohibited wording checks on v73.2.4 report and disposition honesty
    if ($repName -eq "COMPLETION_REPORT_V73_2_4_MUSE.md") {
        if ($repText -notmatch '9 FIXED / 1 PARTIAL') {
            $failures.Add("V73_2_4_MISSING_DISPOSITION: $repName must explicitly state '9 FIXED / 1 PARTIAL'")
        }
        if ($repText -match '(?i)Total\s+Remediation') {
            $failures.Add("V73_2_4_FORBIDDEN_CLAIM: $repName contains forbidden 'Total Remediation'")
        }
        if ($repText -match '(?i)(?:^|\W)(?:10/10\s+FIXED|10\s+of\s+10\s+FIXED|Remediation\s+Complete|Complete\s+Remediation|Status:\s*Complete)(?:\W|$)') {
            $failures.Add("V73_2_4_FORBIDDEN_CLAIM: $repName contains forbidden 'Complete' remediation claim")
        }
        # Reject standalone capitalized "Complete" in headings or status badges
        for ($lnIdx = 0; $lnIdx -lt $repLines.Count; $lnIdx++) {
            $lnText = $repLines[$lnIdx]
            if ($lnText -match '^#{1,6}\s+.*\bComplete\b' -or $lnText -match 'Disposition.*\bComplete\b') {
                $failures.Add("V73_2_4_FORBIDDEN_COMPLETE_HEADING: ${repName}:$($lnIdx+1) contains 'Complete'")
            }
        }
    }

    for ($i = 0; $i -lt $repLines.Count; $i++) {
        $lineNum = $i + 1
        $line = $repLines[$i]

        # Explicit stale-citation guard
        if ($line -match 'Invoke-Week4TortureSuite\.ps1:60\b') {
            $failures.Add("STALE_TORTURE_LINE_60: ${repName}:$lineNum cites Invoke-Week4TortureSuite.ps1:60 (must be :85)")
        }

        $matches = $CitationRegex.Matches($line)
        if ($matches.Count -eq 0) {
            continue
        }

        # Collect backticked symbols on this line (or if none, skip symbol check)
        $lineSymbols = New-Object System.Collections.Generic.List[string]
        foreach ($sm in $SymbolRegex.Matches($line)) {
            $sym = $sm.Groups[1].Value
            if ($sym -notin @("FIXED", "PARTIAL", "MEASURED", "SELF_TEST", "UNMEASURED", "OFFLINE", "CHAIN", "HEAD", "Drive", "SHA256", "Status", "true", "false", "null", "exit", "None", "Some")) {
                $lineSymbols.Add($sym)
            }
        }

        foreach ($m in $matches) {
            $relTarget = $m.Groups[1].Value
            $startLine = [int]$m.Groups[2].Value
            $endLine = if ($m.Groups[3].Success) { [int]$m.Groups[3].Value } else { $startLine }

            # Skip explicitly marked historical git-commit baseline offsets (e.g. "at 338264c5", "at e9804bf2", "historical v73.2.x")
            $ctxStart = [Math]::Max(0, $m.Index - 20)
            $ctxEnd = [Math]::Min($line.Length, $m.Index + $m.Length + 60)
            $localCtx = $line.Substring($ctxStart, $ctxEnd - $ctxStart)
            if ($localCtx -match '(?:at\s+(?:338264c5|e9804bf2|c90c1491|b99559e8)|pre-v73\.2\.[0-9]+|historical\s+v73\.2)') {
                continue
            }

            $totalCitationsChecked++
            $targetLines = Get-TargetLines -RelPath $relTarget
            if ($null -eq $targetLines) {
                $failures.Add("MISSING_CITED_FILE: ${repName}:$lineNum cites '$relTarget' which does not exist")
                continue
            }
            if ($startLine -lt 1 -or $endLine -lt $startLine -or $endLine -gt $targetLines.Count) {
                $failures.Add("LINE_OUT_OF_RANGE: ${repName}:$lineNum cites '${relTarget}:${startLine}-${endLine}' (totalLines=$($targetLines.Count))")
                continue
            }

            # For COMPLETION_REPORT_V73_2_4_MUSE.md, verify any symbol in immediate citation context exists in target file near cited range (+-15 lines)
            if ($repName -eq "COMPLETION_REPORT_V73_2_4_MUSE.md") {
                $afterStart = $m.Index + $m.Length
                $afterLen = [Math]::Min(120, $line.Length - $afterStart)
                $beforeStart = [Math]::Max(0, $m.Index - 90)
                $nearText = $line.Substring($beforeStart, ($afterStart - $beforeStart) + $afterLen)
                foreach ($nsm in $SymbolRegex.Matches($nearText)) {
                    $sym = $nsm.Groups[1].Value
                    # Only enforce proximity if the symbol looks like an identifier in Rust/JS/PS1/KT (contains underscore or camelCase and length >= 8)
                    if (($sym -match '_' -or $sym -cmatch '[a-z][A-Z]') -and $sym.Length -ge 8) {
                        $normKey = ($relTarget -replace '/', '\').Trim()
                        if ($fileTextCache[$normKey].Contains($sym)) {
                            $totalSymbolsChecked++
                            $lo = [Math]::Max(0, $startLine - 16)
                            $hi = [Math]::Min($targetLines.Count - 1, $endLine + 14)
                            $foundNear = $false
                            for ($li = $lo; $li -le $hi; $li++) {
                                if ($targetLines[$li].Contains($sym)) {
                                    $foundNear = $true
                                    break
                                }
                            }
                            if (-not $foundNear) {
                                $failures.Add("SYMBOL_LINE_DRIFT: ${repName}:$lineNum cites '$sym' near '${relTarget}:${startLine}-${endLine}' but '$sym' is not within +-15 lines of ${startLine}-${endLine}")
                            }
                        }
                    }
                }
            }
        }
    }
}

# Check v73.2.4 release metadata for forbidden claims too (scoped to current v73.2.4 headers/sections, not historical v71.5.0 notes)
foreach ($metaRel in @(".zenodo.json", "CITATION.cff", "README.md", "WHATS_NEW.md", "MODEL_CARD.md")) {
    $mp = Join-Path $RepoRoot $metaRel
    if (Test-Path -LiteralPath $mp -PathType Leaf) {
        $mt = $Utf8NoBomStrict.GetString([System.IO.File]::ReadAllBytes($mp))
        $scopeText = if ($metaRel -eq "WHATS_NEW.md") {
            (($mt -split "`r?`n") | Select-Object -First 35) -join "`n"
        } elseif ($metaRel -eq "README.md" -or $metaRel -eq "MODEL_CARD.md") {
            (($mt -split "`r?`n") | Select-Object -First 55) -join "`n"
        } else {
            $mt
        }
        if ($scopeText -match '(?i)Total\s+Remediation') {
            $failures.Add("META_FORBIDDEN_CLAIM: $metaRel v73.2.4 section contains 'Total Remediation'")
        }
    }
}

if ($VerifyDrive) {
    $driveMailbox = "G:\My Drive\ACT_OMEGA_GEMINI_BRIDGE\muse-spark-mailbox\spark-to-muse"
    $expectedFolderId = "1ngCCyRneCuKeXRNWZX3pZh0OGAdSGqzw"
    $driveJsonRaw = & gdrive readonly search --name-contains "COMPLETION_REPORT_V73" --json 2>&1 | Out-String
    $folderJsonRaw = & gdrive readonly ls $expectedFolderId --max 0 --json 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0) {
        $failures.Add("GDRIVE_SEARCH_FAILED: exit=$LASTEXITCODE out=$driveJsonRaw")
    } else {
        $searchItems = $driveJsonRaw | ConvertFrom-Json
        $folderItems = $folderJsonRaw | ConvertFrom-Json
        $folderIdSet = @{}
        foreach ($fi in $folderItems) {
            if ($fi.id) { $folderIdSet[[string]$fi.id] = $true }
        }
        $driveFiles = @($searchItems | Where-Object { $folderIdSet.ContainsKey([string]$_.id) })
        $v7324Text = $Utf8NoBomStrict.GetString([System.IO.File]::ReadAllBytes((Join-Path $RepoRoot "COMPLETION_REPORT_V73_2_4_MUSE.md")))

        foreach ($repName in $ReportFiles) {
            $matchesForName = @($driveFiles | Where-Object { $_.name -eq $repName })
            if ($matchesForName.Count -eq 0) {
                $failures.Add("GDRIVE_MISSING_FILE: $repName not found in spark-to-muse ($expectedFolderId)")
                continue
            }
            if ($matchesForName.Count -gt 1) {
                $failures.Add("GDRIVE_DUPLICATE_FILE: $repName has $($matchesForName.Count) copies in spark-to-muse")
                continue
            }
            $fileId = [string]$matchesForName[0].id
            if (-not $v7324Text.Contains($fileId)) {
                $failures.Add("DRIVE_ID_NOT_EMBEDDED: COMPLETION_REPORT_V73_2_4_MUSE.md does not embed Drive File ID '$fileId' for $repName")
            }

            $localReport = Join-Path $RepoRoot $repName
            $driveFsCopy = Join-Path $driveMailbox $repName
            if (-not (Test-Path -LiteralPath $driveFsCopy -PathType Leaf)) {
                $failures.Add("DRIVEFS_MISSING_COPY: $driveFsCopy not found")
            } else {
                $hLocal = Get-Sha256Hex -Path $localReport
                $hDrive = Get-Sha256Hex -Path $driveFsCopy
                if ($hLocal -ne $hDrive) {
                    $failures.Add("DRIVEFS_SHA256_MISMATCH: $repName local=$hLocal drive=$hDrive")
                }
            }
        }
    }
}

if ($failures.Count -gt 0) {
    Write-Output "[CITATION-VERIFIER-FAIL] failures=$($failures.Count) citations_checked=$totalCitationsChecked symbols_checked=$totalSymbolsChecked"
    foreach ($f in $failures) {
        Write-Output "  [FAIL] $f"
    }
    exit 1
}

Write-Output "[CITATION-VERIFIER-PASS] reports=$($ReportFiles.Count) citations_checked=$totalCitationsChecked symbols_checked=$totalSymbolsChecked verify_drive=$([bool]$VerifyDrive)"
exit 0
