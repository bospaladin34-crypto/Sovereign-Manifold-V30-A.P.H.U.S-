$ErrorActionPreference = "SilentlyContinue"
Set-Location -Path "C:\sovereign_manifold_v31"
while(1){
    $swProc = Get-Process -Name "v31_swarm" -ErrorAction SilentlyContinue
    $cargoProc = Get-Process -Name "cargo" -ErrorAction SilentlyContinue
    if(
        (-not($swProc)) -and
        (-not($cargoProc))
    ){
        Start-Process -FilePath "C:\sovereign_manifold_v31\01_l0_rust\target\release\v31_swarm.exe" -ArgumentList("--daemon") -WindowStyle Hidden
    }
    $cfProc = Get-Process -Name "cloudflared" -ErrorAction SilentlyContinue
    if(-not($cfProc)){
        $cfLog = "C:\sovereign_manifold_v31\00_control\cloudflared_live.log"
        Remove-Item -Path($cfLog) -Force -ErrorAction SilentlyContinue
        Start-Process -FilePath "C:\sovereign_manifold_v31\00_control\cloudflared.exe" -ArgumentList("tunnel --url http://127.0.0.1:5173 --no-autoupdate --logfile C:\sovereign_manifold_v31\00_control\cloudflared_live.log") -WindowStyle Hidden
        Start-Sleep -Seconds 5
        if(Test-Path -Path($cfLog)){
            $lines =
                Get-Content -Path($cfLog) -ErrorAction SilentlyContinue
            foreach(
                $ln in
                $lines
            ){
                if($ln -match "(https://[a-zA-Z0-9\-]+\.trycloudflare\.com)"){
                    $newUrl =
                        $Matches[1].Trim()
                    $enc =
                        New-Object System.Text.UTF8Encoding(0)
                    [System.IO.File]::WriteAllText(
                        "C:\sovereign_manifold_v31\03_vault\models\cloudflare_wan_url.txt",
                        $newUrl,
                        $enc
                    )
                    git add 03_vault/models/cloudflare_wan_url.txt
                    git commit -m "chore(beacon): Auto-sync active Cloudflare WAN tunnel URL for Pixel 10"
                    git push origin vesper_production
                    break
                }
            }
        }
    }
    Start-Sleep -Seconds 5
}