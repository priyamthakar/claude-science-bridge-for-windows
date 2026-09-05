# Read-only Windows state inspection. Does not print secrets.
$ErrorActionPreference = "Continue"
. (Join-Path $PSScriptRoot "windows-lib.ps1")

function Section([string]$Name) { Write-Output ""; Write-Output ("== {0} ==" -f $Name) }

Section "System"
Write-Output ("OS: {0}" -f [System.Environment]::OSVersion.VersionString)
Write-Output ("User: {0}" -f $env:USERNAME)
Write-Output ("Project: {0}" -f (Get-BridgeRoot))

Section "Python"
try {
    $py = Get-BridgePython
    Write-Output ("python: {0}" -f $py)
    & $py --version
} catch {
    Write-Output "python: missing"
}

Section "Config"
$config = Join-Path (Get-BridgeRoot) "config.json"
if (Test-Path $config) {
    Write-Output "config.json: present (contents not printed)"
} else {
    Write-Output "config.json: missing"
}

Section "Proxy"
$hostName = Get-BridgeProxyHost
$port = Get-BridgeProxyPort
$url = Get-BridgeProxyUrl
$listenPid = Get-BridgeListeningPid
Write-Output ("URL: {0}" -f $url)
Write-Output ("Listening PID: {0}" -f $(if ($listenPid) { $listenPid } else { "none" }))
if (Test-TcpOpen $hostName $port) {
    try {
        $health = Invoke-RestMethod -Uri "$url/health" -TimeoutSec 5
        Write-Output ("health.status={0} os_family={1} backend={2} custom_configured={3}" -f $health.status, $health.os_family, $health.default_backend, $health.custom_configured)
    } catch {
        Write-Output "port open, /health failed"
    }
} else {
    Write-Output "proxy is not listening"
}

Section "Login task"
$task = Get-ScheduledTask -TaskName (Get-BridgeTaskName) -ErrorAction SilentlyContinue
if ($task) {
    Write-Output ("Task: {0} State={1}" -f $task.TaskName, $task.State)
} else {
    Write-Output "Login task: not installed"
}

Section "User environment"
$userUrl = [Environment]::GetEnvironmentVariable("ANTHROPIC_BASE_URL", "User")
Write-Output ("User ANTHROPIC_BASE_URL={0}" -f $(if ($userUrl) { $userUrl } else { "unset" }))
Write-Output ("Session ANTHROPIC_BASE_URL={0}" -f $(if ($env:ANTHROPIC_BASE_URL) { $env:ANTHROPIC_BASE_URL } else { "unset" }))

Section "Optional WSL Claude Science"
$wsl = Get-Command wsl -ErrorAction SilentlyContinue
if ($wsl) {
    wsl -d Ubuntu-24.04 -- bash -lc 'echo distro=Ubuntu-24.04; ~/.local/bin/claude-science --version 2>/dev/null || echo claude-science=missing; test -f ~/.claude-science/encryption.key && echo encryption.key=present || echo encryption.key=missing'
} else {
    Write-Output "wsl: not found (native Windows proxy does not require it)"
}

Write-Output ""
Write-Output "doctor complete"
