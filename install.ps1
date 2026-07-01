# Installer for the cleanup-temp Claude Code skill + Stop hook (Windows).
# Idempotent: safe to re-run.

$ErrorActionPreference = 'Stop'

$ClaudeDir = if ($env:CLAUDE_DIR) { $env:CLAUDE_DIR } else { Join-Path $env:USERPROFILE '.claude' }
$SkillDir  = Join-Path $ClaudeDir 'skills\cleanup-temp'
$HooksDir  = Join-Path $ClaudeDir 'hooks'
$Settings  = Join-Path $ClaudeDir 'settings.json'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "Installing cleanup-temp skill to $ClaudeDir ..."

New-Item -ItemType Directory -Force -Path $SkillDir | Out-Null
New-Item -ItemType Directory -Force -Path $HooksDir | Out-Null

Copy-Item "$ScriptDir\SKILL.md" "$SkillDir\SKILL.md" -Force
Copy-Item "$ScriptDir\hooks\cleanup-temp-stop.ps1" "$HooksDir\cleanup-temp-stop.ps1" -Force

$HookCmd = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$HooksDir\cleanup-temp-stop.ps1`""

if (-not (Test-Path $Settings)) {
    [System.IO.File]::WriteAllText($Settings, '{}')
}
$cfg = Get-Content -Raw $Settings | ConvertFrom-Json
if (-not $cfg) { $cfg = [PSCustomObject]@{} }

# Ensure hooks.Stop structure exists.
if (-not ($cfg.PSObject.Properties.Name -contains 'hooks')) {
    $cfg | Add-Member -NotePropertyName hooks -NotePropertyValue ([PSCustomObject]@{})
}
if (-not ($cfg.hooks.PSObject.Properties.Name -contains 'Stop')) {
    $cfg.hooks | Add-Member -NotePropertyName Stop -NotePropertyValue @()
}

# Register only if not already present.
$existing = @($cfg.hooks.Stop) | Where-Object {
    $_.hooks | Where-Object { $_.command -match 'cleanup-temp-stop' }
}
if ($existing) {
    Write-Host "Stop hook already registered in $Settings - skipping."
} else {
    $entry = [PSCustomObject]@{
        hooks = @([PSCustomObject]@{ type = 'command'; command = $HookCmd })
    }
    $cfg.hooks.Stop = @($cfg.hooks.Stop) + $entry
    $json = $cfg | ConvertTo-Json -Depth 10
    [System.IO.File]::WriteAllText($Settings, $json)
    Write-Host "Registered Stop hook in $Settings"
}

Write-Host ""
Write-Host "Done. Restart Claude Code for the hook to take effect."
Write-Host "Tip: add '.claude\tmp\' to your project's .gitignore."
