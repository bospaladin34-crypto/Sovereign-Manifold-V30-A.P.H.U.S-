$ErrorActionPreference = "SilentlyContinue"
Set-Location -Path "C:\sovereign_manifold_v31\05_hud_cockpit"
while($true){
    & "C:\Program Files\nodejs\node.exe" "C:\sovereign_manifold_v31\05_hud_cockpit\mux_server_5173.mjs"
    Start-Sleep -Milliseconds 400
}
