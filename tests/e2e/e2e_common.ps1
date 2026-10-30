# ACT-Omega Net v49.0.0 (CHAIN 100 Century Milestone)
# E2E Test Suite Common Test Utilities & Assertion Library
# File: C:\sovereign_manifold_v31\tests\e2e\e2e_common.ps1
# STRICT CONSTRAINT: ZERO PYTHON | MUSE ZERO-UNMEASURED DATA MANDATE

$ErrorActionPreference = "Continue"

class TestResult {
    [int]$Tier
    [string]$Id
    [string]$Name
    [string]$Milestone
    [bool]$Passed
    [string]$Message
    [double]$ElapsedMs
    [hashtable]$MeasuredData

    TestResult([int]$tier, [string]$id, [string]$name, [string]$milestone, [bool]$passed, [string]$msg, [double]$elapsedMs, [hashtable]$data) {
        $this.Tier = $tier
        $this.Id = $id
        $this.Name = $name
        $this.Milestone = $milestone
        $this.Passed = $passed
        $this.Message = $msg
        $this.ElapsedMs = $elapsedMs
        $this.MeasuredData = $data
    }
}

function New-TestResult {
    param(
        [Parameter(Mandatory=$true)][int]$Tier,
        [Parameter(Mandatory=$true)][string]$Id,
        [Parameter(Mandatory=$true)][string]$Name,
        [Parameter(Mandatory=$true)][string]$Milestone,
        [Parameter(Mandatory=$true)][bool]$Passed,
        [Parameter(Mandatory=$true)][string]$Message,
        [Parameter(Mandatory=$true)][double]$ElapsedMs,
        [hashtable]$MeasuredData = @{}
    )
    return [TestResult]::new($Tier, $Id, $Name, $Milestone, $Passed, $Message, $ElapsedMs, $MeasuredData)
}

function Test-ZeroSquareBrackets {
    param([Parameter(Mandatory=$true)][string]$FilePath)
    if (-not (Test-Path $FilePath)) {
        return @{ Exists = $false; BracketCount = -1; Error = "File not found: $FilePath" }
    }
    $bytes = [System.IO.File]::ReadAllBytes($FilePath)
    $bracketCount = 0
    for ($i = 0; $i -lt $bytes.Length; $i++) {
        $b = $bytes[$i]
        if ($b -eq 0x5B -or $b -eq 0x5D) {
            $bracketCount++
        }
    }
    return @{
        Exists = $true
        ByteLength = $bytes.Length
        BracketCount = $bracketCount
        Passed = ($bracketCount -eq 0)
    }
}

function Invoke-SafeRestMethod {
    param(
        [Parameter(Mandatory=$true)][string]$Uri,
        [hashtable]$Headers = @{},
        [int]$TimeoutSec = 4,
        [string]$Method = "GET",
        [string]$Body = $null,
        [string]$ContentType = "application/json"
    )
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        $params = @{
            Uri = $Uri
            TimeoutSec = $TimeoutSec
            Method = $Method
        }
        if ($Headers.Count -gt 0) {
            $params["Headers"] = $Headers
        }
        if ($Body) {
            $params["Body"] = $Body
            $params["ContentType"] = $ContentType
        }
        $response = Invoke-RestMethod @params
        $sw.Stop()
        return @{
            Success = $true
            StatusCode = 200
            Data = $response
            ElapsedMs = $sw.Elapsed.TotalMilliseconds
            Error = $null
        }
    } catch [System.Net.WebException] {
        $sw.Stop()
        $statusCode = 0
        $errBody = ""
        if ($_.Exception.Response) {
            $statusCode = [int]$_.Exception.Response.StatusCode
            $stream = $_.Exception.Response.GetResponseStream()
            if ($stream) {
                $reader = [System.IO.StreamReader]::new($stream)
                $errBody = $reader.ReadToEnd()
            }
        }
        return @{
            Success = $false
            StatusCode = $statusCode
            Data = $null
            RawError = $errBody
            ElapsedMs = $sw.Elapsed.TotalMilliseconds
            Error = $_.Exception.Message
        }
    } catch {
        $sw.Stop()
        return @{
            Success = $false
            StatusCode = 0
            Data = $null
            RawError = ""
            ElapsedMs = $sw.Elapsed.TotalMilliseconds
            Error = $_.Exception.Message
        }
    }
}

function Invoke-SafeWebRequest {
    param(
        [Parameter(Mandatory=$true)][string]$Uri,
        [hashtable]$Headers = @{},
        [int]$TimeoutSec = 4,
        [string]$Method = "GET"
    )
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        $params = @{
            Uri = $Uri
            TimeoutSec = $TimeoutSec
            Method = $Method
            UseBasicParsing = $true
        }
        if ($Headers.Count -gt 0) {
            $params["Headers"] = $Headers
        }
        $response = Invoke-WebRequest @params
        $sw.Stop()
        return @{
            Success = $true
            StatusCode = [int]$response.StatusCode
            Headers = $response.Headers
            Content = $response.Content
            ElapsedMs = $sw.Elapsed.TotalMilliseconds
            Error = $null
        }
    } catch [System.Net.WebException] {
        $sw.Stop()
        $statusCode = 0
        $headers = @{}
        $content = ""
        if ($_.Exception.Response) {
            $statusCode = [int]$_.Exception.Response.StatusCode
            $headers = $_.Exception.Response.Headers
            $stream = $_.Exception.Response.GetResponseStream()
            if ($stream) {
                $reader = [System.IO.StreamReader]::new($stream)
                $content = $reader.ReadToEnd()
            }
        }
        return @{
            Success = $false
            StatusCode = $statusCode
            Headers = $headers
            Content = $content
            ElapsedMs = $sw.Elapsed.TotalMilliseconds
            Error = $_.Exception.Message
        }
    } catch {
        $sw.Stop()
        return @{
            Success = $false
            StatusCode = 0
            Headers = @{}
            Content = ""
            ElapsedMs = $sw.Elapsed.TotalMilliseconds
            Error = $_.Exception.Message
        }
    }
}

function Format-TestSummary {
    param([Parameter(Mandatory=$true)][TestResult[]]$Results)
    $total = $Results.Count
    $passed = ($Results | Where-Object { $_.Passed }).Count
    $failed = $total - $passed
    $pct = if ($total -gt 0) { [math]::Round(($passed / $total) * 100.0, 1) } else { 0.0 }
    
    Write-Host ""
    Write-Host "==========================================================================" -ForegroundColor Cyan
    Write-Host "                  E2E TEST SUITE EXECUTION SUMMARY                        " -ForegroundColor Cyan
    Write-Host "==========================================================================" -ForegroundColor Cyan
    Write-Host ("  Total Tests Run : {0}" -f $total) -ForegroundColor White
    Write-Host ("  Passed          : {0} ({1}%)" -f $passed, $pct) -ForegroundColor Green
    Write-Host ("  Failed          : {0}" -f $failed) -ForegroundColor $(if($failed -gt 0){"Red"}else{"Green"})
    Write-Host "--------------------------------------------------------------------------" -ForegroundColor Gray
    
    # Summary by Tier
    for ($t = 1; $t -le 4; $t++) {
        $tierResults = $Results | Where-Object { $_.Tier -eq $t }
        if ($tierResults.Count -gt 0) {
            $tPass = ($tierResults | Where-Object { $_.Passed }).Count
            $tTotal = $tierResults.Count
            Write-Host ("  Tier {0} Pass Rate: {1}/{2} ({3}%)" -f $t, $tPass, $tTotal, [math]::Round(($tPass / $tTotal) * 100.0, 1)) -ForegroundColor $(if($tPass -eq $tTotal){"Green"}else{"Yellow"})
        }
    }
    Write-Host "==========================================================================" -ForegroundColor Cyan
    Write-Host ""
    return @{ Total = $total; Passed = $passed; Failed = $failed; PassRatePct = $pct }
}

function Export-TestResultsJson {
    param(
        [Parameter(Mandatory=$true)][TestResult[]]$Results,
        [Parameter(Mandatory=$true)][string]$OutputPath
    )
    $exportObj = @{
        timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
        suite = "ACT-Omega Net v56.0.0 E2E Test Suite"
        summary = @{
            total = $Results.Count
            passed = ($Results | Where-Object { $_.Passed }).Count
            failed = ($Results | Where-Object { -not $_.Passed }).Count
            pass_rate_pct = if ($Results.Count -gt 0) { [math]::Round((($Results | Where-Object { $_.Passed }).Count / $Results.Count) * 100.0, 1) } else { 0.0 }
        }
        results = $Results | ForEach-Object {
            @{
                tier = $_.Tier
                id = $_.Id
                name = $_.Name
                milestone = $_.Milestone
                passed = $_.Passed
                message = $_.Message
                elapsed_ms = $_.ElapsedMs
                measured_data = $_.MeasuredData
            }
        }
    }
    $json = $exportObj | ConvertTo-Json -Depth 6
    [System.IO.File]::WriteAllText($OutputPath, $json, [System.Text.Encoding]::UTF8)
    Write-Host "  Results exported to JSON: $OutputPath" -ForegroundColor DarkGray
}
