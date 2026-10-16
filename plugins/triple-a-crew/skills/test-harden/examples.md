# Test hardening examples

The snippets use Vitest syntax. Translate them to the project's framework; the point is the scenario, not
the syntax.

## Example 1: Cursor Loop Risk

Weak test:
- only verifies first-page happy path

High-value addition:

```ts
it("should_stop_iteration_when_next_cursor_repeats", async () => {
  mockApi.getTickets
    .mockResolvedValueOnce({ results: [{ id: "1" }], paging: { next: "abc" } })
    .mockResolvedValueOnce({ results: [{ id: "2" }], paging: { next: "abc" } });

  const result = await runSyncWithCursor(null);

  expect(result.finished).toBe(true);
  expect(result.cursor.reason).toBe("REPEATED_CURSOR");
});
```

## Example 2: Timezone Boundary

Weak test:
- validates only UTC midday timestamps

High-value addition:

```ts
it("should_preserve_event_order_across_dst_boundary", () => {
  const input = [
    { id: "a", ts: "2026-03-29T00:59:59+01:00" },
    { id: "b", ts: "2026-03-29T02:00:00+02:00" },
  ];

  const output = normalizeAndSort(input);

  expect(output.map((x) => x.id)).toEqual(["a", "b"]);
});
```

## Example 3: Partial Batch Failure

Weak test:
- all-success path only

High-value addition:

```ts
it("should_return_partial_success_summary_when_one_item_fails", async () => {
  mockWorker.process
    .mockResolvedValueOnce({ id: "1", ok: true })
    .mockRejectedValueOnce(new Error("transient"))
    .mockResolvedValueOnce({ id: "3", ok: true });

  const summary = await processBatch(["1", "2", "3"]);

  expect(summary.successCount).toBe(2);
  expect(summary.failureCount).toBe(1);
  expect(summary.errors[0].id).toBe("2");
});
```

## Example 4: Unicode and Control Chars

```ts
it("should_sanitize_control_chars_without_dropping_unicode", () => {
  const raw = "Hello\u0000 world 🚀  مرحبا";
  const cleaned = sanitizeText(raw);
  expect(cleaned).toContain("🚀");
  expect(cleaned).not.toContain("\u0000");
});
```
