# Claude Science Bridge for Windows — this PC

Local Anthropic-compatible proxy for `ANTHROPIC_BASE_URL` clients. This folder is the Windows + WSL port of [Jyx0208/claude-science-api-bridge](https://github.com/Jyx0208/claude-science-api-bridge), published as [priyamthakar/claude-science-bridge-for-windows](https://github.com/priyamthakar/claude-science-bridge-for-windows). On this machine the backend is **9Router**, including `oc/muse-spark-1.3-contributor-free` (Muse Spark 1.3 Free).

Portable install notes (no machine paths): [docs/windows.md](docs/windows.md).

> `proxy.py` is pure Python and runs natively on Windows. Official Claude Science here is the Linux binary under WSL `Ubuntu-24.04`.

---

## 1. Locations

| Item | Path |
|---|---|
| Bridge | `D:\claude-science-bridge-for-windows` |
| GitHub | https://github.com/priyamthakar/claude-science-bridge-for-windows |
| Starter | `D:\claude-science-bridge-for-windows\start-windows.ps1` |
| Config (keys + mapping) | `D:\claude-science-bridge-for-windows\config.json` (git-ignored) |
| Python env | `D:\claude-science-bridge-for-windows\.venv` |
| Windows logs | `%USERPROFILE%\.claude-science\logs` |
| 9Router data | `%APPDATA%\9router` |
| Dashboard | http://127.0.0.1:9876/dashboard |
| Health | http://127.0.0.1:9876/health |
| 9Router API | http://127.0.0.1:20128/v1 |
| 9Router dashboard | http://localhost:20128/dashboard |
| WSL Science UI | http://127.0.0.1:8765 |

## 2. Requirements

- Windows 10/11 + PowerShell 5.1 or newer
- Python 3.12
- Node.js + npm with `9router` (`npm i -g 9router`)
- 9Router providers connected. Current: antigravity, grok-cli, deepseek, tokenrouter, opencode-go, codex
- Optional: WSL Ubuntu-24.04 with `claude-science` (this PC: 0.1.43)

## 3. Daily startup

Order: **9Router first, then the bridge**. Two PowerShell windows.

**Window 1 — 9Router (keep open):**
```powershell
9router
```

**Window 2 — bridge (keep open):**
```powershell
powershell -ExecutionPolicy Bypass -File D:\claude-science-bridge-for-windows\start-windows.ps1
```

**Verify + open:**
```powershell
Invoke-RestMethod http://127.0.0.1:9876/health | Select-Object status, default_backend, custom_configured, os_family, wsl_distro
Start-Process "http://127.0.0.1:9876/dashboard"
```

**Client env (this session):**
```powershell
$env:ANTHROPIC_BASE_URL='http://127.0.0.1:9876'
```

**Optional — official Science in WSL (after the bridge is up):**
```powershell
powershell -ExecutionPolicy Bypass -File D:\claude-science-bridge-for-windows\scripts\start-claude-science.ps1
```
Then open http://127.0.0.1:8765 in a Windows browser.

Stop the bridge with Ctrl+C or `.\scripts\stop.ps1`.

## 4. Current configuration

Backend: `custom` → `http://127.0.0.1:20128/v1` (`custom_upstream_mode=openai`),
`model_list_mode=aliases`, `model_menu_strategy=claude_compatible`,
`inline_image_policy=preserve`, `reasoning_content_policy=never`.

| Claude slot | Display name | Real 9Router model |
|---|---|---|
| `claude-opus-4-8` | gpt-5.6-sol | `cx/gpt-5.6-sol` |
| `claude-sonnet-5` | grok-4.6-high | `gcli/grok-4.6-high` |
| `claude-haiku-4-5` | Muse Spark 1.3 Free | `oc/muse-spark-1.3-contributor-free` |

## 5. 9Router notes

- `/v1/models` on 9Router lists a subset only (~51 models, prefixes `ag/ cx/ ds/ gcli/ ocg/ tokenrouter/`). **`oc/` models are not listed but are callable.**
- If `/v1/messages` returns 401, the 9Router key likely rotated — re-sync it into `config.json` from the 9Router dashboard (do not commit that file).
- If a model stops working, check its provider is still connected at http://localhost:20128/dashboard → Providers.

## 6. Muse Spark 1.3 Free quirks

1. **Hidden from fetch list** — keep it in `config.json` (`model_aliases` + `custom_model_map`). Re-applying the Dashboard model picker can overwrite it; re-add afterwards.
2. **Minimum budget** — provider rejects `max_output_tokens < 16`. Use generous `max_tokens` (2000+).
3. **Streaming only** — non-streaming `/v1/messages` can return HTTP 200 with empty content. Streaming returns the real text. Claude Science streams by default.

## 7. Verification

```powershell
Invoke-RestMethod http://127.0.0.1:9876/health
(Invoke-RestMethod http://127.0.0.1:9876/v1/models).data | Format-Table id, display_name

$body = @{model='claude-opus-4-8'; max_tokens=32;
  messages=@(@{role='user'; content='Reply OK'})} | ConvertTo-Json -Depth 5
Invoke-RestMethod -Uri "http://127.0.0.1:9876/v1/messages" -Method Post `
  -ContentType "application/json" -Body $body

$body = @{model='claude-haiku-4-5'; max_tokens=2000; stream=$true;
  messages=@(@{role='user'; content='Reply with exactly: OK'})} | ConvertTo-Json -Depth 5
Invoke-WebRequest -Uri "http://127.0.0.1:9876/v1/messages" -Method Post `
  -ContentType "application/json" -Body $body -TimeoutSec 180

Invoke-RestMethod http://127.0.0.1:9876/api/recent-requests
```

Or: `.\scripts\verify-proxy.ps1`

## 8. Dashboard (English)

- **Providers**: add/edit/clone/switch backends. Keys stay on the server.
- **Model menu**: fetch list → tick models → Apply to menu. Hidden `oc/*` models stay in `config.json` (§6.1).
- **Open / Restart Claude Science**: starts WSL `claude-science serve` on `:8765` with `ANTHROPIC_BASE_URL` pointed at this proxy.
- **Apply and patch menu**: updates `/v1/models` and patches the WSL `claude-science` binary display names.
- **Refresh OAuth token**: mints a local token in WSL `~/.claude-science`.
- **Install login service**: Windows scheduled task `ClaudeScienceApiBridge`.
- **Update**: `git pull` + pip (not a macOS DMG).
- **CC Switch sync**: writes `~/.cc-switch` if present. Installing `CC Switch.app` is still macOS-only.
- **Diagnostics**: recent requests with backend model and success/fail.

## 9. Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `/v1/messages` → 401 | 9Router key rotated / provider logged out | Re-login in 9Router, re-sync key, restart bridge |
| Empty content, `output_tokens: 0` | Budget too small or non-stream Muse Spark | Raise `max_tokens`; use `stream:true` for `oc/*` |
| Port 9876 in use | Old proxy still running | `.\scripts\stop.ps1` then start again |
| 9Router down (`:20128`) | 9Router window closed | Start `9router` first, then the bridge |
| Science UI not on `:8765` | WSL daemon not started with the env var | Start the bridge, then `scripts\start-claude-science.ps1` |

## 10. Rebuild if this folder is lost

```powershell
git clone https://github.com/priyamthakar/claude-science-bridge-for-windows.git D:\claude-science-bridge-for-windows
cd D:\claude-science-bridge-for-windows
git checkout windows-native
powershell -ExecutionPolicy Bypass -File .\scripts\install-safe.ps1
# restore config.json from backup (never from git), then start-windows.ps1
```

## 11. Security

- Never commit `config.json`, `.env`, logs, or `.venv`.
- The bridge binds `127.0.0.1` only.
- Optional `proxy_auth_mode: required` + `proxy_auth_token` restricts other local processes (then `ANTHROPIC_BASE_URL` must include the secret).
