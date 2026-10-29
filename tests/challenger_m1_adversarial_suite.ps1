# Challenger M1-2: Adversarial Verification & Stress Test Suite
# Target: Milestone 1 Iteration 2 (ACT-Omega Net v50.2.0 Production Release)
# File: C:\sovereign_manifold_v31\tests\challenger_m1_adversarial_suite.ps1
# Constraints: Zero Python | Zero Mock Data | Empirical Verification Mandate

param(
    [string]$RepoRoot = "C:\sovereign_manifold_v31",
    [switch]$Detailed = $true
)

$ErrorActionPreference = "Continue"

Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "  CHALLENGER M1-2: ADVERSARIAL ZERO-JS SSR & SUBPATH TEST SUITE           " -ForegroundColor Cyan
Write-Host "  Target Root: $RepoRoot                                                  " -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan

$TotalTests = 0
$PassedTests = 0
$FailedTests = 0
$Violations = [System.Collections.Generic.List[string]]::new()

function Record-Result {
    param(
        [string]$TestCategory,
        [string]$Description,
        [bool]$Success,
        [string]$Detail = ""
    )
    $script:TotalTests++
    if ($Success) {
        $script:PassedTests++
        Write-Host "  [PASS] [$TestCategory] $Description" -ForegroundColor Green
        if ($Detail -and $script:Detailed) {
            Write-Host "         $Detail" -ForegroundColor DarkGreen
        }
    } else {
        $script:FailedTests++
        $err = "[$TestCategory] $Description : $Detail"
        $script:Violations.Add($err)
        Write-Host "  [FAIL] $err" -ForegroundColor Red
    }
}

# Helper: Extract balanced tag inner content
function Get-BalancedTagContent {
    param(
        [string]$Html,
        [string]$TagName,
        [string]$OpenPattern
    )
    $m = [regex]::Match($Html, $OpenPattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    if (-not $m.Success) { return $null }

    $startIndex = $m.Index + $m.Length
    $depth = 1
    $pos = $startIndex

    $tagRegex = [regex]::new("<\s*(/)?\s*$TagName\b[^>]*>", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    while ($pos -lt $Html.Length) {
        $nextTag = $tagRegex.Match($Html, $pos)
        if (-not $nextTag.Success) { break }
        
        $isClosing = $nextTag.Groups[1].Success -and ($nextTag.Groups[1].Value -eq "/")
        if ($isClosing) {
            $depth--
            if ($depth -eq 0) {
                $length = $nextTag.Index - $startIndex
                return $Html.Substring($startIndex, $length)
            }
        } else {
            # Check if self-closing
            if (-not $nextTag.Value.EndsWith("/>")) {
                $depth++
            }
        }
        $pos = $nextTag.Index + $nextTag.Length
    }
    return $null
}

# -----------------------------------------------------------------------------
# TEST SUITE 1: ROOT ASSET EXISTENCE & DIST PARITY (Remediation Verification)
# -----------------------------------------------------------------------------
Write-Host "`n--- [SUITE 1: Root Assets & SHA-256 Parity] ---" -ForegroundColor Yellow

$requiredRootAssets = @(
    "icon-512.png", "icon-192.png", "logo.svg", "favicon.ico", "favicon.png",
    "manifest.webmanifest", "sw.js", "sovereign_harmonic_iv_v5000.e8z",
    "sovereign_harmonic_iv_v4000.e8z", "act_omega_logo.jpg",
    "telemetry_snapshot.json", "llms.txt"
)
$distDir = Join-Path $RepoRoot "05_hud_cockpit\dist"

foreach ($asset in $requiredRootAssets) {
    $rootAssetPath = Join-Path $RepoRoot $asset
    $exists = Test-Path $rootAssetPath
    if (-not $exists) {
        Record-Result "RootAssets" "$asset physically exists in repo root" $false "File not found at $rootAssetPath"
    } else {
        $len = (Get-Item $rootAssetPath).Length
        Record-Result "RootAssets" "$asset physically exists in repo root" ($len -gt 0) "Length: $len bytes"

        $distAssetPath = Join-Path $distDir $asset
        if (Test-Path $distAssetPath) {
            $rootHash = (Get-FileHash $rootAssetPath -Algorithm SHA256).Hash
            $distHash = (Get-FileHash $distAssetPath -Algorithm SHA256).Hash
            $match = ($rootHash -eq $distHash)
            Record-Result "RootAssetsParity" "$asset SHA-256 matches 05_hud_cockpit/dist" $match "Root=$rootHash Dist=$distHash"
        }
    }
}

# -----------------------------------------------------------------------------
# TEST SUITE 2: ZERO-JS SSR DOM PARSING (<div id="root"> & <main data-sovereign-ssr>)
# -----------------------------------------------------------------------------
Write-Host "`n--- [SUITE 2: Zero-JS Crawler Retrieval & SSR Pre-Population] ---" -ForegroundColor Yellow

$targetHtmlFiles = @(
    "index.html",
    "hud.html",
    "docs\index.html",
    "docs\hud.html",
    "05_hud_cockpit\dist\index.html",
    "02_l2_orchestration\hud\dist\index.html"
)

$expectedDOIs = @(
    "10.5281/zenodo.23651696",
    "10.17605/OSF.IO/2XQ5Z"
)

$expectedSpecs = @(
    "Anchor-1",
    "i5-12450HX",
    "RTX 3050",
    "Edge-1",
    "Pixel 10",
    "Tensor G5",
    "Edge-2",
    "Pixel 8",
    "Tensor G3",
    "Layer 1.5",
    "Haskell",
    "DuckDB",
    "63,360",
    "1,013,760",
    "1,440",
    "Lean 4"
)

foreach ($relPath in $targetHtmlFiles) {
    $fullPath = Join-Path $RepoRoot $relPath
    if (-not (Test-Path $fullPath)) {
        Record-Result "HtmlFileCheck" "$relPath exists on disk" $false "File not found"
        continue
    }

    $rawHtml = [System.IO.File]::ReadAllText($fullPath)

    # 1. Balanced parse of <div id="root">
    $rootContent = Get-BalancedTagContent -Html $rawHtml -TagName "div" -OpenPattern '<div\s+id=["'']root["''][^>]*>'
    $hasRootDiv = ($rootContent -ne $null -and $rootContent.Length -gt 0)
    Record-Result "ZeroJS-DOM" "$relPath contains populated <div id='root'>" $hasRootDiv "Length: $($rootContent.Length) chars"

    # 2. Balanced parse of <main data-sovereign-ssr="v50.2.0"> inside root
    $ssrContent = Get-BalancedTagContent -Html $rootContent -TagName "main" -OpenPattern '<main\s+[^>]*data-sovereign-ssr=["'']v50\.2\.0["''][^>]*>'
    $hasSsrMain = ($ssrContent -ne $null -and $ssrContent.Length -gt 0)
    Record-Result "ZeroJS-SSR" "$relPath has populated <main data-sovereign-ssr='v50.2.0'>" $hasSsrMain "Length: $($ssrContent.Length) chars"

    # 3. Check DOIs inside SSR
    foreach ($doi in $expectedDOIs) {
        $hasDoi = ($ssrContent -ne $null) -and $ssrContent.Contains($doi)
        Record-Result "SSR-DOI" "$relPath SSR contains DOI $doi" $hasDoi "Found: $hasDoi"
    }

    # 4. Check Cluster and Connectome Specs inside SSR
    $missingSpecs = @()
    if ($ssrContent -ne $null) {
        foreach ($spec in $expectedSpecs) {
            if (-not $ssrContent.Contains($spec)) {
                $missingSpecs += $spec
            }
        }
    } else {
        $missingSpecs = $expectedSpecs
    }
    $specsOk = ($missingSpecs.Count -eq 0)
    Record-Result "SSR-Specs" "$relPath SSR contains full cluster/connectome specs" $specsOk "Missing: $($missingSpecs -join ', ')"
}

# -----------------------------------------------------------------------------
# TEST SUITE 3: SCHEMA.ORG JSON-LD & CRAWLER METADATA
# -----------------------------------------------------------------------------
Write-Host "`n--- [SUITE 3: Schema.org JSON-LD & Crawler Metadata] ---" -ForegroundColor Yellow

foreach ($relPath in $targetHtmlFiles) {
    $fullPath = Join-Path $RepoRoot $relPath
    if (-not (Test-Path $fullPath)) { continue }

    $rawHtml = [System.IO.File]::ReadAllText($fullPath)

    # 1. Locate and parse <script type="application/ld+json">
    $hasLdJson = $rawHtml -match '(?si)<script\s+type=["'']application/ld\+json["''][^>]*>(.*?)</script>'
    if (-not $hasLdJson) {
        Record-Result "JSON-LD" "$relPath has application/ld+json script" $false "Missing ld+json tag"
    } else {
        $jsonRaw = $matches[1].Trim()
        try {
            $jsonObj = $jsonRaw | ConvertFrom-Json
            $validJson = $true
        } catch {
            $validJson = $false
        }
        Record-Result "JSON-LD" "$relPath JSON-LD is syntactically valid JSON" $validJson "Parsed successfully"

        if ($validJson) {
            $typeMatch = ($jsonObj.'@type' -eq "SoftwareApplication")
            Record-Result "JSON-LD-Type" "$relPath @type is SoftwareApplication" $typeMatch "Type: $($jsonObj.'@type')"

            $versionMatch = ($jsonObj.softwareVersion -match '50\.2\.0')
            Record-Result "JSON-LD-Version" "$relPath softwareVersion is 50.2.0" $versionMatch "Version: $($jsonObj.softwareVersion)"

            $idString = if ($jsonObj.identifier -is [Array]) { $jsonObj.identifier -join " " } else { [string]$jsonObj.identifier }
            $hasZenodoDoi = $idString.Contains("10.5281/zenodo.23651696")
            $hasOsfDoi = $idString.Contains("10.17605/OSF.IO/2XQ5Z")
            Record-Result "JSON-LD-DOIs" "$relPath JSON-LD contains Zenodo DOI" $hasZenodoDoi "Zenodo DOI verified"
            Record-Result "JSON-LD-DOIs" "$relPath JSON-LD contains OSF DOI" $hasOsfDoi "OSF DOI verified"
        }
    }

    # 2. Meta tags check
    $hasMetaDesc = $rawHtml -match '(?i)<meta\s+name=["'']description["'']\s+content=["'']([^"'']+)["'']'
    $hasOgTitle = $rawHtml -match '(?i)<meta\s+property=["'']og:title["'']\s+content=["'']([^"'']+)["'']'
    $hasCanonical = $rawHtml -match '(?i)<link\s+rel=["'']canonical["'']\s+href=["'']([^"'']+)["'']'
    Record-Result "MetaTags" "$relPath contains description, og:title, and canonical link" ($hasMetaDesc -and $hasOgTitle -and $hasCanonical) "Desc=$hasMetaDesc OgTitle=$hasOgTitle Canonical=$hasCanonical"
}

# -----------------------------------------------------------------------------
# TEST SUITE 4: SUBPATH RELATIVE LINKS & ASSET RESOLUTION
# -----------------------------------------------------------------------------
Write-Host "`n--- [SUITE 4: Subpath Relative Links & Asset Resolution] ---" -ForegroundColor Yellow

# Adversarial URL Simulation: base https://bospaladin34-crypto.github.io/Sovereign-Manifold-V30-A.P.H.U.S-/
foreach ($relPath in $targetHtmlFiles) {
    $fullPath = Join-Path $RepoRoot $relPath
    if (-not (Test-Path $fullPath)) { continue }

    $rawHtml = [System.IO.File]::ReadAllText($fullPath)
    $fileDir = Split-Path -Parent $fullPath

    # 1. Check for root-relative paths starting with single / (e.g., href="/assets/..." or src="/logo.svg")
    # Exclude protocol-relative (//) or external links
    $rootRelativeMatches = [regex]::Matches($rawHtml, '(?i)(?:src|href)=["'']/(?![/])([^"'']*)["'']')
    $hasRootRelative = ($rootRelativeMatches.Count -gt 0)
    $rootRelativeList = @()
    foreach ($m in $rootRelativeMatches) {
        $rootRelativeList += $m.Value
    }
    Record-Result "SubpathSafety" "$relPath has 0 root-relative (/) links" (-not $hasRootRelative) "Root-relative found: $($rootRelativeList -join ', ')"

    # 2. Extract all relative asset references (src="./..." or href="./...")
    $relAssetMatches = [regex]::Matches($rawHtml, '(?i)(?:src|href)=["'']\./([^"'']+)["'']')
    $allResolved = $true
    $missingAssets = @()

    foreach ($m in $relAssetMatches) {
        $relTarget = $m.Groups[1].Value.Split('?')[0].Split('#')[0]
        # Skip external or anchor-only
        if ([string]::IsNullOrWhiteSpace($relTarget)) { continue }
        
        $resolvedDiskPath = Join-Path $fileDir $relTarget
        if (-not (Test-Path $resolvedDiskPath)) {
            $allResolved = $false
            $missingAssets += "./$relTarget (referenced in $relPath, expected at $resolvedDiskPath)"
        }
    }
    Record-Result "AssetResolution" "$relPath all referenced ./ assets exist on disk" $allResolved "Missing: $($missingAssets -join ', ')"
}

# -----------------------------------------------------------------------------
# TEST SUITE 5: SERVICE WORKER & MANIFEST RELATIVE RESOLUTION
# -----------------------------------------------------------------------------
Write-Host "`n--- [SUITE 5: Service Worker & Manifest Subpath Resolution] ---" -ForegroundColor Yellow

$swLocations = @(
    "sw.js",
    "docs\sw.js",
    "05_hud_cockpit\dist\sw.js",
    "05_hud_cockpit\public\sw.js"
)
foreach ($swRel in $swLocations) {
    $swPath = Join-Path $RepoRoot $swRel
    if (-not (Test-Path $swPath)) { continue }
    $swContent = [System.IO.File]::ReadAllText($swPath)
    $swDir = Split-Path -Parent $swPath

    # Extract STATIC_ASSETS array
    if ($swContent -match 'STATIC_ASSETS\s*=\s*\[(.*?)\]') {
        $assetsListRaw = $matches[1]
        $assetItems = [regex]::Matches($assetsListRaw, '["''](\./[^"'']*)["'']')
        $swMissing = @()
        foreach ($item in $assetItems) {
            $itemRel = $item.Groups[1].Value
            if ($itemRel -eq "./") { continue } # Root directory itself
            $cleaned = $itemRel.TrimStart('.').TrimStart('/')
            $targetPath = Join-Path $swDir $cleaned
            if (-not (Test-Path $targetPath)) {
                $swMissing += "$itemRel in $swRel"
            }
        }
        $swOk = ($swMissing.Count -eq 0)
        Record-Result "ServiceWorkerAssets" "$swRel static pre-cache assets exist on disk" $swOk "Missing: $($swMissing -join ', ')"
    }
}

# -----------------------------------------------------------------------------
# SUMMARY & VERDICT
# -----------------------------------------------------------------------------
Write-Host "`n==========================================================================" -ForegroundColor Cyan
Write-Host "  TEST SUMMARY: Total=$TotalTests | Passed=$PassedTests | Failed=$FailedTests" -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan

if ($FailedTests -gt 0) {
    Write-Host "`n[ADVERSARIAL VERDICT: REQUEST_CHANGES ($FailedTests failures)]" -ForegroundColor Red
    foreach ($v in $Violations) {
        Write-Host "  - $v" -ForegroundColor Red
    }
    exit 1
} else {
    Write-Host "`n[ADVERSARIAL VERDICT: APPROVED (All $PassedTests tests passed!)]" -ForegroundColor Green
    exit 0
}
