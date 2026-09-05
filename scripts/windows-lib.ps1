# Shared Windows helpers for claude-science-api-bridge.
# Dot-source from other scripts. Does not print secrets.

$script:BridgeRoot = Split-Path $PSScriptRoot -Parent
if (-not (Test-Path (Join-Path $script:BridgeRoot "proxy.py"))) {
    throw "proxy.py not found next to scripts/. Expected $script:BridgeRoot\proxy.py"
}

function Get-BridgeRoot { $script:BridgeRoot }

function Get-BridgeStateDir {
    $dir = Join-Path $env:USERPROFILE ".claude-science"
    New-Item -ItemType Directory -Force -Path (Join-Path $dir "logs") | Out-Null
    return $dir
}

function Get-BridgePython {
    $venv = Join-Path (Get-BridgeRoot) ".venv\Scripts\python.exe"
    if (Test-Path $venv) { return $venv }
    foreach ($name in @("python", "py")) {
        $cmd = Get-Command $name -ErrorAction SilentlyContinue
        if ($cmd) { return $cmd.Source }
    }
    throw "Python 3 is required. Install Python 3.10+ and rerun."
}

function Get-BridgeBootstrapPython {
    foreach ($name in @("py", "python")) {
        $cmd = Get-Command $name -ErrorAction SilentlyContinue
        if ($cmd) { return $cmd.Source }
    }
    throw "Python 3 is required. Install Python 3.10+ and rerun."
}

function Get-BridgeProxyHost {
    if ($env:PROXY_HOST) { return $env:PROXY_HOST }
    return "127.0.0.1"
}

function Get-BridgeProxyPort {
    if ($env:PROXY_PORT) { return [int]$env:PROXY_PORT }
    return 9876
}

function Get-BridgeProxyUrl {
    return ("http://{0}:{1}" -f (Get-BridgeProxyHost), (Get-BridgeProxyPort))
}

function Test-TcpOpen([string]$TargetHost, [int]$Port) {
    try {
        $client = New-Object System.Net.Sockets.TcpClient
        $iar = $client.BeginConnect($TargetHost, $Port, $null, $null)
        $ok = $iar.AsyncWaitHandle.WaitOne(400)
        if (-not $ok) { $client.Close(); return $false }
        $client.EndConnect($iar)
        $client.Close()
        return $true
    } catch {
        return $false
    }
}

function Get-BridgeListeningPid {
    $port = Get-BridgeProxyPort
    try {
        $conn = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($conn) { return [int]$conn.OwningProcess }
    } catch {}
    return $null
}

function Stop-BridgeProcess {
    $pidFile = Join-Path (Get-BridgeStateDir) "proxy.pid"
    if (Test-Path $pidFile) {
        $procId = (Get-Content $pidFile -ErrorAction SilentlyContinue | Select-Object -First 1)
        if ($procId) {
            Stop-Process -Id ([int]$procId) -Force -ErrorAction SilentlyContinue
        }
        Remove-Item $pidFile -Force -ErrorAction SilentlyContinue
    }
    Get-CimInstance Win32_Process -Filter "Name = 'python.exe' OR Name = 'pythonw.exe'" -ErrorAction SilentlyContinue |
        Where-Object { $_.CommandLine -and $_.CommandLine -match 'proxy\.py' } |
        ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
}

$script:WindowsTaskName = "ClaudeScienceApiBridge"

function Get-BridgeTaskName { $script:WindowsTaskName }
