# Decisions

- **2026-10-19 Publish last.** v1.0.0 should ship the roadmap items that are approved; versions start then.
  Rejected: publishing `file-issue` alone first (possible if you want it sooner; it is the most finished
  plugin).
- **2026-10-19 `version` in each `plugin.json` only.** The docs warn against setting it in both places
  (`plugin.json` silently wins). Tags (`<plugin>--v<version>`) are only required for dependency ranges, but
  `claude plugin tag` checks consistency, so tag every release anyway.
- **2026-10-19 A license file in each plugin folder too.** A Claude chat zip and the Anthropic directory see
  only the plugin folder. Rejected: root only.
- **2026-10-19 Promise Claude chat support for `file-issue` only, until tested.** `onboard`, `test-harden`,
  `work` and `handoff` need files, a shell or subagents. The README's tier-1 claim gets corrected in T3.
- **2026-10-19 Your author email stays a decision, not an automatic fix.** Rewriting history changes every
  SHA and breaks links to PRs #1-#6; keeping it exposes the address. Only you can weigh that.
- **2026-10-19 Plan approved by the user as written.** Runs last, after the other approved items.
- **2026-10-27 Resumed** after `issue-30-criteria-check` and `effort-ladder` closed; `cursor-check` paused
  by the user. The facts were refreshed: 74 commits now, the Gmail address on 55 of them (13 of 19 at T1),
  no LICENSE anywhere, `main` unprotected, repository private, no `version` fields.
- **2026-10-27 T2, the user's decisions:**
  - **License: Apache-2.0** (what Anthropic's plugin repositories use). Rejected: MIT.
  - **History: keep.** The Gmail address stays in 55 commits; the local repository config switches to the
    GitHub noreply address for new commits. Rejected: a fresh public repository (the only full scrub, but it
    splits issues #32, #37-#39 from the code and breaks the README's PR references); a `filter-repo`
    rewrite (every SHA changes, and GitHub's PR pages keep the old commits anyway). So T6 is dropped.
  - **`ACT-` example keys: rename** to a neutral key in all 16 files, mocks and graders in lockstep.
  - **Committed work items: keep,** with the Actioner-specific sentences and this machine's paths reworded.
  - **Profile notes: keep,** reworded so they don't describe one machine.
  - **GitHub: protect `main`** (pull requests only, no force-push or deletion, no required approvals) and
    **turn on private vulnerability reporting** with a `SECURITY.md`. Both after the repository is public
    (T11), since the free plan offers them for public repositories. Rejected for now: submitting to the
    Anthropic plugin directory; revisit after v1.0.0 has been public and the chat test is done.
- **2026-10-27 Plan changes from T2.** T3 splits into T3a (README, DESIGN, profile, work-item wording, the
  README License section; engineer, standard) and T3b (the `ACT-` rename across `plugins/**`; engineer,
  mechanical). T4 writes only the three LICENSE files, so it runs beside T3a. T5 runs beside them too: its
  file set is the two `plugin.json` files. T7 reads PRs #1-#36 (the plan said #1-#7). New T12: the five eval
  cases whose mocks or graders the rename touches run once after T3b (about $2). T3a, T3b, T4, T5 and T7 run
  in parallel without worktrees because their file sets are disjoint (staffing.md: overlapping writers go
  in sequence or in worktrees; these don't overlap).
- **2026-10-27 T3a, T3b, T4, T5, T7 done.** T3b asked about the bare team key `ACT` in 11 files the
  `ACT-` grep had missed; answered yes and resumed (findings.md). T5: `claude plugin validate --strict`
  passes. T7: no secrets in any PR; six bodies name the old project or an `ACT-` key (findings.md).
  **T13 verify: 3/3 pass, no warnings** (haiku verifier). **T12 so far:** `no-fire-already-tracked` 1.00
  ($0.06), `stays-out-of-read-only-investigation` 1.00 ($0.15); the three mocked-Linear cases are running.
- **2026-10-27 T12 done: all five cases 1.00** (`linear-confirms-before-creating` $0.16,
  `linear-duplicate-offers-comment` $0.14, `profile-confirm-never-creates` $0.16); $0.67 in all against
  about $2 planned. The rename left every case consistent with itself.
- **2026-10-27 T8 review (opus, effort high): changes requested**, one must-fix, four should-fix, four nits
  (team/T8-reviewer.md). Everything else met: license files identical, manifests strict-valid, no secrets in
  the tree or in 74 commits, every eval case consistent, verify passing. The organizer made the fixes (all
  size S, none written by it before):
  - R3 must-fix: the clone-then-add example said `./claude-skill-folder`; a clone of the public repository is
    `./triple-a-crew`. Fixed.
  - R1, R2: bare team key `ACT` in `README.md:118` and `docs/DESIGN.md:416`, missed because T3a's check
    looked for `actioner` and T3b's scope stopped at `plugins/`. Both now `SHOP`.
  - R5: a version-bump rule before releases, in the README Develop section and the profile note.
  - R6: the Updating block now updates both plugins. R7: the YAML comments realigned. R8: "private plugin
    with one user" reworded in `cut-no-gain-skills/brief.md`. R9: `"license": "Apache-2.0"` added to both
    manifests; `claude plugin validate --strict` still passes.
  - R4 is the user's: commits `367af47` and the PR #3 merge `0177e6a` name the previous project in their
    messages. The history-keeping decision covered the Gmail address only; asked with the push decision.
  Per step 8, verify is rerun (T15) and a fresh reviewer rechecks the fix diff (T14).
- **2026-10-27 T15 verify rerun: 3/3 pass, no warnings. T14 recheck (opus, effort high): approve.** Every
  T8 finding resolved; R4 pending the user. Three nits, applied by the organizer: the two over-long lines
  rewrapped (`cursor-check/brief.md`, `DESIGN.md`); the bump rule now says "in every change to
  `plugins/<name>/` that users should get", since users install whatever is on `main`; the profile's update
  note names `claude plugin marketplace update` before `claude plugin update`. These are prose edits in files
  no verify command reads, so verify was not run a third time. The change is committed on `publish-v1`;
  the push, the two commit messages (R4) and the six PR bodies (T7) go to the user.
- **2026-10-27 The user's answers:** push and open the PR; **R4 accepted as history** (the two commit
  messages that name the previous project stay; a rewrite was rejected at T2); **edit the six PR bodies**
  (#1, #2, #3, #4, #6, #8, and #3's title) to drop the old project name and `ACT-` keys, with `gh pr edit`.
- **2026-10-27 Pushed; PR #41 open against `main`.** The six PR bodies and #3's title were edited (eleven
  passages: T7's ten plus a second `ACT-512` in #6's verification line); the originals are kept in the
  session scratchpad, and GitHub keeps each body's edit history. The commit `6be2e5f` is the first authored
  with the noreply address.
- **2026-10-27 T9.** PR #41 merged at 17:10Z (`02cac9b`); the user made the repository public (checked:
  `gh repo view` says PUBLIC). Tags `triple-a-crew--v1.0.0` and `file-issue--v1.0.0` created with
  `claude plugin tag` at `main`'s HEAD and pushed with the gh credential helper (the command's own `--push`
  would have hit this machine's missing HTTPS helper). Install from an empty `CLAUDE_CONFIG_DIR` with the
  README's three commands: marketplace added (SSH clone), both plugins installed at 1.0.0 and enabled. A
  second empty config with `CLAUDE_CODE_PLUGIN_PREFER_HTTPS=1` cloned over HTTPS and installed `file-issue`
  the same way, so the README's line for users without an SSH key holds. The two test configs live in the
  session scratchpad and touched no user settings. T10 zips built without `evals/`: `file-issue-1.0.0.zip`
  (18 files, 22 KB) and `triple-a-crew-1.0.0.zip` (71 KB).
- **2026-10-27 T11, with the user's go-ahead on all three:** branch protection on `main` (pull requests
  required, zero required approvals, force-pushes and deletion blocked, enforced for admins); private
  vulnerability reporting on; description and five topics set. `SECURITY.md` is drafted and goes into the
  close PR with the README chat row, once the user reports the T10 chat test.
- **2026-10-27 T10, the user's chat test.** Uploading `file-issue-1.0.0.zip` to Claude chat with "Load this
  plugin": chat read the plugin (two commands, one file), summarized the skill correctly (scope test, tracker
  order, duplicate check, confirm before creating, no secrets, no public security issues), said it would
  follow the workflow for the rest of that conversation and that it cannot install a plugin permanently from
  chat, found Linear among its connectors, and asked for a problem to file. So in chat a zip works as a
  per-conversation skill, not an install. Not exercised: the proactive trigger on an out-of-scope bug
  mentioned in passing, and the confirm-before-create step. Chat also reviewed the plugin unasked: keep
  `confirm: always` as the default given the proactive description, and the evals mock only Linear
  (findings.md).
- **2026-10-27 T10, second prompt.** A message about fixing a login timeout that mentioned, in passing, an
  export endpoint ignoring its page size: chat answered the login question, treated the export problem as out
  of scope, searched the connected Linear twice for duplicates, drafted a complete issue (title, problem,
  evidence marked unconfirmed, impact, approach, three acceptance criteria), picked the team from the search
  results, and stopped: "Should I create this … as written?" Nothing was created. So the skill's whole flow
  works in chat: trigger, duplicate check, draft, confirm. T10 done; the README footnote gets this result.
- **2026-10-27 Closed.** Every done-when line of `brief.md` holds (ticked there). `retro.md` has six lessons:
  two profile notes and one follow-up issue proposed; one lesson becomes the README footnote in this close PR;
  two stay in the retro. The close branch `close-publish-v1` carries `SECURITY.md`, the README footnote and
  roadmap row, and these records.
