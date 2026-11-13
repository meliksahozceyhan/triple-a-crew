# Grader rows

Saved rows that `scripts/test-graders.mjs` runs the eval graders against, with no model call.

Each checkable grader (`regex` on the trace or the final message, and `tool_used`) gets two files at
`scripts/grader-rows/<plugin>/<case>/<grader name>.pass.jsonl` and `.fail.jsonl`. One JSON message per line.

- `.pass.jsonl`: real rows the grader must pass. For a `not_contains` grader these are real rows without the forbidden text.
- `.fail.jsonl`: the near miss the grader must fail: the same rows with the wanted text removed. For a
  `not_contains` grader it is a real row that contains the forbidden text.

A grader needs both files or neither. A grader with neither is reported as "no rows". A rows file whose
grader does not exist (a renamed case or grader) fails the run.

## Making them

1. Keep a trace from one real run: `claude plugin eval ... --keep-temp`, then take `out/trace.jsonl`.
2. `node scripts/test-graders.mjs harvest <trace.jsonl> <plugin>/<case>` writes each `.pass.jsonl` from the
   rows the match needs and replaces your home folder with `$HOME`. It never overwrites without `--force`.
3. Make each `.fail.jsonl` by hand: copy the `.pass.jsonl` rows and remove the wanted text from the row
   itself. Do not invent rows: a probe on made-up text hides the real row shape.
4. `node scripts/test-graders.mjs` checks them all.
