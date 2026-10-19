# Findings

- 2026-10-19 · No eval checks the rules folded into the organizer: the size-L convention check recorded in
  `decisions.md` (`plugins/triple-a-crew/skills/work/SKILL.md`, step 5) and the noise rule in the verify step
  (step 8). README "Conventions for new skills" asks for one case per key rule. The fixtures of the cut cases
  (`git show main:plugins/triple-a-crew/evals/plan-review-cites-project-rules/fixture.sh`,
  `.../cleanup-stays-in-scope-and-verifies/fixture.sh`) could seed them. · found by T5 reviewer · not filed yet
