$ErrorActionPreference = "SilentlyContinue";
while($true){
    $sw = Get-Process -Name "v31_swarm" -ErrorAction SilentlyContinue;
    if(-not $sw){
        $exe = "C:\sovereign_manifold_v31\01_l0_rust\target\release\v31_swarm.exe";
        if(Test-Path -Path($exe)){
            Start-Process -FilePath($exe) -ArgumentList("--daemon") -WindowStyle Hidden;
        };
    };
    Start-Sleep -Seconds 5;
};