#!/usr/bin/env bash
# Installer for the cleanup-temp Claude Code skill + Stop hook (macOS/Linux).
# Idempotent: safe to re-run.

set -euo pipefail

CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
SKILL_DIR="$CLAUDE_DIR/skills/cleanup-temp"
HOOKS_DIR="$CLAUDE_DIR/hooks"
SETTINGS="$CLAUDE_DIR/settings.json"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing cleanup-temp skill to $CLAUDE_DIR ..."

if ! command -v jq >/dev/null 2>&1; then
  echo "ERROR: jq is required. Install it (e.g. 'brew install jq' or 'apt install jq') and re-run." >&2
  exit 1
fi

mkdir -p "$SKILL_DIR" "$HOOKS_DIR"
cp "$SCRIPT_DIR/SKILL.md" "$SKILL_DIR/SKILL.md"
cp "$SCRIPT_DIR/hooks/cleanup-temp-stop.sh" "$HOOKS_DIR/cleanup-temp-stop.sh"
chmod +x "$HOOKS_DIR/cleanup-temp-stop.sh"

HOOK_CMD="bash \"$HOOKS_DIR/cleanup-temp-stop.sh\""

if [ ! -f "$SETTINGS" ]; then
  echo "{}" > "$SETTINGS"
fi

if jq -e '.hooks.Stop[]? | .hooks[]? | select(.command | test("cleanup-temp-stop"))' "$SETTINGS" >/dev/null 2>&1; then
  echo "Stop hook already registered in $SETTINGS — skipping."
else
  tmp="$(mktemp)"
  jq --arg cmd "$HOOK_CMD" \
    '.hooks.Stop = ((.hooks.Stop // []) + [{"hooks":[{"type":"command","command":$cmd}]}])' \
    "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"
  echo "Registered Stop hook in $SETTINGS"
fi

echo
echo "Done. Restart Claude Code for the hook to take effect."
echo "Tip: add '.claude/tmp/' to your project's .gitignore."
