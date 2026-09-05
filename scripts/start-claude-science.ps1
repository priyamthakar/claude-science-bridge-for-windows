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
$winRoot = Get-BridgeRoot
$drive = $winRoot.Substring(0,1).ToLower()
$wslRoot = "/mnt/$drive" + ($winRoot.Substring(2) -replace '\\','/')
$env:CLAUDE_SCIENCE_WSL_DISTRO = $Distro
$env:CLAUDE_SCIENCE_PORT = "$Port"
Write-Output "UI: http://127.0.0.1:$Port  (WSL forwards localhost to Windows browsers)"
wsl -d $Distro -- bash -lc "export BRIDGE_DIR='$wslRoot'; export ANTHROPIC_BASE_URL='$bridge'; export CLAUDE_SCIENCE_PORT='$Port'; bash `"$wslRoot/scripts/wsl-science.sh`" start"
