# Findings

- 2026-11-13 · The stop hook's six-heading report check may not run when an employee finishes through the
  desktop app's `SubagentHandback` call: five employees finished with complete reports today and no
  `triple-a-crew-done-*` marker was written (`plugins/triple-a-crew/scripts/subagent-stop.sh:149` allows when
  the input has no `last_assistant_message`). The docs say that field holds only closing text in that case.
  Not probed live · found by T1 researcher and the organizer · crew feedback, waits for the close step
- 2026-11-13 · A worktree-isolated employee cannot write its status file in the main checkout; the stop hook
  then blocks it three times before letting it go · found by `organizer-rules` P1 · handled in
  `organizer-rules` (issue F)
- 2026-11-13 · `updated` far in the past is not checked (out of scope: #32 asks for future or missing) · no
  issue
- 2026-11-13 · `claude plugin validate <root>` prints only "Validating marketplace manifest"; it may not read
  `plugins/triple-a-crew/hooks/hooks.json` at all, so that verify command may prove less than it seems for
  hooks · found by T9 reviewer · crew feedback, waits for the close step
- 2026-11-13 · Hook state files fall back to `${TMPDIR:-/tmp}` when `CLAUDE_PLUGIN_DATA` is unset. On a shared
  Linux machine another local user could plant a symlink under a state file's name. The stop hook already
  did this; three more scripts now do · found by T9 reviewer · crew feedback, waits for the close step
- 2026-11-13 · The guard's brief check is a substring match: a brief that lists `x | q2` also allows `x | q`
  · found by T4 engineer · accepted (the guard is a reminder, not a wall)
- 2026-11-13 · The probe left an empty folder `~/.claude/plugins/data/hookprobe-inline`, created by Claude
  Code for the throwaway plugin. Earlier probes left the same kind (`spike-inline`, `teams-probe-inline`) ·
  found by T2 engineer · told to the user; not removed
