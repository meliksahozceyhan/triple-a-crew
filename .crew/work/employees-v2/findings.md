# Findings
- 2026-10-19 · Incident: the organizer ran the new `verify-staffs-verifier/fixture.sh` from the repository
  root instead of a temp folder. The fixture's `git add -A && git commit` made a local commit on
  `employees-v2` (with the uncommitted work and fixture files) and overwrote `.crew/profile.md` and the ignored
  `.crew/work/index.md`. Undone the same minute: `git reset --mixed` to `d97d355`, profile restored from git,
  fixture files removed, index rebuilt. Nothing was pushed. Lesson: run a fixture only inside `mktemp -d`;
  fixtures could also refuse to run in a non-empty folder · organizer · filed as #15 https://github.com/meliksahozceyhan/triple-a-crew/issues/15
- 2026-10-19 · First `verify-staffs-verifier` run (0.86, $0.67): the verifier wrapped each verify command in a
  compound shell line (`start=$(date +%s); node --test > "$TMPDIR/…" 2>&1; echo "exit=$?" …`) as its
  instructions asked, so `Bash(node *)` did not match and the call was denied; the judge then failed
  "failure-reported". In real sessions the same wrapping would prompt for every verify command. Fix in this
  work item: run each command exactly as listed, alone · found by T6 eval · fixing now
- 2026-10-19 · `starts-work-item-on-large-request` sized the request M once in six runs (5 at 1.00): the
  organizer treated "the mobile app parses this export" as several files rather than public-API risk, so it
  skipped plan.md and the go-ahead. Two reruns on this branch scored 1.00, so it is variance, not a regression.
  The sizing table in `skills/work/SKILL.md` step 2 could say that a format another system consumes counts as
  public API · organizer · filed as #13 https://github.com/meliksahozceyhan/triple-a-crew/issues/13
- 2026-10-19 · In eval runs the organizer, the researcher and once the test-engineer had Bash calls denied
  because they chained or piped commands (`node --test 2>&1 | tail`, `cd x && …`) that `Bash(node *)` doesn't
  match; in real sessions each such call prompts. The verifier now runs commands plain; `protocol.md` could
  say the same for every employee, and the organizer's SKILL.md for itself · found by T9 eval traces · filed as #12
  https://github.com/meliksahozceyhan/triple-a-crew/issues/12
