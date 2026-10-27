# Publish the marketplace

**Size:** L · **Ticket:** none (roadmap, W2 of the v1 handoff) · **Opened:** 2026-10-19

## What
Make Triple-A-Crew installable by anyone: choose a license, set `version` in both `plugin.json` files and tag
releases, remove or rewrite anything personal or Actioner-specific, make the GitHub repository public, and
test the `file-issue` plugin as a zip in Claude chat.

## Why
DESIGN Goals: "Publishable: nothing personal or Actioner-specific in the plugin; skills work with tools the
author does not use daily." `file-issue` was built to be published first (D6).

## Done when
- [x] A license file and the README License section.
- [x] `version` set in both `plugin.json` files, and a tag per release.
- [x] An exposure audit of the tree and the git history, with every hit fixed or accepted by the user.
- [x] The repository is public (the user's action) and installs from a clean machine with the README steps.
- [x] A `file-issue` zip tested in Claude chat, with the result in the README.

## Constraints
- Making the repository public is the user's decision and click; forks and caches make it hard to undo.
- Conventions (profile): README "Conventions for new skills", `docs/DESIGN.md` (Goals, Verified mechanics).
- The author's own install from the local folder must keep working, or the switch must be documented.

## Edge cases
| Case | In scope? | Covered by |
|---|---|---|
| A secret or personal detail in git history, not only the tree | yes | T1 audit of all refs |
| Committed `.crew/` files (profile, work items) read oddly in public | yes | T1 audit; decision |
| Actioner examples (ACT keys, actioner-new migration) | yes | T1 audit; keep as history or genericize |
| Users on an older version when `version` starts being set | yes | release notes |
| Claude chat: skills that need Bash or scripts (`handoff`) | yes | T1 research; only tier-1 skills promised |
| Name clash with another marketplace or plugin | yes | T1 research |
| A security report from a stranger | yes | GitHub private vulnerability reporting |
