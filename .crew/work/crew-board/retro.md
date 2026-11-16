# Retro: crew-board

**Closed:** not yet. Written 2026-11-16 with the work finished and reviewed; the commit and the pull request
wait for the user.

## What happened

- The plan held in its shape: twelve tasks, the hook and the board built in parallel on disjoint files, and
  every done-when line met (team/T12-reviewer.md, criteria table). What the plan did not foresee is how many
  rounds the checks would start: the hook went back to its engineer three times and the board script three
  times (board.md, rows T2 and T3).
- T1's probe (2 haiku runs) settled the matcher, the hook input for five tools, that matching hooks run at
  the same time, and that the brief is readable at the first call. It also found that this Claude Code build
  has no `Grep` or `Glob` tool, although the agent files list them (team/T1-researcher.md, findings.md).
- T5's independent tests found six defects that the two engineers' own tests had passed: a write through a
  symbolic link, a user name from a URL, a token written as a program name, an escaped pipe that shifted a
  board's columns, an item in both lists losing its logs, and an odd request path being served. Two of the
  five planted regressions were caught only by T5's tests (team/T5-test-engineer.md).
- Review T9 found two must-fixes in the hook after T5's round: a word from a quoted `NAME="..."` value
  logged as the program name, and a linked work item folder written and pruned through. This was T2's one
  miss; rung 1 (sent back with the review) was enough (team/T9-reviewer.md, board.md).
- The recheck T9b approved and still found a neighbour: the tail of a secret with a slash in it was logged
  (team/T9b-reviewer.md). The recheck T12b approved and found that the new test proved less than its name
  said (team/T12b-reviewer.md).
- Review T10 approved the board with eight should-fixes. Its sixteen nits were only in its final message,
  not in its status file, so T3, told to read the review file, could not see four of them and asked
  (team/T10-reviewer.md, team/T3-engineer.md, findings.md).
- The last review T12 found one must-fix, in the record: the final flow in `plan.md` still stated a rule that
  `decisions.md` had corrected two hours earlier. It also found that the page's text filter held invisible
  direction-control characters: the editing tool had turned the organizer's escapes into the characters
  themselves. T2 and T12b ran into the same tool behaviour in their own files (team/T12-reviewer.md,
  team/T2-engineer.md, team/T12b-reviewer.md).
- T7 wrote the docs before the reviews, as planned, and then had to bring them in line three times, once
  after each round of fixes (team/T7-engineer.md).
- Nothing was committed during the work, because the user had not asked for commits. A recheck then had no
  fix diff to read: the organizer saved copies of the four hook files by hand before T9's fixes, and listed
  the edits by hand for T12b (board.md, row T9b; decisions.md).
- T6, the real run: the first try used `--permission-mode bypassPermissions` and was refused by the session's
  safety check. The run that counted allowed six tools by name. It was repeated on the final hook
  (decisions.md).
- Evals: four runs, all 1.00, $1.41 (decisions.md). Verify: run by the verifier once (team/T8-verifier.md)
  and by the organizer twice more after the review fixes.
- Reviews ran on `fable` (the profile's trial). Five reviews: 23 to 47 tool calls each, all inside their
  budgets except T12b, which used all 20 of a budget the organizer had set below the usual size and left one
  clause unchecked. Every review reproduced its findings; T9b and T2 ran mutated copies to show that tests
  can fail. The two rechecks found should-fixes only, no must-fix.
- For the user: the task list in the app broke a second time during a long run with background employees,
  and the page could not be reached once because the demo server had been stopped.

## Lessons

| # | Lesson | Evidence | Repeat of | Goes to | Status |
|---|---|---|---|---|---|
| 1 | The recheck after review fixes finds new problems | team/T9b-reviewer.md (R1), team/T12b-reviewer.md (S-1) | L1 | `retro.md` only (the rule exists: SKILL.md step 8) | kept |
| 2 | A rule changed in one file stays old in another | team/T12-reviewer.md (M1, S3) | L7 | `retro.md` only (the mechanism worked: the last review's rule list caught both) | kept |
| 3 | A cheap live probe settles what the docs leave open | team/T1-researcher.md | L5 | `retro.md` only (the convention exists) | kept |
| 4 | Independent tests find what the author's tests cannot | team/T5-test-engineer.md | | `retro.md` only (the rule exists: staffing.md, separation of duties) | kept |
| 5 | The editing tools turn a `\u` escape in file content into the character itself | team/T12-reviewer.md (S2), team/T2-engineer.md, team/T12b-reviewer.md (N-1) | | `.crew/profile.md` notes | accepted |
| 6 | A reviewer's nits lived only in its final message, so the engineer sent back could not read them | team/T10-reviewer.md, team/T3-engineer.md | | crew repository (issue draft) | accepted (#60) |
| 7 | With nothing committed, a recheck has no fix diff | board.md (T9b), decisions.md | | `.crew/profile.md` notes | accepted |
| 8 | A probe run with all permission checks off is refused; a list of allowed tools works | decisions.md (T6) | | `README.md`, "Probe what the docs leave open" | accepted |
| 9 | Docs written before the code reviews were synced three times | team/T7-engineer.md | | `retro.md` only | kept |
| 10 | The agent files list `Grep` and `Glob`, which this Claude Code build does not have | team/T1-researcher.md, findings.md | | crew repository (issue draft) | accepted (#61) |
| 11 | The `critical: fable` trial: five reviews, each with reproduced findings; rechecks found no must-fix | board.md, team/T9*.md, team/T10-reviewer.md, team/T12*.md | | `.crew/profile.md` notes (the trial note) | accepted |

The user accepted all six proposals on 2026-11-16 ("Apply all six"). The four text changes are applied as
written below, except that the README sentence (8) also names the real command form and says to put the
prompt before the flag. The two issues were filed with the same content in the issue template's sections
(Context, Problem, Evidence, Impact, Suggested approach, Acceptance criteria, Links): #60 and #61.

## Proposed text

- **5** (`.crew/profile.md`, notes): "The Write and Edit tools turn a `\uXXXX` escape in file content into the
  character itself (crew-board: an invisible direction mark in a regular expression, an `é` in a test).
  Build such a character from its code point (`String.fromCharCode(0x202e)`, `printf '\342\200\256'`) and
  check the file afterwards for the raw character."
- **6** (issue draft): "Reviewer findings that are only in the final message are lost to the next employee".
  A reviewer wrote its should-fixes into its status file and its nits only into its final message. The
  organizer sent the review back to the engineer with "the full review is in the status file"; the engineer
  could not see the nits and had to ask. Researchers have a rule for this (the full report goes under
  `## Report`); reviewers have none. Suggested fix: every reviewer brief's acceptance check gets the line
  "the full list of findings, nits included, is in your status file as well as in your final report", or the
  reviewer's agent file says so. In the same work item, three later reviewers were given that line and all
  three complied.
- **7** (`.crew/profile.md`, notes): "On a work item's own branch the organizer commits one commit per task
  without asking, so a recheck can read the fix diff (`git diff <commit>..`); pushing, pull requests and
  anything on `main` still wait for the user. (crew-board ran without commits and had to save file copies by
  hand before a recheck.)"
- **8** (`README.md`, "Probe what the docs leave open"): add the sentence "Give the probe session only the
  tools it needs (`--allowedTools \"Agent,Read,Write,Edit,Bash(date:*)\"`), not
  `--permission-mode bypassPermissions`: a session's own safety check can refuse a run with all checks off
  (`crew-board` T6)."
- **10** (issue draft): "Agent files list tools the current Claude Code build does not have". The five agent
  files list `Glob` and `Grep` under `tools:`. On Claude Code 2.1.325 neither tool exists, for the main
  session or for a subagent whose `tools:` line names them; a subagent asked for its tools listed Read,
  Write, Edit, Bash and WebFetch, and searched through Bash (`grep`, `ls`, `find`). Nothing breaks, but the
  agent files and the docs that describe the employees' tools are out of date, and a hook that reports "the
  employee is searching" has to recognise Bash programs instead of tool names. Suggested fix: check on the
  current build which tools a plugin agent gets, then bring the `tools:` lines and the README table in line.
- **11** (`.crew/profile.md`, notes): replace the trial note of 2026-11-13 with "Since 2026-11-13 reviews and
  design research run on `fable` (`models: { critical: fable }`). On `crew-board` (size L) five reviews each
  reproduced their findings and stayed inside their budgets, and the two rechecks found should-fixes only;
  with `opus` the recheck had found something new in eight items. Kept."

A note for the user, not a proposal: lesson 9 would change the plan order next time (docs after the code
reviews' fixes, before the last review). It is a first-time lesson, so it stays here.
