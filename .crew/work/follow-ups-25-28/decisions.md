# Decisions

- **2026-10-19 Size M; the organizer writes T2 and T3 itself** (a line or a paragraph each), a researcher
  settles #27 first, a fresh opus reviewer checks the diff. The user asked to see the plan first.
- **2026-10-19 #28 goes into protocol.md and the verifier agent, not SKILL.md** (160-line budget). Rejected: a
  SKILL.md step 8 line.
- **2026-10-19 Plan approved by the user as written** (S3 not added).
- **2026-10-19 T2 done.** #25: the fixture writes `lines.join("\n")`; in a fresh `mktemp -d` scaffold the new
  `src/routes/orders.js` passes `node --check` and `node --test` passes, while the old fixture's file fails
  `node --check` at line 21. #26: the README says fixtures are bash scripts run with `bash` (to run one by hand,
  `bash <path>`), and only the hook scripts are POSIX `sh`. #28: protocol.md's shell rule and the verifier's
  step 1 say each Bash call starts in the project root, so a command for another folder comes ready to run
  (`pnpm -C web test`, or `cd "web" && pnpm test`) and runs as written. SKILL.md untouched (160 lines).
