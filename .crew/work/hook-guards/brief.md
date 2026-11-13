# Hook guards for three rules employees keep breaking

**Size:** L · **Tickets:** #32, #51 (B: chained commands), #44 (C: stale definitions) · **Opened:** 2026-11-13

## What
Enforce three written crew rules in the plugin's hooks:

1. A status file's `updated` time is real (#32).
2. An employee runs one plain command per Bash call: no chains, no `cd` (issue B).
3. The organizer is told when an agent or skill definition changed after the session started (issue C).

## Why
The retros record 19 cases of these rules being broken in 6 work items: invented or hand-written `updated`
times in 4 items (`agent-teams-mode`, `fix-open-issues`, `follow-ups-25-28`, `effort-ladder`), chained shell
commands and a leaking `cd` in 4 (`employees-v2`, `agent-teams-mode`, `fix-open-issues`, `review-24-fixes`),
and stale definitions in 2 (`fix-open-issues`, `issue-30-criteria-check`). Each was answered with a text rule,
and each came back. A repeat needs a mechanism (`SKILL.md` step 10).

## Done when
- [ ] #32.1 The hook test has a future-time case that blocks and a real-time case that passes.
- [ ] #32.2 (derived) A status file with no `updated` line blocks the stop, and the message gives the exact
      `date -u` command.
- [ ] B.1 An employee's Bash call that chains commands or uses `cd` is refused, with a message that names the
      rule.
- [ ] B.2 A chained command that the brief lists as written still runs.
- [ ] B.3 Commands from the main session, and from agents that are not crew employees, are never refused.
- [ ] B.4 The hook test covers: a chain is refused, a plain command passes, `&&` inside a quoted argument
      passes.
- [ ] C.1 When an agent file of the plugin changed after the session started, the organizer is told when it
      staffs that employee, and the message names `/reload-plugins`.
- [ ] C.2 No message when nothing changed; the hook test covers both cases.
- [ ] D.1 (derived) `sh plugins/triple-a-crew/scripts/test-hooks.sh` passes under `sh` and `dash`, and
      `claude plugin validate .` passes.
- [ ] D.2 (derived) README "Hooks", DESIGN "Enforcement through hooks" and DESIGN "Verified mechanics"
      describe the new behavior, with the probe's date.
- [ ] D.3 (derived) The eval cases that load the hooks still score 1.00, one run each.

The B lines are the criteria of #51 and the C lines those of #44, as written (filed 2026-11-13).

## Constraints
- Hooks are tier 3: nothing breaks when they are off, and a hook never traps an employee. The stop hook keeps
  its cap of three blocks and its escape hatch (`docs/DESIGN.md`).
- The plugin is public (v1.0.0): a guard must not change what the main session or another plugin's agents may
  run.
- Hook scripts are POSIX `sh`, tested under `dash`; `jq` may be missing (README "Develop").
- Probe what the docs leave open, and record the result with its date in DESIGN (README "Conventions for new
  skills").
- No file under `.claude/`. No version bump in this item: one release PR bumps the version after the three
  items merge.
- The main checkout stays on `main`; every edit happens in a worktree.

## Edge cases
| Case | In scope? | Covered by |
|---|---|---|
| `updated` in the future | yes | #32.1 |
| `updated` missing, or not a timestamp | yes | #32.2 |
| `updated` far in the past (never refreshed) | no | findings.md: the issue asks for future or missing only |
| Clock skew, and the gap between the last write and the stop | yes | a tolerance, set in the plan from T1 |
| A local-offset timestamp instead of `Z` | yes | plan |
| `&&`, `;` or a pipe inside a quoted argument or a heredoc | yes | B.4 |
| A chained command the brief lists as written (`cd web && pnpm test`) | yes | B.2 |
| A hook input that cannot tell an employee from the main session | yes | T2 decides; if it cannot, B is redesigned or deferred in decisions.md |
| Teammates in agent-teams mode (named `T2-engineer`) | yes | the matcher covers both names |
| Several employees at once sharing the state folder | yes | state keyed per agent |
| A plugin installed from the versioned cache, where file times never change | yes | C.2: no false message |
| Missing `jq`; `dash` as `sh` | yes | D.1 |
| Windows without a POSIX shell | no | findings.md: already recorded in `crew-hooks` |
