---
name: test-harden
description: Harden a test suite against real production failures - find the high-risk edge cases the tests miss (pagination and cursor loops, time zones and DST, malformed or partial data, unicode and extremes, retries and partial batch failure) and either report them as ranked, concrete test proposals or add them, in the project's own test framework and style. Use when the user asks to review test quality, find missing edge cases, harden or strengthen tests, or after tests were written or changed. Behavior-first; never couples tests to implementation details.
---

# Test harden

Review tests like a senior engineer who has been paged at 3 a.m. Find the cases that break production, then
close the biggest gaps with the fewest high-signal tests.

**Mode:** report the gaps (default), or fill them when the user asks you to add, write or fix the tests. In
fill mode, review first.

## 1. Learn the project's testing rules

- The test framework and style come from the existing suites and `.crew/profile.md` (`stack`, `tests`). Use
  that framework only; never introduce another one.
- Read testing rules in the `conventions` files (`CLAUDE.md`, `.claude/rules/`, `.cursor/rules/`). They win
  over the defaults below.

## 2. Non-negotiable rules

1. Behavior first: assert observable outcomes, never private helpers or internal call order.
2. Mock only external or non-deterministic dependencies (network, clock, randomness, file system). Never mock
   the domain logic under test.
3. Parameterize combinatorial input spaces (`it.each`, `test.each`, `@pytest.mark.parametrize`, table tests).
4. Deterministic and independent: fixed clocks and seeds, no ordering between tests.
5. Every new test must fail when the behavior it protects breaks.

## 3. Review

1. From the production code, list the behaviors under test.
2. Classify the existing tests: happy path, boundary, invalid input, null or empty, side effects, external
   failure.
3. Find blind spots with the catalog below and rank them by production risk: what outage, data loss or
   corruption each one could let through.
4. Propose the smallest set of tests that closes the highest risks.

## 4. Edge-case catalog

- **Time:** DST forward and backward, leap days, mixed time zone offsets, out-of-order timestamps.
- **Cursors and pagination:** a repeated cursor (infinite loop), `hasMore` true with no next cursor, an empty
  page between non-empty pages, a stale cursor after data changed.
- **Data shape:** missing nested optional fields, null inside arrays, empty vs whitespace-only strings,
  duplicate ids with conflicting payloads.
- **Input extremes:** maximum lengths, unicode and emoji, control characters, zero, negative and huge numbers.
- **Concurrency and ordering:** the same operation retried (idempotency), parallel calls finishing out of
  order, partial success in a batch.
- **External failure:** rate limits (429), a transient 5xx then recovery, a timeout mid-stream, a malformed
  but syntactically valid payload.

[examples.md](examples.md) shows weak tests and the additions that fix them.

## 5. Report (review mode)

```markdown
## Critical gaps
- [risk] <missing case> - <how it breaks production> - <test name to add>

## High-value additions
- `<behavior> when <extreme condition>`: scenario, expected observable behavior, minimal mock strategy

## Snippets
<ready-to-paste tests in the project's framework>
```

## 6. Fill (fill mode)

1. Add the tests to the matching existing suite; create a new file only when none fits. Reuse the suite's
   helpers and naming.
2. Run the tests with the project's test command (`verify` or `tests` in `.crew/profile.md`, or the test
   script in the manifest). This is required: a fill run is not done until you have run the new tests and
   seen the result. If you cannot run commands, say so explicitly.
3. If a new test exposes a real bug, do not weaken it: keep it, mark it expected-to-fail only if the framework
   supports that, and report the bug as a finding.
4. Report: files changed, which gaps you closed, which you skipped and why, and the test command with its
   result.
