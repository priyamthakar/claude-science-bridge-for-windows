# Claude Science Bridge for Windows

Local Anthropic-compatible proxy for Windows. Point `ANTHROPIC_BASE_URL` clients at `http://127.0.0.1:9876` and send inference to DeepSeek, OpenAI, Kimi, 9Router, or any OpenAI-compatible API.

**Repo:** https://github.com/priyamthakar/claude-science-bridge-for-windows  
**This machine:** `D:\claude-science-bridge-for-windows`

This is unofficial. Anthropic’s [Claude Science](https://claude.com/product/claude-science) only talks to Claude models. This bridge keeps that wire format and routes the request to the backend you configure.

## Inspired from

| Source | Role |
| --- | --- |
| [Jyx0208/claude-science-api-bridge](https://github.com/Jyx0208/claude-science-api-bridge) (MIT) | Original proxy: Anthropic Messages ↔ OpenAI Chat Completions, Dashboard, provider profiles, model aliases, image policy, path-secret. |
| [Anthropic Claude Science](https://claude.com/product/claude-science) | Client contract: `/v1/messages`, `/v1/models`, `ANTHROPIC_BASE_URL`. Official Windows path is WSL 2 + `claude-science serve`. |

This fork is the Windows + WSL port of that bridge: English Dashboard, PowerShell install, logon scheduled task, and WSL helpers for an already-installed `claude-science` binary.

## How it works

```text
Windows client  (Claude Code, Cursor, any ANTHROPIC_BASE_URL app)
        or
WSL Claude Science  (`claude-science serve` on :8765)
        |
        |  Anthropic Messages API
        v
This bridge  http://127.0.0.1:9876
  English Dashboard  /dashboard
  Slot IDs (claude-opus-*) → your real model names
  Anthropic → OpenAI translation, or Anthropic passthrough
        |
        v
Your backend  (DeepSeek, OpenAI, Kimi, OpenRouter, 9Router, custom)
```

The proxy binds **loopback only**. Default install does not change Clash, VPN, DNS, hosts, certificates, or port 443.

## Quick start (Windows)

```powershell
git clone https://github.com/priyamthakar/claude-science-bridge-for-windows.git D:\claude-science-bridge-for-windows
cd D:\claude-science-bridge-for-windows
git checkout windows-native
powershell -ExecutionPolicy Bypass -File .\scripts\install-safe.ps1
powershell -ExecutionPolicy Bypass -File .\start-windows.ps1
```

Or double-click `install.bat`, then `start.bat`.

Then:

```powershell
$env:ANTHROPIC_BASE_URL='http://127.0.0.1:9876'
Start-Process http://127.0.0.1:9876/dashboard
```

Full Windows guide: [docs/windows.md](docs/windows.md).  
This PC’s 9Router notes: [README-windows.md](README-windows.md).

## Dashboard

Open http://127.0.0.1:9876/dashboard (English).

| Action | Windows / WSL |
| --- | --- |
| Run test | `/v1/messages` through the local proxy |
| Open / Restart Claude Science | WSL `claude-science serve --port 8765 --detached` with `ANTHROPIC_BASE_URL`, then open the login URL in a Windows browser |
| Apply / patch model menu | Live `/v1/models`, plus WSL binary display-name patch when Science is installed |
| Refresh OAuth token | `setup-token.py` in WSL using `~/.claude-science/encryption.key` |
| Set user `ANTHROPIC_BASE_URL` | Windows `setx` and WSL `~/.profile` / `~/.bashrc` |
| Install login service | Scheduled task `ClaudeScienceApiBridge` |
| Update | `git pull` + `pip install` (not the macOS DMG) |
| CC Switch sync | Writes `~/.cc-switch` if that DB exists. `.app` install is still macOS-only |

## Official Claude Science (WSL)

Anthropic does not ship a native Windows Science GUI as the primary path; this PC uses Ubuntu-24.04:

```powershell
# proxy first
powershell -ExecutionPolicy Bypass -File D:\claude-science-bridge-for-windows\start-windows.ps1

# then Science, inheriting the bridge
powershell -ExecutionPolicy Bypass -File D:\claude-science-bridge-for-windows\scripts\start-claude-science.ps1
```

Open http://127.0.0.1:8765 in a Windows browser.

## Verify

```powershell
cd D:\claude-science-bridge-for-windows
powershell -ExecutionPolicy Bypass -File .\scripts\self-test.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\verify-proxy.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\doctor.ps1
```

Vision check (needs a vision-capable backend):

```powershell
$env:VERIFY_IMAGE='1'
powershell -ExecutionPolicy Bypass -File .\scripts\verify-proxy.ps1
```

## Other docs

| Doc | What it is |
| --- | --- |
| [docs/windows.md](docs/windows.md) | Portable Windows + WSL install |
| [README-windows.md](README-windows.md) | This machine: 9Router, model slots, daily boot |
| [AGENTS.md](AGENTS.md) | Rules for local coding agents |
| [docs/agent-runbook.md](docs/agent-runbook.md) | Step-by-step agent procedure |
| [docs/troubleshooting.md](docs/troubleshooting.md) | Failure modes |
| [docs/linux.md](docs/linux.md) | Linux proxy / systemd notes |
| [SECURITY.md](SECURITY.md) | Secrets and network safety |

## Uninstall

```powershell
powershell -ExecutionPolicy Bypass -File D:\claude-science-bridge-for-windows\scripts\uninstall.ps1
```

Stops the proxy, removes the logon task, and clears user `ANTHROPIC_BASE_URL`. Leaves `config.json`, keys, and logs in place.
