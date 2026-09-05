# Optional: start the already-installed WSL Claude Science binary pointed at this Windows proxy.
# Official Science on Windows is the Linux binary under WSL 2. This does not install WSL.
param(
    [string]$Distro = "Ubuntu-24.04",
    [int]$Port = 8765
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "windows-lib.ps1")

$bridge = Get-BridgeProxyUrl
if (-not (Test-TcpOpen (Get-BridgeProxyHost) (Get-BridgeProxyPort))) {
    throw "Windows proxy is not listening at $bridge. Start it with start-windows.ps1 first."
}

Write-Output "Starting Claude Science in $Distro with ANTHROPIC_BASE_URL=$bridge"
Write-Output "UI: http://127.0.0.1:$Port  (WSL forwards localhost to Windows browsers)"
Write-Output "Leave this window open."
wsl -d $Distro -- bash -lc "export ANTHROPIC_BASE_URL='$bridge'; exec ~/.local/bin/claude-science serve --port $Port --no-browser"
