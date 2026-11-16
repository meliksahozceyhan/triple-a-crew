# Decisions

- **2026-11-16 Size L, on branch `crew-board` in the main checkout.** A hook that runs before every tool call
  of every session is a risk area, and the work spans the plugin, a new tool folder and the docs. The branch
  is in the main checkout so the user can see the work (their feedback of 2026-11-13).
- **2026-11-16 The live detail comes from a `PreToolUse` hook, not from reading subagent transcripts.** The
  hook input is a documented interface and the hook writes a small format of our own. Rejected: the board
  script tailing `~/.claude/projects/.../subagents/agent-<id>.jsonl`. It needs no plugin change and adds no
  time per call, but the transcript format is internal to Claude Code, the script would have to search the
  home folder, and it would parse full transcripts, content included. The user asked for the hook.
- **2026-11-16 The log lives in the work item: `.crew/work/<id>/live/<task>-<role>.log`.** The hook derives
  the folder from the `**Status file:**` line of the brief, as the stop hook does. Rejected: the system temp
  folder or `${CLAUDE_PLUGIN_DATA}` (the user's first idea was a temp file): the page would have to know
  where that is on each machine, and hook state there already has an open problem (#57, lesson L15).
- **2026-11-16 The hook writes only when `live/` exists; the board script creates it.** The plugin is public
  and other users have no page. Without the folder the hook costs a few early exits and writes nothing.
  Rejected: a profile field (`live: on`), which would change `onboard` and its evals.
- **2026-11-16 `live/` ignores itself** with a `.gitignore` of `*` inside it, as `.crew/handoffs/` does.
  A project whose `.crew/.gitignore` predates this change then never sees the logs in `git status`.
  Rejected: a new line in the `.crew/.gitignore` list of `formats.md`, which reaches an existing project
  only when the organizer opens its next item.
- **2026-11-16 Cleanup is done by mechanisms, with no new rule in `SKILL.md`.** The board script removes the
  `live/` folder of an item that is no longer open (it created the folder), and the session-start hook
  deletes live logs older than 7 days. The user's wording was "clean after the retro"; an instruction to the
  organizer can be forgotten, and a change to `SKILL.md` means rerunning 13 eval cases (about $9 at the last
  recorded costs). To confirm with the user at plan approval.
- **2026-11-16 A log line holds the time, the tool name and a short target only.** For a file tool the path,
  for a search its pattern cut short, for Bash the program name, for a web call the host. Never file content,
  a full command or a query string: tool input can hold secrets, and the log is plain text in the project.
- **2026-11-16 `PreToolUse` only, no `PostToolUse`.** "What is it doing now" needs the start of a call. The
  end of a call (to show "thinking") would double the hook runs; left for later if the page needs it.
- **2026-11-16 The page's look (T4) is the organizer's own task.** It is design-heavy and the user's taste
  decides; the organizer built the flowchart page the user accepted on 2026-11-16. A reviewer still reviews
  it. The server, the parser and the tests go to an engineer.
- **2026-11-16 From T1's probe (Claude Code 2.1.325): the hook entry uses matcher `"*"`, and the hook needs
  both `agent_type` and `agent_id`.** All four "match all" forms fired for every tool; `"*"` is the documented
  one. The docs say a main session started with `--agent` has `agent_type` without `agent_id`, so `agent_type`
  alone is not enough. Matching hooks run at the same time, and a hook still runs to its end when another
  refuses the call: a log line therefore means "a call was started", not "a call ran".
- **2026-11-16 The hook keeps no state file and reads the brief on every call.** The command guard does the
  same and takes about 40 ms for an employee's call and 12 ms for a main-session call (T1, 30 runs each).
  Rejected: a cache file per agent in `${CLAUDE_PLUGIN_DATA}`, which would bring back the open problem of
  lesson L15. The main-session path must leave before any `jq` or `awk` starts; T2 measures both paths.
- **2026-11-16 The user approved the plan as written ("Approve as planned").** Cleanup stays with the two
  mechanisms; no close-step rule is added to `SKILL.md`. Offered and not chosen: the same plan plus that rule,
  at about $9 of eval reruns.
- **2026-11-16 T2: the hook reads stdin with the shell's own `read`, not `cat`.** It brings the main-session
  path from about 8 to 10 ms down to 5.5 ms (an empty `sh` is about 5 ms). The price is a byte-by-byte read of
  a very large input: about 30 ms more at 100 KB and 120 ms more at 250 KB, which only a large Write or Edit
  pays. Accepted by the organizer; the hook review (T9) is asked to challenge it. Measured by T2, 7 batches of
  30 runs: main session 5.5 ms, employee with `live/` 19 ms, without 15.7 ms (median batches).
- **2026-11-16 T6, the real run: 8 log lines for 8 tool calls.** A haiku session in a scratch project with one
  `triple-a-crew:engineer` employee (model haiku), the board running on that project. The hook loaded from the
  installed plugin, which reads this checkout, so no `--plugin-dir` was needed. The log held `Bash date`,
  `Write .crew/work/probe-item/team/T1-engineer.md`, `Read a.txt`, `Write b.txt`, `Edit b.txt`, `Bash ls`,
  `Bash date`, `Write ...T1-engineer.md`; the page showed "Working: Editing b.txt" with 5 calls, then "Done"
  with 8. Cost: not printed by `claude -p`; one short haiku session. The first try used
  `--permission-mode bypassPermissions` and was refused by this session's safety check; the run that counted
  allowed only `Agent, Read, Write, Edit, Bash(date:*), Bash(ls:*)`.
- **2026-11-16 The plugin is installed at user scope from this checkout** (`claude plugin list`). While the
  branch `crew-board` is checked out, every new Claude Code session on this machine already loads the
  activity hook. It writes nothing without a `live/` folder. Told to the user.
- **2026-11-16 `formats.md` gets two small changes (the tree and the one-writer sentence), and T11 gains one
  eval case for it.** The README's table lists eight cases for a `formats.md` change; the change adds no
  instruction, so one cheap case that reads the formats, `starts-work-item-on-large-request` ($0.49 last
  time), is run as a check that nothing broke. Rejected: all eight (about $5.50) for two descriptive lines.
- **2026-11-16 T11: three eval cases, one run each, all 1.00, $1.35 in total.** Run from
  `plugins/triple-a-crew` with `--runs 1 --ablation none --case <name> --scaffold`, on plugin version 1.2.0
  with the activity hook in `hooks.json`: `session-start-mentions-open-item` 1.00, $0.06 (5 of 5 graders);
  `starts-work-item-on-large-request` 1.00, $0.33 (11 of 11); `medium-fix-end-to-end` 1.00, $0.96 (17 of 17,
  with a reviewer staffed, so the hook ran before an employee's tool calls and broke nothing). The eval
  sandbox has no `live/` folder, so these runs show that the hook stays out of the way, not that it logs; T6
  shows the logging. The runs came after the fixes that followed T5 and before the reviews.
- **2026-11-16 After T10: the `live/` cleanup stays "only ids listed under Closed"; the wording is corrected,
  the code is not widened.** T10 (S5) noted that an id deleted from the index keeps its `live/`. Widening the
  cleanup to every folder missing from the Open list was rejected: an index read while half written, or with
  a broken `## Open` heading, would then delete every item's logs. The 7-day prune at session start removes
  such leftovers. Done-when line 8 therefore means "an item listed under Closed". One change was taken:
  `live/.gitignore` is removed only when the folder ends up empty.
- **2026-11-16 After T10: the page says "Busy", not "Thinking", once 20 seconds pass without a new call.**
  The log has no end of a call (`PreToolUse` only), so a two-minute test run looked like thinking (S3). The
  bubble now shows the last call and when it started. Rejected for now: a `PostToolUse` hook to record the
  end of a call, which would double the hook runs; noted as a possible follow-up.
- **2026-11-16 After the review fixes: verify, one eval case and the real run were repeated on the final
  state.** All five verify commands pass (run by the organizer at 15:46Z: `all hook tests passed` with 0 FAIL
  lines, `all crew-board tests passed` with 87 checks, `all checked graders behave`, `Validation passed`, the
  syntax check silent). `session-start-mentions-open-item` again 1.00, $0.06 (`session-start.sh` changed in
  the review fixes); evals total $1.41. The real run was repeated with the final hook: a second haiku
  employee (`T2-engineer`) in the same scratch project wrote 8 log lines for 8 tool calls, two of them from
  calls sent in one block (`Bash ls`, `Bash date`), both whole. `medium-fix-end-to-end` was not rerun: the
  review fixes only make the hook write less, and the eval sandbox has no `live/` folder.
- **2026-11-16 The hook's cost, measured again after the review fixes: the figures in README and DESIGN.**
  One batch of 30 runs each, input through a pipe, by T2 after the fixes to review T9: main session 4.4 ms,
  employee with `live/` 14.8 ms, without 12.0 ms, an empty `sh -c :` 4.0 ms. These replace the earlier
  5.5, 19 and 15.7 ms (input from a file, before the fixes) in the docs. No reviewer measured them; they are
  the engineer's figures.
- **2026-11-16 After the last review (T12): one must-fix in the record, fixed by the organizer.** The final
  flow in `plan.md` still said the board removes `live/` "for items no longer open"; it now says "listed
  under Closed", as the code and the decision above. Also fixed: a broken sentence in the README, the page's
  text filter (the file held invisible direction-control characters instead of escapes, because the editing
  tool turns an escape into the character; the filter is now built from code points and a test guards it),
  one more own-property lookup in the page, two comments in `server.mjs`, and a clause in DESIGN on what the
  30-character limit does not catch. Left: N1 (the docs say "exactly" for the index headings; the code also
  takes any letter case), N3 (the mood is still named `thinking` inside the page), N9 (one test is skipped
  without a note when run as root).
- **2026-11-16 After the recheck of those fixes (T12b, approve): four more small changes, by the organizer.**
  The page's filter now takes all twelve characters of Unicode's direction-control set (U+061C was missing),
  and its test runs the page's own filter on every code point up to U+FFFF and requires that exactly those
  twelve are removed; the test also scans every `.mjs`, `.html` and `.md` file of `tools/crew-board/` for
  such a character. DESIGN names `./` and `../` beside `/` in the clause on the 30-character limit. The
  done-when table in `plan.md` uses the exact wording of line 8. Entries in this file are now in the order
  they were made. Checked and left: the README's "from the eighth day on" for hook state files is right
  (`-mtime +7` in `session-start.sh:32`, `bash-guard.sh:261`, `subagent-stop.sh:34`).
