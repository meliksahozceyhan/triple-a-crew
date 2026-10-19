# Findings
- 2026-10-19 · `tool_used` graders match `input_match` against the whole tool input, so a "never Write
  profile.md" grader also fails when a Write to another file merely mentions `profile.md` in its content. The
  first `retro-on-request` baseline lost 0.25 that way although it never touched profile.md or CLAUDE.md. Match
  the path only: `'"file_path"\s*:\s*"[^"]*profile\.md"'`. README "Conventions for new skills" could say so ·
  organizer · not filed
- 2026-10-19 · `medium-fix-end-to-end` cannot check that the organizer runs a single verify command itself
  for size M (SKILL.md step 8): the case's allowed tools give the organizer no Bash, and `verify-ran` counts
  `node --test` calls made inside subagents. In run e-jcmqXV the organizer said it could not run commands and
  staffed a verifier · found by T11 reviewer · not filed
- 2026-10-19 · The reviewer hit its 40-turn limit again on a small recheck (T11) and had to be resumed; repeat of
  the crew-hooks finding on `maxTurns` · found by organizer · not filed
