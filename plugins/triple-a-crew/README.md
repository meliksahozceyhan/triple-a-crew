# Triple-A-Crew

The workflow organizer. v0 ships one skill, `onboard`; the organizer, its employees and hooks arrive in v1
(see [docs/DESIGN.md](../../docs/DESIGN.md)).

## onboard

Writes or refreshes `.crew/profile.md`, the contract the crew's skills read instead of guessing a project's
setup:

- **Detected:** stack, the commands that verify a change (taken from CI first), test globs, the files that
  hold conventions, and issue tracker candidates from connected tools, the git remote and issue keys in
  branch names.
- **Asked:** only what it cannot detect, at most four questions, each with a suggested answer.
- **Refresh:** re-detects facts but keeps what you set (tracker, organizer mode, model overrides, notes)
  and any keys it does not know.

Run it with `/triple-a-crew:onboard`, or ask "set this repo up for the crew". The format is in
[skills/onboard/profile-format.md](skills/onboard/profile-format.md).

Work state lives in `.crew/`, not `.claude/`: Claude Code treats `.claude/` as protected and prompts for, or
denies, every write there.

## Evals

| Case | Checks | Flags it needs |
|---|---|---|
| `creates-profile-from-repo` | On a scaffolded pnpm + Vitest repo with GitHub CI: verify commands from CI, no build/deploy, tests glob, `CLAUDE.md`, GitHub tracker read from `.git/config` without a shell | `--scaffold`, `--allow-tools Write` |
| `refreshes-profile-keeps-user-values` | Refreshes stale npm/Jest values to pnpm/Vitest; keeps tracker, organizer mode, an unknown key and the notes | `--scaffold`, `--allow-tools Write Edit` |
| `no-fire-setup-question` | Stays out of a general "how do I set up a pnpm workspace" question | |

```bash
claude plugin eval . --scaffold --allow-tools Write Edit
```
