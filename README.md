# claude-code-cleanup-temp

A [Claude Code](https://docs.anthropic.com/en/docs/claude-code) **skill + Stop hook** that automatically reminds Claude to clean up the temporary/intermediate files it creates while working on a task.

When Claude finishes a task, if any throwaway scratch files are sitting in `.claude/tmp/`, the Stop hook nudges Claude to list them, ask you which to delete, and remove only the ones you confirm. **No silent deletion, no touching files outside the temp directory.claude/tmp/ 
> Community project — not affiliated with Anthropic.

---

## Why

Claude often creates intermediate artifacts while completing a task — a quick probe script, a downloaded archive, a temporary CSV used for a transformation. These pile up and clutter your project. This skill gives them a single, predictable home (`.claude/tmp/`) and cleans them up at the end of each task — with your confirmation.

## How it works

1. While working, Claude writes any scratch/intermediate file into `<project>/.claude/tmp/` (not alongside your real code).
2. When Claude stops, the **Stop hook** checks `.claude/tmp/`:
   - Empty / missing / only a `keep/` subfolder → **silent**, zero interruption.
   - Has files → returns a `block` decision that reminds Claude to run the `cleanup-temp` skill.
3. The skill lists the files, classifies them (*created this session* vs. *stale leftovers*), shows you a checklist, and:
   - **Deletes** the ones you confirm.
   - **Moves** the ones you want to keep into `.claude/tmp/keep/` (the hook ignores that folder, so they won't be offered again).
   - Leaves everything else untouched.

A built-in `stop_hook_active` guard prevents reminder loops, so you're never pestered twice in a row.

## Requirements

- **Claude Code** (CLI).
- **macOS / Linux:** [`jq`](https://stedolan.github.io/jq/) — `brew install jq` / `apt install jq` / `dnf install jq`.
- **Windows:** PowerShell (preinstalled on Windows 10/11).

## Install

### Quick (install script)

**macOS / Linux**
```bash
git clone https://github.com/foogtil/claude-code-cleanup-temp.git
cd claude-code-cleanup-temp
./install.sh
```

**Windows (PowerShell)**
```powershell
git clone https://github.com/foogtil/claude-code-cleanup-temp.git
cd claude-code-cleanup-temp
.\install.ps1
```

The installer copies the skill to `~/.claude/skills/cleanup-temp/`, the hook to `~/.claude/hooks/`, and registers the Stop hook in `~/.claude/settings.json`. It's **idempotent** — safe to re-run. Then **restart Claude Code** so the hook is picked up.

### Manual

1. Copy `SKILL.md` → `~/.claude/skills/cleanup-temp/SKILL.md`.
2. Copy the hook for your OS into `~/.claude/hooks/`:
   - macOS/Linux: `hooks/cleanup-temp-stop.sh` (then `chmod +x`).
   - Windows: `hooks/cleanup-temp-stop.ps1`.
3. Add a Stop hook to `~/.claude/settings.json` (merge into any existing keys):

**macOS / Linux**
```json
{
  "hooks": {
    "Stop": [
      { "hooks": [ { "type": "command", "command": "bash \"$HOME/.claude/hooks/cleanup-temp-stop.sh\"" } ] }
    ]
  }
}
```一个[Claude代码](https://docs.anthropic.com/en/docs/claude-code) **技能停止钩子**，它自动提醒Claude清理它在处理任务时创建的临时/中间文件。

**Windows**
```json
{
  "hooks": {
    "Stop": [
      { "hooks": [ { "type": "command", "command": "powershell.exe -NoProfile -ExecutionPolicy Bypass -File \"%USERPROFILE%\\.claude\\hooks\\cleanup-temp-stop.ps1\"" } ] }
    ]
  }
}
```

Restart Claude Code.   

## Usage   

Use Claude Code as usual — there's nothing special to do. When Claude creates intermediate files it puts them in `.claude/tmp/`; when it finishes a task, it asks you what to clean up.

You can also invoke the skill manually any time with `/cleanup-temp`.你也可以在任何时候使用`/cleanup-temp`手动调用该技能。

**Tip:** add `.claude/tmp/` to your project's `.gitignore` so temp files never get committed:
```
.claude/tmp/
```

## Safety   

- The hook and skill **only ever operate inside `.claude/tmp/`** (excluding `keep/`).
- **Nothing is ever deleted silently** — Claude always lists the files and waits for your explicit confirmation.- 
- Files you decline to delete are moved to `.claude/tmp/keep/` and not re-offered.
- If `.claude/tmp/` contains something Claude didn't create, it surfaces it to you instead of deleting.
- The skill never uses broad `rm -rf` / wildcard deletes — only named files you've approved.

## Uninstall

1. Remove the `Stop` hook entry whose command contains `cleanup-temp-stop` from `~/.claude/settings.json`.
2. Delete `~/.claude/skills/cleanup-temp/` and `~/.claude/hooks/cleanup-temp-stop.*`.

## Project structure   

```
SKILL.md                         # the skill definition
hooks/cleanup-temp-stop.sh       # Stop hook (macOS/Linux)hooks/cleanup-temp-stop.sh 
hooks/cleanup-temp-stop.ps1      # Stop hook (Windows)钩子/ cleanup-temp-stop。ps1 
install.sh / install.ps1         # one-command installerinstall.sh /安装。Ps1 
LICENSE                          # MIT
```

## How Claude Code skills & hooks work## Claude Code skills &； hooks

- A **skill** is a Markdown file with frontmatter that Claude reads when relevant. It carries the cleanup logic and safety rules.- 
- A **Stop hook** is a command Claude Code runs every time Claude finishes responding. Here it checks the temp dir and, if non-empty, blocks the stop with a reminder that drives Claude to the skill. Hooks are configured in `settings.json`.- 

## License   

MIT © foogtil

## Contact information

Please contact me via the email address below if you have any questions: lhy_ynmzdx@qq.com

*Disclaimer: This tool is for learning and communication purposes only. Users shall bear all risks and responsibilities arising from the use of this tool.*
