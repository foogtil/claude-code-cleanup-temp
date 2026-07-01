#!/usr/bin/env bash
# Stop hook for the cleanup-temp skill (macOS/Linux).
# Reminds Claude to clean up .claude/tmp/ when it is non-empty.
#
# Behavior:
#  - If stop_hook_active is true, exit silently (avoid loop / re-reminder in the same chain).
#  - If <cwd>/.claude/tmp/ is missing or empty (ignoring the keep/ subfolder), exit silently.
#  - Otherwise, block the stop with a reason that tells Claude to invoke the cleanup-temp skill.
#
# Input: JSON on stdin with at least { cwd, stop_hook_active }.
# Output: a single JSON object on stdout when blocking; nothing otherwise.
# Requires: jq

set -u

if ! command -v jq >/dev/null 2>&1; then
  exit 0
fi

payload="$(cat)"

active="$(printf '%s' "$payload" | jq -r '.stop_hook_active // false' 2>/dev/null || printf 'false')"
[ "$active" = "true" ] && exit 0

cwd="$(printf '%s' "$payload" | jq -r '.cwd // empty' 2>/dev/null || printf '')"
[ -z "$cwd" ] && cwd="$PWD"

tmpdir="$cwd/.claude/tmp"
[ -d "$tmpdir" ] || exit 0

# Entries excluding the keep/ subfolder.
entries="$(ls -A "$tmpdir" 2>/dev/null | grep -vx 'keep' || true)"
[ -z "$entries" ] && exit 0

count="$(printf '%s\n' "$entries" | grep -c . || printf '0')"
names="$(printf '%s\n' "$entries" | paste -sd, -)"
reason="Before finishing: .claude/tmp/ contains $count item(s) [$names]. Invoke the cleanup-temp skill: list them, classify this-session vs stale, show the user a checklist, delete only what they confirm, move declined items into .claude/tmp/keep/, and report. If nothing here is yours, say so and stop."

printf '{"decision":"block","reason":%s}' "$(printf '%s' "$reason" | jq -Rs .)"
