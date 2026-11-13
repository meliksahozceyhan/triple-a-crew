# Lessons

| Id | Lesson | Hits | Items | Mechanism |
|---|---|---|---|---|
| L1 | The recheck after review fixes finds new problems | 6 | crew-hooks, employees-v2, retro-skill, agent-teams-mode, fix-open-issues, review-24-fixes | rule: a fresh reviewer rechecks the fix diff (SKILL.md step 8, #19) |
| L2 | The reviewer runs out of turns before it reports | 4 | crew-hooks, retro-skill, fix-open-issues, follow-ups-25-28 | brief: a tool-call budget in every reviewer brief (protocol.md, #38) |
| L3 | A regex grader was tested only on hand-made rows | 4 | retro-skill, fix-open-issues, issue-30-criteria-check, effort-ladder | open (#45: grader tests on real rows) |
| L4 | An employee writes an invented `updated` time | 4 | agent-teams-mode, fix-open-issues, follow-ups-25-28, effort-ladder | open (#32: the stop hook checks the time) |
| L5 | A cheap live probe settles what the docs leave open | 3 | crew-hooks, employees-v2, agent-teams-mode | convention: README "Probe what the docs leave open" |
| L6 | An employee or the organizer chains shell commands | 3 | employees-v2, agent-teams-mode, fix-open-issues | open (#51: a hook refuses an employee's chained command) |
| L7 | A rule changed in one file stays old in another | 3 | follow-ups-25-28, effort-ladder, publish-v1 | profile note: grep the other files for the words the rule hinges on |
| L8 | A review must check each ticket's criteria one by one | 3 | review-24-fixes, follow-ups-25-28, issue-30-criteria-check | rule: the last review reports evidence per done-when line (protocol.md, #30) |
| L9 | A pull request was called merged before it was | 2 | review-24-fixes, follow-ups-25-28 | rule: the ship step checks the pull request's state (SKILL.md step 10, #48) |
| L10 | Employees run on definitions that changed after the session started | 2 | fix-open-issues, issue-30-criteria-check | open (#44: a hook tells the organizer) |
| L11 | A researcher's full report lives only in its final message | 2 | publish-v1, and the item behind #37 | rule: the report goes into the status file under `## Report` (protocol.md, #37) |
