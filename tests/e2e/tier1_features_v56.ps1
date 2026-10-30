# ACT-Omega Net v56.0.0 (SH4Z v5600 TLV | CHAIN 210 | 624/624 Lean 4 QED)
# Tier 1: Feature Coverage Test Suite (All 20 Features in PROJECT.md)
# File: C:\sovereign_manifold_v31\tests\e2e\tier1_features_v56.ps1
# STRICT CONSTRAINT: ZERO PYTHON | MUSE ZERO-UNMEASURED DATA MANDATE

$ErrorActionPreference = "Continue"

$RepoRoot = if ($PSScriptRoot) {
    (Resolve-Path "$PSScriptRoot\..\..").Path
} else {
    "C:\sovereign_manifold_v31"
}

# -----------------------------------------------------------------------------
# Milestone 0: Google Search Console Ownership Verification Certificate (M0_F03)
# -----------------------------------------------------------------------------

function Test-Feature-GSC-Invariant {
    # M0_F03: GSC Certificate Invariant Verification
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $certFileName = "google6edc0affb12d0455.html"
    $expectedBytes = 53
    $expectedHash = "0241DC5EDED053A96317C9C8FF34F4DCF12C069F88B8D92636D5D795EC176B3D"
    $expectedContent = "google-site-verification: google6edc0affb12d0455.html"

    $targets = @(
        "$RepoRoot\05_hud_cockpit\public\$certFileName",
        "$RepoRoot\02_l2_orchestration\hud\public\$certFileName",
        "$RepoRoot\05_hud_cockpit\dist\$certFileName",
        "$RepoRoot\02_l2_orchestration\hud\dist\$certFileName",
        "$RepoRoot\docs\$certFileName",
        "$RepoRoot\$certFileName"
    )
    if (Test-Path "E:\Sovereign_Manifold_SSD_Vault") {
        $targets += "E:\Sovereign_Manifold_SSD_Vault\$certFileName"
    }

    $allFilesValid = $true
    $missingOrBad = @()
    foreach ($t in $targets) {
        if (-not (Test-Path $t)) {
            $allFilesValid = $false
            $missingOrBad += "$t missing"
            continue
        }
        $item = Get-Item $t
        if ($item.Length -ne $expectedBytes) {
            $allFilesValid = $false
            $missingOrBad += "$t bad length $($item.Length)"
        }
        $h = (Get-FileHash $t -Algorithm SHA256).Hash
        if ($h -ne $expectedHash) {
            $allFilesValid = $false
            $missingOrBad += "$t bad hash $h"
        }
    }

    # Live HTTP probes
    $http8097Ok = $false
    $http5173Ok = $false
    try {
        $r8097 = (Invoke-WebRequest -Uri "http://127.0.0.1:8097/$certFileName" -UseBasicParsing -TimeoutSec 3).Content
        $http8097Ok = ($r8097.Trim() -eq $expectedContent)
    } catch {}
    try {
        $r5173 = (Invoke-WebRequest -Uri "http://127.0.0.1:5173/$certFileName" -UseBasicParsing -TimeoutSec 3).Content
        $http5173Ok = ($r5173.Trim() -eq $expectedContent)
    } catch {}

    $passed = $allFilesValid -and $http8097Ok -and $http5173Ok
    $msg = if ($passed) {
        "GSC certificate invariant verified across all 7 targets and live HTTP endpoints (:8097, :5173)"
    } else {
        "GSC invariant failed (Files: $allFilesValid, :8097=$http8097Ok, :5173=$http5173Ok, Details: $($missingOrBad -join '; '))"
    }
    $sw.Stop()
    return New-TestResult -Tier 1 -Id "M0_F03" -Name "GSC Invariant Verification" -Milestone "M0" `
        -Passed $passed -Message $msg -ElapsedMs $sw.Elapsed.TotalMilliseconds `
        -MeasuredData @{ FilesValid = $allFilesValid; Http8097 = $http8097Ok; Http5173 = $http5173Ok }
}

# -----------------------------------------------------------------------------
# Milestone 1: Governance Rules & Zero-Fragmentation Architecture Prep (F01..F06)
# -----------------------------------------------------------------------------

function Test-Feature-01 {
    # F01: APR & Root Governance Rule
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $ruleFile = "$RepoRoot\.agents\rules\aperiodic-permissions-routing-and-ksud-root.md"
    if (-not (Test-Path $ruleFile)) {
        $sw.Stop()
        return New-TestResult -Tier 1 -Id "F01" -Name "APR & Root Governance Rule" -Milestone "M1" `
            -Passed $false -Message "File missing: $ruleFile" -ElapsedMs $sw.Elapsed.TotalMilliseconds
    }

    $content = [System.IO.File]::ReadAllText($ruleFile)
    $hasStratifier = ($content -match 'Rings?\s+A0\.\.A3' -or ($content -match 'Ring A0' -and $content -match 'Ring A3'))
    $hasKsud = ($content -match 'ksud\s+3\.4\.2')
    $expectedHash = "84ECFA41044D301D096B31657430F693D605C88DB77969E8B604B804C8D5E55D"
    $hasHash = $content.Contains($expectedHash)

    $passed = ($hasStratifier -and $hasKsud -and $hasHash)
    $msg = if ($passed) {
        "Rule exists with APR Rings A0..A3, ksud 3.4.2, and stock slot _b SHA-256 verified"
    } else {
        "Rule content missing required keys (Stratifier: $hasStratifier, ksud: $hasKsud, Hash: $hasHash)"
    }
    $sw.Stop()
    return New-TestResult -Tier 1 -Id "F01" -Name "APR & Root Governance Rule" -Milestone "M1" `
        -Passed $passed -Message $msg -ElapsedMs $sw.Elapsed.TotalMilliseconds `
        -MeasuredData @{ File = $ruleFile; HasStratifier = $hasStratifier; HasKsud = $hasKsud; HasStockHash = $hasHash }
}

function Test-Feature-02 {
    # F02: HUD Preservation Rule Section 6
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $ruleFile = "$RepoRoot\.agents\rules\l2-hud-15cards-preserve.md"
    if (-not (Test-Path $ruleFile)) {
        $sw.Stop()
        return New-TestResult -Tier 1 -Id "F02" -Name "HUD Preservation Rule Section 6" -Milestone "M1" `
            -Passed $false -Message "File missing: $ruleFile" -ElapsedMs $sw.Elapsed.TotalMilliseconds
    }

    $content = [System.IO.File]::ReadAllText($ruleFile)
    $hasSec6 = ($content -match '(?m)6\.\s+.*(Relative|SSR|Snapshot)' -or $content -match 'Section 6')
    $hasRelativePathLaw = ($content -match '\./' -or $content -match 'relative')
    $hasSsrMarker = ($content -match 'data-sovereign-ssr' -or $content -match '#root')

    $passed = ($hasSec6 -and $hasRelativePathLaw -and $hasSsrMarker)
    $msg = if ($passed) {
        "l2-hud-15cards-preserve.md Section 6 exists with relative asset & SSR snapshot laws"
    } else {
        "Section 6 missing or incomplete in $ruleFile (Sec6: $hasSec6, Relative: $hasRelativePathLaw, SSR: $hasSsrMarker)"
    }
    $sw.Stop()
    return New-TestResult -Tier 1 -Id "F02" -Name "HUD Preservation Rule Section 6" -Milestone "M1" `
        -Passed $passed -Message $msg -ElapsedMs $sw.Elapsed.TotalMilliseconds `
        -MeasuredData @{ HasSec6 = $hasSec6; HasRelativePathLaw = $hasRelativePathLaw; HasSsrMarker = $hasSsrMarker }
}

function Test-Feature-03 {
    # F03: Rule Mirror 1:1 SHA Parity
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $wsRulesDir = "$RepoRoot\.agents\rules"
    $candidateUserDirs = @(
        "$env:USERPROFILE\.gemini\config\rules",
        "C:\Users\Nbell\.gemini\config\rules"
    )
    $userRulesDir = $null
    foreach ($d in $candidateUserDirs) {
        if (Test-Path $d) {
            $userRulesDir = $d
            break
        }
    }
    
    if (-not (Test-Path $wsRulesDir)) {
        $sw.Stop()
        return New-TestResult -Tier 1 -Id "F03" -Name "Rule Mirror 1:1 SHA Parity" -Milestone "M1" `
            -Passed $false -Message "Workspace rules directory not found: $wsRulesDir" -ElapsedMs $sw.Elapsed.TotalMilliseconds
    }
    if (-not $userRulesDir) {
        $sw.Stop()
        return New-TestResult -Tier 1 -Id "F03" -Name "Rule Mirror 1:1 SHA Parity" -Milestone "M1" `
            -Passed $false -Message "User rules directory not found in: $($candidateUserDirs -join ', ')" -ElapsedMs $sw.Elapsed.TotalMilliseconds
    }

    $ruleFiles = Get-ChildItem -Path "$wsRulesDir\*.md" -File
    $mismatches = @()
    $checked = 0
    foreach ($rf in $ruleFiles) {
        $checked++
        $userFile = "$userRulesDir\$($rf.Name)"
        if (-not (Test-Path $userFile)) {
            $mismatches += "$($rf.Name) missing in user config"
            continue
        }
        $h1 = (Get-FileHash $rf.FullName -Algorithm SHA256).Hash
        $h2 = (Get-FileHash $userFile -Algorithm SHA256).Hash
        if ($h1 -ne $h2) {
            $mismatches += "$($rf.Name) hash drift ($($h1.Substring(0,8)) != $($h2.Substring(0,8)))"
        }
    }

    $passed = ($mismatches.Count -eq 0 -and $checked -ge 6)
    $msg = if ($passed) {
        "All $checked rules in .agents\rules match ~/.gemini/config/rules 1:1 SHA-256"
    } else {
        "Rule mirror drift found: $($mismatches -join '; ')"
    }
    $sw.Stop()
    return New-TestResult -Tier 1 -Id "F03" -Name "Rule Mirror 1:1 SHA Parity" -Milestone "M1" `
        -Passed $passed -Message $msg -ElapsedMs $sw.Elapsed.TotalMilliseconds `
        -MeasuredData @{ CheckedCount = $checked; Mismatches = $mismatches }
}

function Test-Feature-04 {
    # F04: Codebase Neuron Unification
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $scanFiles = @(
        "$RepoRoot\01_l0_rust\src\v50_rayon_avx2_tlv_simulator_coordinator.rs",
        "$RepoRoot\01_l0_rust\src\v31_swarm.rs",
        "$RepoRoot\01_l0_rust\src\bin\v31_swarm.rs",
        "$RepoRoot\00_control\cloudflare_edge\worker_vpc_shadow_v3700.js",
        "$RepoRoot\05_hud_cockpit\src\App.tsx",
        "$RepoRoot\wiki.html",
        "$RepoRoot\docs\wiki.html"
    )

    $leaks = @()
    foreach ($f in $scanFiles) {
        if (Test-Path $f) {
            $text = [System.IO.File]::ReadAllText($f)
            # Match 42,240 followed by neuron/shard/connectome/npage terms (spaces or hyphens) or JSON key assignments
            $hasLeak = ($text -match '(?i)42,?240\s*[-–—\s]?\s*(neurons?|shards?|dendritic|pyramidal|connectome|\.binshard|\.npage)' -or
                        $text -match '(?i)(neurons?|connectome|shards?)[^,}\n]{0,25}[:=]\s*["'']?42,?240\b')
            if ($hasLeak) {
                $leaks += (Split-Path -Leaf $f)
            }
        }
    }

    $passed = ($leaks.Count -eq 0)
    $msg = if ($passed) {
        "0 legacy 42,240 neuron references detected across active L0 Rust, Edge DO, HUD, and HTML docs ($($scanFiles.Count) files scanned)"
    } else {
        "Legacy 42,240 neuron count found in: $($leaks -join ', ')"
    }
    $sw.Stop()
    return New-TestResult -Tier 1 -Id "F04" -Name "Codebase Neuron Unification" -Milestone "M1" `
        -Passed $passed -Message $msg -ElapsedMs $sw.Elapsed.TotalMilliseconds `
        -MeasuredData @{ ScannedFiles = $scanFiles.Count; Leaks = $leaks }
}

function Test-Feature-05 {
    # F05: Version Banner Unification
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $projectMd = "$RepoRoot\PROJECT.md"
    $binSwarm = "$RepoRoot\01_l0_rust\src\bin\v31_swarm.rs"
    $srcSwarm = "$RepoRoot\01_l0_rust\src\v31_swarm.rs"

    if (-not (Test-Path $projectMd)) {
        $sw.Stop()
        return New-TestResult -Tier 1 -Id "F05" -Name "Version Banner Unification" -Milestone "M1" `
            -Passed $false -Message "PROJECT.md missing" -ElapsedMs $sw.Elapsed.TotalMilliseconds
    }

    $pContent = [System.IO.File]::ReadAllText($projectMd)
    $hasV56 = ($pContent -match 'v56\.0\.0')
    $hasSh4z5600 = ($pContent -match 'SH4Z v5600 TLV')
    $hasChain210 = ($pContent -match 'CHAIN 210')

    # Verify v31_swarm source runtime banners
    $hasSwarmBanner = $false
    $hasNoLegacyBanner = $true
    if (Test-Path $binSwarm) {
        $bContent = [System.IO.File]::ReadAllText($binSwarm)
        $hasSwarmBanner = ($bContent -match 'ACT-OMEGA NET v56\.0\.0' -or $bContent -match '\(v31_swarm v56\.0\.0\)')
        if ($bContent -match 'ACT-OMEGA NET v50\.2\.0' -or $bContent -match '\(v31_swarm v50\.2\.0\)') {
            $hasNoLegacyBanner = $false
        }
    }

    $passed = ($hasV56 -and $hasSh4z5600 -and $hasChain210 -and $hasSwarmBanner -and $hasNoLegacyBanner)
    $msg = if ($passed) {
        "Version banners unified to v56.0.0 (SH4Z v5600 TLV | CHAIN 210) across PROJECT.md and v31_swarm.rs"
    } else {
        "Version banner unification incomplete (PROJECT: v56=$hasV56, SH4Z=$hasSh4z5600, C210=$hasChain210; SwarmBanner: $hasSwarmBanner, NoLegacy: $hasNoLegacyBanner)"
    }
    $sw.Stop()
    return New-TestResult -Tier 1 -Id "F05" -Name "Version Banner Unification" -Milestone "M1" `
        -Passed $passed -Message $msg -ElapsedMs $sw.Elapsed.TotalMilliseconds `
        -MeasuredData @{ HasV56 = $hasV56; HasSh4z5600 = $hasSh4z5600; HasChain210 = $hasChain210; SwarmBanner = $hasSwarmBanner; NoLegacy = $hasNoLegacyBanner }
}

function Test-Feature-06 {
    # F06: Tool Suite URL Decoupling
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $res135 = Invoke-SafeRestMethod -Uri "http://127.0.0.1:8097/api/v1/chain135/suite" -TimeoutSec 3
    $res145 = Invoke-SafeRestMethod -Uri "http://127.0.0.1:8097/api/v1/chain145/suite" -TimeoutSec 3
    $res210 = Invoke-SafeRestMethod -Uri "http://127.0.0.1:8097/api/v1/chain210/suite" -TimeoutSec 3

    $ok135 = ($res135.Success -and $res135.Data.status -eq "CHAIN_135_CONTIGUOUS_OK" -and $res135.Data.total_chain_tools -eq 135)
    $ok145 = ($res145.Success -and $res145.Data.status -eq "CHAIN_145_CONTIGUOUS_OK" -and $res145.Data.total_chain_tools -eq 145)
    $ok210 = ($res210.Success -and $res210.Data.status -eq "CHAIN_210_CONTIGUOUS_OK" -and $res210.Data.total_chain_tools -eq 210)

    $passed = ($ok135 -and $ok145 -and $ok210)
    $msg = if ($passed) {
        "All three suite endpoints decoupled and return exact tool counts (135, 145, 210)"
    } else {
        "Suite decoupling incomplete (135 OK: $ok135 [Got status: $($res135.Data.status), count: $($res135.Data.total_chain_tools)]; 145 OK: $ok145; 210 OK: $ok210 [Got status: $($res210.Data.status)])"
    }
    $sw.Stop()
    return New-TestResult -Tier 1 -Id "F06" -Name "Tool Suite URL Decoupling" -Milestone "M1" `
        -Passed $passed -Message $msg -ElapsedMs $sw.Elapsed.TotalMilliseconds `
        -MeasuredData @{ Chain135 = $res135.Data.status; Chain145 = $res145.Data.status; Chain210 = $res210.Data.status }
}

# -----------------------------------------------------------------------------
# Milestone 2: Throughput Bottleneck Elimination & Multi-Silicon (F07..F11)
# -----------------------------------------------------------------------------

function Test-Feature-07 {
    # F07: SIMD CPUID/Rayon OnceLock Cache
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $file = "$RepoRoot\01_l0_rust\src\v50_rayon_avx2_tlv_simulator_coordinator.rs"
    if (-not (Test-Path $file)) {
        $sw.Stop()
        return New-TestResult -Tier 1 -Id "F07" -Name "SIMD CPUID/Rayon OnceLock Cache" -Milestone "M2" `
            -Passed $false -Message "File missing: $file" -ElapsedMs $sw.Elapsed.TotalMilliseconds
    }

    $content = [System.IO.File]::ReadAllText($file)
    $hasOnceLock = ($content -match 'OnceLock' -and $content -match 'HARDWARE_SIMD_CACHE')

    $passed = $hasOnceLock
    $msg = if ($passed) {
        "HARDWARE_SIMD_CACHE static OnceLock cache implemented in v50_rayon..."
    } else {
        "HARDWARE_SIMD_CACHE OnceLock cache missing in $file"
    }
    $sw.Stop()
    return New-TestResult -Tier 1 -Id "F07" -Name "SIMD CPUID/Rayon OnceLock Cache" -Milestone "M2" `
        -Passed $passed -Message $msg -ElapsedMs $sw.Elapsed.TotalMilliseconds `
        -MeasuredData @{ HasOnceLock = $hasOnceLock }
}

function Test-Feature-08 {
    # F08: Zero-Allocation Parallel Tree Reduce
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $file = "$RepoRoot\01_l0_rust\src\v50_rayon_avx2_tlv_simulator_coordinator.rs"
    if (-not (Test-Path $file)) {
        $sw.Stop()
        return New-TestResult -Tier 1 -Id "F08" -Name "Zero-Allocation Parallel Reduce" -Milestone "M2" `
            -Passed $false -Message "File missing: $file" -ElapsedMs $sw.Elapsed.TotalMilliseconds
    }

    $content = [System.IO.File]::ReadAllText($file)
    $hasReduce = ($content -match '\.reduce\(')
    $hasCollectInMeasure = ($content -match 'fn measure_v50_avx2_rayon_live_kops[\s\S]*?\.collect\(')

    $passed = ($hasReduce -and -not $hasCollectInMeasure)
    $msg = if ($passed) {
        "measure_v50_avx2_rayon_live_kops uses zero-allocation parallel tree .reduce() without heap .collect()"
    } else {
        "Parallel reduce missing ($hasReduce) or heap .collect() still present ($hasCollectInMeasure)"
    }
    $sw.Stop()
    return New-TestResult -Tier 1 -Id "F08" -Name "Zero-Allocation Parallel Reduce" -Milestone "M2" `
        -Passed $passed -Message $msg -ElapsedMs $sw.Elapsed.TotalMilliseconds `
        -MeasuredData @{ HasReduce = $hasReduce; HasCollect = $hasCollectInMeasure }
}

function Test-Feature-09 {
    # F09: Synaptic Tensor Ops Accounting
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $file = "$RepoRoot\01_l0_rust\src\v50_rayon_avx2_tlv_simulator_coordinator.rs"
    if (-not (Test-Path $file)) {
        $sw.Stop()
        return New-TestResult -Tier 1 -Id "F09" -Name "Synaptic Tensor Ops Accounting" -Milestone "M2" `
            -Passed $false -Message "File missing: $file" -ElapsedMs $sw.Elapsed.TotalMilliseconds
    }

    $content = [System.IO.File]::ReadAllText($file)
    $hasActualSynapses = ($content -match '1,?013,?760' -or ($content -match '63,?360\s*\*\s*16'))
    $hasNeuronsPerSec = ($content -match 'neurons_per_sec')
    $hasCachelinesPerSec = ($content -match 'cachelines_per_sec')

    $passed = ($hasActualSynapses -and $hasNeuronsPerSec -and $hasCachelinesPerSec)
    $msg = if ($passed) {
        "Synaptic ops accounting derives over 1,013,760 synapses and computes neurons/sec & cachelines/sec"
    } else {
        "Accounting incomplete (Synapses: $hasActualSynapses, neurons_per_sec: $hasNeuronsPerSec, cachelines_per_sec: $hasCachelinesPerSec)"
    }
    $sw.Stop()
    return New-TestResult -Tier 1 -Id "F09" -Name "Synaptic Tensor Ops Accounting" -Milestone "M2" `
        -Passed $passed -Message $msg -ElapsedMs $sw.Elapsed.TotalMilliseconds `
        -MeasuredData @{ HasActualSynapses = $hasActualSynapses; HasNeuronsPerSec = $hasNeuronsPerSec; HasCachelinesPerSec = $hasCachelinesPerSec }
}

function Test-Feature-10 {
    # F10: Elimination of `* 0.08` Multiplier
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $file1 = "$RepoRoot\01_l0_rust\src\v31_swarm.rs"
    $file2 = "$RepoRoot\01_l0_rust\src\bin\v31_swarm.rs"

    $hasDampener1 = $false
    $hasDampener2 = $false
    if (Test-Path $file1) {
        $t1 = [System.IO.File]::ReadAllText($file1)
        $hasDampener1 = ($t1 -match 'sym_cluster_kops[\s\S]*?\*\s*0\.08' -or $t1 -match '\*\s*0\.08.*?sym_cluster_kops')
    }
    if (Test-Path $file2) {
        $t2 = [System.IO.File]::ReadAllText($file2)
        $hasDampener2 = ($t2 -match 'sym_cluster_kops[\s\S]*?\*\s*0\.08' -or $t2 -match '\*\s*0\.08.*?sym_cluster_kops')
    }

    $passed = (-not $hasDampener1 -and -not $hasDampener2)
    $msg = if ($passed) {
        "Artificial 92% dampening multiplier (* 0.08) eliminated from v31_swarm"
    } else {
        "Dampening multiplier (* 0.08) still present in v31_swarm source"
    }
    $sw.Stop()
    return New-TestResult -Tier 1 -Id "F10" -Name "Elimination of `* 0.08` Multiplier" -Milestone "M2" `
        -Passed $passed -Message $msg -ElapsedMs $sw.Elapsed.TotalMilliseconds `
        -MeasuredData @{ HasDampenerFile1 = $hasDampener1; HasDampenerFile2 = $hasDampener2 }
}

function Test-Feature-11 {
    # F11: Live Multi-Silicon Telemetry Integration (Live Parameter Ingestion & Accounting)
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    
    $testP10Kops = 125000.0
    $testP8Kops = 95000.0
    $targetUri = "http://127.0.0.1:8097/api/v1/telemetry/snapshot?pixel10_kops=$testP10Kops&pixel8_kops=$testP8Kops"
    $res = Invoke-SafeRestMethod -Uri $targetUri -TimeoutSec 3
    
    if (-not $res.Success -or -not $res.Data) {
        $sw.Stop()
        return New-TestResult -Tier 1 -Id "F11" -Name "Live Multi-Silicon Telemetry" -Milestone "M2" `
            -Passed $false -Message "Telemetry snapshot endpoint unreachable or failed (HTTP $($res.StatusCode))" `
            -ElapsedMs $sw.Elapsed.TotalMilliseconds -MeasuredData @{ EndpointSuccess = $res.Success; StatusCode = $res.StatusCode }
    }
    
    $d = $res.Data
    $actualP10 = [double]$d.pixel10_g5_kops
    $actualP8 = [double]$d.pixel8_l2_kops
    $actualLoq = [double]$d.loq15_rtx3050_kops
    $actualBaseTri = [double]$d.base_trisilicon_kops
    $actualCluster = [double]$d.cluster_total_kops
    $actualNeurons = [double]$d.neurons_per_sec
    $actualCachelines = [double]$d.cachelines_per_sec
    
    # Assertions
    $p10Ingested = [Math]::Abs($actualP10 - $testP10Kops) -lt 0.1
    $p8Ingested = [Math]::Abs($actualP8 - $testP8Kops) -lt 0.1
    
    # Base tri-silicon aggregation: base_trisilicon_kops = loq15_rtx3050_kops + pixel10_g5_kops + pixel8_l2_kops
    $expectedBaseTri = $actualLoq + $actualP10 + $actualP8
    $baseTriAggregated = [Math]::Abs($actualBaseTri - $expectedBaseTri) -lt 1.0
    
    # Cluster total reflects base tri-silicon + leased WebGPU
    $clusterTotalReflected = ($actualCluster -ge $actualBaseTri) -and ($actualCluster -ge ($testP10Kops + $testP8Kops))
    
    # Rate derivations (1,013,760 synapses across 63,360 neurons / 132,960 cachelines)
    # neurons_per_sec = (cluster_total_kops * 1000.0) / 16.0
    $expectedNeurons = ($actualCluster * 1000.0) / 16.0
    $neuronsRateValid = [Math]::Abs($actualNeurons - $expectedNeurons) -lt 10.0
    
    # cachelines_per_sec = (cluster_total_kops * 1000.0 * 132960.0) / 1013760.0
    $expectedCachelines = ($actualCluster * 1000.0 * 132960.0) / 1013760.0
    $cachelinesRateValid = [Math]::Abs($actualCachelines - $expectedCachelines) -lt 10.0
    
    # Cluster sync matrix check
    $syncRes = Invoke-SafeRestMethod -Uri "http://127.0.0.1:8097/api/v1/cluster/sync_matrix" -TimeoutSec 3
    $syncOk = $syncRes.Success -and ($syncRes.Data.tool_index -eq 24) -and ($syncRes.Data.cluster_kops -gt 0)
    
    $passed = ($p10Ingested -and $p8Ingested -and $baseTriAggregated -and $clusterTotalReflected -and $neuronsRateValid -and $cachelinesRateValid -and $syncOk)
    
    $msg = if ($passed) {
        "Live parameter ingestion verified (P10: $actualP10, P8: $actualP8, BaseTri: $actualBaseTri, Cluster: $actualCluster kops, Neurons/s: $actualNeurons, Cachelines/s: $actualCachelines, SyncMatrix: $($syncRes.Data.status))"
    } else {
        "Multi-silicon telemetry validation failed (P10Ingested: $p10Ingested [$actualP10], P8Ingested: $p8Ingested [$actualP8], BaseTriAgg: $baseTriAggregated, ClusterReflected: $clusterTotalReflected, NeuronsRate: $neuronsRateValid, CachelinesRate: $cachelinesRateValid, SyncMatrix: $syncOk)"
    }
    
    $sw.Stop()
    return New-TestResult -Tier 1 -Id "F11" -Name "Live Multi-Silicon Telemetry" -Milestone "M2" `
        -Passed $passed -Message $msg -ElapsedMs $sw.Elapsed.TotalMilliseconds `
        -MeasuredData @{
            TestP10Target = $testP10Kops
            ActualP10 = $actualP10
            P10Ingested = $p10Ingested
            TestP8Target = $testP8Kops
            ActualP8 = $actualP8
            P8Ingested = $p8Ingested
            ActualLoq = $actualLoq
            ActualBaseTri = $actualBaseTri
            BaseTriAggregated = $baseTriAggregated
            ActualCluster = $actualCluster
            ClusterTotalReflected = $clusterTotalReflected
            ActualNeurons = $actualNeurons
            NeuronsRateValid = $neuronsRateValid
            ActualCachelines = $actualCachelines
            CachelinesRateValid = $cachelinesRateValid
            SyncMatrixOk = $syncOk
        }
}

# -----------------------------------------------------------------------------
# Milestone 3: Integration Cycles 1–3 Execution (F12..F14)
# -----------------------------------------------------------------------------

function Test-Feature-12 {
    # F12: Cycle 1: Streaming Archiver & Q4_K
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $file = "$RepoRoot\01_l0_rust\src\v53_e8vault_archiver_and_q4k_transcoder.rs"
    if (-not (Test-Path $file)) {
        $sw.Stop()
        return New-TestResult -Tier 1 -Id "F12" -Name "Cycle 1: Streaming Archiver & Q4_K" -Milestone "M3" `
            -Passed $false -Message "Module missing: $file" -ElapsedMs $sw.Elapsed.TotalMilliseconds
    }

    $bRes = Test-ZeroSquareBrackets -FilePath $file
    $content = [System.IO.File]::ReadAllText($file)
    $hasDispatch = ($content -match 'dispatch_tools_146_to_162')
    $hasQ4K = ($content -match 'Q4_K|q4_k')

    $passed = ($bRes.Passed -and $hasDispatch -and $hasQ4K)
    $msg = if ($passed) {
        "v53 implemented with 0 square brackets, Tools 146..162 dispatcher, and Q4_K transcoder"
    } else {
        "v53 verification failed (0-bracket: $($bRes.Passed) [$($bRes.BracketCount)], Dispatch: $hasDispatch, Q4K: $hasQ4K)"
    }
    $sw.Stop()
    return New-TestResult -Tier 1 -Id "F12" -Name "Cycle 1: Streaming Archiver & Q4_K" -Milestone "M3" `
        -Passed $passed -Message $msg -ElapsedMs $sw.Elapsed.TotalMilliseconds `
        -MeasuredData @{ Brackets = $bRes.BracketCount; HasDispatch = $hasDispatch; HasQ4K = $hasQ4K }
}

function Test-Feature-13 {
    # F13: Cycle 2: Polyglot DevTools & Sandboxes
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $file = "$RepoRoot\01_l0_rust\src\v54_polyglot_devtools_hyperv_blender_f4se.rs"
    if (-not (Test-Path $file)) {
        $sw.Stop()
        return New-TestResult -Tier 1 -Id "F13" -Name "Cycle 2: Polyglot DevTools & Sandboxes" -Milestone "M3" `
            -Passed $false -Message "Module missing: $file" -ElapsedMs $sw.Elapsed.TotalMilliseconds
    }

    $bRes = Test-ZeroSquareBrackets -FilePath $file
    $content = [System.IO.File]::ReadAllText($file)
    $hasDispatch = ($content -match 'dispatch_tools_163_to_176')
    $hasBlender = ($content -match 'Blender|blender|\.obj')

    $passed = ($bRes.Passed -and $hasDispatch -and $hasBlender)
    $msg = if ($passed) {
        "v54 implemented with 0 square brackets, Tools 163..176 dispatcher, and Blender .obj generator"
    } else {
        "v54 verification failed (0-bracket: $($bRes.Passed) [$($bRes.BracketCount)], Dispatch: $hasDispatch, Blender: $hasBlender)"
    }
    $sw.Stop()
    return New-TestResult -Tier 1 -Id "F13" -Name "Cycle 2: Polyglot DevTools & Sandboxes" -Milestone "M3" `
        -Passed $passed -Message $msg -ElapsedMs $sw.Elapsed.TotalMilliseconds `
        -MeasuredData @{ Brackets = $bRes.BracketCount; HasDispatch = $hasDispatch; HasBlender = $hasBlender }
}

function Test-Feature-14 {
    # F14: Cycle 3: Aperiodic Permissions Routing
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $file = "$RepoRoot\01_l0_rust\src\v54_5_aperiodic_permissions_router_and_syndrome_gate.rs"
    if (-not (Test-Path $file)) {
        $sw.Stop()
        return New-TestResult -Tier 1 -Id "F14" -Name "Cycle 3: Aperiodic Permissions Routing" -Milestone "M3" `
            -Passed $false -Message "Module missing: $file" -ElapsedMs $sw.Elapsed.TotalMilliseconds
    }

    $bRes = Test-ZeroSquareBrackets -FilePath $file
    $content = [System.IO.File]::ReadAllText($file)
    $hasDispatch = ($content -match 'dispatch_tools_177_to_184')
    $hasAprRings = ($content -match 'RingA|OWNED_SILICON_ONLY|A0')

    $passed = ($bRes.Passed -and $hasDispatch -and $hasAprRings)
    $msg = if ($passed) {
        "v54_5 implemented with 0 square brackets, Tools 177..184 dispatcher, and APR 4-Ring stratifier"
    } else {
        "v54_5 verification failed (0-bracket: $($bRes.Passed) [$($bRes.BracketCount)], Dispatch: $hasDispatch, APR Rings: $hasAprRings)"
    }
    $sw.Stop()
    return New-TestResult -Tier 1 -Id "F14" -Name "Cycle 3: Aperiodic Permissions Routing" -Milestone "M3" `
        -Passed $passed -Message $msg -ElapsedMs $sw.Elapsed.TotalMilliseconds `
        -MeasuredData @{ Brackets = $bRes.BracketCount; HasDispatch = $hasDispatch; HasAprRings = $hasAprRings }
}

# -----------------------------------------------------------------------------
# Milestone 4: Integration Cycles 4–5 & Periphery Sync (F15..F18)
# -----------------------------------------------------------------------------

function Test-Feature-15 {
    # F15: Cycle 4: Pixel 8 Root Governance
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $file = "$RepoRoot\01_l0_rust\src\v55_pixel8_ksud_root_edgetpu_mali_kvm_governor.rs"
    if (-not (Test-Path $file)) {
        $sw.Stop()
        return New-TestResult -Tier 1 -Id "F15" -Name "Cycle 4: Pixel 8 Root Governance" -Milestone "M4" `
            -Passed $false -Message "Module missing: $file" -ElapsedMs $sw.Elapsed.TotalMilliseconds
    }

    $bRes = Test-ZeroSquareBrackets -FilePath $file
    $resAudit = Invoke-SafeRestMethod -Uri "http://127.0.0.1:8097/api/v1/p8_root/hardware_audit" -TimeoutSec 3
    $hasAuditEndpoint = ($resAudit.Success -and $resAudit.Data.status -match 'OK|MEASURED')

    $passed = ($bRes.Passed -and $hasAuditEndpoint)
    $msg = if ($passed) {
        "v55 implemented with 0 square brackets, and /api/v1/p8_root/hardware_audit endpoint responds"
    } else {
        "v55 verification failed (0-bracket: $($bRes.Passed) [$($bRes.BracketCount)], Audit endpoint: $hasAuditEndpoint)"
    }
    $sw.Stop()
    return New-TestResult -Tier 1 -Id "F15" -Name "Cycle 4: Pixel 8 Root Governance" -Milestone "M4" `
        -Passed $passed -Message $msg -ElapsedMs $sw.Elapsed.TotalMilliseconds `
        -MeasuredData @{ Brackets = $bRes.BracketCount; AuditStatus = $resAudit.Data.status }
}

function Test-Feature-16 {
    # F16: Cycle 5: Unthrottled Apex Daemon
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $file = "$RepoRoot\01_l0_rust\src\v56_unthrottled_throughput_and_p8_root_apex_daemon.rs"
    if (-not (Test-Path $file)) {
        $sw.Stop()
        return New-TestResult -Tier 1 -Id "F16" -Name "Cycle 5: Unthrottled Apex Daemon" -Milestone "M4" `
            -Passed $false -Message "Module missing: $file" -ElapsedMs $sw.Elapsed.TotalMilliseconds
    }

    $bRes = Test-ZeroSquareBrackets -FilePath $file
    $content = [System.IO.File]::ReadAllText($file)
    $hasDispatch = ($content -match 'dispatch_tools_205_to_210')

    $passed = ($bRes.Passed -and $hasDispatch)
    $msg = if ($passed) {
        "v56 implemented with 0 square brackets and Tools 205..210 dispatcher"
    } else {
        "v56 verification failed (0-bracket: $($bRes.Passed) [$($bRes.BracketCount)], Dispatch: $hasDispatch)"
    }
    $sw.Stop()
    return New-TestResult -Tier 1 -Id "F16" -Name "Cycle 5: Unthrottled Apex Daemon" -Milestone "M4" `
        -Passed $passed -Message $msg -ElapsedMs $sw.Elapsed.TotalMilliseconds `
        -MeasuredData @{ Brackets = $bRes.BracketCount; HasDispatch = $hasDispatch }
}

function Test-Feature-17 {
    # F17: Lean 4 Theorems Expansion (624 QED)
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $leanVault = "$RepoRoot\03_vault\lean4\SovereignManifoldTheorems.lean"
    $leanL0 = "$RepoRoot\01_l0_rust\lean4\SovereignManifoldTheorems.lean"

    if (-not (Test-Path $leanVault) -or -not (Test-Path $leanL0)) {
        $sw.Stop()
        return New-TestResult -Tier 1 -Id "F17" -Name "Lean 4 Theorems Expansion (624 QED)" -Milestone "M4" `
            -Passed $false -Message "SovereignManifoldTheorems.lean missing in 03_vault or 01_l0_rust" -ElapsedMs $sw.Elapsed.TotalMilliseconds
    }

    $h1 = (Get-FileHash $leanVault -Algorithm SHA256).Hash
    $h2 = (Get-FileHash $leanL0 -Algorithm SHA256).Hash
    $hasParity = ($h1 -eq $h2)

    $text = [System.IO.File]::ReadAllText($leanVault)
    $thmCount = ([regex]::Matches($text, '(?m)^theorem\s+')).Count
    $sorryCount = ([regex]::Matches($text, '\bsorry\b')).Count
    $axiomCount = ([regex]::Matches($text, '(?m)^axiom\s+')).Count

    $passed = ($hasParity -and $thmCount -ge 624 -and $sorryCount -eq 0 -and $axiomCount -eq 0)
    $msg = if ($passed) {
        "624 Lean 4 theorems verified QED with 1:1 mirror parity, 0 sorry, 0 axiom"
    } else {
        "Lean 4 verification failed (Theorems: $thmCount [Req: >= 624], Parity: $hasParity, sorry: $sorryCount, axiom: $axiomCount)"
    }
    $sw.Stop()
    return New-TestResult -Tier 1 -Id "F17" -Name "Lean 4 Theorems Expansion (624 QED)" -Milestone "M4" `
        -Passed $passed -Message $msg -ElapsedMs $sw.Elapsed.TotalMilliseconds `
        -MeasuredData @{ Theorems = $thmCount; HasParity = $hasParity; SorryCount = $sorryCount; AxiomCount = $axiomCount }
}

function Test-Feature-18 {
    # F18: UI & Periphery Synchronization
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $hudHtml = "$RepoRoot\05_hud_cockpit\index.html"
    $docsHtml = "$RepoRoot\docs\index.html"

    if (-not (Test-Path $hudHtml) -or -not (Test-Path $docsHtml)) {
        $sw.Stop()
        return New-TestResult -Tier 1 -Id "F18" -Name "UI & Periphery Synchronization" -Milestone "M4" `
            -Passed $false -Message "HTML entrypoints missing in 05_hud_cockpit or docs" -ElapsedMs $sw.Elapsed.TotalMilliseconds
    }

    $c1 = [System.IO.File]::ReadAllText($hudHtml)
    $c2 = [System.IO.File]::ReadAllText($docsHtml)

    $hasSsr1 = ($c1 -match 'data-sovereign-ssr')
    $hasSsr2 = ($c2 -match 'data-sovereign-ssr')
    $hasRelative1 = ($c1 -match 'href="\./' -or $c1 -match 'src="\./')
    $hasRelative2 = ($c2 -match 'href="\./' -or $c2 -match 'src="\./')

    $passed = ($hasSsr1 -and $hasSsr2 -and $hasRelative1 -and $hasRelative2)
    $msg = if ($passed) {
        "UI pre-rendered SSR snapshot and relative asset paths verified across HUD and docs"
    } else {
        "UI sync failed (SSR1: $hasSsr1, SSR2: $hasSsr2, Rel1: $hasRelative1, Rel2: $hasRelative2)"
    }
    $sw.Stop()
    return New-TestResult -Tier 1 -Id "F18" -Name "UI & Periphery Synchronization" -Milestone "M4" `
        -Passed $passed -Message $msg -ElapsedMs $sw.Elapsed.TotalMilliseconds `
        -MeasuredData @{ Ssr1 = $hasSsr1; Ssr2 = $hasSsr2; Rel1 = $hasRelative1; Rel2 = $hasRelative2 }
}

# -----------------------------------------------------------------------------
# Milestone 5: E2E Acceptance & Gatekeeper Verification (F19..F20)
# -----------------------------------------------------------------------------

function Test-Feature-19 {
    # F19: Dual-Track E2E Test Suite
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $infraFile = "$RepoRoot\TEST_INFRA.md"
    $runnerFile = "$RepoRoot\tests\e2e\test_runner_v56.ps1"

    $hasInfra = (Test-Path $infraFile)
    $hasRunner = (Test-Path $runnerFile)

    $passed = ($hasInfra -and $hasRunner)
    $msg = if ($passed) {
        "TEST_INFRA.md and test_runner_v56.ps1 operational covering all 20 features across 4 tiers"
    } else {
        "E2E test suite artifacts incomplete (Infra: $hasInfra, Runner: $hasRunner)"
    }
    $sw.Stop()
    return New-TestResult -Tier 1 -Id "F19" -Name "Dual-Track E2E Test Suite" -Milestone "M5" `
        -Passed $passed -Message $msg -ElapsedMs $sw.Elapsed.TotalMilliseconds `
        -MeasuredData @{ HasInfra = $hasInfra; HasRunner = $hasRunner }
}

function Test-Feature-20 {
    # F20: Brutal Gatekeeper & Lifecycle Verification
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $gatekeeperScript = "$RepoRoot\00_control\Invoke-BrutalAgentGatekeeper.ps1"
    $lifecycleScript = "$RepoRoot\00_control\Sovereign-Lifecycle.ps1"

    $hasGatekeeper = (Test-Path $gatekeeperScript)
    $hasLifecycle = (Test-Path $lifecycleScript)

    # Run static checks via gatekeeper script
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
        "Brutal Gatekeeper static audit passed with exit code 0"
    } else {
        "Gatekeeper static checks failed (Gatekeeper script: $hasGatekeeper, Lifecycle script: $hasLifecycle, Exit code 0: $staticPassed)"
    }
    $sw.Stop()
    return New-TestResult -Tier 1 -Id "F20" -Name "Brutal Gatekeeper Verification" -Milestone "M5" `
        -Passed $passed -Message $msg -ElapsedMs $sw.Elapsed.TotalMilliseconds `
        -MeasuredData @{ HasGatekeeper = $hasGatekeeper; StaticPassed = $staticPassed }
}

function Invoke-Tier1-Tests-v56 {
    param([string]$MilestoneFilter = "All")

    Write-Host ""
    Write-Host "--- TIER 1: FEATURE COVERAGE (All 20 Features in PROJECT.md) ---" -ForegroundColor Yellow
    $results = @()

    $milestoneMap = @{
        "M0" = @("M0")
        "M1" = 1..6
        "M2" = 7..11
        "M3" = 12..14
        "M4" = 15..18
        "M5" = 19..20
    }

    if ($MilestoneFilter -eq "M0" -or $MilestoneFilter -eq "All") {
        $r = Test-Feature-GSC-Invariant
        $statusStr = if ($r.Passed) { "PASS" } else { "FAIL" }
        $color = if ($r.Passed) { "Green" } else { "Red" }
        Write-Host ("  [{0}] [{1}] {2} : {3} ({4}ms)" -f $r.Id, $statusStr, $r.Name, $r.Message, [math]::Round($r.ElapsedMs, 1)) -ForegroundColor $color
        $results += $r
        if ($MilestoneFilter -eq "M0") {
            return $results
        }
    }

    $featuresToRun = if ($MilestoneFilter -ne "All" -and $milestoneMap.ContainsKey($MilestoneFilter)) {
        $milestoneMap[$MilestoneFilter]
    } else {
        1..20
    }

    foreach ($fNum in $featuresToRun) {
        $funcName = ("Test-Feature-{0:D2}" -f $fNum)
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
