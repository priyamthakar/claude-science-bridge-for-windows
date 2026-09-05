# Windows native setup

Windows-native port of [Jyx0208/claude-science-api-bridge](https://github.com/Jyx0208/claude-science-api-bridge).

This branch keeps the original Python proxy and adds a Windows install path: English Dashboard, PowerShell scripts, a per-user logon task, and any client that honors `ANTHROPIC_BASE_URL`.

It does **not** reimplement Anthropic's Claude Science workbench. Official Claude Science on Windows is still the Linux binary under WSL 2. The optional helper `scripts/start-claude-science.ps1` only starts that already-installed binary with `ANTHROPIC_BASE_URL` pointed at this proxy.

Anthropic does not support third-party models inside Claude Science. This project is unofficial.

## Where this comes from

| Source | What we took |
| --- | --- |
| [Jyx0208/claude-science-api-bridge](https://github.com/Jyx0208/claude-science-api-bridge) (MIT) | The proxy itself: Anthropic Messages ↔ OpenAI Chat Completions, Dashboard, provider profiles, model aliases, image policy, path-secret. macOS DMG / LaunchAgent / daemon patches stay upstream-only. |
| [Anthropic Claude Science](https://claude.com/product/claude-science) | The client contract: `/v1/messages`, `/v1/models`, and `ANTHROPIC_BASE_URL`. Official Windows path is WSL 2 + `claude-science serve --port 8765 --no-browser`. Models in the official app are Claude-only. |
| Official WSL docs | Distro (`Ubuntu-24.04`), sandbox deps (`bubblewrap`, `socat`), and localhost forwarding into a Windows browser. |

This is the usual unofficial “Path A”: keep the official Science UI/sandbox when you have it, and send inference through a local Anthropic-compatible proxy. Other public Path A tools (Codex-connector, AIUsage) are macOS-centric forks or apps. This branch is the Windows-native version of the original bridge.

## How it works

```text
Windows client  (Claude Code, Cursor, any ANTHROPIC_BASE_URL app)
        or
WSL Claude Science  (`claude-science serve` on :8765)
        |
        |  Anthropic Messages API
        v
This bridge  http://127.0.0.1:9876
  - English Dashboard at /dashboard
  - model aliases (claude-opus-* slot → your real model)
  - Anthropic → OpenAI translation, or Anthropic passthrough
        |
        v
Your backend  (DeepSeek, OpenAI, Kimi, OpenRouter, 9Router, any OpenAI-compatible URL)
```

1. `start-windows.ps1` runs `proxy.py` on `127.0.0.1:9876` (loopback only).
2. Clients set `ANTHROPIC_BASE_URL=http://127.0.0.1:9876`.
3. `/v1/models` returns Claude-compatible slot IDs with your display names.
4. `/v1/messages` is translated to the configured backend and streamed back.
5. Optional: a current-user scheduled task (`ClaudeScienceApiBridge`) restarts the proxy at logon. No admin, no system proxy, no hosts file, no port 443.

On Windows the live `/v1/models` list **is** the model menu. There is no Claude Science.app daemon to patch.

## What Windows gets

| Capability | Windows native equivalent |
| --- | --- |
| Local proxy on `127.0.0.1:9876` | `proxy.py` + `start-windows.ps1` / `start.bat` |
| Dashboard | English UI at `/dashboard` |
| Login auto-start | Scheduled task `ClaudeScienceApiBridge` (no admin) |
| User `ANTHROPIC_BASE_URL` | Dashboard "Set user ANTHROPIC_BASE_URL" or `setx` |
| Model menu | Live `/v1/models` (no macOS daemon binary patch) |
| Updates | `git pull` then rerun `scripts/install-safe.ps1` |

## Feature map (Windows + WSL)

Every Dashboard button stays visible. Windows/WSL implementations:

| Dashboard action | Windows + WSL behavior |
| --- | --- |
| Run test | `/v1/messages` through the local proxy |
| Open / Restart Claude Science | `claude-science serve --port 8765 --no-browser --detached` in Ubuntu-24.04 with `ANTHROPIC_BASE_URL`, then open the login URL in a Windows browser |
| Patch model menu | Byte-patch the WSL `~/.local/bin/claude-science` binary (auth URL + display names), same scripts as macOS |
| Refresh OAuth token | `setup-token.py` inside WSL using `~/.claude-science/encryption.key` |
| Set user ANTHROPIC_BASE_URL | Windows `setx` **and** WSL `~/.profile` / `~/.bashrc` |
| Install login service | Scheduled task `ClaudeScienceApiBridge` for the proxy |
| Check / install update | `git pull --ff-only` + `pip install -r requirements.txt` (not the macOS DMG) |
| CC Switch sync | Writes `~/.cc-switch` if that DB exists; `.app` install remains macOS-only |
| `/v1/models` menu | Always live for any `ANTHROPIC_BASE_URL` client |

Still impossible to clone 1:1: macOS `CC Switch.app` bundle replace, LaunchAgent plists, and the DMG installer. Those have the WSL/git/task replacements above.

## Install

```powershell
git clone https://github.com/Jyx0208/claude-science-api-bridge.git
cd claude-science-api-bridge
powershell -ExecutionPolicy Bypass -File .\scripts\install-safe.ps1
powershell -ExecutionPolicy Bypass -File .\start-windows.ps1
```

Or double-click `install.bat`, then `start.bat`.

The installer:

1. Creates `.venv` and installs Python dependencies
2. Creates `config.json` from `config.example.json` if missing
3. Applies provider settings from environment variables when set
4. Registers a current-user logon task (skip with `-SkipService`)
5. Does not change system proxy, DNS, VPN, TUN, hosts, certificates, or port 443

## Point a client at the bridge

```powershell
$env:ANTHROPIC_BASE_URL='http://127.0.0.1:9876'
```

Open the Dashboard at [http://127.0.0.1:9876/dashboard](http://127.0.0.1:9876/dashboard) to add a provider, fetch models, and run a test.

## Verify

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\self-test.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\verify-proxy.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\doctor.ps1
```

Vision check (requires a vision-capable backend):

```powershell
$env:VERIFY_IMAGE='1'
powershell -ExecutionPolicy Bypass -File .\scripts\verify-proxy.ps1
```

## Optional: official Claude Science in WSL

Anthropic does not ship a native Windows Science build. If Ubuntu-24.04 already has `claude-science` (for example `claude-science 0.1.43`), start the **Windows proxy first**, then:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\start-claude-science.ps1
```

That wraps the documented command:

```powershell
wsl -d Ubuntu-24.04 -- bash -lc "export ANTHROPIC_BASE_URL='http://127.0.0.1:9876'; exec ~/.local/bin/claude-science serve --port 8765 --no-browser"
```

Open `http://127.0.0.1:8765` in a Windows browser. WSL 2 forwards localhost. A local OAuth token, if needed, lives in the WSL home (`/home/<user>/.claude-science`), not the Windows home.

This is unofficial BYOK routing. Anthropic does not support third-party models inside Claude Science.

## Uninstall

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\uninstall.ps1
```

This stops the proxy, removes the logon task, and clears the user `ANTHROPIC_BASE_URL`. It does not delete `config.json`, API keys, or logs.
