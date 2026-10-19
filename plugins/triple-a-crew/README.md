# Triple-A-Crew

The workflow organizer for Claude Code, its employees, and the skills they work with. See the
[root README](../../README.md) for how the pieces fit and [docs/DESIGN.md](../../docs/DESIGN.md) for the
design.

```
/plugin install triple-a-crew --marketplace meliksahozceyhan/triple-a-crew
```

## Skills

| Skill | Invoke | What it does |
|---|---|---|
| `work` | starts on its own for multi-step work; `/triple-a-crew:work [start <request> \| next \| status]` | The organizer: sizes the request, opens a work item in `.crew/work/`, stress-tests edge cases, plans, staffs employees on model tiers, tracks status files, verifies, reviews, files follow-ups |
| `onboard` | "set this repo up for the crew" | Writes or refreshes `.crew/profile.md`: stack, verify commands from CI, test globs, convention files, tracker |
| `test-harden` | "harden these tests" | Finds risky missing test cases and reports or adds them in the project's own framework |
| `handoff` | "write a handoff", `/triple-a-crew:handoff resume` | Writes, resumes or briefs from a session handoff in `.crew/handoffs/`, with facts from git and the transcript |

## Agents

| Agent | Model | Role |
|---|---|---|
| `researcher` | sonnet | Maps code, docs and tickets; ranks a bug's likely causes; writes only its status file |
| `engineer` | sonnet | Implements one task inside its file set and runs its acceptance check |
| `test-engineer` | sonnet | Writes the tests for a task, never production code; `test-harden` preloaded |
| `verifier` | haiku | Runs the verify commands and reports exit codes and failing lines verbatim; never fixes |
| `reviewer` | opus | Adversarial diff review; findings carry a failure scenario |

The organizer picks the model per task from three tiers (`mechanical`: haiku, `standard`: sonnet,
`critical`: opus); a project can override a tier with `models:` in its profile.

## Hooks

`hooks/hooks.json` runs three POSIX `sh` scripts from `scripts/`: `SessionStart` lists open work items from
`.crew/work/index.md`; `SubagentStart` reminds employees of the status-file protocol; `SubagentStop` sends an
employee back while its status file or final report is incomplete. They match only `triple-a-crew:*` agents
and are silent in projects without `.crew/`. Test them with `sh scripts/test-hooks.sh`.

## State

Everything is written to `.crew/` at the project root, never `.claude/`, which Claude Code protects:
`profile.md`, `work/<id>/` (brief, plan, decisions, findings and retro committed; board, team status files,
handoff ignored through `.crew/.gitignore`), and `handoffs/`.

## Evals

13 cases in [evals/](evals/), each scaffolding its own small fixture repository.

| Tag | Cases | Run with |
|---|---|---|
| `organizer` | large request opens a work item and waits; small request and read-only investigation stay out; status of an open item; verify staffs the verifier; a test task keeps its failing test; medium fix end to end | `claude plugin eval . --tag organizer --ablation none --scaffold --allow-tools Write Edit "Bash(node *)" "Bash(git *)"` |
| `migrated` | test-harden, handoff | `claude plugin eval . --tag migrated --scaffold --allow-tools Write Edit "Bash(node *)" "Bash(git *)"` |
| `hooks` | the session-start summary names the open item | `claude plugin eval . --tag hooks --scaffold` |
| `onboard` | create a profile; refresh one and keep user values | `claude plugin eval . --tag onboard no-trigger --scaffold --allow-tools Write Edit` |

The organizer cases run one arm (without the plugin there is no organizer to compare against), except the
two that check it stays out, which also run with the `no-trigger` tag and a baseline.

`plan-review`, `cleanup` and `investigate` were cut after their evals showed no gain over plain Claude. What
they added now lives in the organizer (the size-L convention check, the noise rule in the verify step) and the
`researcher` (ranked likely causes). See the [root README](../../README.md#evals).
