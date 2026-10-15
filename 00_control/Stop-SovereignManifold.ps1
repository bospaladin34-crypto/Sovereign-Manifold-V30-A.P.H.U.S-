$ErrorActionPreference="SilentlyContinue";
Write-Host "[v31 Control] Stopping existing Sovereign Manifold host listeners..." -ForegroundColor Yellow;
$ports=@(8097,8098,8099,5173);
foreach($p in($ports)){
$conns=Get-NetTCPConnection -LocalPort($p) -ErrorAction SilentlyContinue;
foreach($c in($conns)){
if($c.OwningProcess -gt 4){
Stop-Process -Id($c.OwningProcess) -Force -ErrorAction SilentlyContinue;
}
}
}
Get-Process -Name "v31_swarm","p2p_swarm_node","harmonic_endpoint" -ErrorAction SilentlyContinue|Stop-Process -Force -ErrorAction SilentlyContinue;
Write-Host "[v31 Control] Host ports 8097, 8098, 8099, 5173 cleared." -ForegroundColor Green;