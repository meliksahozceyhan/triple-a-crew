---
name: handoff
description: >
  Write or resume a session handoff: a markdown file with the session's talking points, decisions
  (with rationale), lessons learned, files changed and how, open work and next steps, so a fresh
  session or a subagent can continue without the transcript. Use when the context window is nearly
  full, before /clear or /compact, or when the user says "handoff", "hand off", "write a handoff",
  "save session state", "wrap up for a new session". Also use at the start of a session to
  "resume", "pick up where we left off", "continue from the handoff", and to brief subagents from a
  handoff ("brief W2", "split the remaining work across subagents").
argument-hint: "[resume [file] | brief <file> <W#...> | <focus note>]"
---

# Handoff

A handoff is a markdown file: a narrative you write (intent, decisions, lessons) plus a facts appendix
that `handoff.mjs` generates from git and the Claude Code transcript (every user prompt including those
before compaction, files edited incl. by subagents, failed and denied commands, task list, git state).

Commands run from the repo root. The helper is `${CLAUDE_SKILL_DIR}/handoff.mjs` (`node … help` lists
everything). Handoffs go to `<main checkout>/.crew/handoffs/`, which ignores itself in git. If the repository
root is your home directory (dotfiles in git), they go to the working directory's `.crew/handoffs/` instead.

Arguments given: `$ARGUMENTS`

- empty, or a focus note → **Write**
- `resume` or `resume <file>` → **Resume**
- `brief <file> <W#> …` → **Brief**

## Write

1. Collect the facts (read the output, it's your checklist):
   ```bash
   node "${CLAUDE_SKILL_DIR}/handoff.mjs" facts --session "${CLAUDE_SESSION_ID}"
   ```
   If the Session block says it picked the "newest transcript", confirm the title/prompts are this session's;
   otherwise re-run with `--session <id or path to .jsonl>`.
2. Get a file path (topic = 3–6 words naming the effort):
   ```bash
   node "${CLAUDE_SKILL_DIR}/handoff.mjs" path --topic "<topic>"
   ```
3. Write the narrative to that path with the Write tool using the template below: every section,
   headings unchanged. If the user gave a focus note, put it first in Next steps.
4. Finalize. This adds frontmatter (branch, HEAD, session, chain) and the facts appendix, then validates:
   ```bash
   node "${CLAUDE_SKILL_DIR}/handoff.mjs" finalize <path> --session "${CLAUDE_SESSION_ID}"
   ```
   Fix every warning with Edit and re-run finalize until it passes. It is idempotent. Never skip this step:
   without it the handoff has no frontmatter, no facts appendix and no validation, and `resume` cannot
   chain it.
5. Tell the user the path, the open work items in one line each, and how to continue:
   start a new session and run `/triple-a-crew:handoff resume`.

### How to write it

- **The reader starts cold.** Assume they have no context. Never write "as discussed", "the bug" or "that approach"; name the thing.
- **Be precise.** Use `path:line`, function names, exact commands, and short verbatim error messages.
- **Decisions carry their why** and the alternatives you rejected, so the next session doesn't argue them again.
  Every entry in "User answers to agent questions" is a decision.
- **Lessons include dead ends**: "tried X, failed because Y, don't retry". Go through "Commands that failed" and
  "Tool calls the user denied": each one is either a lesson or a ground rule.
- **Cross-check against the facts.** Each user prompt should show up in Talking points. Each edited file goes in
  Changes made, or gets flagged as scratch or reverted. Say what was verified and what is only assumed.
- **Point at code, don't paste it.** Git holds the diff. Keep the narrative under about 1,500 words.
- **No secrets.** Never copy env values or tokens, even into Ground rules.
- **Carry forward.** If this session resumed from an earlier handoff, copy over its decisions, lessons, ground rules
  and open work that still apply. Each handoff must stand alone.
- **Near the limit, don't re-read files to write this.** Use your context and the facts; spot-check only what you're unsure of.

### Template

Replace every `{{…}}`; finalize flags any left over. Keep the `## N. Name` headings and the `### W1 — title`
shape, because `brief` and `finalize` parse them. Write "None." under a section that is truly empty.

```markdown
# Handoff: {{the effort, e.g. "HubSpot MCP connection-permission fix"}}

## 1. Mission
{{2–5 sentences: overall goal, why it matters, what "done" looks like. Link issue/PR/spec.}}

## 2. Status at handoff
- **Done:** {{finished pieces}}
- **In progress:** {{exactly where work stopped: file/function, half-applied change, failing test name}}
- **Not started:** {{…}}
- **Verification:** {{commands run + result; what is still unverified}}
- **Environment:** {{running servers/background jobs, DB/data setup, flags, things only the user can do}}

## 3. Talking points
- {{chronological: each user ask, pivot, clarification or feedback → what came of it (≤2 lines each)}}

## 4. Decisions
| # | Decision | Why | Rejected alternatives | By |
|---|----------|-----|-----------------------|----|
| D1 | {{…}} | {{…}} | {{…}} | {{user / agent, user-approved / agent}} |

## 5. Lessons learned
- **L1** {{gotcha, surprise, dead end + reason, or the command that finally worked}}

## 6. Changes made
- **{{logical change}}**: `{{path}}` (+ others). What: {{…}}. How: {{approach/pattern followed}}.
  Why: {{→ D#}}. State: {{committed <sha> / uncommitted / verified by <command>}}.

## 7. Open work
### W1 — {{title}}
- **Goal:** {{…}}
- **Context:** {{files/functions to start from; relevant D#/L#}}
- **Steps:** {{…}}
- **Done when:** {{check: command + expected result}}
- **Depends on:** {{W# / none}} · **Parallel-safe:** {{yes/no, and the files it touches}}

## 8. Next steps
1. {{the first concrete action for the next session}}

## 9. Ground rules
- {{standing user instructions from this session and repo rules that mattered, e.g. "don't commit", "ask before X"}}

## 10. References
- **Read first:** `{{path}}`: {{why}}
- {{docs, plans (~/.claude/plans/…), issues, PRs, useful commands}}
```

## Resume

1. Find the handoff and see what changed since it was written:
   ```bash
   node "${CLAUDE_SKILL_DIR}/handoff.mjs" resume
   ```
   This picks the newest handoff for the current branch. Pass a file to choose another, or `--any` to ignore the branch.
   It reports branch/HEAD drift, new commits and the current working tree.
2. Read the handoff in full with the Read tool, then the files it lists under **Read first**.
3. Reconcile drift. New commits or changes the handoff doesn't explain probably came from the user. Ask before overwriting them.
4. Rebuild the task list from Open work, then follow Next steps. Ground rules bind you exactly like instructions from the user.
5. If you write a handoff later, carry this one forward (see *How to write it*). Finalize records the chain for you
   (`previous:` in the frontmatter), because you Read this file.

## Brief subagents

```bash
node "${CLAUDE_SKILL_DIR}/handoff.mjs" brief <handoff file> W2 [W3 …]
```

This prints a standalone brief: mission, status, ground rules, decisions, lessons, references and only the chosen
work items. It also names the items other agents own. Paste it into the Agent prompt verbatim; that works for every
agent type, including ones without Bash. Add anything session-specific below it.

- Run items concurrently only when they are marked `Parallel-safe: yes` and don't touch the same files.
  Otherwise run them one after another, or give each agent `isolation: "worktree"`.
- The brief asks each subagent to report files changed, verification, leftovers and new lessons.
  Merge those into your own handoff before you write the next one.

## Gotchas

- **Session id.** Claude Code fills in the `--session` value in the commands above when the skill loads. If it arrives
  empty (other harnesses, e.g. Cursor), the helper uses the newest transcript for this directory, which is the wrong one
  when two sessions share a checkout. The Session block shows which transcript it picked.
- **Where transcripts live.** `~/.claude/projects/<cwd with every non-alphanumeric as ->/<session>.jsonl`.
  Subagent edits are in `<session>/subagents/agent-*.jsonl`, and they appear in the facts as `via subagent "…"`.
- **Bash edits aren't tracked.** Changes made through Bash (`sed -i`, heredocs, codegen, formatters) are missing from
  "Files edited". The Git block's working tree and diff stat catch them.
- **Git state is current, not historical.** The git column shows state now. `clean` means the edit was committed
  before the branch base, or reverted.
- **One handoff folder per repo.** Handoffs always go to the main checkout's `.crew/handoffs/`, even from a worktree,
  so every session in the repo finds them. Set `HANDOFF_DIR` to override. They can contain pasted prompts, so never commit them.
- **Not `.claude/`.** Claude Code prompts for (or denies) every write under `.claude/`, which is why handoffs moved to
  `.crew/`. Handoffs written by the older `session-handoff` skill are in `.claude/handoffs/`; resume one with
  `HANDOFF_DIR=.claude/handoffs node "${CLAUDE_SKILL_DIR}/handoff.mjs" resume`, or move the files to `.crew/handoffs/`.
- **Work items.** If a Triple-A-Crew work item is open (`.crew/work/index.md`), name it in Open work with its id and
  current board phase. The organizer's own `.crew/work/<id>/handoff.md` is a short status note for that item; this
  handoff covers the whole session.
- **Redaction is best-effort.** Only obvious patterns are scrubbed: `Bearer …`, `token=`, `password:`, `sk-…`, `ghp_…`, `xox…-`.
- **Re-sent prompts.** A prompt re-sent after an interrupt collapses into one entry. Pasted test failures with a shared
  prefix stay separate.
- **Size.** Facts for a 2-day, 20-prompt, 180-command session came to about 24k chars (about 6k tokens), in under 0.5 s.
  The biggest cost is prompt text; pass `--clip <n>` to shorten each prompt (default 500).

## Maintaining this skill

After you edit `SKILL.md` or `handoff.mjs`, run the plugin's eval case for it from `plugins/triple-a-crew`:

```bash
claude plugin eval . --case writes-handoff-to-crew --runs 1 --ablation none --scaffold --allow-tools Write Edit "Bash(node *)" "Bash(git *)"
```
