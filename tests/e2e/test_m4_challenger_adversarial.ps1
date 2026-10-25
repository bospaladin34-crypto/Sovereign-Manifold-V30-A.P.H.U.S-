# ==============================================================================
# ACT-OMEGA NET v49.0.0 — MILESTONE 4: ADVERSARIAL CHALLENGER VERIFICATION SUITE
# Challenger M4-1: 100% UI Preservation, Parity, Passkey Purge & Periphery Sync
# File: C:\sovereign_manifold_v31\tests\e2e\test_m4_challenger_adversarial.ps1
# STRICT ZERO-PYTHON MANDATE | ZERO-UNMEASURED DATA MANDATE
# ==============================================================================

$ErrorActionPreference = "Stop"
$RepoRoot = "C:\sovereign_manifold_v31"
$PassCount = 0
$FailCount = 0
$Findings = @()

function Report-Pass($desc) {
    Write-Host "  [PASS] $desc" -ForegroundColor Green
    $global:PassCount++
}

function Report-Fail($desc, $details) {
    Write-Host "  [FAIL] $desc" -ForegroundColor Red
    Write-Host "         Details: $details" -ForegroundColor DarkYellow
    $global:FailCount++
    $global:Findings += [PSCustomObject]@{
        Test = $desc
        Details = $details
    }
}

Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "   MILESTONE 4: ADVERSARIAL CHALLENGER M4-1 RIGOR & PRESERVATION PROBE   " -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan

# ------------------------------------------------------------------------------
# SECTION 1: APP.TSX SHA256 BYTE-FOR-BYTE PARITY
# ------------------------------------------------------------------------------
Write-Host "`n--- [SECTION 1] App.tsx SHA-256 Parity & Single-Source Integrity ---" -ForegroundColor Yellow

$app1 = Join-Path $RepoRoot "05_hud_cockpit\src\App.tsx"
$app2 = Join-Path $RepoRoot "02_l2_orchestration\hud\src\App.tsx"

if ((Test-Path $app1) -and (Test-Path $app2)) {
    $h1 = (Get-FileHash -Path $app1 -Algorithm SHA256).Hash
    $h2 = (Get-FileHash -Path $app2 -Algorithm SHA256).Hash
    $len1 = (Get-Item $app1).Length
    $len2 = (Get-Item $app2).Length

    if ($h1 -eq $h2) {
        Report-Pass "Byte-for-byte SHA256 parity confirmed ($h1)"
    } else {
        Report-Fail "SHA256 mismatch between App.tsx copies" "app1=$h1, app2=$h2"
    }

    if ($len1 -eq $len2) {
        Report-Pass "Exact file length parity confirmed ($len1 bytes)"
    } else {
        Report-Fail "File length mismatch between App.tsx copies" "len1=$len1, len2=$len2"
    }
} else {
    Report-Fail "Missing App.tsx source files" "Checked $app1 and $app2"
}

# ------------------------------------------------------------------------------
# SECTION 2: 100% UI PRESERVATION ACROSS DRAWER A (ALL 15 CARDS)
# ------------------------------------------------------------------------------
Write-Host "`n--- [SECTION 2] Drawer A: 15-Card Telemetry Preservation ---" -ForegroundColor Yellow

$content = Get-Content -Raw $app1

# Test Drawer A container
if ($content -match "drawerAOpen" -and $content -match "DRAWER A: 15.965 Hz DECADIC EPOCH") {
    Report-Pass "Drawer A container and toggle state intact"
} else {
    Report-Fail "Drawer A container or toggle missing" "Check drawerAOpen in App.tsx"
}

# Test all 15 cards
$expectedCards = @(
    "15.965 Hz DECADIC EPOCH CLOCK",
    "PIXEL 10 24D MAGNETOMETER & DIPOLE",
    "PER-SENSOR STIEFEL & THEODORUS Q_n",
    "21,120\+21,120 SHARD VAULT & HARVESTER",
    "PIXEL 8 MALI-G715 L2 \.NPAGE SHM RING",
    "ACOUSTIC I/Q SDR WAVE BUS",
    "CLOUDFLARE PQ, SIEM & PHOTOELECTRIC",
    "460/460 LEAN 4 PROOFS & MEASURED QAT",
    "SECTOR 8_v: ENV & nc-AFM HEX SHEAF",
    "SECTOR 8_\+: KINEMATICS & U\(1\) GAUGE",
    "SECTOR 8_-: TENSOR G5 & ALWAYS-ON",
    "NVIDIA RTX 3050 6GB & ANYON BRAID",
    "65,536 BPE \+ 16D COMPOUND \(TOOL 27\)",
    "LLM GATEWAY & EPISODIC SEARCH \(T21/T28\)",
    "10-LAPLACIAN FNO & E:\\\\ SSD VAULT"
)

$cardIdx = 0
foreach ($cardPattern in $expectedCards) {
    if ($content -match $cardPattern) {
        Report-Pass "Drawer A Card #$cardIdx present ($cardPattern)"
    } else {
        Report-Fail "Drawer A Card #$cardIdx missing ($cardPattern)" "Not found in cards15 array"
    }
    $cardIdx++
}

# ------------------------------------------------------------------------------
# SECTION 3: DRAWER B 3D VECTOR SCOPE & OSCILLOSCOPE INTEGRITY
# ------------------------------------------------------------------------------
Write-Host "`n--- [SECTION 3] Drawer B: 3D Vector Scope & Oscilloscope Preservation ---" -ForegroundColor Yellow

if ($content -match "drawerBOpen" -and $content -match "DRAWER B: PER-SENSOR COUPLED STIEFEL") {
    Report-Pass "Drawer B container and toggle intact"
} else {
    Report-Fail "Drawer B container or toggle missing" "Check drawerBOpen in App.tsx"
}

if ($content -match 'ref=\{scopeCanvasRef\}' -and $content -match 'width=\{440\}' -and $content -match 'height=\{95\}') {
    Report-Pass "Drawer B 3D Stiefel / Theodorus scope canvas intact (440x95)"
} else {
    Report-Fail "Drawer B 3D scope canvas missing or altered" "Check scopeCanvasRef in App.tsx"
}

if ($content -match 'ref=\{oscCanvasRef\}' -and $content -match 'width=\{620\}' -and $content -match 'height=\{95\}') {
    Report-Pass "Drawer B 15.965 Hz Decadic Oscilloscope canvas intact (620x95)"
} else {
    Report-Fail "Drawer B oscilloscope canvas missing or altered" "Check oscCanvasRef in App.tsx"
}

# ------------------------------------------------------------------------------
# SECTION 4: 16x130 (2,080-CACHELINE) 1:1 BIJECTION HEATMAP INTEGRITY
# ------------------------------------------------------------------------------
Write-Host "`n--- [SECTION 4] Pinned Workspace: 16x130 (2,080-Cacheline) Heatmap ---" -ForegroundColor Yellow

if ($content -match "16x130 \(2,080-CACHELINE\) 1:1 BIJECTION HEATMAP") {
    Report-Pass "16x130 (2,080-cacheline) Heatmap header and descriptor present"
} else {
    Report-Fail "Heatmap descriptor altered" "Expected 16x130 2,080-cacheline reference"
}

if ($content -match "repeat\(16, 6px\)" -and $content -match "repeat\(130, 1fr\)") {
    Report-Pass "Heatmap 16-row x 130-col grid structure preserved"
} else {
    Report-Fail "Heatmap grid layout altered" "Missing repeat(16, 6px) or repeat(130, 1fr)"
}

if ($content -match "SECTOR_NAMES\.map") {
    Report-Pass "Sector selector buttons (S00..S79) mapped across SECTOR_NAMES"
} else {
    Report-Fail "Sector selector buttons missing" "Check SECTOR_NAMES.map in App.tsx"
}

# ------------------------------------------------------------------------------
# SECTION 5: DRAWERS 1, 2, 3, 4 PRESERVATION
# ------------------------------------------------------------------------------
Write-Host "`n--- [SECTION 5] Drawers 1, 2, 3, 4 Structural Preservation ---" -ForegroundColor Yellow

# Drawer 1
if ($content -match "DRAWER 1: LIVE 12-CHANNEL SENSOR SPARKLINES" -and $content -match "drawer1Open" -and $content -match "ref=\{sparkCanvasRef\}") {
    Report-Pass "Drawer 1 (12-Channel Sparklines) fully preserved"
} else {
    Report-Fail "Drawer 1 missing or damaged" "Check drawer1Open / sparkCanvasRef"
}

# Drawer 2 (8x64 Grid Waterfall)
if ($content -match "DRAWER 2: FCC-EXEMPT ACOUSTIC I/Q WAVE SDR WATERFALL" -and $content -match "drawer2Open" -and $content -match "repeat\(8, 6px\)" -and $content -match "repeat\(64, 1fr\)") {
    Report-Pass "Drawer 2 (Acoustic SDR 8x64 Grid Waterfall & FNO) fully preserved"
} else {
    Report-Fail "Drawer 2 missing or damaged" "Check drawer2Open / repeat(8, 6px) grid"
}

# Drawer 3
if ($content -match "DRAWER 3: FORMAL VERIFICATION SUITE \(460/460 LEAN 4 PROOFS QED\)" -and $content -match "drawer3Open") {
    Report-Pass "Drawer 3 (460/460 Lean 4 Proofs QED) fully preserved"
} else {
    Report-Fail "Drawer 3 missing or damaged" "Check drawer3Open / 460 Lean 4 Proofs"
}

# Drawer 4
if ($content -match "DRAWER 4: 100-TOOL EXECUTION REGISTRY \(CHAIN 100 CENTURY MILESTONE\)" -and $content -match "drawer4Open") {
    Report-Pass "Drawer 4 (CHAIN 100 Century Milestone Registry) fully preserved"
} else {
    Report-Fail "Drawer 4 missing or damaged" "Check drawer4Open in App.tsx"
}

# ------------------------------------------------------------------------------
# SECTION 6: DRAWER 4 EXPANSION: TOOLS 91..100 & CHAIN 100 OMNI-SUITE
# ------------------------------------------------------------------------------
Write-Host "`n--- [SECTION 6] Drawer 4: Tools 91..100 & CHAIN 100 Buttons ---" -ForegroundColor Yellow

$v49Card = "v49\.0\.0 TEN-PIECE EXTERNAL RESEARCH SYNTHESIS"
if ($content -match $v49Card) {
    Report-Pass "Drawer 4 dedicated v49.0.0 Ten-Piece External Research Synthesis card present"
} else {
    Report-Fail "v49.0.0 Synthesis card missing in Drawer 4" "Expected $v49Card"
}

$expectedToolEndpoints = @(
    "/api/v1/v49/chain100_omni_suite",
    "/api/v1/v49/tool_100_dzhanibekov_euler_axis_stabilizer",
    "/api/v1/v49/tool_99_stanford_together_hybrid_link_agent",
    "/api/v1/v49/tool_98_poincare_bendixson_destiny_atlas",
    "/api/v1/v49/tool_97_hamilton_tait_nabla_quaternionic_field",
    "/api/v1/v49/tool_96_bipolar_vesica_caustic_envelope",
    "/api/v1/v49/tool_95_bell_polytope_noncontextuality_audit",
    "/api/v1/v49/tool_94_cubic_pyramid_integral_proof",
    "/api/v1/v49/tool_93_bekenstein_hawking_area_horizon_guard",
    "/api/v1/v49/tool_92_amplituhedron_9loop_hexagon_plucker",
    "/api/v1/v49/tool_91_ds3_triangulated_cft2_gravity"
)

foreach ($ep in $expectedToolEndpoints) {
    if ($content -match [regex]::Escape($ep)) {
        Report-Pass "Endpoint call button wired in App.tsx ($ep)"
    } else {
        Report-Fail "Missing endpoint call button in App.tsx" "Endpoint: $ep"
    }
}

if ($content -match "CHAIN 100: 100-TOOL CENTURY OMNI-SUITE") {
    Report-Pass "Primary tool button for CHAIN 100 Century Omni-Suite present"
} else {
    Report-Fail "Missing primary CHAIN 100 button in tool grid" "Check CHAIN 100 button label"
}

# Quick Command Palette entries (Tools 91..100)
$palettePresent = $true
for ($t = 91; $t -le 100; $t++) {
    if ($content -notmatch "Tool $($t):") {
        $palettePresent = $false
        break
    }
}
if ($palettePresent -and ($content -match "CHAIN 100: Century Milestone Omni-Suite")) {
    Report-Pass "Command Palette modal contains Tools 91 through 100 and CHAIN 100"
} else {
    Report-Fail "Command Palette modal missing v49 tools" "Could not find Tool 91..100 in palette items"
}

# ------------------------------------------------------------------------------
# SECTION 7: GLOBAL PASSKEY LEAK SCAN (REDACTED_LEGACY_KEY)
# ------------------------------------------------------------------------------
Write-Host "`n--- [SECTION 7] Global Passkey Leak Scan (REDACTED_LEGACY_KEY) ---" -ForegroundColor Yellow

$targetExtensions = @("*.html", "*.js", "*.ts", "*.tsx", "*.rs", "*.cs", "*.kt", "*.xml")
$scannedFiles = Get-ChildItem -Path $RepoRoot -Recurse -File -Include $targetExtensions | Where-Object {
    $_.FullName -notmatch '\\\.git\\' -and
    $_.FullName -notmatch '\\node_modules\\'
}

$leaksFound = @()
foreach ($file in $scannedFiles) {
    $m = Select-String -Path $file.FullName -Pattern ("SOVEREIGN-" + "LOQ15-4200") -SimpleMatch
    if ($m) {
        $leaksFound += $file.FullName
    }
}

if ($leaksFound.Count -eq 0) {
    Report-Pass "Global passkey leak scan: strictly 0 occurrences across $($scannedFiles.Count) code/markup files"
} else {
    Report-Fail "Deprecated passkey ("SOVEREIGN-" + "LOQ15-4200") found in code files" ($leaksFound -join ", ")
}

# ------------------------------------------------------------------------------
# SECTION 8: PERIPHERY & WIDGET SYNCHRONIZATION
# ------------------------------------------------------------------------------
Write-Host "`n--- [SECTION 8] Periphery & Widget Synchronization ---" -ForegroundColor Yellow

# 8.1 Windows 11 Native Tray HUD
$trayCs = Join-Path $RepoRoot "00_control\Win11_Native_Tray_HUD\SovereignTrayAndHud.cs"
if (Test-Path $trayCs) {
    $trayContent = Get-Content -Raw $trayCs
    if ($trayContent -match "v49\.0\.0" -and $trayContent -match "100 Tools" -and $trayContent -match "460/460 QED" -and $trayContent -match "ActOmegaSovereignCockpitTray_v4900") {
        Report-Pass "Win11 SovereignTrayAndHud.cs synchronized to v49.0.0 (100 Tools, 460 QED, v4900 mutex)"
    } else {
        Report-Fail "Win11 SovereignTrayAndHud.cs not fully synchronized" "Check v49.0.0 strings"
    }
} else {
    Report-Fail "Missing SovereignTrayAndHud.cs" "File not found: $trayCs"
}

# 8.2 Windows 11 Native Tray Executable
$trayExe = Join-Path $RepoRoot "00_control\Win11_Native_Tray_HUD\SovereignCockpitHUD.exe"
if (Test-Path $trayExe) {
    $exeSize = (Get-Item $trayExe).Length
    if ($exeSize -gt 10000) {
        Report-Pass "Win11 SovereignCockpitHUD.exe compiled and present ($exeSize bytes)"
    } else {
        Report-Fail "Win11 SovereignCockpitHUD.exe size suspiciously small" "Size: $exeSize bytes"
    }
} else {
    Report-Fail "Missing SovereignCockpitHUD.exe" "Binary not found: $trayExe"
}

# 8.3 Android Homescreen Widget Layout
$widgetXml = Join-Path $RepoRoot "04_edge_silicon\pixel10_ndk_app\app\src\main\res\layout\sovereign_heatmap_widget.xml"
if (Test-Path $widgetXml) {
    $wXmlContent = Get-Content -Raw $widgetXml
    if ($wXmlContent -match "v49\.0\.0 \(CHAIN 100\)" -and $wXmlContent -match "460/460 QED") {
        Report-Pass "Android Widget layout synchronized to v49.0.0 (CHAIN 100, 460/460 QED)"
    } else {
        Report-Fail "Android Widget layout not synchronized" "Missing v49.0.0 / 460 QED in $widgetXml"
    }
} else {
    Report-Fail "Missing sovereign_heatmap_widget.xml" "File not found: $widgetXml"
}

# 8.4 Android Strings
$stringsXml = Join-Path $RepoRoot "04_edge_silicon\pixel10_ndk_app\app\src\main\res\values\strings.xml"
if (Test-Path $stringsXml) {
    $strContent = Get-Content -Raw $stringsXml
    if ($strContent -match "v49\.0\.0 \(CHAIN 100\)" -and $strContent -match "460/460 QED") {
        Report-Pass "Android strings.xml synchronized to v49.0.0 (CHAIN 100, 460/460 QED)"
    } else {
        Report-Fail "Android strings.xml not synchronized" "Missing v49.0.0 / 460 QED in $stringsXml"
    }
} else {
    Report-Fail "Missing strings.xml" "File not found: $stringsXml"
}

# 8.5 Android Manifest
$manifestXml = Join-Path $RepoRoot "04_edge_silicon\pixel10_ndk_app\app\src\main\AndroidManifest.xml"
if (Test-Path $manifestXml) {
    $manContent = Get-Content -Raw $manifestXml
    if ($manContent -match "v49\.0\.0 \(CHAIN 100\)") {
        Report-Pass "Android AndroidManifest.xml label synchronized to v49.0.0 (CHAIN 100)"
    } else {
        Report-Fail "Android AndroidManifest.xml not synchronized" "Missing v49.0.0 in $manifestXml"
    }
} else {
    Report-Fail "Missing AndroidManifest.xml" "File not found: $manifestXml"
}

# 8.6 Android MainActivity.kt
$mainKt = Join-Path $RepoRoot "04_edge_silicon\pixel10_ndk_app\app\src\main\java\com\actomega\manifold\MainActivity.kt"
if (Test-Path $mainKt) {
    $ktContent = Get-Content -Raw $mainKt
    if ($ktContent -match "tool_100_dzhanibekov" -and $ktContent -match "tool_91_ds3" -and $ktContent -match "chain100_omni_suite" -and $ktContent -match "460/460 QED") {
        Report-Pass "Android MainActivity.kt synchronized with Tools 91..100, CHAIN 100, and 460/460 QED"
    } else {
        Report-Fail "Android MainActivity.kt missing v49 tools or proofs" "Check MainActivity.kt content"
    }
} else {
    Report-Fail "Missing MainActivity.kt" "File not found: $mainKt"
}

# 8.7 PWA Service Worker Cache Key
$swJs = Join-Path $RepoRoot "05_hud_cockpit\public\sw.js"
if (Test-Path $swJs) {
    $swContent = Get-Content -Raw $swJs
    if ($swContent -match "act-omega-cockpit-v49") {
        Report-Pass "PWA sw.js cache key updated to 'act-omega-cockpit-v49'"
    } else {
        Report-Fail "PWA sw.js cache key not bumped to v49" "Expected 'act-omega-cockpit-v49' in $swJs"
    }
} else {
    Report-Fail "Missing sw.js" "File not found: $swJs"
}

# 8.8 Web App Titles
$hudIndex = Join-Path $RepoRoot "05_hud_cockpit\index.html"
if (Test-Path $hudIndex) {
    $idxContent = Get-Content -Raw $hudIndex
    if ($idxContent -match "v49\.0\.0" -and $idxContent -match "460/460 Lean 4 QED" -and $idxContent -match "100 Tools") {
        Report-Pass "HUD Cockpit index.html title synchronized to v49.0.0 | 460/460 Lean 4 QED & 100 Tools"
    } else {
        Report-Fail "HUD Cockpit index.html title not synchronized" "Check index.html title"
    }
} else {
    Report-Fail "Missing index.html" "File not found: $hudIndex"
}

# ------------------------------------------------------------------------------
# SECTION 9: PRODUCTION BUILD INTEGRITY (VITE / TYPESCRIPT)
# ------------------------------------------------------------------------------
Write-Host "`n--- [SECTION 9] Production Build Integrity ---" -ForegroundColor Yellow

try {
    $buildOut = & npm --prefix "$RepoRoot\05_hud_cockpit" run build 2>&1
    if ($LASTEXITCODE -eq 0) {
        Report-Pass "05_hud_cockpit production build succeeded with exit code 0"
        $distIndex = Join-Path $RepoRoot "05_hud_cockpit\dist\index.html"
        if (Test-Path $distIndex) {
            Report-Pass "Production dist/index.html generated successfully"
        } else {
            Report-Fail "dist/index.html missing after npm run build" "File not found: $distIndex"
        }
    } else {
        Report-Fail "05_hud_cockpit npm run build failed" ($buildOut -join "`n")
    }
} catch {
    Report-Fail "Could not execute npm run build" $_.Exception.Message
}

# ------------------------------------------------------------------------------
# SUMMARY & VERDICT
# ------------------------------------------------------------------------------
Write-Host "`n==========================================================================" -ForegroundColor Cyan
Write-Host "   CHALLENGER M4-1 SUMMARY: $PassCount PASSED, $FailCount FAILED" -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan

if ($FailCount -eq 0) {
    Write-Host "`nVERDICT: APPROVE (ALL ADVERSARIAL STRESS CHALLENGES MET WITH 100% RIGOR)" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`nVERDICT: REQUEST_CHANGES ($FailCount CHALLENGES FAILED)" -ForegroundColor Red
    exit 1
}
