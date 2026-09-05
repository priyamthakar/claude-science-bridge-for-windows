# Agent Operating Manual

This repository is **Claude Science Bridge for Windows**: a local Anthropic-compatible proxy so Claude Science and other `ANTHROPIC_BASE_URL` clients can use a third-party OpenAI-compatible API.

GitHub: https://github.com/priyamthakar/claude-science-bridge-for-windows  
Inspired by: https://github.com/Jyx0208/claude-science-api-bridge (MIT)

Read this file first, then follow `docs/windows.md` and `docs/agent-runbook.md`.

## Prime Directive

Do not break the user's network.

Default to safe mode:

- Do not edit Clash, Surge, Shadowrocket, system proxy, VPN, DNS, or TUN settings.
- Do not reload network daemons.
- Do not write to `/etc/hosts`.
- Do not install a root CA.
- Do not bind port 443.
- Do not print, commit, or summarize API keys, OAuth tokens, private keys, or certificate private keys.

Only use advanced HTTPS interception after the user explicitly approves it for the current machine.

## Goal

Make Claude Science (and any `ANTHROPIC_BASE_URL` client) usable with DeepSeek, OpenAI, 9Router, or another OpenAI-compatible provider.
If the user needs image understanding, choose a vision-capable backend model and preserve image inputs.

On this Windows machine:

1. Run the proxy on `127.0.0.1:9876` via `start-windows.ps1`.
2. Set `$env:ANTHROPIC_BASE_URL='http://127.0.0.1:9876'`.
3. Configure API key and model mapping in `config.json` or the English Dashboard.
4. If Ubuntu-24.04 already has `claude-science`, start it with `scripts/start-claude-science.ps1` (or Dashboard Open Claude Science) so WSL Science inherits the bridge.
5. Verify `/health`, `/v1/models`, `/v1/messages`, and recent-requests.

Do not install WSL, edit system proxy, or bind 443 unless the user explicitly asks.

## Repository map

- `proxy.py` — FastAPI proxy, Anthropic Messages ↔ OpenAI Chat Completions
- `start-windows.ps1` / `start.bat` — foreground Windows start
- `install.bat` / `scripts/install-safe.ps1` — venv, deps, optional logon task
- `scripts/wsl-science.sh` — WSL start/stop/token/patch/env for official Science
- `scripts/start-claude-science.ps1` — Windows wrapper around `wsl-science.sh start`
- `scripts/doctor.ps1`, `verify-proxy.ps1`, `self-test.ps1`, `stop.ps1`, `uninstall.ps1`
- `docs/windows.md` — portable Windows + WSL guide
- `README-windows.md` — this PC (9Router slots, daily boot)
- `config.example.json` — sanitized template (`config.json` is git-ignored)
- `setup-network.sh` — advanced HTTPS interception; opt-in only

## Success criteria (Windows)

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\self-test.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\verify-proxy.ps1
Invoke-RestMethod http://127.0.0.1:9876/health
Invoke-RestMethod http://127.0.0.1:9876/v1/models
```

And `http://127.0.0.1:9876/api/recent-requests` shows a successful backend request.

Vision:

```powershell
$env:VERIFY_IMAGE='1'
powershell -ExecutionPolicy Bypass -File .\scripts\verify-proxy.ps1
```

## If blocked

Use `scripts/doctor.ps1` first. It is read-only. Do not guess at network state.
