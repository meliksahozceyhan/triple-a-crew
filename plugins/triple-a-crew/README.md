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
| `plan-review` | "review this plan" | Tightens a plan against the project's rules, reuse, edge cases, failure handling and scale; returns a reinforced plan |
| `cleanup` | "clean up what we touched" | Removes debug logs, redundant comments, dead code and log-and-rethrow try-catch from changed files; proves behavior with the verify commands |
| `test-harden` | "harden these tests" | Finds risky missing test cases and reports or adds them in the project's own framework |
| `investigate` | "investigate ACT-123" | Reads a bug report from any tracker or pasted text and ranks root causes with `path:line` evidence; read-only |
| `handoff` | "write a handoff", `/triple-a-crew:handoff resume` | Writes, resumes or briefs from a session handoff in `.crew/handoffs/`, with facts from git and the transcript |

## Agents

| Agent | Model | Role |
|---|---|---|
| `researcher` | sonnet | Maps code, docs and tickets; writes only its status file |
| `engineer` | sonnet | Implements one task inside its file set and runs its acceptance check |
| `reviewer` | opus | Adversarial diff review; findings carry a failure scenario |

The organizer picks the model per task from three tiers (`mechanical`: haiku, `standard`: sonnet,
`critical`: opus); a project can override a tier with `models:` in its profile.

## State

Everything is written to `.crew/` at the project root, never `.claude/`, which Claude Code protects:
`profile.md`, `work/<id>/` (brief, plan, decisions, findings committed; board, team status files, handoff
ignored through `.crew/.gitignore`), and `handoffs/`.

## Evals

12 cases in [evals/](evals/), each scaffolding its own small fixture repository.

| Tag | Cases | Run with |
|---|---|---|
| `organizer` | large request opens a work item and waits; small request stays out; status of an open item; medium fix end to end | `claude plugin eval . --tag organizer --ablation none --scaffold --allow-tools Write Edit "Bash(node *)" "Bash(git *)"` |
| `migrated` | plan-review, cleanup, test-harden, investigate, handoff | `claude plugin eval . --tag migrated --scaffold --allow-tools Write Edit "Bash(node *)" "Bash(git *)"` |
| `onboard` | create a profile; refresh one and keep user values | `claude plugin eval . --tag onboard no-trigger --scaffold --allow-tools Write Edit` |

The organizer cases run one arm: without the plugin there is no organizer to compare against.
