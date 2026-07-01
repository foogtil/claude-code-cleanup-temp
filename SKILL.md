---
name: cleanup-temp
description: Clean up temporary/intermediate files that Claude created during the current task. Invoke this skill when finishing a task that produced scratch files, intermediate scripts, downloaded archives, or other throwaway artifacts, or whenever the Stop hook reminds you that .claude/tmp/ contains files to review.
---

# cleanup-temp

This skill governs the lifecycle of **temporary files** — the throwaway intermediate artifacts Claude creates while completing a task (scratch scripts, downloaded archives, intermediate data files, probe/exploration code, etc.).

## Where temp files live

ALL temporary files Claude creates MUST be written under:

```
<project-root>/.claude/tmp/
```

Never write a temp file anywhere else. Never write a user's requested deliverable into `.claude/tmp/` — that directory is exclusively for throwaway intermediates. If a file is something the user asked you to produce, it is NOT a temp file; put it where the user expects it.

Files the user declined to delete are moved to `.claude/tmp/keep/` (see below) so they are preserved but not re-offered.

## What counts as a temp file

A file is a temp file iff ALL of these hold:
- Claude created it during the current task (not pre-existing, not user-supplied).
- It is an intermediate/scratch artifact, not a requested deliverable.
- It lives under `.claude/tmp/`.

When in doubt, treat the file as NOT a temp file and leave it alone.

## Cleanup procedure

Run this when invoked, or when the Stop hook reminds you that `.claude/tmp/` is non-empty.

1. **List** the contents of `.claude/tmp/` (excluding the `keep/` subfolder). Use `ls` / `Glob`.
2. **Classify** each entry:
   - *This session*: files you created during the current task.
   - *Stale*: files from earlier sessions you did not create now.
3. **Present a checklist to the user**, e.g.:
   ```
   .claude/tmp/ contains:
     [this session]  parse_probe.py        — scratch parser used while debugging
     [this session]  raw_dump.csv          — intermediate data, no longer needed
     [stale]         old_test.sh           — from a previous session
   Delete which? Reply with the names, "all", "all this-session", or "none".
   ```
4. **Act on the user's answer**:
   - Files the user confirms → delete them.
   - Files the user says to keep → `mv` them into `.claude/tmp/keep/` (create it if missing). The Stop hook ignores `keep/`, so they will not be re-offered next time.
   - "none" → do nothing.
5. **Never delete**:
   - Anything outside `.claude/tmp/`.
   - Anything the user did not confirm.
   - The `keep/` subfolder or its contents.
6. **Report** concisely what was deleted, what was moved to `keep/`, and what was left.

## Safety rules (non-negotiable)

- This skill ONLY ever deletes files inside `.claude/tmp/` (excluding `keep/`).
- Never delete silently — always list and get explicit confirmation first.
- Never use destructive flags (`rm -rf` on broad paths, `*` globs without preview). Delete named files one by one or via an explicitly listed set after showing the user.
- If `.claude/tmp/` contains something you did not create and do not recognize, surface it to the user rather than deleting it.

## Notes

- The Stop hook fires this skill automatically when `.claude/tmp/` (excluding `keep/`) is non-empty. You do not need to remember to clean up — but you DO need to remember to write temp files into `.claude/tmp/` in the first place.
- Add `.claude/tmp/` to the project's `.gitignore` if the project is a git repo, so temp files never get committed.
