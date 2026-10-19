# Findings
- 2026-10-19 · `tool_used` graders match `input_match` against the whole tool input, so a "never Write
  profile.md" grader also fails when a Write to another file merely mentions `profile.md` in its content. The
  first `retro-on-request` baseline lost 0.25 that way although it never touched profile.md or CLAUDE.md. Match
  the path only: `'"file_path"\s*:\s*"[^"]*profile\.md"'`. README "Conventions for new skills" could say so ·
  organizer · filed as #16 https://github.com/meliksahozceyhan/triple-a-crew/issues/16
- 2026-10-19 · `medium-fix-end-to-end` cannot check that the organizer runs a single verify command itself
  for size M (SKILL.md step 8): the case's allowed tools give the organizer no Bash, and `verify-ran` counts
  `node --test` calls made inside subagents. In run e-jcmqXV the organizer said it could not run commands and
  staffed a verifier · found by T11 reviewer · filed as #17 https://github.com/meliksahozceyhan/triple-a-crew/issues/17
- 2026-10-19 · The reviewer hit its 40-turn limit again on a small recheck (T11) and had to be resumed; repeat of
  the crew-hooks finding on `maxTurns` · found by organizer · filed as #14 https://github.com/meliksahozceyhan/triple-a-crew/issues/14
