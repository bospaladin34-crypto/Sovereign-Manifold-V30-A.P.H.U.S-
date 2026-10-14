Write-Host "====================================================" -ForegroundColor Cyan;
Write-Host "ACT-Omega v30.0: Sovereign Cluster Health Diagnostic" -ForegroundColor Cyan;
Write-Host "Geodesic Anchor: Missoula, MT (15.0 Hz Carrier Clock)" -ForegroundColor Cyan;
Write-Host "====================================================" -ForegroundColor Cyan;

# 1. Host Port Audit
Write-Host "`n[1. Host Ports]" -ForegroundColor Yellow;
$p8097 = (Test-NetConnection -ComputerName "127.0.0.1" -Port 8097 -WarningAction SilentlyContinue).TcpTestSucceeded;
$p8098 = (Test-NetConnection -ComputerName "127.0.0.1" -Port 8098 -WarningAction SilentlyContinue).TcpTestSucceeded;
$p8099 = (Test-NetConnection -ComputerName "127.0.0.1" -Port 8099 -WarningAction SilentlyContinue).TcpTestSucceeded;
$p5173 = (Test-NetConnection -ComputerName "127.0.0.1" -Port 5173 -WarningAction SilentlyContinue).TcpTestSucceeded;

if ($p8097) { Write-Host "  Port 8097 (P2P Swarm)      : ONLINE" -ForegroundColor Green; } else { Write-Host "  Port 8097 (P2P Swarm)      : OFFLINE" -ForegroundColor Red; };
if ($p8098) { Write-Host "  Port 8098 (Telemetry/mDNS) : ONLINE" -ForegroundColor Green; } else { Write-Host "  Port 8098 (Telemetry/mDNS) : OFFLINE" -ForegroundColor Red; };
if ($p8099) { Write-Host "  Port 8099 (Deno Gateway)   : ONLINE" -ForegroundColor Green; } else { Write-Host "  Port 8099 (Deno Gateway)   : OFFLINE" -ForegroundColor Red; };
if ($p5173) { Write-Host "  Port 5173 (WebGPU HUD)     : ONLINE" -ForegroundColor Green; } else { Write-Host "  Port 5173 (WebGPU HUD)     : OFFLINE" -ForegroundColor Red; };

# 2. Mobile Edge Nodes
Write-Host "`n[2. Mobile Edge Nodes]" -ForegroundColor Yellow;
$devList = (& adb devices);

# Pixel 10 Check
if ($devList -match "58170DLCR0004V") {
    $t10 = ((& adb -s 58170DLCR0004V shell "dumpsys battery | grep -E 'level|temperature'") -join ", ").Trim();
    $rev10 = ((& adb -s 58170DLCR0004V reverse --list) -join " ").Trim();
    Write-Host "  Pixel 10 (frankel, Tensor G5): ATTACHED" -ForegroundColor Green;
    Write-Host "    Battery: $t10" -ForegroundColor DarkGray;
    Write-Host "    Tunnels: $rev10" -ForegroundColor DarkGray;
} else {
    Write-Host "  Pixel 10 (frankel, Tensor G5): DISCONNECTED" -ForegroundColor Red;
};

# Pixel 8 Check
if ($devList -match "3A121FDJH00BW5") {
    $t8 = ((& adb -s 3A121FDJH00BW5 shell "dumpsys battery | grep -E 'level|temperature'") -join ", ").Trim();
    $rev8 = ((& adb -s 3A121FDJH00BW5 reverse --list) -join " ").Trim();
    Write-Host "  Pixel 8 (shiba, Tensor G3): ATTACHED" -ForegroundColor Green;
    Write-Host "    Battery: $t8" -ForegroundColor DarkGray;
    Write-Host "    Tunnels: $rev8" -ForegroundColor DarkGray;
} else {
    Write-Host "  Pixel 8 (shiba, Tensor G3): DISCONNECTED" -ForegroundColor Red;
};

# 3. Vault & Gradient Checkpoint Status
Write-Host "`n[3. Vault Checkpoint Status]" -ForegroundColor Yellow;
$modelFile = [System.IO.FileInfo]::new("C:\sovereign_manifold_v30\04_canonical_vault\models\model_harmonic_iii.e8q");
$deltaFile = [System.IO.FileInfo]::new("C:\sovereign_manifold_v30\04_canonical_vault\weights\edge_gradient_delta.bin");

if ($modelFile.Exists) {
    Write-Host "  Canonical Model : $($modelFile.Length) bytes | Modified: $($modelFile.LastWriteTime)" -ForegroundColor Green;
} else {
    Write-Host "  Canonical Model : MISSING" -ForegroundColor Red;
};

if ($deltaFile.Exists) {
    Write-Host "  Edge Swarm Delta: $($deltaFile.Length) bytes | Modified: $($deltaFile.LastWriteTime)" -ForegroundColor Green;
} else {
    Write-Host "  Edge Swarm Delta: MISSING" -ForegroundColor Yellow;
};

# 4. REST API Endpoints & Reflex Generation Audit (Positional URI expression - zero parameter collapse)
Write-Host "`n[4. REST API Endpoints & Reflex Generation]" -ForegroundColor Yellow;

$endpoints = @(
    "http://localhost:8099/health",
    "http://localhost:8099/api/v1/status",
    "http://localhost:8099/api/v1/telemetry",
    "http://localhost:8099/api/v1/vault/scale",
    "http://localhost:8099/api/v1/cluster/nodes"
);

$endpoints.ForEach({
    $ep =$_;
    try {
        $res = Invoke-RestMethod ($ep) -TimeoutSec 3 -ErrorAction Stop;
        $summary = "";
        if ($ep -match "/health") { $summary = "status=$($res.status), clients=$($res.clients_connected)"; }
        elseif ($ep -match "/status") { $summary = "manifold=$($res.manifold), params=$($res.total_parameters)"; }
        elseif ($ep -match "/telemetry") { $summary = "carrier=$($res.carrier_hz)Hz, phase=$($res.thalamic_phase_rad)rad, seq=$($res.seq)"; }
        elseif ($ep -match "/vault/scale") { $summary = "shards=$($res.shards_total), tokens=$($res.tokens_total)"; }
        elseif ($ep -match "/cluster/nodes") { $summary = "active_nodes=$($res.active_nodes), cluster=$($res.cluster)"; }
        Write-Host "  GET $ep : PASS ($summary)" -ForegroundColor Green;
    } catch {
        Write-Host "  GET $ep : FAILED ($($_.Exception.Message))" -ForegroundColor Red;
    }
});

# In-Flight Reflex Generation Smoke Test
try {
    $genBody = @{ prompt = "the sovereign manifold converges"; length = 12 } | ConvertTo-Json;
    $genRes = Invoke-RestMethod "http://localhost:8099/api/v1/harmonic/generate" -Method POST -Body $genBody -ContentType "application/json" -TimeoutSec 3;
    Write-Host "  POST /api/v1/harmonic/generate : PASS" -ForegroundColor Green;
    Write-Host "    Generated Text : '$($genRes.text)'" -ForegroundColor DarkGray;
    Write-Host "    Tokens Emitted : $($genRes.tokens -join ', ')" -ForegroundColor DarkGray;
    Write-Host "    Latency        : $([math]::Round($genRes.latency_us, 1)) us" -ForegroundColor DarkGray;
} catch {
    Write-Host "  POST /api/v1/harmonic/generate : FAILED ($($_.Exception.Message))" -ForegroundColor Red;
};