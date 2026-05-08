const assert = require("assert");
const fs = require("fs");
const os = require("os");
const path = require("path");
const { createToolHandlers } = require("./src/tools.js");
const { callPowerShellHelper } = require("./src/powershell-helper.js");

const tests = [];

function run(name, fn) {
  tests.push({ name, fn });
}

function makeLayout() {
  return {
    version: 1,
    grid: { origin_x: 0, origin_y: 0, spacing_x: 10, spacing_y: 10, columns: 3, rows: 2 },
    icons: [
      { index: 0, name: "A", x: 0, y: 0 },
      { index: 1, name: "B", x: 10, y: 0 },
      { index: 2, name: "C", x: 20, y: 0 },
    ],
  };
}

run("tool schemas include JS planner alias", async () => {
  const tools = createToolHandlers({ helper: async () => ({}) });
  assert(tools.schemas.some((tool) => tool.name === "plan_and_apply_desktop_icon_layout"));
  assert(tools.schemas.some((tool) => tool.name === "plan_desktop_icon_layout"));
});

run("plan_desktop_icon_layout works from input_path without helper mutation", async () => {
  const temp = fs.mkdtempSync(path.join(os.tmpdir(), "desktop-icon-tools-"));
  const input = path.join(temp, "layout.json");
  const output = path.join(temp, "planned.json");
  fs.writeFileSync(input, JSON.stringify(makeLayout()), "utf8");

  let helperCalls = 0;
  const tools = createToolHandlers({
    cwd: temp,
    helper: async () => {
      helperCalls++;
      throw new Error("helper should not be called");
    },
  });
  const result = await tools.call("plan_desktop_icon_layout", { input_path: input, output_path: output, mode: "corners" });
  assert.strictEqual(result.ok, true);
  assert.strictEqual(result.count, 3);
  assert.strictEqual(helperCalls, 0);
  assert(fs.existsSync(output));
});

run("plan_desktop_icon_layout resolves relative preferences_path from MCP cwd", async () => {
  const temp = fs.mkdtempSync(path.join(os.tmpdir(), "desktop-icon-tools-"));
  const input = path.join(temp, "layout.json");
  const output = path.join(temp, "planned.json");
  const preferences = path.join(temp, "prefs.json");
  fs.writeFileSync(input, JSON.stringify(makeLayout()), "utf8");
  fs.writeFileSync(preferences, JSON.stringify({
    blocks: [{ id: "uncategorized", anchor: "bottom-right", direction: "left", width: 1, priority: 1 }],
  }), "utf8");

  const tools = createToolHandlers({
    cwd: temp,
    helper: async () => {
      throw new Error("helper should not be called");
    },
  });
  const result = await tools.call("plan_desktop_icon_layout", {
    input_path: "layout.json",
    output_path: "planned.json",
    preferences_path: "prefs.json",
    mode: "custom",
    margin_x: 5,
    margin_y: 7,
    spacing_x: 10,
    spacing_y: 20,
    columns: 3,
    rows: 2,
  });
  assert.strictEqual(result.ok, true);
  const planned = JSON.parse(fs.readFileSync(output, "utf8"));
  assert.deepStrictEqual(planned.icons.map((item) => [item.col, item.row]), [[2, 1], [2, 0], [1, 1]]);
  assert.deepStrictEqual(planned.icons.map((item) => [item.x, item.y]), [[25, 27], [25, 7], [15, 27]]);
});

run("plan_and_apply_desktop_icon_layout applies through helper", async () => {
  const temp = fs.mkdtempSync(path.join(os.tmpdir(), "desktop-icon-tools-"));
  const input = path.join(temp, "layout.json");
  fs.writeFileSync(input, JSON.stringify(makeLayout()), "utf8");

  const calls = [];
  const tools = createToolHandlers({
    cwd: temp,
    helper: async (command, args) => {
      calls.push({ command, args });
      if (command === "apply_layout") return { ok: true, moved: [], missing: [], duplicates: [], mismatches: [] };
      throw new Error(`unexpected helper call ${command}`);
    },
  });
  const result = await tools.call("plan_and_apply_desktop_icon_layout", { input_path: input, mode: "corners" });
  assert.strictEqual(result.ok, true);
  assert.strictEqual(calls.length, 1);
  assert.strictEqual(calls[0].command, "apply_layout");
  assert.strictEqual(calls[0].args.use_index, false);
});

run("arrange_desktop_icons_grid computes index targets from explicit grid overrides", async () => {
  const calls = [];
  const tools = createToolHandlers({
    helper: async (command, args) => {
      calls.push({ command, args });
      if (command === "get_layout_snapshot") return makeLayout();
      if (command === "apply_layout") return { ok: true, moved: [], missing: [], duplicates: [], mismatches: [] };
      throw new Error(`unexpected helper call ${command}`);
    },
  });
  const result = await tools.call("arrange_desktop_icons_grid", {
    columns: 2,
    origin_x: 100,
    origin_y: 50,
    spacing_x: 30,
    spacing_y: 40,
    settle_ms: 0,
  });
  assert.strictEqual(result.ok, true);
  const apply = calls.find((call) => call.command === "apply_layout");
  assert(apply);
  assert.strictEqual(apply.args.use_index, true);
  assert.deepStrictEqual(apply.args.icons.map((item) => [item.index, item.x, item.y]), [[0, 100, 50], [1, 130, 50], [2, 100, 90]]);
  assert.strictEqual(result.grid.origin_x, 100);
  assert.strictEqual(result.grid.spacing_y, 40);
});

run("arrange_desktop_icons_grid rejects invalid or overflowing grid overrides", async () => {
  const calls = [];
  const tools = createToolHandlers({
    helper: async (command) => {
      calls.push(command);
      if (command === "get_layout_snapshot") return makeLayout();
      throw new Error(`unexpected helper call ${command}`);
    },
  });

  await assert.rejects(
    () => tools.call("arrange_desktop_icons_grid", { columns: 2, rows: 1 }),
    /Not enough grid cells/
  );
  await assert.rejects(
    () => tools.call("arrange_desktop_icons_grid", { spacing_x: 0 }),
    /spacing_x must be positive/
  );
  assert(!calls.includes("apply_layout"));
});

run("PowerShell helper invocation handles JSON and non-ASCII script paths", async () => {
  const temp = fs.mkdtempSync(path.join(os.tmpdir(), "desktop icon \u0442\u0435\u0441\u0442 "));
  const helperPath = path.join(temp, "echo helper.ps1");
  fs.writeFileSync(helperPath, `
$raw = [Console]::In.ReadToEnd()
$request = $raw | ConvertFrom-Json
[Console]::Out.WriteLine((@{ ok = $true; result = @{ command = $request.command; name = $request.args.name } } | ConvertTo-Json -Compress -Depth 10))
`, "utf8");
  const result = await callPowerShellHelper("echo", { name: "\u041a\u043e\u0440\u0437\u0438\u043d\u0430" }, { helperPath, timeoutMs: 10000 });
  assert.deepStrictEqual(result, { command: "echo", name: "\u041a\u043e\u0440\u0437\u0438\u043d\u0430" });
});

async function main() {
  let failed = 0;
  for (const { name, fn } of tests) {
    try {
      await fn();
      console.log(`ok ${name}`);
    } catch (error) {
      failed++;
      console.error(`not ok ${name}`);
      console.error(error);
    }
  }
  if (failed > 0) process.exitCode = 1;
}

main();
