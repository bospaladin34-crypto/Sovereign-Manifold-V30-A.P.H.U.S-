# =============================================================================
# ACT-OMEGA SOVEREIGN MANIFOLD v73.2.3 — EXTERNAL TELEMETRY KEY PROVISIONING
# =============================================================================
# Provisions C:\Users\Nbell\.act_omega_telemetry_ingest_key (or $env:ACT_OMEGA_TELEMETRY_KEY)
# onto attached Pixel 10 & Pixel 8 devices dynamically discovered via `adb devices -l`
# (and optional hints in C:\Users\Nbell\.act_omega_adb_devices.json) with ZERO hardcoded
# device serials and ZERO secret logging/echoing.
#
# Security model:
#   - Both Pixel 10 and Pixel 8: streams key via stdin into app-private
#     `files/.act_omega_telemetry_ingest_key` (chmod 0600) via `run-as com.actomega.manifold`.
#   - Rooted Pixel 8 (dynamic `su` / `ksud` detection): ALSO writes
#     `/data/local/tmp/.act_omega_telemetry_ingest_key` (chown root:root, chmod 0600)
#     for `p8_ksu_apex_daemon`.
#   - Ensures `adb -s <serial> reverse tcp:8097 tcp:8097` on each attached phone.
#   - Verifies non-destructively via byte count / `ls -la` / `stat` only (never `cat`).
# =============================================================================

[CmdletBinding()]
param(
    [string]$PackageName = "com.actomega.manifold",
    [switch]$RequireBothDevices
)

$ErrorActionPreference = "Stop"

$adb = "C:\Users\Nbell\AppData\Local\Android\Sdk\platform-tools\adb.exe"
if (-not (Test-Path $adb)) {
    $cmd = Get-Command adb -ErrorAction SilentlyContinue
    if ($cmd) { $adb = $cmd.Source } else { throw "adb.exe not found on host." }
}

# 1. Load external telemetry key without printing/logging its value
$keyFile = "C:\Users\Nbell\.act_omega_telemetry_ingest_key"
$telemetryKey = ""
if (Test-Path $keyFile) {
    $telemetryKey = ([System.IO.File]::ReadAllText($keyFile)).Trim()
} elseif (-not [string]::IsNullOrWhiteSpace($env:ACT_OMEGA_TELEMETRY_KEY)) {
    $telemetryKey = ($env:ACT_OMEGA_TELEMETRY_KEY).Trim()
}

if ([string]::IsNullOrWhiteSpace($telemetryKey) -or $telemetryKey.Length -lt 24) {
    throw "External telemetry key missing or < 24 chars at $keyFile / ACT_OMEGA_TELEMETRY_KEY."
}
$expectedBytes = ([System.Text.Encoding]::UTF8.GetBytes($telemetryKey)).Length

# Helper: stream raw UTF-8 bytes into `adb` stdin without trailing newline or CLI arg exposure
function Invoke-AdbStdinStream {
    param(
        [string]$AdbExe,
        [string]$Serial,
        [string[]]$ShellArgs,
        [byte[]]$PayloadBytes
    )
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $AdbExe
    $allArgs = @("-s", $Serial) + $ShellArgs
    $escaped = $allArgs | ForEach-Object {
        if ($_ -match '[\s"]') { '"' + ($_ -replace '"', '\"') + '"' } else { $_ }
    }
    $psi.Arguments = ($escaped -join ' ')
    $psi.UseShellExecute = $false
    $psi.RedirectStandardInput = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.CreateNoWindow = $true

    $proc = New-Object System.Diagnostics.Process
    $proc.StartInfo = $psi
    [void]$proc.Start()
    $proc.StandardInput.BaseStream.Write($PayloadBytes, 0, $PayloadBytes.Length)
    $proc.StandardInput.BaseStream.Flush()
    $proc.StandardInput.Close()
    $stdout = $proc.StandardOutput.ReadToEnd()
    $stderr = $proc.StandardError.ReadToEnd()
    $proc.WaitForExit()
    if ($proc.ExitCode -ne 0) {
        throw "ADB stdin stream failed (exit=$($proc.ExitCode)): $stderr $stdout"
    }
    return $stdout
}

# 2. Load optional role hints from external ~/.act_omega_adb_devices.json (never hardcoded in repo)
$roleHints = @{}
$cfgFile = "C:\Users\Nbell\.act_omega_adb_devices.json"
if (Test-Path $cfgFile) {
    try {
        $cfg = Get-Content -Raw $cfgFile | ConvertFrom-Json
        foreach ($role in @("pixel10", "pixel8")) {
            if ($cfg.$role -and $cfg.$role.serial) {
                $roleHints[([string]$cfg.$role.serial).Trim()] = $role
            }
        }
    } catch {
        Write-Warning "Could not parse optional ADB hints file: $($_.Exception.Message)"
    }
}

# 3. Dynamically discover connected ADB devices
$adbLines = @(& $adb devices -l 2>$null)
$targets = New-Object System.Collections.Generic.List[PSCustomObject]
foreach ($line in $adbLines) {
    if ($line -match '^(\S+)\s+device\b(.*)$') {
        $serial = $Matches[1].Trim()
        $meta = $Matches[2].Trim()
        $role = "android"
        if ($roleHints.ContainsKey($serial)) {
            $role = $roleHints[$serial]
        } elseif ($meta -match 'model:Pixel_10|product:frankel|device:frankel') {
            $role = "pixel10"
        } elseif ($meta -match 'model:Pixel_8|product:shiba|device:shiba') {
            $role = "pixel8"
        }
        $targets.Add([PSCustomObject]@{
            Role = $role
            Serial = $serial
            Meta = $meta
        })
    }
}

if ($targets.Count -eq 0) {
    throw "No connected ADB devices found in 'adb devices -l'."
}

if ($RequireBothDevices) {
    $hasP10 = @($targets | Where-Object { $_.Role -eq "pixel10" }).Count -gt 0
    $hasP8 = @($targets | Where-Object { $_.Role -eq "pixel8" }).Count -gt 0
    if (-not ($hasP10 -and $hasP8)) {
        throw "RequireBothDevices specified, but missing Pixel 10 ($hasP10) or Pixel 8 ($hasP8)."
    }
}

Write-Host "[Provision-PhoneTelemetryKey] Key source verified ($expectedBytes bytes, value redacted). Discovered $($targets.Count) device(s)." -ForegroundColor Cyan

$keyBytes = [System.Text.Encoding]::UTF8.GetBytes($telemetryKey)

foreach ($t in $targets) {
    $serial = $t.Serial
    $role = $t.Role
    Write-Host "  -> [$role] Ensuring reverse tcp:8097 tcp:8097..." -ForegroundColor Cyan
    & $adb -s $serial reverse tcp:8097 tcp:8097 | Out-Null

    # App-private provisioning via run-as (avoids world-readable /data/local/tmp exposure)
    $pkgPath = (& $adb -s $serial shell pm path $PackageName 2>$null) -join ""
    if ($pkgPath -match 'package:') {
        [void](Invoke-AdbStdinStream -AdbExe $adb -Serial $serial -ShellArgs @(
            "shell", "run-as", $PackageName, "sh", "-c",
            '"umask 077 && cat > files/.act_omega_telemetry_ingest_key && chmod 0600 files/.act_omega_telemetry_ingest_key"'
        ) -PayloadBytes $keyBytes)

        $appStat = ((& $adb -s $serial shell "run-as $PackageName sh -c 'ls -la files/.act_omega_telemetry_ingest_key && wc -c < files/.act_omega_telemetry_ingest_key'") -join " | ").Trim()
        if ($appStat -notmatch '^-rw-------' -or $appStat -notmatch "\b$expectedBytes\b") {
            throw "[$role] App-private telemetry key byte/mode verification failed: $appStat"
        }
        Write-Host "     [$role] App-private files/.act_omega_telemetry_ingest_key verified (0600, $expectedBytes B)." -ForegroundColor Green
    } else {
        Write-Warning "[$role] Package $PackageName not installed; skipped app-private provisioning."
    }

    # Rooted Pixel 8 daemon provisioning (/data/local/tmp/.act_omega_telemetry_ingest_key, root:root 0600)
    $suId = ((& $adb -s $serial shell "su -c id 2>/dev/null") -join " ").Trim()
    $useSu = ($suId -match 'uid=0\(root\)')
    $useKsud = $false
    if (-not $useSu) {
        $ksudId = ((& $adb -s $serial shell "echo id | ksud debug su 2>/dev/null") -join " ").Trim()
        if ($ksudId -match 'uid=0\(root\)') { $useKsud = $true }
    }

    if ($useSu -or $useKsud) {
        if ($useSu) {
            [void](Invoke-AdbStdinStream -AdbExe $adb -Serial $serial -ShellArgs @(
                "shell", "su", "-c",
                '"umask 077 && cat > /data/local/tmp/.act_omega_telemetry_ingest_key && chown root:root /data/local/tmp/.act_omega_telemetry_ingest_key && chmod 0600 /data/local/tmp/.act_omega_telemetry_ingest_key"'
            ) -PayloadBytes $keyBytes)
            $rootStat = ((& $adb -s $serial shell "su -c 'ls -la /data/local/tmp/.act_omega_telemetry_ingest_key && wc -c < /data/local/tmp/.act_omega_telemetry_ingest_key'") -join " | ").Trim()
        } else {
            # ksud debug su consumes stdin for commands, so write temp 0600 in shell then chown/chmod/mv via ksud
            $b64 = [Convert]::ToBase64String($keyBytes)
            $cmd = "umask 077 && printf '%s' '$b64' | base64 -d > /data/local/tmp/.act_omega_telemetry_ingest_key && chown root:root /data/local/tmp/.act_omega_telemetry_ingest_key && chmod 0600 /data/local/tmp/.act_omega_telemetry_ingest_key"
            [void](Invoke-AdbStdinStream -AdbExe $adb -Serial $serial -ShellArgs @(
                "shell", "ksud", "debug", "su"
            ) -PayloadBytes ([System.Text.Encoding]::UTF8.GetBytes("$cmd`n")))
            $rootStat = ((& $adb -s $serial shell "echo 'ls -la /data/local/tmp/.act_omega_telemetry_ingest_key && wc -c < /data/local/tmp/.act_omega_telemetry_ingest_key' | ksud debug su") -join " | ").Trim()
        }
        if ($rootStat -notmatch '^-rw-------' -or $rootStat -notmatch "\b$expectedBytes\b") {
            throw "[$role] Root /data/local/tmp telemetry key byte/mode verification failed: $rootStat"
        }
        Write-Host "     [$role] Root /data/local/tmp/.act_omega_telemetry_ingest_key verified (root:root 0600, $expectedBytes B)." -ForegroundColor Green
    } else {
        Write-Host "     [$role] Non-rooted node detected; skipped /data/local/tmp root key write (strict 0600 app-private only)." -ForegroundColor DarkGray
    }
}

Write-Host "[Provision-PhoneTelemetryKey] Complete across $($targets.Count) device(s)." -ForegroundColor Green
