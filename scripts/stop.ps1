# Stop the Windows proxy process. Leaves config.json and the login task in place.
$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "windows-lib.ps1")
Stop-BridgeProcess
Write-Output "Stopped proxy processes for $(Get-BridgeProxyUrl)."
