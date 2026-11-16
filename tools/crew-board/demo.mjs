// Demo mode: a throwaway project in the system temp folder whose files change on a timer, in the
// formats the real crew writes, so the board has something to show. Used by `server.mjs --demo`.

import fs from "node:fs";
import os from "node:os";
import path from "node:path";

const CYCLE = 60; // seconds
const ITEM = "csv-export";

// start: second the employee starts; steps: when each progress box gets ticked.
const CAST = [
  { id: "T1", role: "researcher", model: "sonnet", effort: "medium", start: 0,
    steps: [["Map the order query path", 2], ["List the callers", 4], ["Check the row count limits", 6], ["Write the report", 8]],
    tools: [["Read", "src/routes/orders.js"], ["Grep", "listOrders"], ["Read", "src/db/orders.js"], ["Glob", "src/**/*.js"]] },
  { id: "T2", role: "engineer", model: "sonnet", effort: "medium", start: 12, miss: 22,
    steps: [["Open a cursor", 15], ["Write rows one by one", 18], ["Test with 200k rows", 99], ["Update the route", 99]],
    tools: [["Edit", "src/db/orders.js"], ["Bash", "node"], ["Read", "src/export/csv.js"]] },
  { id: "T3", role: "engineer", model: "sonnet", effort: "medium", start: 12, blocked: [22, 32],
    question: "The CSV header names: keep the old ones or use the API names? Proposed: keep the old ones.",
    steps: [["Read the old header order", 15], ["Write the header test", 19], ["Add the quote test", 36], ["Run the suite", 38]],
    tools: [["Read", "test/export.test.js"], ["Write", "test/export.test.js"], ["Bash", "node"], ["Edit", "test/export.test.js"]] },
  { id: "T2b", role: "engineer", model: "sonnet", effort: "high", start: 24,
    steps: [["Open a cursor", 28], ["Write rows one by one", 32], ["Test with 200k rows", 36], ["Update the route", 40]],
    tools: [["Edit", "src/db/orders.js"], ["Bash", "node"], ["Edit", "src/routes/orders.js"], ["WebFetch", "code.claude.com"]] },
  { id: "T4", role: "reviewer", model: "opus", effort: "high", start: 42,
    steps: [["Read the diff", 45], ["Run the checks", 49], ["Write the verdict", 53]],
    tools: [["Read", "src/db/orders.js"], ["Grep", "cursor"], ["Bash", "git"]] },
  { id: "T5", role: "verifier", model: "haiku", effort: "low", start: 53,
    steps: [["Run the test command", 56], ["Run the lint command", 58]],
    tools: [["Bash", "node"], ["Bash", "npm"]] },
];

const iso = (d = new Date()) => d.toISOString().replace(/\.\d+Z$/, "Z");

function stateAt(emp, t) {
  if (t < emp.start) return "todo";
  if (emp.miss !== undefined && t >= emp.miss) return "failed";
  if (emp.blocked && t >= emp.blocked[0] && t < emp.blocked[1]) return "blocked";
  if (emp.steps.every(([, at]) => at <= t)) return "done";
  return "in-progress";
}

function writeAtomic(file, content) {
  const tmp = path.join(path.dirname(file), `.${path.basename(file)}.tmp`);
  fs.writeFileSync(tmp, content);
  fs.renameSync(tmp, file);
}

export function startDemo() {
  const parent = fs.mkdtempSync(path.join(os.tmpdir(), "crew-board-demo-"));
  const root = path.join(parent, "shop-demo");
  const work = path.join(root, ".crew", "work");
  const dir = path.join(work, ITEM);
  const team = path.join(dir, "team");
  const live = path.join(dir, "live");
  fs.mkdirSync(team, { recursive: true });
  fs.mkdirSync(live, { recursive: true });
  fs.writeFileSync(path.join(live, ".gitignore"), "*\n");

  const fileName = (e) => `${e.id}-${e.role}`;

  function render(t) {
    if (t === 0) {
      for (const f of fs.readdirSync(team)) fs.rmSync(path.join(team, f), { force: true });
      for (const f of fs.readdirSync(live)) if (f.endsWith(".log")) fs.rmSync(path.join(live, f), { force: true });
    }
    const states = CAST.map((e) => stateAt(e, t));
    const now = iso();

    CAST.forEach((e, i) => {
      if (states[i] === "todo") return;
      const items = e.steps.map(([text, at]) => `- [${at <= t ? "x" : " "}] ${text}`).join("\n");
      const question = states[i] === "blocked" ? e.question : "None.";
      writeAtomic(
        path.join(team, `${fileName(e)}.md`),
        `---\ntask: ${e.id} ${e.role} work\nrole: ${e.role}\nmodel: ${e.model}\nstate: ${states[i]}   # in-progress | blocked | done | failed\nupdated: ${now}\n---\n` +
          `## Progress\n${items}\n\n## Assumptions\n\n## Questions\n${question}\n\n## Findings\n`,
      );
    });

    const rows = CAST.map((e, i) => {
      const s = states[i];
      const label =
        s === "failed" ? "missed: sent back, still failing" : s === "blocked" ? "blocked: waiting for an answer" : s;
      return `| ${e.id} | ${e.role} | ${e.model} | ${e.effort} | ${label} | ${s === "todo" ? "" : `team/${fileName(e)}.md`} |`;
    });
    const running = CAST.filter((_, i) => states[i] === "in-progress" || states[i] === "blocked").map((e) => e.id);
    const allDone = CAST.every((e, i) => states[i] === "done" || states[i] === "failed");
    const phase = t >= 42 ? "verify" : "implement";
    const next = allDone ? "none: ready to close." : running.length ? `wait for ${running.join(", ")}.` : "staff the next task.";
    writeAtomic(
      path.join(dir, "board.md"),
      `# Board: ${ITEM}\n\n**Phase:** ${phase} · **Updated:** ${now}\n\n` +
        `| Task | Role | Model | Effort | State | Status file |\n|---|---|---|---|---|---|\n${rows.join("\n")}\n\n**Next:** ${next}\n`,
    );

    const summary = running.length ? `${phase} - ${running.join(", ")} running` : `${phase} - waiting`;
    writeAtomic(
      path.join(work, "index.md"),
      `# Work items\n\n## Open\n- \`${ITEM}\` (L) - ${summary} - updated ${now.slice(0, 10)}\n\n` +
        "## Closed\n- `orders-limit` (M) - done 2026-10-12\n- `csv-headers` (S) - done 2026-10-05\n",
    );
  }

  function log(t) {
    CAST.forEach((e, i) => {
      if (stateAt(e, t) !== "in-progress" || (t + i) % 2 !== 0) return;
      const [tool, target] = e.tools[Math.floor(t / 2) % e.tools.length];
      fs.appendFileSync(path.join(live, `${fileName(e)}.log`), `${iso()}\t${tool}\t${target}\n`);
    });
  }

  let tick = 0;
  let reported = false;
  const step = () => {
    const t = tick++ % CYCLE;
    try {
      render(t);
      log(t);
    } catch (err) {
      if (!reported) process.stderr.write(`crew-board demo: ${err.message}\n`);
      reported = true;
    }
  };
  step();
  const timer = setInterval(step, 1000);

  let stopped = false;
  const stop = () => {
    if (stopped) return;
    stopped = true;
    clearInterval(timer);
    fs.rmSync(parent, { recursive: true, force: true });
  };
  process.on("exit", stop);
  return { root, stop };
}
