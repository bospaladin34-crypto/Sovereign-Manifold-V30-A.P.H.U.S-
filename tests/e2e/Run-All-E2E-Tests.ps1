# ACT-Omega Net v56.1.0 (CHAIN 210 Master Milestone)
# Unified Master E2E Test Suite Runner
# File: C:\sovereign_manifold_v31\tests\e2e\Run-All-E2E-Tests.ps1
# STRICT CONSTRAINT: ZERO PYTHON | MUSE ZERO-UNMEASURED DATA MANDATE

param(
    [ValidateSet("1", "2", "3", "4", "All")]
    [string]$Tier = "All",

    [int]$Feature = 0,

    [ValidateSet("M0", "M1", "M2", "M3", "M4", "M5", "All")]
    [string]$Milestone = "All",

    [ValidateSet("Console", "JSON", "Markdown", "All")]
    [string]$ReportFormat = "Console",

    [string]$OutputPath = "",

    [ValidateSet("Baseline", "v56.1", "All")]
    [string]$Suite = "All",

    [switch]$Strict
)

$ErrorActionPreference = "Continue"

# Dispatch to v56 master runner
& "$PSScriptRoot\test_runner_v56.ps1" -Tier $Tier -Feature $Feature -Milestone $Milestone -ReportFormat $ReportFormat -OutputPath $OutputPath -Suite $Suite -Strict:$Strict
exit $LASTEXITCODE
