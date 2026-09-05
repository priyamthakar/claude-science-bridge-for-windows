# Agent Runbook

Step-by-step guide for an AI agent configuring **Claude Science Bridge for Windows**.

Default to safe mode. Do not modify Clash, VPN, TUN, DNS, system proxy, `/etc/hosts`, system certificates, or port 443.

Repo: https://github.com/priyamthakar/claude-science-bridge-for-windows  
This PC: `D:\claude-science-bridge-for-windows`

## Phase 0: Safety check

Read-only:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\doctor.ps1
```

Inspect:

- Windows version and whether WSL Ubuntu-24.04 is present
- Python path and `.venv`
- whether `config.json` exists (do not print keys)
- whether `ANTHROPIC_BASE_URL` is set
- whether ports `9876` and `8765` are in use
- whether `/health` is already ok
- whether `claude-science` exists in WSL (`~/.local/bin/claude-science`)

Do not change Clash or any network proxy tool. Do not install WSL unless the user asks.

## Phase 1: Install

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install-safe.ps1
powershell -ExecutionPolicy Bypass -File .\start-windows.ps1
```

This should:

1. Create `.venv` and install Python dependencies
2. Create `config.json` from `config.example.json` if missing
3. Apply provider settings from environment variables when set
4. Optionally register logon task `ClaudeScienceApiBridge`
5. Start the proxy on `127.0.0.1:9876`

See `docs/windows.md`.

## Phase 2: Configure provider

Open http://127.0.0.1:9876/dashboard

Never echo secrets into chat logs.

Prefer Dashboard or `/api/fetch-models` before finalizing aliases. Hidden 9Router `oc/*` models may need a manual `config.json` alias (see `README-windows.md`).

Use `*_upstream_mode=anthropic` when the provider has a native Anthropic Messages endpoint; otherwise `openai`.

## Phase 3: Optional WSL Claude Science

Only if `claude-science` is already installed in Ubuntu-24.04:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\start-claude-science.ps1
```

Dashboard **Open Claude Science** does the same: `serve --port 8765 --no-browser --detached` with `ANTHROPIC_BASE_URL=http://127.0.0.1:9876`, then opens the login URL in a Windows browser.

OAuth token minting uses WSL `~/.claude-science/encryption.key` via Dashboard **Refresh OAuth token**.

## Phase 4: Verify

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\verify-proxy.ps1
Invoke-RestMethod http://127.0.0.1:9876/api/recent-requests
```

Vision:

```powershell
$env:VERIFY_IMAGE='1'
powershell -ExecutionPolicy Bypass -File .\scripts\verify-proxy.ps1
```

## Uninstall

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\uninstall.ps1
```

Removes the logon task and user `ANTHROPIC_BASE_URL`. Leaves keys and logs.
