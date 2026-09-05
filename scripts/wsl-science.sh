#!/usr/bin/env bash
# WSL helper for official Claude Science + this Windows bridge.
# Does not change Clash, VPN, DNS, system proxy, hosts, certificates, or port 443.
set -euo pipefail

DISTRO_HOME="${HOME}"
SCIENCE_BIN="${SCIENCE_BIN:-$DISTRO_HOME/.local/bin/claude-science}"
SCIENCE_PORT="${CLAUDE_SCIENCE_PORT:-8765}"
BRIDGE_DIR="${BRIDGE_DIR:-}"
PROXY_URL="${ANTHROPIC_BASE_URL:-http://127.0.0.1:9876}"
CMD="${1:-status}"

if [ -z "$BRIDGE_DIR" ]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  BRIDGE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
fi

die() { echo "error: $*" >&2; exit 1; }

require_science() {
  [ -x "$SCIENCE_BIN" ] || die "claude-science not found at $SCIENCE_BIN"
}

science_running() {
  require_science
  "$SCIENCE_BIN" status 2>/dev/null | python3 -c 'import json,sys; print("true" if json.load(sys.stdin).get("running") else "false")' 2>/dev/null || echo "false"
}

persist_env() {
  local marker="# claude-science-api-bridge ANTHROPIC_BASE_URL"
  local line="export ANTHROPIC_BASE_URL=\"$PROXY_URL\""
  local file
  for file in "$DISTRO_HOME/.profile" "$DISTRO_HOME/.bashrc"; do
    touch "$file"
    if grep -q "$marker" "$file" 2>/dev/null; then
      python3 - "$file" "$marker" "$line" <<'PY'
import pathlib, sys
path = pathlib.Path(sys.argv[1])
marker, line = sys.argv[2], sys.argv[3]
text = path.read_text(encoding="utf-8")
out = []
skip = False
for raw in text.splitlines(True):
    if raw.strip() == marker:
        out.append(raw if raw.endswith("\n") else raw + "\n")
        out.append(line + "\n")
        skip = True
        continue
    if skip:
        skip = False
        continue
    out.append(raw)
path.write_text("".join(out), encoding="utf-8")
PY
    else
      printf '\n%s\n%s\n' "$marker" "$line" >> "$file"
    fi
  done
  echo "Wrote ANTHROPIC_BASE_URL into ~/.profile and ~/.bashrc"
}

cmd_token() {
  [ -f "$DISTRO_HOME/.claude-science/encryption.key" ] || die "encryption.key missing in WSL ~/.claude-science"
  python3 "$BRIDGE_DIR/setup-token.py"
}

cmd_patch_auth() {
  require_science
  PYTHON=python3 PROXY_PORT="${PROXY_PORT:-9876}" "$BRIDGE_DIR/scripts/patch-daemon-auth.sh" "$SCIENCE_BIN"
}

cmd_patch_models() {
  require_science
  [ -f "$BRIDGE_DIR/config.json" ] || die "config.json not found in $BRIDGE_DIR"
  PYTHON=python3 CONFIG_FILE="$BRIDGE_DIR/config.json" "$BRIDGE_DIR/scripts/patch-daemon-models.sh" "$SCIENCE_BIN"
}

cmd_stop() {
  require_science
  "$SCIENCE_BIN" stop >/dev/null 2>&1 || true
  echo "stopped"
}

cmd_url() {
  require_science
  "$SCIENCE_BIN" url
}

cmd_status() {
  require_science
  "$SCIENCE_BIN" status
}

cmd_start() {
  require_science
  persist_env
  export ANTHROPIC_BASE_URL="$PROXY_URL"
  if [ "$(science_running)" = "true" ]; then
    echo "already running"
    "$SCIENCE_BIN" url || true
    return 0
  fi
  if [ -f "$DISTRO_HOME/.claude-science/encryption.key" ]; then
    python3 "$BRIDGE_DIR/setup-token.py" >/dev/null || true
  fi
  "$SCIENCE_BIN" serve --port "$SCIENCE_PORT" --no-browser --detached --no-auto-update
  sleep 2
  "$SCIENCE_BIN" url || true
}

cmd_restart() {
  cmd_stop
  sleep 1
  cmd_start
}

case "$CMD" in
  start) cmd_start ;;
  stop) cmd_stop ;;
  restart) cmd_restart ;;
  url) cmd_url ;;
  status) cmd_status ;;
  token) cmd_token ;;
  patch-auth) cmd_patch_auth ;;
  patch-models) cmd_patch_models ;;
  setenv) persist_env ;;
  *) die "unknown command: $CMD" ;;
esac
