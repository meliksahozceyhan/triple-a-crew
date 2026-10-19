# Findings

- 2026-10-19 · `docs/DESIGN.md` "Enforcement through hooks" says SubagentStop checks the status file for the
  final report sections; `plugins/triple-a-crew/skills/work/protocol.md` puts the report in the reply · found by
  T1 researcher · fixed by T8 of this plan
- 2026-10-19 · Hooks run through `sh -c`; Windows users without a POSIX shell get no hooks (nothing breaks,
  tier 3) · organizer · not filed: unconfirmed, since native
  Claude Code on Windows runs hooks through Git Bash, which has `sh`
- 2026-10-19 · The reviewer agent's `maxTurns: 40` (`plugins/triple-a-crew/agents/reviewer.md`) ran out
  mid-review on this 9-file change (scripts plus adversarial probes) before it recorded any finding; it had
  to be resumed. Raise the limit, or tell reviewers to write findings as they go · organizer · filed as #14 https://github.com/meliksahozceyhan/triple-a-crew/issues/14
