# Troubleshooting

This is **Claude Science Bridge for Windows**. Prefer the PowerShell scripts in this repo.

## Proxy is not running

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\doctor.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\stop.ps1
powershell -ExecutionPolicy Bypass -File .\start-windows.ps1
```

Login task: `ClaudeScienceApiBridge`.  
Logs: `%USERPROFILE%\.claude-science\logs`.  
If port 9876 is in use, stop the old process before starting a new one.

This machine’s folder: `D:\claude-science-bridge-for-windows`.

## 9Router 401 or empty replies

See [README-windows.md](../README-windows.md). Typical causes: rotated 9Router key, provider logged out, Muse Spark non-stream request, or `max_tokens` too small.

## WSL Claude Science did not open

1. Confirm the Windows proxy is healthy: `Invoke-RestMethod http://127.0.0.1:9876/health`
2. Start Science with the env var: `.\scripts\start-claude-science.ps1`
3. Open http://127.0.0.1:8765
4. `wsl -d Ubuntu-24.04 -- ~/.local/bin/claude-science status`

Do not use `open -a "Claude Science"` on Windows.

## Backend 400: invalid tool schema

The proxy sanitizes Claude tool schemas before sending them to OpenAI-compatible APIs. Capture only the backend error text from `proxy.log`. Do not log full prompts or API keys.

## Backend 400: max_tokens too large

Set a per-model cap in `config.json`:

```json
{
  "model_token_caps": {
    "provider-model-name": 8192
  }
}
```

Restart the proxy and rerun `.\scripts\verify-proxy.ps1`.

## Linux / macOS leftovers

systemd unit name on Linux remains `claude-science-api-bridge.service` (inherited from upstream). macOS LaunchAgent label remains `com.byok.claude-science-proxy`. This fork’s primary path is Windows.

```bash
./scripts/doctor.sh
systemctl --user status claude-science-api-bridge.service
```
