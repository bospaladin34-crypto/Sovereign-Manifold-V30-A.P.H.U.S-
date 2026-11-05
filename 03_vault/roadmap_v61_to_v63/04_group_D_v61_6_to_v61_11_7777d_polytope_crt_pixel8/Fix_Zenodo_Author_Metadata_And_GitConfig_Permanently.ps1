param(
    [string]$WorkspaceRoot = "C:\sovereign_manifold_v31",
    [string]$AuthorLastFirst = "Frownfelter, Donevin",
    [string]$AuthorGivenName = "Donevin",
    [string]$AuthorFamilyName = "Frownfelter",
    [string]$AuthorAffiliation = "Sovereign Harmonic Research Initiative, Missoula, Montana, USA",
    [switch]$PushToGitHubNow = $true
)

$ErrorActionPreference = "Continue"
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

Write-Host "=========================================================================" -ForegroundColor Cyan
Write-Host " ACT-OMEGA ZENODO AUTHOR & GIT CONFIG PERMANENT LOCK                     " -ForegroundColor Cyan
Write-Host "=========================================================================" -ForegroundColor Cyan

if (-not (Test-Path $WorkspaceRoot)) {
    Write-Host "[WARN] Workspace $WorkspaceRoot not found." -ForegroundColor Magenta
    exit 1
}

Set-Location -Path $WorkspaceRoot

$ZenodoFile = Join-Path $WorkspaceRoot ".zenodo.json"
$CffFile = Join-Path $WorkspaceRoot "CITATION.cff"

# 1. Lock local git config user.name so GitHub contributor fallback never uses old Windows profile names
& git config user.name "Donevin Frownfelter"
Write-Host "[OK] Locked local git config user.name -> 'Donevin Frownfelter'" -ForegroundColor Green

# 2. Write strict .zenodo.json with 'Frownfelter, Donevin'
$ZenodoJson = @'
{
  "title": "ACT-Omega Net v61.6.0 (SH4Z v6160 TLV | CHAIN 292 | 712/712 Lean 4 QED): Tri-Silicon E8/Leech/7777D Topological Computing Framework",
  "version": "61.6.0",
  "upload_type": "software",
  "publication_date": "2026-11-01",
  "access_right": "open",
  "license": "MIT",
  "creators": [
    {
      "name": "Frownfelter, Donevin",
      "affiliation": "Sovereign Harmonic Research Initiative, Missoula, Montana, USA"
    }
  ],
  "description": "<p><strong>ACT-Omega Net (Sovereign Harmonic IV / SH4Z)</strong> by <strong>Donevin Frownfelter</strong> is a hardware-anchored tri-silicon topological computing framework, 8D E8 and 24D Leech lattice vector quantizer, 7777D De Bruijn quasicrystal super-frame engine, Cellular Sheaf distributed verifier, and 700+ theorem Lean 4 formal verification harness.</p>",
  "keywords": [
    "ACT-Omega",
    "Sovereign Harmonic IV",
    "SH4Z",
    "Donevin Frownfelter",
    "E8 Lattice",
    "Leech Lattice",
    "7777D Polytope",
    "De Bruijn Quasicrystal",
    "Cellular Sheaf",
    "Lean 4 Formal Verification"
  ]
}
'@

$CrChar = [char]13
[System.IO.File]::WriteAllText($ZenodoFile, $ZenodoJson.Replace([string]$CrChar, ""), $Utf8NoBom)
Write-Host "[OK] Wrote strict .zenodo.json -> $ZenodoFile (Creator: Frownfelter, Donevin)" -ForegroundColor Green

# 3. Write strict CFF 1.2.0 CITATION.cff using family-names and given-names (Required by Zenodo's CFF parser!)
$CffContent = @'
cff-version: 1.2.0
message: "If you use ACT-Omega Net or the Sovereign Harmonic IV (SH4Z) framework in your research, please cite it using the metadata below."
type: software
title: "ACT-Omega Net (SH4Z): Tri-Silicon E8/Leech/7777D Topological Computing Framework"
version: "61.6.0"
date-released: "2026-11-01"
license: "MIT"
repository-code: "https://github.com/bospaladin34-crypto/Sovereign-Manifold-V30-A.P.H.U.S-"
authors:
  - family-names: "Frownfelter"
    given-names: "Donevin"
    affiliation: "Sovereign Harmonic Research Initiative, Missoula, Montana, USA"
keywords:
  - "ACT-Omega"
  - "Sovereign Harmonic IV"
  - "SH4Z"
  - "E8 Lattice"
  - "Leech Lattice"
  - "7777D Polytope"
  - "Cellular Sheaf"
  - "Lean 4"
'@

[System.IO.File]::WriteAllText($CffFile, $CffContent.Replace([string]$CrChar, ""), $Utf8NoBom)
Write-Host "[OK] Wrote strict CFF 1.2.0 CITATION.cff -> $CffFile (family-names: Frownfelter, given-names: Donevin)" -ForegroundColor Green

if ($PushToGitHubNow) {
    & git add .zenodo.json CITATION.cff
    $Status = & git status --porcelain .zenodo.json CITATION.cff
    if ($Status) {
        & git commit -m "chore(zenodo): lock creator metadata to Donevin Frownfelter in .zenodo.json and CITATION.cff"
        & git push origin HEAD
        Write-Host "[PASS] Committed and pushed locked Zenodo author metadata to GitHub!" -ForegroundColor Green
    } else {
        Write-Host "[INFO] .zenodo.json and CITATION.cff are already up to date." -ForegroundColor Yellow
    }
}
