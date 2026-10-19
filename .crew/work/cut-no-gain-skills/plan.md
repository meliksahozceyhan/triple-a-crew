# Plan

| Task | Goal | File set | Acceptance check | Role | Tier | Depends on |
|---|---|---|---|---|---|---|
| T1 | Fold the three skills into the organizer and researcher | plugins/triple-a-crew/skills/work/SKILL.md, plugins/triple-a-crew/skills/work/staffing.md, plugins/triple-a-crew/agents/researcher.md | size-L convention check, verify cleanup line, researcher ranked causes; description no longer routes to cut skills | organizer | standard | - |
| T2 | Delete the three skills and their eval cases | plugins/triple-a-crew/skills/{plan-review,cleanup,investigate}/, plugins/triple-a-crew/evals/{plan-review-cites-project-rules,cleanup-stays-in-scope-and-verifies,investigate-reads-tracker-ranks-causes}/ | folders gone; remaining evals list 9 cases | organizer | mechanical | - |
| T3 | Update the docs and plugin.json | README.md, plugins/triple-a-crew/README.md, docs/DESIGN.md, plugins/triple-a-crew/.claude-plugin/plugin.json | grep finds only intended (historical) mentions | organizer | standard | T1, T2 |
| T4 | Verify | read only | profile verify passes; organizer evals 1.00 at --runs 1 | organizer | mechanical | T3 |
| T5 | Review the full diff | read only | verdict + findings in team/T5-reviewer.md | reviewer | critical | T4 |
