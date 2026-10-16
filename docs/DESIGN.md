# Triple-A-Crew: design

Status: draft, from the brainstorm on 2026-10-16; open questions answered the same day.
Name: **Triple-A-Crew**, plugin id `triple-a-crew` (plugin names must be kebab-case).

## What this is

A personal, publishable set of workflow skills maintained in this one repo and installed into every project.
It holds **process** (how work moves from a problem to a shipped change); each project keeps its own
**knowledge** (stack, conventions, commands). At its center is an **organizer** that runs work like a team
lead: it understands the problem, staffs subagents ("employees") on the right models, tracks their state,
answers their questions and files follow-up issues for anything out of scope.

### Goals

- One place to write and maintain workflow skills, reused across projects.
- Covers both coding work (Claude Code) and general work (Claude chat), not only code.
- Claude Code is the primary target; Cursor is supported for the portable skills.
- Publishable: nothing personal or Actioner-specific in the plugin; skills work with tools the author does not use daily.

### Non-goals

- An ECC-style catalog. A skill earns its place only if it encodes something Claude would not do by default:
  a gate, an artifact, a preference, a protocol.
- Language packs, framework pattern skills and library docs. Those are project knowledge or third-party.
- Adapters for harnesses other than Claude Code, Cursor and Claude chat.

## Decisions

| # | Decision | Why |
|---|---|---|
| D1 | Broad scope: coding and non-coding workflows | The author works in Claude Code and Claude chat; issue writing, status, triage apply to both. |
| D2 | Claude Code first, Cursor second | Organizer, subagents and hooks are Claude Code features. For Cursor, promise only tier-1 skills until a v2 test shows what Cursor loads. |
| D3 | The organizer holds full state and staffs employees | Matches how the author wants to work: a lead who reasons about the problem and delegates to the right "employee". |
| D4 | Work state lives in the repo under `.crew/`; the durable record is committed, working state is ignored | State travels with the code and survives sessions. Committing only the record (brief, plan, decisions, findings) gives history without churning every PR. Not under `.claude/`, which Claude Code protects (see state on disk). |
| D5 | Process in the plugin, knowledge in the project | Plugins cannot ship rules or CLAUDE.md anyway; skills read a project profile instead of hardcoding a stack. |
| D6 | The issue-writing skill is the first deliverable and must stand alone | Highest daily value, and the part most worth publishing. |
| D7 | The organizer starts on its own for multi-step work | The author should not have to remember a command; a sizing step keeps it out of small requests. |
| D8 | `file-issue` confirms every issue by default; `batch` is a profile setting | `always` is the safe default for a published skill; the author's own projects can use `batch`. |

## Architecture

Three tiers in the plugin, plus a layer each project owns.

```
┌─ Tier 3: automation (Claude Code only) ─────────────────────────────┐
│  hooks: session-start board summary, subagent-stop status sync      │
├─ Tier 2: organization (Claude Code only) ───────────────────────────┤
│  organizer skill · employee agents · .crew/work/ state            │
├─ Tier 1: portable skills (Claude Code, Cursor, Claude chat) ────────┤
│  file-issue · intake · plan-review · cleanup · handoff · onboard    │
└─────────────────────────────────────────────────────────────────────┘
   project layer (not in the plugin): .crew/profile.md, project skills and rules
```

**Rules per tier**

- **Tier 1** skills are a plain `SKILL.md` plus optional reference files. No dependency on hooks, subagents or
  the work folder. If a work folder exists they write into it; if not, they still work. Every tier-2 feature
  is built from tier-1 skills, so the organizer and a user calling a skill by hand get the same behavior.
  Frontmatter is limited to `name` and `description`: other fields are Claude Code extensions to the
  [Agent Skills spec](https://agentskills.io/specification) and may be ignored elsewhere.
- **Tier 2** may assume Claude Code: subagents, model selection, worktrees, background agents.
- **Tier 3** hooks only make things faster or more visible. Nothing breaks if they are disabled.

This split matches what each surface loads. A plugin zip uploaded to Claude chat (Customize > Plugins) loads
skills and remote MCP connectors but ignores agents and hooks; Cowork loads everything; Claude Code loads
everything. So in chat, only tier 1 exists.

## The organization model

### Organizer

Runs in the main session, because only the main session can spawn employees and talk to the user.

Responsibilities, in order:

1. **Understand.** Restate the problem, the why, and what done looks like. Ask the user only what cannot be
   found in the code, the tracker or the profile.
2. **Stress-test.** Before planning, list edge and extreme cases: empty and huge inputs, concurrency, partial
   failure, permissions, migrations, rollback. Record which ones the plan must cover and which are out of scope.
3. **Plan and decompose.** Break the work into tasks with clear inputs, outputs and file sets.
4. **Staff.** Pick a role and model per task (see staffing policy), and decide sequential vs parallel.
5. **Brief.** Hand each employee a self-contained brief (see protocol). Employees never see the conversation.
6. **Track.** Keep `board.md` current from the employees' status files.
7. **Unblock.** Answer employee questions, or escalate to the user when the answer is the user's call.
8. **Integrate and verify.** Check results against acceptance criteria; send work back when it falls short.
9. **File follow-ups.** Collect out-of-scope findings from all employees, dedupe them, file them via `file-issue`.
10. **Close.** Write the handoff/retro, update the profile with anything learned about the project.

### How work starts

The organizer starts on its own; the user does not need a command.

1. **Trigger.** The organizer skill's description makes Claude invoke it for requests that look multi-step:
   building or fixing something across several files or areas, anything that needs investigation before
   implementation, or a reference to a ticket. It does not trigger on questions, explanations or one-spot edits.
2. **Resume before creating.** If the request matches an open work item in `.crew/work/index.md`, the
   organizer resumes that item instead of starting a new one.
3. **Size the work** before creating anything:

   | Size | Looks like | What the organizer does |
   |---|---|---|
   | S | one spot, no unknowns | steps aside; Claude just does it, no work folder |
   | M | several files, or one unknown | work folder; does most of it itself, staffs one or two employees |
   | L | several areas, unknowns, risk | work folder and full staffing |

4. **Announce in one line** ("Organizing this as work item `act-1062-entitlements`, size L") and continue.
   The user can say "just do it" to drop back to a normal session for that request.

`work start` still exists to force it, `work next` advances a phase, and `work status` lists open items.
A project that wants no proactive start sets `organizer: manual` in its profile; the default is `proactive`.

### Employees

Plugin agents with a fixed role, default model and tool set. The organizer can override the model per task.

| Role | Does | Default model | Tools | Notes |
|---|---|---|---|---|
| researcher | Maps code, docs and tickets; answers "where/how does X work" | haiku → sonnet | read-only | Cheap, parallel-friendly |
| architect | Options and trade-offs for ambiguous or cross-cutting work | opus | read-only | Only staffed when the design is unclear |
| engineer | Implements one task from the plan | sonnet | edit, bash | Own worktree when running in parallel |
| test-engineer | Finds missing high-risk cases, adds tests | sonnet | edit, bash | Generalized from test-robustness-reviewer/filler |
| reviewer | Fresh-context, adversarial review of a diff | opus | read-only | Never reviews its own work |
| verifier | Runs the profile's check commands, reports facts | haiku | bash | Reports, does not fix |
| scribe | Issues, handoffs, PR text, status reports | haiku | write | Uses tier-1 skills |

Roles stay few. A new role is added only when a task type keeps recurring and needs a different model,
tool set or protocol than the existing ones.

How a role maps onto an agent file (`agents/<role>.md`):

- `model` and `effort` carry the default tier; the organizer overrides both per task when it spawns.
- `tools` / `disallowedTools` carry the tool set. Employees do not get the `Agent` tool: Claude Code allows
  nesting up to three levels, but a flat team keeps every task visible on the board.
- `isolation: worktree` for engineers that run in parallel; `maxTurns` as a runaway guard.
- Plugin agents ignore `permissionMode`, `hooks` and `mcpServers`. Employees run under the user's own
  permission rules, and a background employee's permission prompts surface in the main session under its name.
  Hooks that must apply to employees go in the plugin's `hooks/hooks.json`.

### Staffing policy

Model choice is a rule table, not a judgment call buried in prose. Signals per task:

- **Ambiguity**: is the outcome fully specified?
- **Blast radius**: data, security, money, public API, migrations?
- **Novelty**: has this codebase done it before?
- **Reversibility**: can a mistake be undone cheaply?
- **Size**: files touched, steps.

| Tier | Situation | Default model |
|---|---|---|
| `mechanical` | Fully specified and reversible: run checks, rename, write from a template | haiku |
| `standard` | Implementation or investigation with a clear plan | sonnet |
| `critical` | Ambiguous design, high blast radius, security, review of others' work | opus |

A project overrides a tier's model with `models: { critical: fable }` in its profile.

Rules on top of the table:

- **Escalate on failure.** A task that fails acceptance twice moves up one tier, with the failure in its brief.
- **Separation of duties.** The agent that wrote a change never reviews it.
- **Parallel only on disjoint file sets.** Overlapping writers run in sequence, or in separate worktrees with
  the organizer merging.
- **Aliases, not model IDs.** Agents use `haiku` / `sonnet` / `opus` / `fable` so the plugin does not age
  with releases. The tier table lives in one reference file, and a project can override it in its profile.
  New models slot into the table without touching any skill.
- **Effort is the second knob.** Within a tier, raise `effort` for tasks with many edge cases before moving
  up a tier.
- **Precedence.** The model the organizer passes at spawn time wins over the agent file's default. A user's
  `CLAUDE_CODE_SUBAGENT_MODEL_FORCE` setting wins over both; the organizer records the actual model on the board.

### Communication protocol

**Brief (organizer → employee).** Fixed sections: goal; why it matters; context pointers (`path:line`, docs,
ticket); scope in and out; acceptance criteria; constraints from the profile; where to write status; report
format. Written for a reader who has seen nothing.

**Status file (employee → organizer).** One file per task at `.crew/work/<id>/team/<task>.md`, written only
by that employee, so parallel employees never edit the same file. The brief gives it as an absolute path into
the main checkout: an employee in its own worktree would otherwise write into the worktree's copy, which the
organizer never sees and git never merges (`team/` is ignored).

```markdown
---
task: T3
role: engineer
model: sonnet
state: in-progress   # todo | in-progress | blocked | done | failed
updated: 2026-10-16T14:05
---
## Progress
- [x] Added schema
- [ ] Wire route
## Assumptions        (reversible choices made without asking)
## Questions          (what blocks me, and my proposed answer)
## Findings           (problems outside my task; the organizer decides what to file)
```

**Questions up.** An employee that hits an unknown either (a) makes a reversible assumption and records it,
or (b) stops with `state: blocked`, the question and its proposed answer. It never guesses on anything
irreversible. The organizer answers by continuing that employee with `SendMessage` (the employee resumes
with its full history), or escalates to the user. Stopping is the reliable way to ask: subagents cannot use
`AskUserQuestion`, and the docs do not say whether a subagent waits after messaging its parent.

**Questions down.** The organizer can question a finished employee ("why X?", "what's left?") the same way,
instead of starting a new one that would have to rediscover everything. Built-in Explore and Plan agents
cannot be resumed, which is one more reason employees are plugin agents.

**Enforcement through hooks** (tier 3, so the protocol holds even when an employee forgets it):

- `SubagentStart` injects the protocol and the employee's status-file path as additional context.
- `SubagentStop` blocks an employee from finishing while its status file is missing, not in a final state
  (`done`, `blocked`, `failed`), or lacks the final report sections.
- `SessionStart` injects a one-paragraph summary of open work items from `.crew/work/index.md`.

**Two channel modes.**

| | Subagent mode (default) | Team mode (optional) |
|---|---|---|
| Requires | nothing | `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`, interactive session |
| Employees | subagents spawned by the organizer | teammates led by the organizer |
| Questions | stop as `blocked`, organizer resumes them | live messages, teammates can talk to each other |
| Task list | `board.md` + `team/*.md` | built-in shared task list with dependencies and file locking |
| Limits | one round-trip per question | experimental, one team per session, `/resume` does not restore teammates |

The design must work fully in subagent mode. Team mode is an upgrade the organizer uses when it is enabled,
and the files on disk stay the source of truth in both modes so a later session can pick up the work.

**Final report.** Every employee ends with the same shape: outcome, what changed (files), evidence (commands
and results), assumptions, open questions, findings. The organizer copies findings into `findings.md`.

**Findings → issues.** Employees never file issues themselves. The organizer dedupes findings across the team
and files them via `file-issue`, the way an engineer flags a problem and the lead decides what becomes a ticket.

### Lifecycle

```
intake → investigate → plan → plan-review → implement → verify → cleanup → review → ship → retro
```

Each phase is skippable; the organizer records why in `decisions.md`. `work next` reads the current phase
from `board.md` and runs the next one.

### State on disk

```
.crew/
  .gitignore                   written on first use
  profile.md                   the project contract (see "Project profile")     committed
  issues/<date>-<slug>.md      file-issue drafts when no tracker is found       committed
  work/
    index.md                   open work items, one line each                   ignored
    <id>/                      e.g. act-1062-entitlements
      brief.md                 what, why, acceptance criteria, edge cases       committed
      plan.md                  tasks, file sets, staffing                       committed
      decisions.md             decision, why, rejected alternatives             committed
      findings.md              out-of-scope problems and issues filed           committed
      board.md                 phase, task table with state/owner/model         ignored
      team/<task>.md           one status file per task                         ignored
      handoff.md               written on close or before a context reset       ignored
```

**Why `.crew/` and not `.claude/`:** Claude Code treats `.claude/` as a protected directory. Writes there
prompt in default and accept-edits modes, are denied in don't-ask mode, go to the classifier in auto mode, and
allow rules cannot pre-approve them. An organizer and its employees write state constantly, so state lives in
an unprotected folder of its own.

**Committed** files are the durable record: why the code looks the way it does, and problems found along the
way. **Ignored** files are working state that changes minute to minute and means nothing once the work is done.
Issue drafts are committed because without a tracker they are the only place a finding lives.

The organizer keeps the split in its own `.crew/.gitignore`, so it never edits the project's root
`.gitignore`:

```
work/index.md
work/*/board.md
work/*/team/
work/*/handoff.md
```

Ownership rule: every file has exactly one writer. The organizer owns everything except `team/`.

## Flagship skill: `file-issue`

Creates a follow-up issue in whatever tracker the user has, when a problem turns up that is outside the
current task. Tier 1: works in Claude Code, Cursor and Claude chat, inside or outside the organizer.

### Triggers

- Claude notices a bug, debt, risk or missing piece that is outside the current task's scope.
- The user asks to file, log or ticket something.
- The organizer hands over findings from employees.

### Flow

1. **Is it issue-worthy?** Out of scope for the current task, real (evidence, not a hunch), and not a
   two-line fix that belongs in the current change. Otherwise mention it or just fix it. A security problem
   in a public repository never becomes a public issue; the skill points to the private route instead
   (security advisory, confidential issue).
2. **Resolve the tracker**, first match wins:
   1. The project profile pins one (`issue_tracker: linear`, team, default labels).
   2. Connected MCP tools: search the available tools by capability ("create issue", "list projects") and by
      known names (Linear, GitHub, Jira/Atlassian, GitLab, Asana, ClickUp, Notion, Shortcut, Azure DevOps,
      monday). Read the tool's actual schema; never assume tool or field names.
   3. CLI fallback: `gh issue create`, `glab issue create`, when installed and authenticated.
   4. Local fallback: a draft at `.crew/issues/<slug>.md`, ready to paste.

   If several trackers match, ask once and offer to save the choice to the profile.
3. **Gather context**: repo, branch, `path:line`, reproduction, evidence (error text, command output),
   what the current task was doing when it surfaced, links (PR, parent issue, work item).
4. **Dedupe**: search the tracker for open issues on the same thing. If one exists, offer to comment on it
   instead of creating a duplicate.
5. **Draft** from the template: title (problem, not solution), context, problem, evidence, impact,
   suggested approach, acceptance criteria, links.
6. **Map fields** to the tracker: team/project, type, priority, labels, parent/relations. Per-tracker hints
   live in reference files loaded only for the tracker in use.
7. **Confirm** before creating, since it publishes to a shared system, even when the user asked for the
   issue (they asked for an issue, not this exact text in this place). Without anyone to ask (subagent,
   non-interactive run) nothing is created; the drafts go back to the caller. Configurable in the profile:
   `confirm: always` (the published default), `batch` (one confirmation for a list, e.g. the organizer's
   findings at the end of a work item), or `never`.
8. **Create and link back**: record the ID and URL in `findings.md` (when a work item exists) and tell the user.

### Layout

```
plugins/file-issue/
  .claude-plugin/plugin.json
  README.md
  skills/file-issue/
    SKILL.md               trigger, flow, rules
    template.md            issue body template and local-draft format
    trackers/              one short file per tracker: detection, destination, fields, search, gotchas
      linear.md  github.md  jira.md  gitlab.md  asana.md  clickup.md  notion.md  generic.md
  evals/
    <case>/                7 cases: trigger, no-trigger, local draft, mocked Linear, profile
      mocks/linear/        tracker cases only: mocked Linear tools with real schemas (_tools.json)
```

Mocks are per case: the eval harness registers any `mocks/<server>/` as a standalone server, so a suite-wide
mock would give every case a tracker.

`generic.md` describes how to work with an unknown tracker from its tool schemas alone, so the skill still
works with trackers that have no file of their own.

## Project profile (the contract)

`.crew/profile.md` in each project. Skills read it; `onboard` writes the first version by inspecting the
repo and asks only for what it cannot detect. The field-by-field definition lives in
`plugins/triple-a-crew/skills/onboard/profile-format.md`. **Detected** fields (`stack`, `verify`, `tests`,
`conventions`) are refreshed by `onboard`; **user** fields (`issue_tracker`, `organizer`, `models`, notes)
change only when the user asks.

```markdown
---
stack: [typescript, pnpm, prisma, vitest]
verify:                         # commands the verifier runs, in order
  - pnpm lint
  - pnpm typecheck
  - pnpm test
tests: ["packages/**/test/**/*.test.ts", "apps/**/*.test.ts"]
conventions: [CLAUDE.md, .claude/rules/, .cursor/rules/]
issue_tracker: { tool: linear, team: ACT, labels: [follow-up], confirm: batch }
organizer: proactive            # proactive (default) | manual
models: {}                      # optional: { mechanical, standard, critical } -> model alias
---
Free-form notes: architecture boundaries, things that keep going wrong, people to ask.
```

## Repo layout

```
claude-skill-folder/
  .claude-plugin/marketplace.json     marketplace "triple-a-crew", lists both plugins with relative sources
  plugins/
    triple-a-crew/                    onboard now; organizer, employees, hooks from v1
      .claude-plugin/plugin.json
      skills/onboard/                 SKILL.md, profile-format.md
      evals/                          3 cases on a scaffolded fixture repo
    file-issue/                       standalone, so others can install just this
      .claude-plugin/plugin.json
      skills/file-issue/
      evals/                          7 cases
  docs/DESIGN.md
```

Install: `/plugin marketplace add <repo>`, then `/plugin install triple-a-crew@triple-a-crew` and
`/plugin install file-issue@triple-a-crew`.

**No plugin dependency for now.** `triple-a-crew` was meant to declare `dependencies: ["file-issue"]`, but a
plugin whose dependency is not installed fails to load (`dependency-unsatisfied`). That breaks
`claude --plugin-dir` development, and eval sandboxes cannot satisfy it at all: a case may only load plugins
inside the plugin under test. `onboard` does not use `file-issue`, so v0 declares nothing. Decide in v1:
either the organizer detects `file-issue` and falls back to listing findings in `findings.md`, or the
dependency comes back and the organizer's evals run against the installed plugins.

## Verified mechanics

Checked against the Claude Code docs on 2026-10-16.

| Topic | What holds | Source |
|---|---|---|
| Marketplace | One `marketplace.json` can list several plugins with `"source": "./plugins/<name>"` | [marketplace reference](https://code.claude.com/docs/en/plugins/marketplace-reference) |
| Dependencies | `dependencies` in `plugin.json`; versions resolve from git tags `<plugin>--v<version>`. A missing dependency stops the plugin from loading, including under `--plugin-dir` and in eval runs | [dependencies](https://code.claude.com/docs/en/plugins/dependencies); eval run 2026-10-16 |
| Dev loop | `claude --plugin-dir ./plugins/triple-a-crew` loads in place; `/reload-plugins` after edits. A local-path marketplace also loads in place | [loading](https://code.claude.com/docs/en/plugins/loading) |
| Updates | Git-sourced plugins are cached per version. Omit `version` while iterating (every commit is an update), set it when publishing. Auto-update is off for third-party marketplaces | [loading](https://code.claude.com/docs/en/plugins/loading) |
| Validation | `claude plugin validate ./plugins/triple-a-crew` | [manifest reference](https://code.claude.com/docs/en/plugins/manifest-reference) |
| Agents | `model` (aliases incl. `fable`), `effort`, `tools`, `isolation: worktree`, `maxTurns`, `background`, `skills`. Plugin agents ignore `permissionMode`, `hooks`, `mcpServers`, `initialPrompt` | [subagents](https://code.claude.com/docs/en/sub-agents) |
| Nesting | Subagents may spawn subagents up to 3 levels deep by default | [subagents](https://code.claude.com/docs/en/sub-agents) |
| Hooks | `SessionStart` and `SubagentStart` can add context; `SubagentStop` and `Stop` can block. Scripts use `${CLAUDE_PLUGIN_ROOT}`; persistent plugin data goes in `${CLAUDE_PLUGIN_DATA}` | [hooks](https://code.claude.com/docs/en/hooks) |
| Skills | Bundled reference files load on demand; scripts via `${CLAUDE_SKILL_DIR}`; `context: fork` runs a skill in a chosen agent | [skills](https://code.claude.com/docs/en/skills) |
| Workflows | Plugins can ship `workflows/*.js`, but a run cannot take user input mid-way, so the organizer's Q&A loop stays in the main session | [workflows](https://code.claude.com/docs/en/workflows) |
| Evals | `claude plugin eval .` runs `evals/<case>/prompt.md` with graders (`tool_used` to check a skill fired, `llm` rubrics), with and without the plugin, and reports the difference | [plugin evals](https://code.claude.com/docs/en/plugin-evals) |
| Claude chat | Plugin zip upload loads skills and remote MCP connectors; agents, hooks and local MCP are ignored | [platform support](https://claude.com/docs/plugins/platform-support) |
| Protected paths | Writes under `.claude/` (and `.git`, `.vscode`, a few others) are never auto-approved outside bypass mode, and allow rules do not change that | [permission modes](https://code.claude.com/docs/en/permission-modes) |
| Eval mocks | Any `mocks/<server>/` directory becomes a standalone mock server named `<server>`, with tools named `mcp__<server>__<tool>`. Suite-wide mocks apply to every case. Runs use don't-ask mode, so a protected-path write fails there. The sandbox's home directory is a git repository with the working directory inside it, so "the git root" is the home directory | found by running the suite, 2026-10-16 |

Not confirmed by the docs: whether a subagent waits after messaging its parent; how a skill in Claude chat
calls a connector; whether Cursor reads `SKILL.md` from `.claude/skills` or a plugin.

## Migration from actioner-new

| Today (actioner-new) | Becomes | What moves to the actioner-new profile |
|---|---|---|
| `skills/session-handoff` (+ `handoff.mjs`) | `handoff` skill, writing into the work folder | nothing |
| `agents/plan-reinforcer` | `plan-review` skill + architect/reviewer roles | the Actioner stack rules (Zod-first, Prisma, pnpm, queue, MinIO) |
| `agents/post-plan-cleanup` | `cleanup` skill | nothing; already generic |
| `agents/investigate-linear-issue` | `intake` + `investigate` + researcher role | the `apps/*` / `packages/*` layout notes |
| `agents/test-robustness-reviewer` / `-filler` | test-engineer role + `test-harden` skill | Vitest paths, `.cursor/rules` test manifests |
| `.claude/handoffs/` | `.crew/work/<id>/handoff.md` | nothing |

## Build order

1. **v0**: repo and marketplace skeleton; `file-issue` (standalone, with the tracker reference files) and its
   evals (does it fire on out-of-scope findings, does it pick the connected tracker, does it confirm before
   creating); profile format and `onboard`. Develop with `--plugin-dir`, then install into actioner-new
   through the local marketplace and use it for real.
   *Done 2026-10-16:* skeleton, `file-issue` with tracker files and 9 eval cases, `onboard` with the profile
   format and 3 eval cases, pushed to the private repository `meliksahozceyhan/triple-a-crew`. The implicit
   trigger went from 0.67 to 1.00 after fixing the description ("only offering to file is not enough"), the
   draft location (a home-directory git root is not the project root) and its grader (judge the whole
   transcript). All 12 cases score 1.00; results in the README. *Left:* real use in actioner-new.
2. **v1**: organizer with proactive start and sizing, the work folder and its `.gitignore`, the status
   protocol in subagent mode, and three roles: researcher, engineer, reviewer. Evals for the trigger: it
   fires on multi-step requests, resumes a matching open item, and stays out of small ones. One real work
   item end to end.
3. **v2**: remaining roles, `plan-review`, `cleanup`, `test-harden`, `handoff`, `retro`; the three hooks;
   team mode; Cursor check; evals for every skill.
4. **Publish**: README, license, examples, `version` set, git tags; strip anything personal. Test the
   `file-issue` plugin zip in Claude chat.

## Open questions

1. **Command prefix.** The plugin id prefixes every command, e.g. `/triple-a-crew:work status`. With the
   organizer starting on its own this is typed rarely; switch to a shorter id only if it gets annoying.
   `displayName` ("Triple-A-Crew") is what the UI shows either way.

## Resolved

| Question | Answer | Recorded in |
|---|---|---|
| Name | Triple-A-Crew (`triple-a-crew`) | header, repo layout |
| Commit or ignore `.crew/work/` | Commit the durable record, ignore working state | D4, state on disk |
| Default confirmation for `file-issue` | `always` when published; `batch` per profile | D8, `file-issue` flow, profile |
| How the organizer starts | Proactively, with sizing and resume; `organizer: manual` opts out | D7, how work starts |
| Cursor | Tier-1 skills only until tested in v2 | D2, build order |
| One plugin or two | Two; the dependency is deferred to v1 (it breaks `--plugin-dir` and evals) | repo layout |
| Live Q&A channel | Stop-and-resume by default, team mode optional | communication protocol |
