# tests\test_mcp_wrapper_extreme_stress.ps1
# Extreme stress harness for mcp_stdio_wrapper.ps1
# Concurrency: 16 simultaneous child processes
# STRICT INVARIANTS: ZERO PYTHON | MUSE ZERO-UNMEASURED DATA MANDATE | ZERO BACKTICKS

$ErrorActionPreference = "Continue"

Write-Host "=========================================================================="
Write-Host "  MCP STDIO WRAPPER EXTREME CONCURRENCY & DEADLOCK STRESS (16 WORKERS)"
Write-Host "=========================================================================="

$RepoRoot = "C:\sovereign_manifold_v31"
$WrapperPath = Join-Path $RepoRoot "00_control\mcp_stdio_wrapper.ps1"
$workerCount = 16
$sw = [System.Diagnostics.Stopwatch]::StartNew()

$workers = [System.Collections.Generic.List[PSObject]]::new()

for ($i = 1; $i -le $workerCount; $i++) {
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "powershell.exe"
    $psi.Arguments = '-NoProfile -NonInteractive -ExecutionPolicy Bypass -File "' + $WrapperPath + '"'
    $psi.UseShellExecute = $false
    $psi.RedirectStandardInput = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.CreateNoWindow = $true

    $proc = [System.Diagnostics.Process]::Start($psi)
    $stdoutTask = $proc.StandardOutput.ReadToEndAsync()
    $stderrTask = $proc.StandardError.ReadToEndAsync()

    $workers.Add([PSObject]@{
        Id = $i
        Proc = $proc
        StdoutTask = $stdoutTask
        StderrTask = $stderrTask
    })
}

# Flood each worker concurrently
foreach ($w in $workers) {
    $id = $w.Id
    $w.Proc.StandardInput.WriteLine('   ')
    $w.Proc.StandardInput.WriteLine('{"jsonrpc":"2.0","id":' + ($id * 1000 + 1) + ',"method":"tools/list"}')
    $pad = "Q" * 80000
    $w.Proc.StandardInput.WriteLine('{"jsonrpc":"2.0","id":' + ($id * 1000 + 2) + ',"method":"tools/list","params":{"pad":"' + $pad + '"}}')
    $w.Proc.StandardInput.WriteLine('{"jsonrpc":"2.0","id":null,"method":"notifications/initialized"}')
    $w.Proc.StandardInput.WriteLine('{"jsonrpc":"2.0","method":"notifications/initialized"}')
    $w.Proc.StandardInput.WriteLine('{"jsonrpc":"2.0","id":' + ($id * 1000 + 3) + ',"method":"tools/call","params":{"name":"polytope_7777d_crt_rvq_router","arguments":{"action":"crt_pfa"}}}')
    $w.Proc.StandardInput.Close()
}

$cleanExits = 0
$exitZeroCount = 0
$results = [System.Collections.Generic.List[PSObject]]::new()

foreach ($w in $workers) {
    $exited = $w.Proc.WaitForExit(10000)
    if (-not $exited) {
        $w.Proc.Kill()
    } else {
        $cleanExits++
    }

    $stdout = $w.StdoutTask.GetAwaiter().GetResult()
    $stderr = $w.StderrTask.GetAwaiter().GetResult()
    $exitCode = $w.Proc.ExitCode
    if ($exitCode -eq 0) { $exitZeroCount++ }

    $lines = $stdout -split [System.Environment]::NewLine | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    $results.Add([PSObject]@{
        Id = $w.Id
        CleanExit = $exited
        ExitCode = $exitCode
        LineCount = $lines.Count
        StderrLength = if ($stderr) { $stderr.Length } else { 0 }
    })
    $w.Proc.Dispose()
}

$sw.Stop()

$orphans = Get-CimInstance Win32_Process | Where-Object { $_.CommandLine -match "mcp_stdio_wrapper\.ps1" }
$zeroOrphans = ($null -eq $orphans -or $orphans.Count -eq 0)

Write-Host "  Workers Launched: $workerCount"
Write-Host "  Clean Exits (<10s): $cleanExits / $workerCount"
Write-Host "  Exit Code 0: $exitZeroCount / $workerCount"
Write-Host "  Zero Orphan Processes: $zeroOrphans"
Write-Host "  Total Duration: $([math]::Round($sw.Elapsed.TotalMilliseconds, 2)) ms"

$allPassed = ($cleanExits -eq $workerCount) -and ($exitZeroCount -eq $workerCount) -and $zeroOrphans
Write-Host "  EXTREME STRESS HARNESS RESULT: $(if ($allPassed) { 'PASS' } else { 'FAIL' })"
Write-Host "=========================================================================="

if ($allPassed) { exit 0 } else { exit 1 }
