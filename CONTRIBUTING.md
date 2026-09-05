# Contributing

## Development Setup

Windows (this fork’s primary path):

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install-safe.ps1 -SkipService
powershell -ExecutionPolicy Bypass -File .\scripts\self-test.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\doctor.ps1
```

macOS / Linux:

```bash
python3 -m venv .venv
. .venv/bin/activate
pip install -r requirements-dev.txt
./scripts/self-test.sh
./scripts/doctor.sh
```

## Safety Rules

- Keep safe mode as the default path.
- Do not add scripts that silently modify Clash, VPN, TUN, DNS, or system proxy settings.
- Do not log request bodies by default.
- Do not commit generated certificates or API keys.
- Put advanced network interception behind explicit commands.

## Pull Request Checklist

- `scripts/self-test.ps1` (Windows) or `./scripts/self-test.sh` passes.
- If a backend API key is configured, `scripts/verify-proxy.ps1` / `./scripts/verify-proxy.sh` passes.
- README, `docs/windows.md`, and `AGENTS.md` still match behavior.
- No secrets are staged.
