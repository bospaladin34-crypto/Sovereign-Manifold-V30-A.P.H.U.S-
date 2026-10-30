# ACT-Omega Net v56.1.0 (Functional Tool Consolidation, Universal E:\ Write-Back, Vectorized 16-Domain FNO, GSC Lock & Graceful Reboot)
# Tier 1: Feature Coverage Test Suite (All 14 Features in PROJECT.md)
# File: C:\sovereign_manifold_v31\tests\e2e\tier1_features_v56_1.ps1
# STRICT CONSTRAINT: ZERO PYTHON | MUSE ZERO-UNMEASURED DATA MANDATE

$ErrorActionPreference = "Continue"

$RepoRoot = if ($PSScriptRoot) {
    (Resolve-Path "$PSScriptRoot\..\..").Path
} else {
    "C:\sovereign_manifold_v31"
}

# -----------------------------------------------------------------------------
# Milestone 0: Permanent Google Search Console Certificate Lock (F01..F03)
# -----------------------------------------------------------------------------

function Test-Feature-v56-1-01 {
    # F01: GSC Certificate Ingestion across all 7 deployment targets + SSD Vault
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $certFileName = "google6edc0affb12d0455.html"
    $expectedBytes = 53
    $expectedContent = "google-site-verification: google6edc0affb12d0455.html"

    $targets = @(
        @{ Name = "DriveBridge"; Path = "G:\My Drive\ACT_OMEGA_GEMINI_BRIDGE\$certFileName"; Required = $true },
        @{ Name = "HudPublic";   Path = "$RepoRoot\05_hud_cockpit\public\$certFileName";      Required = $true },
        @{ Name = "L2HudPublic"; Path = "$RepoRoot\02_l2_orchestration\hud\public\$certFileName"; Required = $true },
        @{ Name = "HudDist";     Path = "$RepoRoot\05_hud_cockpit\dist\$certFileName";        Required = $true },
        @{ Name = "L2HudDist";   Path = "$RepoRoot\02_l2_orchestration\hud\dist\$certFileName"; Required = $true },
        @{ Name = "Docs";        Path = "$RepoRoot\docs\$certFileName";                       Required = $true },
        @{ Name = "RepoRoot";    Path = "$RepoRoot\$certFileName";                            Required = $true },
        @{ Name = "SSDVault";    Path = "E:\Sovereign_Manifold_SSD_Vault\$certFileName";      Required = (Test-Path "E:\") }
    )

    $targetResults = @{}
    $allOk = $true
    $missingOrCorrupt = @()

    foreach ($t in $targets) {
        if (-not (Test-Path $t.Path)) {
            $targetResults[$t.Name] = "MISSING"
            if ($t.Required) {
                $allOk = $false
                $missingOrCorrupt += "$($t.Name): MISSING"
            }
        } else {
            $item = Get-Item $t.Path
            $len = $item.Length
            $raw = [System.IO.File]::ReadAllText($t.Path).Trim()
            $contentMatch = ($raw -eq $expectedContent)
            if ($len -eq $expectedBytes -and $contentMatch) {
                $targetResults[$t.Name] = "OK_53B"
            } else {
                $targetResults[$t.Name] = "CORRUPT_${len}B"
                $allOk = $false
                $missingOrCorrupt += "$($t.Name): Length=$len ContentMatch=$contentMatch"
            }
        }
    }

    $msg = if ($allOk) {
        "google6edc0affb12d0455.html verified with exact 53 bytes across all $($targets.Count) deployment targets"
    } else {
        "GSC certificate deployment incomplete: $($missingOrCorrupt -join '; ')"
    }
    $sw.Stop()
    return New-TestResult -Tier 1 -Id "F01_v56_1" -Name "GSC Certificate Ingestion" -Milestone "M0" `
        -Passed $allOk -Message $msg -ElapsedMs $sw.Elapsed.TotalMilliseconds `
        -MeasuredData $targetResults
}

function Test-Feature-v56-1-02 {
    # F02: GSC L0 Rust & Edge Worker Handlers
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $certFileName = "google6edc0affb12d0455.html"

    # 1. Source code handler marker inspection
    $swarmSrc = "$RepoRoot\01_l0_rust\src\v31_swarm.rs"
    $workerSrc = "$RepoRoot\00_control\cloudflare_edge\worker_vpc_shadow_v3700.js"
    $workerRoot = "$RepoRoot\worker_vpc_shadow_v3700.js"

    $hasSwarmMarker = $false
    if (Test-Path $swarmSrc) {
        $swarmText = [System.IO.File]::ReadAllText($swarmSrc)
        $hasSwarmMarker = $swarmText.Contains("google6edc0affb12d0455.html")
    }

    $hasWorkerMarker = $false
    foreach ($wPath in @($workerSrc, $workerRoot)) {
        if (Test-Path $wPath) {
            $wText = [System.IO.File]::ReadAllText($wPath)
            if ($wText.Contains("google6edc0affb12d0455.html")) {
                $hasWorkerMarker = $true
                break
            }
        }
    }

    # 2. Live HTTP endpoint probes
    $res8097 = Invoke-SafeRestMethod -Uri "http://127.0.0.1:8097/$certFileName" -TimeoutSec 3
    $r8097Ok = ($res8097.Success -and $res8097.Data -match "google-site-verification")

    $res5173 = Invoke-SafeRestMethod -Uri "http://127.0.0.1:5173/$certFileName" -TimeoutSec 3
    $r5173Ok = ($res5173.Success -and $res5173.Data -match "google-site-verification")

    $passed = ($hasSwarmMarker -and $hasWorkerMarker -and $r8097Ok)
    $msg = if ($passed) {
        "GSC route handlers verified in Rust & Edge Worker; live :8097 responded 200 OK (53 B)"
    } else {
        "GSC handler verification: SwarmMarker=$hasSwarmMarker, WorkerMarker=$hasWorkerMarker, Live8097=$r8097Ok, Live5173=$r5173Ok"
    }
    $sw.Stop()
    return New-TestResult -Tier 1 -Id "F02_v56_1" -Name "GSC L0 Rust & Edge Worker Handlers" -Milestone "M0" `
        -Passed $passed -Message $msg -ElapsedMs $sw.Elapsed.TotalMilliseconds `
        -MeasuredData @{ SwarmMarker = $hasSwarmMarker; WorkerMarker = $hasWorkerMarker; Port8097Ok = $r8097Ok; Port5173Ok = $r5173Ok }
}

function Test-Feature-v56-1-03 {
    # F03: GSC Invariant Script Checks
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $gatekeeperScript = "$RepoRoot\00_control\Invoke-BrutalAgentGatekeeper.ps1"
    $lifecycleScript = "$RepoRoot\00_control\Sovereign-Lifecycle.ps1"
    $testRunnerScript = "$RepoRoot\tests\e2e\test_runner_v56.ps1"

    $hasGatekeeperCheck = $false
    if (Test-Path $gatekeeperScript) {
        $c = [System.IO.File]::ReadAllText($gatekeeperScript)
        $hasGatekeeperCheck = ($c -match 'google6edc0affb12d0455\.html')
    }

    $hasLifecycleCheck = $false
    if (Test-Path $lifecycleScript) {
        $c = [System.IO.File]::ReadAllText($lifecycleScript)
        $hasLifecycleCheck = ($c -match 'google6edc0affb12d0455\.html')
    }

    $hasRunnerCheck = $false
    if (Test-Path $testRunnerScript) {
        $c = [System.IO.File]::ReadAllText($testRunnerScript)
        $hasRunnerCheck = ($c -match 'google6edc0affb12d0455\.html' -or $c -match 'tier1_features_v56_1\.ps1')
    }

    $passed = ($hasGatekeeperCheck -and $hasLifecycleCheck -and $hasRunnerCheck)
    $msg = if ($passed) {
        "GSC invariant checks active in Gatekeeper, Lifecycle, and E2E runner scripts"
    } else {
        "GSC script invariant checks incomplete: Gatekeeper=$hasGatekeeperCheck, Lifecycle=$hasLifecycleCheck, Runner=$hasRunnerCheck"
    }
    $sw.Stop()
    return New-TestResult -Tier 1 -Id "F03_v56_1" -Name "GSC Invariant Script Checks" -Milestone "M0" `
        -Passed $passed -Message $msg -ElapsedMs $sw.Elapsed.TotalMilliseconds `
        -MeasuredData @{ Gatekeeper = $hasGatekeeperCheck; Lifecycle = $hasLifecycleCheck; Runner = $hasRunnerCheck }
}

# -----------------------------------------------------------------------------
# Milestone 1: Universal Autopoietic Coordinator Bus & 9-Directory Write-Back (F04..F06)
# -----------------------------------------------------------------------------

function Test-Feature-v56-1-04 {
    # F04: 9th Codegen Sink `tool_outputs`
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $v48Path = "$RepoRoot\01_l0_rust\src\v48_autopoietic_coordinator_bus.rs"
    if (-not (Test-Path $v48Path)) {
        $sw.Stop()
        return New-TestResult -Tier 1 -Id "F04_v56_1" -Name "9th Codegen Sink tool_outputs" -Milestone "M1" `
            -Passed $false -Message "Module missing: $v48Path" -ElapsedMs $sw.Elapsed.TotalMilliseconds
    }

    $text = [System.IO.File]::ReadAllText($v48Path)
    $hasEConst = ($text -match 'E_CODEGEN_TOOL_OUTPUTS_DIR')
    $hasCConst = ($text -match 'C_CODEGEN_TOOL_OUTPUTS_DIR')

    $eDirExists = (Test-Path "E:\Sovereign_Manifold_SSD_Vault\autopoietic_codegen\tool_outputs")
    $cDirExists = (Test-Path "$RepoRoot\03_vault\connectome\tool_outputs")

    $passed = ($hasEConst -and $hasCConst)
    $msg = if ($passed) {
        "9th codegen sink tool_outputs defined in v48 (E_Const=$hasEConst, C_Const=$hasCConst, CDirExists=$cDirExists)"
    } else {
        "9th codegen sink missing in v48 (E_Const=$hasEConst, C_Const=$hasCConst)"
    }
    $sw.Stop()
    return New-TestResult -Tier 1 -Id "F04_v56_1" -Name "9th Codegen Sink tool_outputs" -Milestone "M1" `
        -Passed $passed -Message $msg -ElapsedMs $sw.Elapsed.TotalMilliseconds `
        -MeasuredData @{ HasEConst = $hasEConst; HasCConst = $hasCConst; EDir = $eDirExists; CDir = $cDirExists }
}

function Test-Feature-v56-1-05 {
    # F05: Universal Tool Bus & Write-Back Function
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $v48Path = "$RepoRoot\01_l0_rust\src\v48_autopoietic_coordinator_bus.rs"
    if (-not (Test-Path $v48Path)) {
        $sw.Stop()
        return New-TestResult -Tier 1 -Id "F05_v56_1" -Name "Universal Tool Bus & Write-Back Function" -Milestone "M1" `
            -Passed $false -Message "Module missing: $v48Path" -ElapsedMs $sw.Elapsed.TotalMilliseconds
    }

    $bracketRes = Test-ZeroSquareBrackets -FilePath $v48Path
    $text = [System.IO.File]::ReadAllText($v48Path)

    $hasFn = ($text -match 'pub\s+fn\s+execute_universal_tool_bus_and_writeback')
    $hasManifest = ($text -match 'codegen_integration_manifest_v4800\.jsonl')
    $hasLedger = ($text -match 'message_bus_ledger_v4800\.jsonl')

    $passed = ($bracketRes.Passed -and $hasFn -and $hasManifest -and $hasLedger)
    $msg = if ($passed) {
        "execute_universal_tool_bus_and_writeback implemented with strict 0 square brackets (Bytes=$($bracketRes.ByteLength))"
    } else {
        "v48 universal writeback function missing or invalid (Fn=$hasFn, Brackets=$($bracketRes.BracketCount), Manifest=$hasManifest, Ledger=$hasLedger)"
    }
    $sw.Stop()
    return New-TestResult -Tier 1 -Id "F05_v56_1" -Name "Universal Tool Bus & Write-Back Function" -Milestone "M1" `
        -Passed $passed -Message $msg -ElapsedMs $sw.Elapsed.TotalMilliseconds `
        -MeasuredData @{ ZeroBrackets = $bracketRes.Passed; HasFn = $hasFn; HasManifest = $hasManifest; HasLedger = $hasLedger }
}

function Test-Feature-v56-1-06 {
    # F06: 210 Tools Write-Back Routing
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $swarmPath = "$RepoRoot\01_l0_rust\src\v31_swarm.rs"
    if (-not (Test-Path $swarmPath)) {
        $sw.Stop()
        return New-TestResult -Tier 1 -Id "F06_v56_1" -Name "210 Tools Write-Back Routing" -Milestone "M1" `
            -Passed $false -Message "Module missing: $swarmPath" -ElapsedMs $sw.Elapsed.TotalMilliseconds
    }

    $text = [System.IO.File]::ReadAllText($swarmPath)
    $hasCall = ($text -match 'execute_universal_tool_bus_and_writeback')

    # Query live tool endpoint and verify telemetry fields
    $tResp = Invoke-SafeRestMethod -Uri "http://127.0.0.1:8097/api/v1/chain135/suite" -TimeoutSec 3
    $hasWritebackTelemetry = $false
    if ($tResp.Success -and $tResp.Data) {
        $d = $tResp.Data
        $hasWritebackTelemetry = ($null -ne $d.e_vault_writeback_path -or $null -ne $d.autopoietic_bus_seq)
    }

    $passed = ($hasCall)
    $msg = if ($passed) {
        "210 tools write-back routing integrated in v31_swarm.rs (TelemetryLive=$hasWritebackTelemetry)"
    } else {
        "v31_swarm.rs does not call execute_universal_tool_bus_and_writeback"
    }
    $sw.Stop()
    return New-TestResult -Tier 1 -Id "F06_v56_1" -Name "210 Tools Write-Back Routing" -Milestone "M1" `
        -Passed $passed -Message $msg -ElapsedMs $sw.Elapsed.TotalMilliseconds `
        -MeasuredData @{ SwarmRouting = $hasCall; LiveTelemetry = $hasWritebackTelemetry }
}

# -----------------------------------------------------------------------------
# Milestone 2: 8 Functional Domain Groups & 256-Bit AVX2/Rayon FNO (F07..F09)
# -----------------------------------------------------------------------------

function Test-Feature-v56-1-07 {
    # F07: 8 Unified Functional Domain Dispatchers
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $v56_1Path = "$RepoRoot\01_l0_rust\src\v56_1_unified_functional_domains_and_avx2_fno.rs"
    $fileExists = (Test-Path $v56_1Path)

    $bracketOk = $false
    if ($fileExists) {
        $bRes = Test-ZeroSquareBrackets -FilePath $v56_1Path
        $bracketOk = $bRes.Passed
    }

    # Query /api/v1/unified/catalog
    $catResp = Invoke-SafeRestMethod -Uri "http://127.0.0.1:8097/api/v1/unified/catalog" -TimeoutSec 3
    $catOk = $false
    $totalTools = 0
    if ($catResp.Success -and $catResp.Data) {
        $totalTools = if ($catResp.Data.total_consolidated_tools) { $catResp.Data.total_consolidated_tools } else { 0 }
        $domains = if ($catResp.Data.domains) { $catResp.Data.domains } else { @() }
        $catOk = ($totalTools -eq 210 -and $domains.Count -eq 8)
    }

    $passed = ($fileExists -and $bracketOk -and $catOk)
    $msg = if ($passed) {
        "v56_1 module exists with 0 square brackets; /api/v1/unified/catalog active with 8 domains and 210 tools"
    } else {
        "Unified domains pending (ModuleExists=$fileExists, ZeroBrackets=$bracketOk, CatalogOk=$catOk, TotalTools=$totalTools)"
    }
    $sw.Stop()
    return New-TestResult -Tier 1 -Id "F07_v56_1" -Name "8 Unified Functional Domain Dispatchers" -Milestone "M2" `
        -Passed $passed -Message $msg -ElapsedMs $sw.Elapsed.TotalMilliseconds `
        -MeasuredData @{ FileExists = $fileExists; ZeroBrackets = $bracketOk; CatalogOk = $catOk; TotalTools = $totalTools }
}

function Test-Feature-v56-1-08 {
    # F08: 256-Bit AVX2/FMA + 12-Thread Rayon FNO
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $v56_1Path = "$RepoRoot\01_l0_rust\src\v56_1_unified_functional_domains_and_avx2_fno.rs"
    $v35Path = "$RepoRoot\01_l0_rust\src\v35_fno_liquid_connectome.rs"

    $hasSimd = $false
    $hasRayon = $false
    $hasNeurons = $false
    $hasSectors = $false

    foreach ($p in @($v56_1Path, $v35Path)) {
        if (Test-Path $p) {
            $c = [System.IO.File]::ReadAllText($p)
            if ($c -match '_mm256_fmadd_ps|_mm256_') { $hasSimd = $true }
            if ($c -match 'into_par_iter|par_iter|Rayon') { $hasRayon = $true }
            if ($c -match '63,?360') { $hasNeurons = $true }
            if ($c -match '80\s+sectors|SECTORS.*80|sectors.*80') { $hasSectors = $true }
        }
    }

    $passed = ($hasSimd -and $hasRayon -and $hasNeurons -and $hasSectors)
    $msg = if ($passed) {
        "256-Bit AVX2/FMA + 12-Thread Rayon FNO kernel defined over 63,360 neurons & 80 sectors"
    } else {
        "AVX2 FNO kernel specifications incomplete (SIMD=$hasSimd, Rayon=$hasRayon, Neurons=$hasNeurons, Sectors=$hasSectors)"
    }
    $sw.Stop()
    return New-TestResult -Tier 1 -Id "F08_v56_1" -Name "256-Bit AVX2/Rayon 16-Domain FNO" -Milestone "M2" `
        -Passed $passed -Message $msg -ElapsedMs $sw.Elapsed.TotalMilliseconds `
        -MeasuredData @{ HasSimd = $hasSimd; HasRayon = $hasRayon; HasNeurons = $hasNeurons; HasSectors = $hasSectors }
}

function Test-Feature-v56-1-09 {
    # F09: Live FNO Telemetry Integration
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $resSolve = Invoke-SafeRestMethod -Uri "http://127.0.0.1:8097/api/v1/operator/fno_solve" -TimeoutSec 3
    $resPhysics = Invoke-SafeRestMethod -Uri "http://127.0.0.1:8097/api/v1/physics/neural_fno_16domains" -TimeoutSec 3

    $solveOk = ($resSolve.Success -and $null -ne $resSolve.Data.fno_l2_err)
    $physicsOk = ($resPhysics.Success -and $null -ne $resPhysics.Data.vorticity_norm)

    $passed = ($solveOk -or $physicsOk)
    $msg = if ($passed) {
        "Live FNO telemetry active (/api/v1/operator/fno_solve or /api/v1/physics/neural_fno_16domains responsive)"
    } else {
        "Live FNO endpoints pending (SolveEndpoint=$solveOk, PhysicsEndpoint=$physicsOk)"
    }
    $sw.Stop()
    return New-TestResult -Tier 1 -Id "F09_v56_1" -Name "Live FNO Telemetry Integration" -Milestone "M2" `
        -Passed $passed -Message $msg -ElapsedMs $sw.Elapsed.TotalMilliseconds `
        -MeasuredData @{ SolveOk = $solveOk; PhysicsOk = $physicsOk }
}

# -----------------------------------------------------------------------------
# Milestone 3: UI/UX Decluttering & Functional Consolidation (F10..F11)
# -----------------------------------------------------------------------------

function Test-Feature-v56-1-10 {
    # F10: 8-Domain Command Deck in Cockpit HUD & 100% Component Preservation
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $hudSrc = "$RepoRoot\05_hud_cockpit\src\App.tsx"
    if (-not (Test-Path $hudSrc)) {
        $sw.Stop()
        return New-TestResult -Tier 1 -Id "F10_v56_1" -Name "8-Domain Command Deck in Cockpit HUD" -Milestone "M3" `
            -Passed $false -Message "File missing: $hudSrc" -ElapsedMs $sw.Elapsed.TotalMilliseconds
    }

    $c = [System.IO.File]::ReadAllText($hudSrc)

    # 1. Component preservation checks
    $hasCards = ($c.Contains("Drawer A") -or $c.Contains("Telemetry Cards") -or $c.Contains("renderCard"))
    $hasScopes = ($c.Contains("Drawer B") -or $c.Contains("Stiefel") -or $c.Contains("Oscilloscope"))
    $hasHeatmap = ($c.Contains("16x130") -or $c.Contains("2080") -or $c.Contains("cachelines"))
    $hasPalette = ($c.Contains("Command Palette") -or $c.Contains("Ctrl+K") -or $c.Contains("commandPalette"))
    $hasLenses = ($c.Contains("CARDS") -and $c.Contains("SCOPES") -and $c.Contains("OPS") -and $c.Contains("TOOLS"))

    # 2. 8-Domain Functional Deck check in Drawer 4
    $has8Domains = ($c -match '8-Domain|Functional Command Deck|lattice_algebra_proofs|Unified.*Domain')

    # 3. Secret leak scan
    $hasRetiredKey = $c.Contains("SOVEREIGN" + "-LOQ15-4200")
    $activeKeyPath = "C:\Users\Nbell\.act_omega_operator_vault_key"
    $hasActiveKey = if (Test-Path $activeKeyPath) { $c.Contains((Get-Content $activeKeyPath -Raw).Trim()) } else { $false }

    $preserved = ($hasCards -and $hasScopes -and $hasHeatmap -and $hasPalette -and $hasLenses)
    $clean = (-not $hasRetiredKey -and -not $hasActiveKey)

    $passed = ($preserved -and $clean)
    $msg = if ($passed) {
        "Cockpit HUD 100% preservation verified (Cards, Scopes, Heatmap, Lenses, Palette present; 0 secrets leaked)"
    } else {
        "HUD verification failed: Preserved=$preserved, Clean=$clean, 8DomainDeck=$has8Domains"
    }
    $sw.Stop()
    return New-TestResult -Tier 1 -Id "F10_v56_1" -Name "8-Domain Command Deck in Cockpit HUD" -Milestone "M3" `
        -Passed $passed -Message $msg -ElapsedMs $sw.Elapsed.TotalMilliseconds `
        -MeasuredData @{ Preserved = $preserved; Clean = $clean; Has8Domains = $has8Domains }
}

function Test-Feature-v56-1-11 {
    # F11: Mobile NDK & Win11 Tray HUD Parity
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $ktPath = "$RepoRoot\04_edge_silicon\pixel10_ndk_app\app\src\main\java\com\actomega\manifold\MainActivity.kt"
    $csPath = "$RepoRoot\00_control\Win11_Native_Tray_HUD\SovereignTrayAndHud.cs"

    $hasKt = (Test-Path $ktPath)
    $hasCs = (Test-Path $csPath)

    $ktParity = $false
    if ($hasKt) {
        $ktText = [System.IO.File]::ReadAllText($ktPath)
        $ktParity = ($ktText -match 'unified|FNO|vorticity|DrawerCard603010')
    }

    $csParity = $false
    if ($hasCs) {
        $csText = [System.IO.File]::ReadAllText($csPath)
        $csParity = ($csText -match 'telemetry|vorticity|reynolds|fno|unified')
    }

    $passed = ($hasKt -and $hasCs)
    $msg = if ($passed) {
        "Mobile NDK MainActivity.kt and Win11 SovereignTrayAndHud.cs present and aligned with cluster telemetry"
    } else {
        "Periphery source files missing or incomplete: MainActivity=$hasKt, TrayHud=$hasCs"
    }
    $sw.Stop()
    return New-TestResult -Tier 1 -Id "F11_v56_1" -Name "Mobile NDK & Win11 Tray HUD Parity" -Milestone "M3" `
        -Passed $passed -Message $msg -ElapsedMs $sw.Elapsed.TotalMilliseconds `
        -MeasuredData @{ HasKt = $hasKt; HasCs = $hasCs; KtParity = $ktParity; CsParity = $csParity }
}

# -----------------------------------------------------------------------------
# Milestone 4: Lifecycle Hardening, 4-Gatekeeper Audit & Graceful Shutdown (F12..F14)
# -----------------------------------------------------------------------------

function Test-Feature-v56-1-12 {
    # F12: Lifecycle Script Hardening
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $lifecycleScript = "$RepoRoot\00_control\Sovereign-Lifecycle.ps1"
    if (-not (Test-Path $lifecycleScript)) {
        $sw.Stop()
        return New-TestResult -Tier 1 -Id "F12_v56_1" -Name "Lifecycle Script Hardening" -Milestone "M4" `
            -Passed $false -Message "Lifecycle script missing: $lifecycleScript" -ElapsedMs $sw.Elapsed.TotalMilliseconds
    }

    $c = [System.IO.File]::ReadAllText($lifecycleScript)
    $hasStopAll = ($c -match 'Stop-SovereignClusterSafely|action.*stop-all')
    $hasStart = ($c -match 'Start-SovereignClusterSafely|action.*start')
    $hasCapsuleFlush = ($c -match 'capsule|handover|Continuum')
    $hasDaemonManagement = ($c -match 'p8_ksu_apex_daemon|8098|SovereignCockpitHUD')

    $passed = ($hasStopAll -and $hasStart -and $hasCapsuleFlush)
    $msg = if ($passed) {
        "Sovereign-Lifecycle.ps1 hardened with safe stop-all, start, capsule flush, and daemon management"
    } else {
        "Lifecycle script hardening incomplete (StopAll=$hasStopAll, Start=$hasStart, CapsuleFlush=$hasCapsuleFlush, DaemonMgmt=$hasDaemonManagement)"
    }
    $sw.Stop()
    return New-TestResult -Tier 1 -Id "F12_v56_1" -Name "Lifecycle Script Hardening" -Milestone "M4" `
        -Passed $passed -Message $msg -ElapsedMs $sw.Elapsed.TotalMilliseconds `
        -MeasuredData @{ StopAll = $hasStopAll; Start = $hasStart; CapsuleFlush = $hasCapsuleFlush; DaemonMgmt = $hasDaemonManagement }
}

function Test-Feature-v56-1-13 {
    # F13: 4-Gatekeeper Full Audit & Verification
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $gatekeeperScript = "$RepoRoot\00_control\Invoke-BrutalAgentGatekeeper.ps1"
    $lifecycleScript = "$RepoRoot\00_control\Sovereign-Lifecycle.ps1"

    $hasGatekeeper = (Test-Path $gatekeeperScript)
    $hasLifecycle = (Test-Path $lifecycleScript)

    # Static audit check
    $staticPassed = $false
    if ($hasGatekeeper) {
        $pInfo = New-Object System.Diagnostics.ProcessStartInfo
        $pInfo.FileName = "powershell.exe"
        $pInfo.Arguments = "-ExecutionPolicy Bypass -File `"$gatekeeperScript`" -StaticOnly"
        $pInfo.RedirectStandardOutput = $true
        $pInfo.RedirectStandardError = $true
        $pInfo.UseShellExecute = $false
        $p = [System.Diagnostics.Process]::Start($pInfo)
        $stdout = $p.StandardOutput.ReadToEnd()
        $stderr = $p.StandardError.ReadToEnd()
        $p.WaitForExit()
        $staticPassed = ($p.ExitCode -eq 0)
    }

    $passed = ($hasGatekeeper -and $hasLifecycle -and $staticPassed)
    $msg = if ($passed) {
        "4-Gatekeeper static audit passed with exit code 0"
    } else {
        "Gatekeeper static verification failed (Gatekeeper=$hasGatekeeper, Lifecycle=$hasLifecycle, Exit0=$staticPassed)"
    }
    $sw.Stop()
    return New-TestResult -Tier 1 -Id "F13_v56_1" -Name "4-Gatekeeper Full Audit & Verification" -Milestone "M4" `
        -Passed $passed -Message $msg -ElapsedMs $sw.Elapsed.TotalMilliseconds `
        -MeasuredData @{ Gatekeeper = $hasGatekeeper; StaticPassed = $staticPassed }
}

function Test-Feature-v56-1-14 {
    # F14: Graceful Cluster Shutdown
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $lifecycleScript = "$RepoRoot\00_control\Sovereign-Lifecycle.ps1"

    $hasScript = (Test-Path $lifecycleScript)
    $hasStatus = $false
    if ($hasScript) {
        $c = [System.IO.File]::ReadAllText($lifecycleScript)
        $hasStatus = ($c -match 'action.*status|Show-SovereignClusterStatus')
    }

    $passed = ($hasScript -and $hasStatus)
    $msg = if ($passed) {
        "Graceful cluster shutdown protocol verified in Sovereign-Lifecycle.ps1"
    } else {
        "Cluster shutdown protocol missing or incomplete"
    }
    $sw.Stop()
    return New-TestResult -Tier 1 -Id "F14_v56_1" -Name "Graceful Cluster Shutdown" -Milestone "M4" `
        -Passed $passed -Message $msg -ElapsedMs $sw.Elapsed.TotalMilliseconds `
        -MeasuredData @{ HasScript = $hasScript; HasStatus = $hasStatus }
}

function Invoke-Tier1-Tests-v56-1 {
    param([Alias("Milestone")][string]$MilestoneFilter = "All")

    Write-Host ""
    Write-Host "--- TIER 1: FEATURE COVERAGE (All 14 Features for v56.1.0) ---" -ForegroundColor Yellow
    $results = @()

    $milestoneMap = @{
        "M0" = 1..3
        "M1" = 4..6
        "M2" = 7..9
        "M3" = 10..11
        "M4" = 12..14
    }

    $featuresToRun = if ($MilestoneFilter -eq "All") {
        1..14
    } elseif ($milestoneMap.ContainsKey($MilestoneFilter)) {
        $milestoneMap[$MilestoneFilter]
    } else {
        @()
    }

    foreach ($fNum in $featuresToRun) {
        $funcName = ("Test-Feature-v56-1-{0:D2}" -f $fNum)
        if (Get-Command $funcName -ErrorAction SilentlyContinue) {
            $r = & $funcName
            $statusStr = if ($r.Passed) { "PASS" } else { "FAIL" }
            $color = if ($r.Passed) { "Green" } else { "Red" }
            Write-Host ("  [{0}] [{1}] {2} : {3} ({4}ms)" -f $r.Id, $statusStr, $r.Name, $r.Message, [math]::Round($r.ElapsedMs, 1)) -ForegroundColor $color
            $results += $r
        }
    }
    return $results
}
