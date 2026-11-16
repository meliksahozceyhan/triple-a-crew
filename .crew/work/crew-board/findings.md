# Findings

- 2026-11-16 · The agent files list `Glob` and `Grep` (`plugins/triple-a-crew/agents/*.md:4`), but Claude Code
  2.1.325 on this machine has neither tool, for the main session or for a subagent whose `tools:` line names
  them; employees search through Bash (`grep`, `ls`, `find`) · found by T1 researcher (probe run 2) · crew
  feedback, filed as #61
- 2026-11-16 · The docs say a main session started with `--agent` carries `agent_type` but no `agent_id`; not
  probed. The command guard already leaves when `agent_id` is missing; the activity hook must do the same ·
  found by T1 researcher · covered in T2's brief
- 2026-11-16 · The hook wrote through a symbolic link: `live` as a link to a folder outside the work item, and
  by the same `>>` a log path that is a link to any file. A repository could ship such a link, and file names
  it controls would be appended to the linked file · found by T5 test-engineer (the `live` case; the log case
  by the organizer) · sent to T2 as a defect
- 2026-11-16 · A WebFetch URL with a slash in its password (`https://user:pa/ss@host`) put the user name into
  the log; a token typed as a bare command (`sk-abc123 --flag`) is written as the program name · found by T5 ·
  sent to T2
- 2026-11-16 · `parse.mjs` split a board cell at an escaped pipe (`\|`), which lost the row's status file; an
  item listed under both Open and Closed lost its logs on every read; `//evil.test/api/state` answered 200 ·
  found by T5 · sent to T3
- 2026-11-16 · Not specified, left as it is: nested list items under a progress item become items of their
  own, a second `## Progress` merges into the first, a second table in a board is ignored · found by T5 · not
  filed
- 2026-11-16 · Review T9, must-fix M1: the hook split a Bash command at blanks with no notion of quotes, so
  `PGPASSWORD="my hunter2 pass" psql` wrote `hunter2` as the program name. The engineer's own test for it
  passed for the wrong reason · found by T9 reviewer · T2's first miss, sent back
- 2026-11-16 · Review T9, must-fix M2: the link checks stopped at `live`; a work item folder that is a link
  was written through by the hook and pruned through by session start, which deleted an old `*.log` outside
  the project · found by T9 reviewer · T2's first miss, sent back
- 2026-11-16 · Review T9, left as they are: the no-jq reader and `jq` differ on input Claude Code does not
  send (N1); the prune starts one `find` per `live/` folder, 2.6 ms each (N3); a root written with `..` logs
  absolute paths (N5) · found by T9 reviewer · not filed
- 2026-11-16 · A reviewer's nits were only in its final message, not in its status file, so the engineer sent
  back with "read the review file" could not see them (T10's N1 to N16). The researcher's report has a rule
  for this (lesson L11); the reviewer's findings have none · seen by the organizer · crew feedback, filed as
  #60
- 2026-11-16 · Out of scope: a teammate's `PreToolUse` input in agent-teams mode was never probed, so the
  activity hook logs a teammate only when its brief can be read (the same limit as the command guard) · from
  the edge-case list · not filed
- 2026-11-16 · Out of scope: a live log has no size limit; the page reads only its end · from the edge-case
  list · not filed
- 2026-11-16 · Out of scope: the organizer's own tool calls are not shown on the page, because a main-session
  call carries no agent id · from the edge-case list · not filed
- 2026-11-16 · Out of scope: two board servers on one project, and steering agents from the page (pause,
  stop). The user wrote "more controllable"; asked what they mean on 2026-11-16, no answer yet · not filed
