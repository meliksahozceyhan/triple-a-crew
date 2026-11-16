# Live status view for the crew: board page and activity hook

**Size:** L · **Ticket:** none · **Opened:** 2026-11-16

## What

Two parts that work together and also apart:

1. **The board page**, a prototype in `tools/crew-board/` (outside the plugin, not shipped to plugin users).
   A small Node script with no dependencies serves a page on `127.0.0.1`. It reads `.crew/work/` (the index,
   each open item's board, each employee's status file) and shows every employee as an animated character
   with its todo list, state and the age of its last update.
2. **The activity hook**, in the `triple-a-crew` plugin. Before each tool call of a crew employee it appends
   one short line (time, tool, short target, never content) to `.crew/work/<id>/live/<task>-<role>.log`.
   It writes only when the `live/` folder exists, and the board script is what creates that folder. The page
   shows the last lines as the character's current action, and the line count as its tool-call count.

Released as `triple-a-crew` 1.2.0 (the hook; the page stays a prototype in this repository).

## Why

The user wants to see what the crew is doing without Claude's UI, in a form that is fun to watch (characters,
animations). The files the crew writes already hold phase, tasks, progress and state, but a status file
changes only when an employee ticks a progress box, so a page built on them alone feels static. The hook adds
the second-by-second detail. The user asked for the hook and for a throwaway file that is cleaned up
(2026-11-16).

## Done when

All lines are derived from the conversation of 2026-11-16; there is no ticket.

- [ ] 1. `node tools/crew-board/server.mjs` serves a page on `127.0.0.1` that lists this repository's open and
      closed work items from `.crew/work/index.md`.
- [ ] 2. For an open item the page shows the board's phase and next step, and one character per board row with
      its task, role, model, effort and state. Attempts of one task (`T2`, `T2b`) are shown as such.
- [ ] 3. Each character shows its `## Progress` checklist, its state and the age of its last update, read from
      its status file. A blocked character shows its question.
- [ ] 4. With the activity hook loaded and `live/` present, a character's current action and its tool-call
      count appear on the page within 3 seconds of the call.
- [ ] 5. The activity hook appends exactly one line per tool call of a crew employee. It writes nothing for the
      main session, for other agents, when `live/` is absent, or when the brief names no status file.
- [ ] 6. A log line holds only a UTC time, the tool name and a short target. Tests show that a secret in a Bash
      command, in written file content and in a URL query string never reaches the log.
- [ ] 7. The hook never prints, never exits non-zero and never refuses a call, with and without `jq`, under
      `sh` and `dash`.
- [ ] 8. The board script removes the `live/` folder of an item listed under Closed (its logs and its
      `.gitignore`; a folder that holds anything else stays), and the session-start hook deletes live logs
      older than 7 days. (Worded more exactly on 2026-11-16 after review T10; see `decisions.md`.)
- [ ] 9. The page shows text from crew files as text, never as HTML. The server answers only `GET`, and refuses
      a request whose `Host` header is not its own loopback address.
- [ ] 10. A demo command shows a moving board (characters working, blocked, done, missed) with no model call.
- [ ] 11. Animations stop when the browser asks for reduced motion.
- [ ] 12. `node tools/crew-board/test.mjs` and `sh plugins/triple-a-crew/scripts/test-hooks.sh` pass and print
      their last lines; `claude plugin validate .` passes.
- [ ] 13. One real run on a cheap model with the hook loaded and `live/` present writes one log line per tool
      call of the employee, and the eval cases `session-start-mentions-open-item` and `medium-fix-end-to-end`
      pass with the hook loaded.
- [ ] 14. README, `docs/DESIGN.md` and `formats.md` describe the hook, the `live/` folder and the page;
      `plugin.json` says 1.2.0; the profile's `verify` list has the page's test command.

## Constraints

- Hook scripts are POSIX `sh`, run as `sh <script>`, use `jq` when installed and work without it
  (README "Hooks", "Develop").
- A public plugin must not refuse or slow down the user's own session: the hook leaves at once for the main
  session and for other plugins' agents (DESIGN "Enforcement through hooks").
- Hook state is one small file per fact; a hook never reads a state file, changes it and writes it back
  (DESIGN, lesson L12). Appending a line is allowed: nothing is read back.
- Never write under `.claude/`; crew state lives in `.crew/` (profile).
- A change under `plugins/triple-a-crew/` that users should get bumps `version` in `plugin.json` (profile).
- A verify command prints a last line that says what it checked (profile, lesson L16).
- A Claude Code mechanic the docs leave open is probed on a cheap model and recorded in DESIGN's
  "Verified mechanics" (README "Probe what the docs leave open", lesson L5).
- Evals are real model calls: run only the cases a change touches, one run each, and record the cost.
- The page has no dependencies to install: Node's standard library only, one HTML file.
- No rule is added to `SKILL.md`, `protocol.md` or `staffing.md` (see `decisions.md`): cleanup is done by
  mechanisms, not by an instruction to the organizer.

## Edge cases

| Case | In scope? | Covered by |
|---|---|---|
| Tool call of the main session, or of another plugin's agent | yes | T2 (leaves before any parsing), T5 test |
| Crew employee, but no `live/` folder | yes | T2, T5 test |
| Brief unreadable, transcript missing, or no `**Status file:**` line | yes | T2 (silent), T5 test |
| Status file path that is not `.../.crew/work/<id>/team/<name>.md` | yes | T2 (no write), T5 test |
| Agent named like a teammate (`T2-engineer`) that is not a crew employee | yes | T2 (only with a status-file line in its brief), T5 test |
| A teammate's `PreToolUse` input in agent-teams mode (never probed) | no | findings.md: same limit as the command guard |
| Parallel tool calls of one employee, or several employees at once | yes | T2 (one append per call, no read-back), T5 test |
| Secret in a Bash command, in file content, in a URL query | yes | T2 (program name, path, host only), T5 test |
| Target with tabs, line breaks, control characters, or very long | yes | T2 (cleaned, cut), T5 test |
| Tool input of 100 KB and more (a large Write) | yes | T2, T5 test |
| No `jq` installed; `dash` as `sh` | yes | T2, T5 test in both modes |
| Unknown tool names (MCP tools) | yes | T2 (tool name, no target), T5 test |
| Log folder read-only, disk full | yes | T2 (silent, exit 0), T5 test |
| The command guard refuses the same Bash call | yes | T1 finds out whether both hooks run; T2 follows it |
| Hook time per call | yes | T1 measures the shell and `jq` start cost; T2 records the hook's time in its report |
| Log grows without limit in a very long task | no | findings.md; the page reads only the end of a log |
| No `.crew/work/`, or an empty index | yes | T3 (empty state), T5 test |
| Board or status file half written, without frontmatter, or in an older column layout | yes | T3 (parse by header name, skip what cannot be read), T5 test on this repository's real items |
| Board row without a status file yet | yes | T3, T4 (character waits) |
| Re-staffed attempts (`T2`, `T2b`, `T2c`) | yes | T3 (grouped by task), T4 (ladder rung shown) |
| Status text that contains HTML or script | yes | T4 (text nodes only), T10 review |
| Request with a foreign `Host` header, or not `GET` | yes | T3, T5 test |
| Port already in use | yes | T3 (clear message, exit 1, `--port`) |
| Many closed items | yes | T3 (closed items are listed by name only) |
| `updated` in UTC, in the future, or missing | yes | T3 (age from UTC; never negative) |
| Last log line read while it is being written | yes | T3 (an incomplete last line is skipped) |
| Item closes while the page is open | yes | T3 (moves to closed, `live/` removed) |
| Plugin older than 1.2.0, or hook switched off | yes | T3, T4 (the page works from status files alone) |
| Project that never runs the page | yes | T2 (no `live/`, no writes) |
| `live/` shows up in `git status` of a project with an older `.crew/.gitignore` | yes | T3 (the folder carries its own `.gitignore`) |
| Browser asks for reduced motion | yes | T4 |
| Rollback | yes | revert the pull request; `live/` folders ignore themselves |
| Two board servers, or two sessions on one project | no | findings.md; only "port in use" is handled |
| The organizer's own tool calls are not shown | no | findings.md: a main-session call carries no agent id |
| Steering agents from the page (pause, stop) | no | findings.md; the user has not asked for it |
| Windows | no | the hooks are POSIX `sh` already |
