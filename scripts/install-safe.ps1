# Safe Windows install: venv, deps, config.json, optional login task.
# Does not change Clash, VPN, DNS, system proxy, hosts, certificates, or port 443.
param(
    [switch]$SkipService
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "windows-lib.ps1")

$root = Get-BridgeRoot
Set-Location $root
$state = Get-BridgeStateDir
$venvDir = Join-Path $root ".venv"
$venvPython = Join-Path $venvDir "Scripts\python.exe"
$bootstrap = Get-BridgeBootstrapPython

Write-Output "Using bootstrap Python: $bootstrap"
if (-not (Test-Path $venvPython)) {
    & $bootstrap -m venv $venvDir
    if ($LASTEXITCODE -ne 0) { throw "Could not create .venv" }
}
$python = $venvPython
Write-Output "Using runtime Python: $python"
& $python -m pip install --upgrade pip | Out-Null
& $python -m pip install -r (Join-Path $root "requirements.txt")
if ($LASTEXITCODE -ne 0) { throw "pip install failed" }

$config = Join-Path $root "config.json"
$example = Join-Path $root "config.example.json"
if (-not (Test-Path $config)) {
    Copy-Item $example $config
    Write-Output "Created config.json from config.example.json"
}

$env:PROJECT_DIR = $root
& $python -c @"
import json, os
from pathlib import Path
path = Path(os.environ['PROJECT_DIR']) / 'config.json'
data = json.loads(path.read_text(encoding='utf-8'))
mapping = {
    'DEEPSEEK_API_KEY': 'deepseek_api_key',
    'OPENAI_API_KEY': 'openai_api_key',
    'CUSTOM_API_KEY': 'custom_api_key',
    'DEEPSEEK_BASE_URL': 'deepseek_base_url',
    'OPENAI_BASE_URL': 'openai_base_url',
    'CUSTOM_BASE_URL': 'custom_base_url',
    'DEFAULT_BACKEND': 'default_backend',
    'FORCE_MODEL': 'force_model',
    'MODEL_LIST_MODE': 'model_list_mode',
    'MODEL_MENU_STRATEGY': 'model_menu_strategy',
    'DEFAULT_MAX_TOKENS_CAP': 'default_max_tokens_cap',
    'DEEPSEEK_UPSTREAM_MODE': 'deepseek_upstream_mode',
    'OPENAI_UPSTREAM_MODE': 'openai_upstream_mode',
    'CUSTOM_UPSTREAM_MODE': 'custom_upstream_mode',
    'PROXY_AUTH_TOKEN': 'proxy_auth_token',
    'PROXY_AUTH_MODE': 'proxy_auth_mode',
    'REASONING_CONTENT_POLICY': 'reasoning_content_policy',
    'INLINE_IMAGE_POLICY': 'inline_image_policy',
}
changed = []
for env_key, config_key in mapping.items():
    value = os.environ.get(env_key)
    if value:
        data[config_key] = value
        changed.append(config_key)
for env_key, config_key in {
    'DEEPSEEK_MODEL_MAP': 'deepseek_model_map',
    'OPENAI_MODEL_MAP': 'openai_model_map',
    'CUSTOM_MODEL_MAP': 'custom_model_map',
    'MODEL_ALIASES': 'model_aliases',
    'MODEL_TOKEN_CAPS': 'model_token_caps',
    'PROVIDER_PROFILES': 'provider_profiles',
}.items():
    value = os.environ.get(env_key)
    if value:
        data[config_key] = json.loads(value)
        changed.append(config_key)
if changed:
    path.write_text(json.dumps(data, indent=2) + '\n', encoding='utf-8')
    safe = [k for k in changed if not k.endswith('_api_key')]
    secrets = sum(1 for k in changed if k.endswith('_api_key'))
    print('Applied config from environment: ' + (', '.join(safe) or '(only secrets)') + f'; secrets updated: {secrets}')
"@

if (-not $SkipService) {
    $runner = Join-Path $PSScriptRoot "windows-service-run.ps1"
    $taskName = Get-BridgeTaskName
    $arg = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$runner`""
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument $arg -WorkingDirectory $root
    $trigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1) -ExecutionTimeLimit ([TimeSpan]::Zero)
    $principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Limited
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Force | Out-Null
    try { Start-ScheduledTask -TaskName $taskName } catch {}
    Write-Output "Installed login task: $taskName"
}

$url = Get-BridgeProxyUrl
if (-not (Test-TcpOpen (Get-BridgeProxyHost) (Get-BridgeProxyPort))) {
    Write-Output "Proxy is not listening yet. Start it with:"
    Write-Output "  powershell -ExecutionPolicy Bypass -File `"$(Join-Path $root 'start-windows.ps1')`""
} else {
    try {
        $health = Invoke-RestMethod -Uri "$url/health" -TimeoutSec 5
        Write-Output ("Health: {0}  backend={1}  os={2}" -f $health.status, $health.default_backend, $health.os_family)
    } catch {
        Write-Output "Port is open but /health did not respond yet."
    }
}

Write-Output ""
Write-Output "Safe install complete."
Write-Output "Dashboard: $url/dashboard"
Write-Output "Client:    `$env:ANTHROPIC_BASE_URL='$url'"
Write-Output "This install does not change system proxy, DNS, hosts, certificates, or port 443."
