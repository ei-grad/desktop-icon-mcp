const assert = require("assert");
const { planLayout, mergePreferences } = require("./src/planner.js");

function icon(index, name, x, y) {
  return { index, name, x, y };
}

function assertNoCollisions(layout) {
  const cells = new Set();
  for (const item of layout.icons) {
    const key = `${item.col},${item.row}`;
    assert(!cells.has(key), `cell collision at ${key}`);
    cells.add(key);
    assert(Number.isFinite(item.x), `${item.name} has invalid x`);
    assert(Number.isFinite(item.y), `${item.name} has invalid y`);
  }
}

function boundsByCategory(layout) {
  const bounds = {};
  for (const item of layout.icons) {
    const current = bounds[item.category] || { minCol: Infinity, minRow: Infinity, maxCol: -Infinity, maxRow: -Infinity };
    current.minCol = Math.min(current.minCol, item.col);
    current.minRow = Math.min(current.minRow, item.row);
    current.maxCol = Math.max(current.maxCol, item.col);
    current.maxRow = Math.max(current.maxRow, item.row);
    bounds[item.category] = current;
  }
  return bounds;
}

function boxesSeparated(a, b) {
  return (
    a.maxCol + 1 < b.minCol ||
    b.maxCol + 1 < a.minCol ||
    a.maxRow + 1 < b.minRow ||
    b.maxRow + 1 < a.minRow
  );
}

function assertGroupGaps(layout) {
  const entries = Object.entries(boundsByCategory(layout));
  for (let i = 0; i < entries.length; i++) {
    for (let j = i + 1; j < entries.length; j++) {
      assert(boxesSeparated(entries[i][1], entries[j][1]), `groups ${entries[i][0]} and ${entries[j][0]} do not have a one-cell gap`);
    }
  }
}

function uncategorizedBlock(extra = {}) {
  return { id: "uncategorized", anchor: "top-left", direction: "right", width: 2, priority: 1, ...extra };
}

function run(name, fn) {
  try {
    fn();
    console.log(`ok ${name}`);
  } catch (error) {
    console.error(`not ok ${name}`);
    throw error;
  }
}

run("preserves duplicate names by index", () => {
  const icons = [
    icon(0, "A", 0, 0),
    icon(1, "A", 10, 0),
    icon(2, "B", 0, 10),
    icon(3, "C", 10, 10),
  ];
  const layout = planLayout(icons, { mode: "custom", blocks: [uncategorizedBlock()] });
  assert.strictEqual(layout.icons.length, 4);
  assert.deepStrictEqual(layout.icons.map((item) => `${item.name}:${item.index}`), ["A:0", "A:1", "B:2", "C:3"]);
  assertNoCollisions(layout);
});

run("uses saved MCP grid metadata for sparse layouts", () => {
  const icons = [icon(0, "A", 28, 2), icon(1, "B", 28, 224)];
  const layout = planLayout(icons, {
    mode: "custom",
    grid: { origin_x: 28, origin_y: 2, spacing_x: 152, spacing_y: 222, columns: 12, rows: 9 },
    blocks: [{ id: "uncategorized", anchor: "bottom-right", direction: "left", width: 2, priority: 1 }],
  });
  assert.strictEqual(layout.grid.columns, 12);
  assert.strictEqual(layout.grid.rows, 9);
  assert.deepStrictEqual(layout.icons.map((item) => [item.col, item.row]), [[11, 8], [10, 8]]);
});

run("explicit grid overrides take precedence over saved metadata", () => {
  const layout = planLayout([icon(0, "A", 0, 0)], {
    mode: "custom",
    grid: { origin_x: 0, origin_y: 0, spacing_x: 10, spacing_y: 10, columns: 2, rows: 2 },
    columns: 4,
    rows: 3,
    originX: 5,
    originY: 7,
    spacingX: 11,
    spacingY: 13,
    blocks: [{ id: "uncategorized", anchor: "bottom-right", direction: "left", width: 1, priority: 1 }],
  });
  assert.strictEqual(layout.grid.columns, 4);
  assert.strictEqual(layout.grid.rows, 3);
  assert.deepStrictEqual([layout.icons[0].x, layout.icons[0].y, layout.icons[0].col, layout.icons[0].row], [38, 33, 3, 2]);
});

run("top-left anchor is literal in custom preferences", () => {
  const layout = planLayout([icon(0, "A", 0, 0)], { mode: "custom", blocks: [uncategorizedBlock()] });
  assert.strictEqual(layout.icons[0].col, 0);
  assert.strictEqual(layout.icons[0].row, 0);
});

run("rejects explicit cells outside the grid", () => {
  assert.throws(
    () => planLayout([icon(0, "A", 0, 0)], { mode: "custom", blocks: [uncategorizedBlock({ cells: [[99, 0]] })] }),
    /outside the 1x1 grid/
  );
});

run("rejects grid overflow deterministically", () => {
  assert.throws(
    () => planLayout([icon(0, "A", 0, 0), icon(1, "B", 0, 0)], {
      mode: "custom",
      columns: 1,
      rows: 1,
      blocks: [uncategorizedBlock()],
    }),
    /Not enough grid cells/
  );
});

run("rejects invalid spacing and counts", () => {
  assert.throws(
    () => planLayout([icon(0, "A", 0, 0)], { mode: "custom", spacingX: 0, blocks: [uncategorizedBlock()] }),
    /axis spacing/
  );
  assert.throws(
    () => planLayout([icon(0, "A", 0, 0)], { mode: "custom", columns: 0, blocks: [uncategorizedBlock()] }),
    /axis count/
  );
});

run("mergePreferences rejects unknown modes", () => {
  assert.throws(() => mergePreferences("definitely-not-a-mode"), /Unknown layout mode/);
});

run("keeps one empty cell between icon group boxes", () => {
  const icons = [
    icon(0, "A1", 0, 0),
    icon(1, "A2", 10, 0),
    icon(2, "A3", 0, 10),
    icon(3, "B1", 10, 10),
    icon(4, "B2", 20, 0),
    icon(5, "B3", 20, 10),
  ];
  const layout = planLayout(icons, {
    mode: "custom",
    columns: 8,
    rows: 4,
    catalog: { alpha: ["A1", "A2", "A3"], beta: ["B1", "B2", "B3"] },
    blocks: [
      { id: "alpha", anchor: "top-left", direction: "right", width: 2, priority: 2 },
      { id: "beta", anchor: "top-left", direction: "right", width: 2, priority: 1 },
    ],
  });
  assertNoCollisions(layout);
  assertGroupGaps(layout);
});

run("uses a free corner when it maximizes group separation", () => {
  const layout = planLayout([icon(0, "A", 0, 0), icon(1, "B", 10, 0)], {
    mode: "custom",
    columns: 5,
    rows: 5,
    catalog: { alpha: ["A"], beta: ["B"] },
    blocks: [
      { id: "alpha", anchor: "top-left", direction: "right", width: 1, priority: 10 },
      { id: "beta", anchor: "content-top-left", direction: "right", width: 1, priority: 1 },
    ],
  });
  const byCategory = Object.fromEntries(layout.icons.map((item) => [item.category, item]));
  assert.deepStrictEqual([byCategory.alpha.col, byCategory.alpha.row], [0, 0]);
  assert.deepStrictEqual([byCategory.beta.col, byCategory.beta.row], [4, 4]);
  assertGroupGaps(layout);
});

run("rejects layouts that cannot keep group boxes separated", () => {
  assert.throws(
    () => planLayout([icon(0, "A", 0, 0), icon(1, "B", 10, 0)], {
      mode: "custom",
      columns: 2,
      rows: 1,
      catalog: { alpha: ["A"], beta: ["B"] },
      blocks: [
        { id: "alpha", anchor: "top-left", direction: "right", width: 1, priority: 1 },
        { id: "beta", anchor: "top-right", direction: "right", width: 1, priority: 1 },
      ],
    }),
    /one-cell empty frame.*Reduce the number of groups/
  );
});

run("rejects explicit group cells that violate the one-cell gap", () => {
  assert.throws(
    () => planLayout([icon(0, "A", 0, 0), icon(1, "B", 10, 0)], {
      mode: "custom",
      columns: 3,
      rows: 1,
      catalog: { alpha: ["A"], beta: ["B"] },
      blocks: [
        { id: "alpha", anchor: "top-left", cells: [[0, 0]], priority: 2 },
        { id: "beta", anchor: "top-left", cells: [[1, 0]], priority: 1 },
      ],
    }),
    /one-cell empty frame.*Reduce the number of groups/
  );
});

run("planning is deterministic", () => {
  const icons = [
    icon(0, "A", 0, 0),
    icon(1, "B", 10, 0),
    icon(2, "C", 0, 10),
    icon(3, "D", 10, 10),
  ];
  const options = { mode: "custom", blocks: [uncategorizedBlock({ anchor: "bottom-right", direction: "left", width: 3 })] };
  const first = planLayout(icons, options);
  const second = planLayout(icons, options);
  assert.deepStrictEqual(first, second);
  assertNoCollisions(first);
});

run("real desktop modes keep all fixture icons collision-free", () => {
  const icons = Array.from({ length: 24 }, (_, index) => icon(index, `Fixture ${index}`, (index % 6) * 10, Math.floor(index / 6) * 10));
  for (const mode of ["islands", "lines", "columns", "corners"]) {
    const layout = planLayout(icons, mergePreferences(mode));
    assert.strictEqual(layout.icons.length, icons.length);
    assertNoCollisions(layout);
  }
});
