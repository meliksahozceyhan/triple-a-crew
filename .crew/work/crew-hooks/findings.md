# Findings

- 2026-10-19 · `docs/DESIGN.md` "Enforcement through hooks" says SubagentStop checks the status file for the
  final report sections; `plugins/triple-a-crew/skills/work/protocol.md` puts the report in the reply · found by
  T1 researcher · fixed by T8 of this plan
- 2026-10-19 · Hooks run through `sh -c`; Windows users without a POSIX shell get no hooks (nothing breaks,
  tier 3) · organizer · not filed
