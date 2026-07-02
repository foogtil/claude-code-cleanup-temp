# claude-code-cleanup-temp

A [Claude Code](https://docs.anthropic.com/en/docs/claude-code) **skill + Stop hook** that automatically reminds Claude to clean up the temporary/intermediate files it creates while working on a task.一个[Claude代码](https://docs.anthropic.com/en/docs/claude-code) **技能停止钩子**，它自动提醒Claude清理它在处理任务时创建的临时/中间文件。

When Claude finishes a task, if any throwaway scratch files are sitting in `.claude/tmp/`, the Stop hook nudges Claude to list them, ask you which to delete, and remove only the ones you confirm. **No silent deletion, no touching files outside the temp directory.**当Claude完成一项任务时，是否有任何一次性的临时文件。claude/tmp/ '时，停止钩子会轻推claude列出它们，询问你要删除哪些，并只删除你确认的那些。**禁止静默删除，禁止触摸临时目录之外的文件。**

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

Restart Claude Code.   重启克劳德代码。

## Usage   # #使用

Use Claude Code as usual — there's nothing special to do. When Claude creates intermediate files it puts them in `.claude/tmp/`; when it finishes a task, it asks you what to clean up.像往常一样使用克劳德代码，没有什么特别的事情要做。当Claude创建中间文件时，它会把它们放在`.claude/tmp/`中；当它完成一项任务时，它会询问你需要清理哪些内容。

You can also invoke the skill manually any time with `/cleanup-temp`.你也可以在任何时候使用`/cleanup-temp`手动调用该技能。

**Tip:** add `.claude/tmp/` to your project's `.gitignore` so temp files never get committed:**提示：**添加`. js `。Claude /tmp/`到你项目的`。Gitignore `这样临时文件就不会被提交：
```
.claude/tmp/
```

## Safety   # #安全

- The hook and skill **only ever operate inside `.claude/tmp/`** (excluding `keep/`).-钩子和技能**只适用于内部。Claude /tmp/`**（不包括`keep/`）。
- **Nothing is ever deleted silently** — Claude always lists the files and waits for your explicit confirmation.- **不会静默删除任何内容** &mdash； Claude总是列出文件并等待你的确认。
- Files you decline to delete are moved to `.claude/tmp/keep/` and not re-offered.-你拒绝删除的文件被移动到`。Claude /tmp/keep/`并且没有被重新报价。
- If `.claude/tmp/` contains something Claude didn't create, it surfaces it to you instead of deleting.-如果`。` claude/tmp/`包含了一些claude没有创建的东西，它会显示给你，而不是删除。
- The skill never uses broad `rm -rf` / wildcard deletes — only named files you've approved.-该技能从不使用宽泛的`rm -rf   rm射频` /通配符删除&mdash；只命名文件，你已经批准。

## Uninstall   # #卸载

1. Remove the `Stop` hook entry whose command contains `cleanup-temp-stop` from `~/.claude/settings.json`.1. 从`~/.claude/settings.json`中删除`Stop`钩子项，其命令包含`cleanup-temp-stop`。
2. Delete `~/.claude/skills/cleanup-temp/` and `~/.claude/hooks/cleanup-temp-stop.*`.2. ~ /删除”。`. Claude /skills/cleanup-temp/`和`~/. Claude /hooks/cleanup-temp-stop.*`

## Project structure   ##项目结构

```
SKILL.md                         # the skill definition技能。md#技能定义
hooks/cleanup-temp-stop.sh       # Stop hook (macOS/Linux)hooks/cleanup-temp-stop.sh #停止hook （macOS/Linux）
hooks/cleanup-temp-stop.ps1      # Stop hook (Windows)钩子/ cleanup-temp-stop。ps1 #停止钩子（Windows）
install.sh / install.ps1         # one-command installerinstall.sh /安装。Ps1 #单命令安装程序
LICENSE                          # MIT
```

## How Claude Code skills & hooks work## Claude Code skills &； hooks是如何工作的

- A **skill** is a Markdown file with frontmatter that Claude reads when relevant. It carries the cleanup logic and safety rules.- **skill**是一个包含frontmatter的Markdown文件，Claude会在相关的时候阅读。它带有清理逻辑和安全规则。
- A **Stop hook** is a command Claude Code runs every time Claude finishes responding. Here it checks the temp dir and, if non-empty, blocks the stop with a reminder that drives Claude to the skill. Hooks are configured in `settings.json`.- **停止钩子**是Claude代码在每次完成响应时运行的命令。在这里，它检查了temp目录，如果非空，则阻止停止，并提示Claude使用技能。Hooks在`settings.json`中配置。

## License   # #许可证

MIT © foogtil

## Contact information

Please contact me via the email address below if you have any questions: lhy_ynmzdx@qq.com
