# GitHub publishing

This project: **Claude Science Bridge for Windows**  
https://github.com/priyamthakar/claude-science-bridge-for-windows  
Default branch: `windows-native`

Inspired by [Jyx0208/claude-science-api-bridge](https://github.com/Jyx0208/claude-science-api-bridge) (MIT). Do not push secrets to either repo.

## Before every push

From `D:\claude-science-bridge-for-windows` (or the clone root):

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\self-test.ps1
git status
git diff --cached
```

Confirm these are **not** staged:

- `config.json`
- `.env`
- `certs/`
- `__pycache__/`
- logs
- API keys, OAuth tokens, `encryption.key`

```powershell
git add <docs and code>
git commit -m "Your message"
git push origin windows-native
```

Never paste API keys or token contents into GitHub issues.
