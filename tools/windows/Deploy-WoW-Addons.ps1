[CmdletBinding()]
param(
    [string]$Server = "minipc",
    [string]$ProjectRoot = "/home/msminipc/projects/simplepoisons",
    [string]$WowAddOnsPath = "C:\Games\World of Warcraft\_classic_era_\Interface\AddOns"
)

$ErrorActionPreference = "Stop"
$stageRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("simplepoisons-deploy-" + [guid]::NewGuid().ToString("N"))
$stageAddon = Join-Path $stageRoot "SimplePoisons"
$destination = Join-Path $WowAddOnsPath "SimplePoisons"

try {
    & ssh.exe $Server "cd '$ProjectRoot' && bash tests/run.sh"
    if ($LASTEXITCODE -ne 0) { throw "SimplePoisons tests failed." }
    New-Item -ItemType Directory -Path $stageAddon -Force | Out-Null
    & scp.exe "$Server`:$ProjectRoot/*.lua" "$Server`:$ProjectRoot/*.toc" $stageAddon
    if ($LASTEXITCODE -ne 0) { throw "Could not download SimplePoisons runtime files." }
    & scp.exe -r "$Server`:$ProjectRoot/Locales" "$Server`:$ProjectRoot/assets" $stageAddon
    if ($LASTEXITCODE -ne 0) { throw "Could not download SimplePoisons locale or asset files." }
    New-Item -ItemType Directory -Path $destination -Force | Out-Null
    & robocopy.exe $stageAddon $destination /MIR /R:2 /W:1 /NFL /NDL /NJH /NJS /NP
    if ($LASTEXITCODE -ge 8) { throw "Robocopy failed with exit code $LASTEXITCODE." }
    Write-Host "SimplePoisons deployed. Enter /reload in WoW." -ForegroundColor Green
}
finally {
    if (Test-Path -LiteralPath $stageRoot) {
        Remove-Item -LiteralPath $stageRoot -Recurse -Force
    }
}
