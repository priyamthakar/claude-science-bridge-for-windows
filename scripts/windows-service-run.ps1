# Login-task wrapper: keep proxy.py running after crashes. No network/cert/port 443 changes.
$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "windows-lib.ps1")

$root = Get-BridgeRoot
$python = Get-BridgePython
$env:PROXY_HOST = Get-BridgeProxyHost
$env:PROXY_PORT = "$(Get-BridgeProxyPort)"
$env:ANTHROPIC_BASE_URL = Get-BridgeProxyUrl
$logDir = Join-Path (Get-BridgeStateDir) "logs"
$outLog = Join-Path $logDir "proxy.log"
$errLog = Join-Path $logDir "proxy-error.log"
$pidFile = Join-Path (Get-BridgeStateDir) "proxy.pid"
$proxy = Join-Path $root "proxy.py"

Set-Location $root
while ($true) {
    $proc = Start-Process -FilePath $python -ArgumentList $proxy -WorkingDirectory $root -PassThru -WindowStyle Hidden -RedirectStandardOutput $outLog -RedirectStandardError $errLog
    $proc.Id | Set-Content -Path $pidFile -Encoding ascii
    $proc.WaitForExit()
    if ($proc.ExitCode -eq 0) { break }
    Start-Sleep -Seconds 3
}
