# Lessons

| Id | Lesson | Hits | Items | Mechanism |
|---|---|---|---|---|
| L1 | The recheck after review fixes finds new problems | 9 | crew-hooks, employees-v2, retro-skill, agent-teams-mode, fix-open-issues, review-24-fixes, hook-guards, eval-tooling, organizer-rules | rule: a fresh reviewer rechecks the fix diff (SKILL.md step 8, #19) |
| L2 | The reviewer runs out of turns before it reports | 4 | crew-hooks, retro-skill, fix-open-issues, follow-ups-25-28 | brief: a tool-call budget in every reviewer brief (protocol.md, #38) |
| L3 | A grader passed a near miss, or was tested only on rows built by hand (#45) | 5 | retro-skill, fix-open-issues, issue-30-criteria-check, effort-ladder, eval-tooling | check: `node scripts/test-graders.mjs` runs graders on rows from real traces, with a near miss that removes one thing (profile `verify`, `scripts/grader-rows/README.md`) |
| L4 | An employee writes an invented `updated` time (#32) | 4 | agent-teams-mode, fix-open-issues, follow-ups-25-28, effort-ladder | hook: the stop hook checks `updated` against the clock and gives the `date -u` command (`subagent-stop.sh`) |
| L5 | A cheap live probe settles what the docs leave open | 5 | crew-hooks, employees-v2, agent-teams-mode, hook-guards, organizer-rules | convention: README "Probe what the docs leave open" |
| L6 | An employee or the organizer chains shell commands (#51) | 3 | employees-v2, agent-teams-mode, fix-open-issues | hook: the command guard refuses an employee's chained command (`bash-guard.sh`); the organizer's own commands are not checked |
| L7 | A rule changed in one file stays old in another | 5 | follow-ups-25-28, effort-ladder, publish-v1, hook-guards, organizer-rules | profile note: grep the other files for the words the rule hinges on; the last review's brief lists each changed rule and asks for that grep |
| L8 | A review must check each ticket's criteria one by one | 3 | review-24-fixes, follow-ups-25-28, issue-30-criteria-check | rule: the last review reports evidence per done-when line (protocol.md, #30) |
| L9 | A pull request was called merged before it was | 2 | review-24-fixes, follow-ups-25-28 | rule: the ship step checks the pull request's state (SKILL.md step 10, #48) |
| L10 | Employees run on definitions that changed after the session started (#44) | 2 | fix-open-issues, issue-30-criteria-check | hook: a note to the organizer when an agent file changed after the session loaded it (`definitions-check.sh`) |
| L11 | A researcher's full report lives only in its final message (#37) | 1 | publish-v1 | rule: the report goes into the status file under `## Report` (protocol.md) |
| L12 | Hook state that is read, changed and written back races; one file per fact does not | 1 | hook-guards | convention: DESIGN "Enforcement through hooks" |
| L13 | The stop hook's report check may be skipped when an employee finishes through a hand-back call (#55) | 1 | hook-guards | open |
| L14 | `claude plugin validate` may not read `hooks.json`, so it proves little for hooks (#56) | 1 | hook-guards | open |
| L15 | Hook state falls back to a shared temp folder, and the 7-day prune can delete a live session's stamp (#57) | 1 | hook-guards | open |
| L16 | A check that can exit 0 without running is worse than no check | 1 | eval-tooling | profile note: a verify command prints a last line that says what it checked |
| L17 | A researcher's figures were wrong; the engineer who used them checked each against its source | 1 | eval-tooling | open |
| L18 | An eval run of a new case finds gaps that review rounds miss | 1 | organizer-rules | convention: README "Ship evals with the skill" (run a new case before the first review) |
| L19 | A brief's own edge-case row contradicted the issue it was built from | 1 | organizer-rules | open |
| L20 | `claude plugin eval --case` takes one glob, not a list of names | 1 | organizer-rules | profile note: run several named cases as separate commands |
