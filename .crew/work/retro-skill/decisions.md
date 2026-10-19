# Decisions

- **2026-10-19 Earn the place through repeats and routing, not through writing a retro.** Plain Claude
  writes a decent retro when asked. What it does not do by default: read the ignored working state before it
  goes stale, compare with earlier retros to spot a problem that keeps coming back, and route each lesson to
  the file where the next work item will read it. The trigger eval must show that gain, or the skill is cut.
- **2026-10-19 `retro.md` is committed** with brief, plan, decisions and findings. Rejected: ignored
  (it is the only durable record of what went wrong).
- **2026-10-19 Retro proposes, the user decides** for profile notes, convention files and issues. Rejected:
  writing notes directly (they are user-owned fields per `profile-format.md`).
- **2026-10-19 Scope is a work item, not a session.** Session lessons already live in `handoff`. Rejected: a
  session retro mode (overlaps `handoff`).
- **2026-10-19 Plan approved by the user as written.**
- **2026-10-19 Crew feedback goes to the plugin's repository, never the project's tracker by default.** A retro
  in another project (say, one tracked in Linear) would otherwise file Triple-A-Crew feedback into that
  project's team. The skill offers an issue draft for the plugin's repository instead. It names `file-issue`
  only as optional (a user may install `triple-a-crew` alone); redaction and confirmation are stated in the
  skill itself.
- **2026-10-19 Two eval cases instead of three.** `retro-on-request` (with a baseline) covers the trigger, the
  working-state read and the repeat in one fixture; `no-fire-retro-question` is the near miss. Rejected: a
  separate repeat-only case (same fixture, double cost). The organizer's close step has no case of its own; a
  closing run costs about $1 and the step is one line.
- **2026-10-19 T7: no gain over plain Claude.** `retro-on-request` scored 1.00 with the skill and 0.75 without,
  but the whole gap came from a grader bug (the "untouched" graders matched `profile.md`/`CLAUDE.md` in the
  text of `retro.md`). With graders matching the file path, both arms scored 1.00: plain Claude globbed
  `.crew/**/*`, read the ignored `board.md` and `team/` files, flagged the orders-filter repeat, proposed edits
  and asked first. `no-fire-retro-question` 1.00 in both arms; `medium-fix-end-to-end` 1.00 with the retro at
  close. Cost $1.43 + $0.41. Per the approved plan ("cut if its eval shows no gain"), the standalone skill
  should go; the user decides between cutting it (keeping a short retro step in the organizer's close) and
  keeping it.
- **2026-10-19 Cut the standalone skill; the organizer's close step writes the retro (your decision).** The
  skill and its two eval cases are deleted (a copy stays in the session scratchpad). Step 10 now writes
  `retro.md` for the item being closed from the board and every status file, marks repeats from other items'
  retros, routes each lesson (profile or convention edit; crew feedback as an issue draft for the plugin's
  own repository, never the project's tracker unless the user says so; or kept), puts proposals in the final
  report, and applies what the user accepts. `formats.md` holds the `retro.md` format. This also settles the
  T6 review's F1 (destination), F3 (who applies the answer) and F4 (update, don't replace, and no item lookup);
  the other findings were about the skill itself. Rejected: keeping the skill with Δ 0.
- **2026-10-19 Close-step retro verified.** `medium-fix-end-to-end` after the cut: 1.00, $1.02. Before
  closing, the organizer wrote `.crew/work/csv-rfc4180-quoting/retro.md`, then the board and the index (trace
  `/private/tmp/e-jcmqXV/out/trace.jsonl`). The fixture folder was cleaned afterwards, so the retro's content
  is not available. The same run staffed the new test-engineer and verifier.
- **2026-10-19 T6b review of the cut-and-fold: changes requested** (full list in `team/T6b-reviewer.md`,
  git-ignored). M1: step 9 files every finding through `file-issue` into the project's tracker before step 10
  can route crew feedback to the plugin's repository; step 9 must skip crew feedback. Should-fix: S1 keep each
  proposal's exact text and destination in `retro.md` so a later answer can be applied; S2 say where the
  plugin's repository URL comes from (`repository` in `.claude-plugin/plugin.json`); S3 crew feedback quotes no
  project code, paths or names; S4 graders in `medium-fix-end-to-end` for `retro.md` and for no writes to
  `CLAUDE.md`/`profile.md` (match `"file_path"`). Nits N1-N5 (README wording, "not another note" vs a profile
  note, "apply none until the user answers", abandoned/stopped outcomes). Not applied yet.
- **2026-10-19 T6b fixes applied.** M1: step 9 files every finding except crew feedback, which waits for
  step 10. S1: `retro.md` keeps each proposal's exact text and destination in a "Proposed text" section, and a
  lesson still `proposed` elsewhere is named, not proposed again. S2: the plugin repository is `repository` in
  `../../.claude-plugin/plugin.json` from the skill folder; if it is missing or unreachable the draft stays
  in `retro.md`. S3: crew feedback describes crew behavior only, with no project code, paths or names. S4:
  `medium-fix-end-to-end` gained `retro-written` and four `*-untouched-*` graders (matching `"file_path"`).
  Nits: N1/N2 README wording; N3 "not another retro-only lesson"; N4 "apply none of them until the user
  answers"; N5 the Outcome field is gone: only an item closing as done gets a retro, a paused one gets
  `handoff.md`, an abandoned one neither. Rejected for N5: retros for paused items (they would spend the
  remaining context reading every status file).
- **2026-10-19 Eval after the T6b fixes.** `medium-fix-end-to-end`: 1.00, $1.09, all 12 graders, including
  `retro-written` and the four untouched-file graders (no Write or Edit to `.crew/profile.md` or `CLAUDE.md`).
  The sandbox was cleaned after the run, so the content of the `retro.md` it wrote was not inspected.
- **2026-10-19 T11 recheck: ship** (`team/T11-reviewer.md`, git-ignored). M1, S1-S4 and N1-N5 resolved; the
  new graders match subagent calls too and do not fire on a `retro.md` that only mentions the files. Its
  should-fix and nits applied: an accepted crew draft is filed in the plugin's repository as written, not
  through `file-issue` (which picks the profile's tracker first and adds project paths); step 10 also reads
  `findings.md`; the example uses `<repository from plugin.json>` instead of a literal URL; a `not filed`
  Status for an accepted draft whose repository was unreachable; the plugin README line rewrapped. Not
  rerun: the case's graders do not depend on these lines.
- **2026-10-19 Closed.** Merged in PR #11. `retro.md` written at close; the user accepted every proposal: L3
  accepted and applied, L5 filed as #19. The other lessons are filed (#14, #16, #17) or kept.
