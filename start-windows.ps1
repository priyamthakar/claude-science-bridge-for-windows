# Windows starter for claude-science-api-bridge (proxy.py is cross-platform)
# Usage: powershell -ExecutionPolicy Bypass -File start-windows.ps1
$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "scripts\windows-lib.ps1")

$root = Get-BridgeRoot
$python = Join-Path $root ".venv\Scripts\python.exe"
if (-not (Test-Path $python)) {
    Write-Output "Missing .venv. Run: powershell -ExecutionPolicy Bypass -File .\scripts\install-safe.ps1"
    exit 1
}
$env:PROXY_HOST = Get-BridgeProxyHost
$env:PROXY_PORT = "$(Get-BridgeProxyPort)"
$env:ANTHROPIC_BASE_URL = Get-BridgeProxyUrl
Write-Output "Dashboard: $($env:ANTHROPIC_BASE_URL)/dashboard"
Write-Output "Health:    $($env:ANTHROPIC_BASE_URL)/health"
Write-Output "Use:       `$env:ANTHROPIC_BASE_URL='$($env:ANTHROPIC_BASE_URL)'"
if (Test-TcpOpen $env:PROXY_HOST ([int]$env:PROXY_PORT)) {
    Write-Output "Port $($env:PROXY_PORT) is already in use. Stop the old proxy first: .\scripts\stop.ps1"
    exit 1
}
Set-Location $root
& $python (Join-Path $root "proxy.py")
