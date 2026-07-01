# Stop hook: remind Claude to clean up .claude/tmp/ when it is non-empty.
#
# Behavior:
#  - If stop_hook_active is true, exit silently (avoid loop / re-reminder in the same chain).
#  - If <cwd>/.claude/tmp/ is missing or empty (ignoring the keep/ subfolder), exit silently.
#  - Otherwise, block the stop with a reason that tells Claude to invoke the cleanup-temp skill.
#
# Input: JSON on stdin with at least { cwd, stop_hook_active }.
# Output: a single JSON object on stdout when blocking; nothing otherwise.

$ErrorActionPreference = 'SilentlyContinue'

$raw = [Console]::In.ReadToEnd()
$payload = $null
try {
    if ($raw -and $raw.Trim()) { $payload = $raw | ConvertFrom-Json }
} catch {
    # Malformed input — bail out silently rather than crash.
    exit 0
}

if ($payload -and $payload.stop_hook_active) { exit 0 }

$cwd = if ($payload -and $payload.cwd) { $payload.cwd } else { (Get-Location).Path }
$tmpDir = Join-Path $cwd ".claude\tmp"

if (-not (Test-Path -LiteralPath $tmpDir -PathType Container)) { exit 0 }

$entries = @(Get-ChildItem -LiteralPath $tmpDir -Force | Where-Object { $_.Name -ne 'keep' })
if ($entries.Count -eq 0) { exit 0 }

$names = ($entries | ForEach-Object { $_.Name }) -join ', '
$count = $entries.Count
$reason = "Before finishing: .claude/tmp/ contains $count item(s) [$names]. Invoke the cleanup-temp skill: list them, classify this-session vs stale, show the user a checklist, delete only what they confirm, move declined items into .claude/tmp/keep/, and report. If nothing here is yours, say so and stop."

$obj = [PSCustomObject]@{ decision = 'block'; reason = $reason }
[Console]::Out.Write(($obj | ConvertTo-Json -Compress))
