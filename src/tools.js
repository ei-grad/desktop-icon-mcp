const fs = require("fs");
const path = require("path");
const { planLayout, mergePreferences } = require("./planner.js");
const { callPowerShellHelper } = require("./powershell-helper.js");

function schema(properties = {}, required = []) {
  return { type: "object", properties, required, additionalProperties: false };
}

const placementOptions = {
  passes: { type: "integer", default: 3 },
  settle_ms: { type: "integer", default: 250 },
  tolerance: { type: "integer", default: 2 },
  verify: { type: "boolean", default: true },
  disable_redraw: { type: "boolean", default: true },
  disable_auto_arrange: { type: "boolean", default: true },
  restore_auto_arrange: { type: "boolean", default: false },
};

const gridOptions = {
  origin_x: { type: "integer" },
  origin_y: { type: "integer" },
  margin_x: { type: "integer" },
  margin_y: { type: "integer" },
  spacing_x: { type: "integer" },
  spacing_y: { type: "integer" },
  columns: { type: "integer" },
  rows: { type: "integer" },
};

const planOptions = {
  mode: { type: "string", enum: ["custom", "islands", "lines", "columns", "corners"], default: "islands" },
  input_path: { type: "string" },
  output_path: { type: "string" },
  preferences_path: { type: "string" },
  apply: { type: "boolean", default: false },
  use_index: { type: "boolean" },
  ...gridOptions,
  ...placementOptions,
};

const toolSchemas = [
  { name: "list_desktop_icons", description: "List Windows desktop icons with their ListView index and x/y position.", inputSchema: schema() },
  { name: "describe_desktop_icon_grid", description: "Describe the desktop ListView grid, rects, display metadata, occupied cells, and optional full cell map.", inputSchema: schema({ ...gridOptions, include_cells: { type: "boolean", default: false } }) },
  { name: "diagnose_desktop_icon_host", description: "Show Progman and WorkerW windows and child classes for desktop icon host troubleshooting.", inputSchema: schema() },
  { name: "list_desktop_displays", description: "List active Windows display monitors, primary and virtual screen bounds, and work areas.", inputSchema: schema() },
  { name: "move_desktop_icon", description: "Move one desktop icon by exact ListView index or exact icon name.", inputSchema: schema({ index: { type: "integer" }, name: { type: "string" }, x: { type: "integer" }, y: { type: "integer" } }, ["x", "y"]) },
  { name: "arrange_desktop_icons_grid", description: "Arrange desktop icons into the detected or specified ListView grid, with optional stabilization passes and verification.", inputSchema: schema({ ...gridOptions, order_by: { type: "string", enum: ["current", "name"], default: "current" }, ...placementOptions }) },
  { name: "plan_desktop_icon_layout", description: "Plan a deterministic desktop icon layout with the JavaScript optimizer, optionally applying it with stabilized placement.", inputSchema: schema(planOptions) },
  { name: "plan_and_apply_desktop_icon_layout", description: "Plan and apply a deterministic desktop icon layout in one stabilized operation.", inputSchema: schema({ ...planOptions, apply: { type: "boolean", default: true } }) },
  { name: "set_desktop_snap_to_grid", description: "Enable or disable the desktop ListView snap-to-grid style.", inputSchema: schema({ enabled: { type: "boolean", default: true } }) },
  { name: "save_desktop_icon_layout", description: "Save the current desktop icon layout to a JSON file.", inputSchema: schema({ path: { type: "string", default: "desktop-icons-layout.json" } }) },
  { name: "restore_desktop_icon_layout", description: "Restore desktop icon positions from a JSON file saved by save_desktop_icon_layout, with stabilization passes and post-restore verification.", inputSchema: schema({ path: { type: "string" }, ...placementOptions }, ["path"]) },
];

function readJson(filePath) {
  return JSON.parse(fs.readFileSync(filePath, "utf8").replace(/^\uFEFF/, ""));
}

function writeJson(filePath, value) {
  fs.writeFileSync(filePath, `${JSON.stringify(value, null, 2)}\n`, "utf8");
}

function resolvePath(filePath, cwd) {
  return path.resolve(cwd, filePath);
}

function finiteNumber(value, name) {
  const number = Number(value);
  if (!Number.isFinite(number)) throw new Error(`${name} must be a finite number`);
  return number;
}

function positiveNumber(value, name) {
  const number = finiteNumber(value, name);
  if (number <= 0) throw new Error(`${name} must be positive`);
  return number;
}

function positiveInteger(value, name) {
  const number = finiteNumber(value, name);
  if (!Number.isInteger(number) || number <= 0) throw new Error(`${name} must be a positive integer`);
  return number;
}

function plannerOptions(args, layout) {
  const prefs = mergePreferences(args.mode || "islands", args.preferences_path ? readJson(args.preferences_path) : undefined);
  return {
    ...prefs,
    mode: args.mode || "islands",
    grid: layout.grid,
    columns: args.columns,
    rows: args.rows,
    originX: args.origin_x ?? args.margin_x,
    originY: args.origin_y ?? args.margin_y,
    spacingX: args.spacing_x,
    spacingY: args.spacing_y,
  };
}

function gridFromSnapshot(snapshot, args = {}, iconCount = 0) {
  const base = snapshot.grid || {};
  const originX = args.origin_x ?? args.margin_x ?? base.origin_x ?? 0;
  const originY = args.origin_y ?? args.margin_y ?? base.origin_y ?? 0;
  const spacingX = args.spacing_x ?? base.spacing_x ?? 96;
  const spacingY = args.spacing_y ?? base.spacing_y ?? 96;
  const columns = Math.max(1, args.columns ?? base.columns ?? Math.max(1, iconCount));
  const rows = Math.max(1, args.rows ?? base.rows ?? Math.ceil(iconCount / columns));
  return {
    ...base,
    origin_x: finiteNumber(originX, "origin_x"),
    origin_y: finiteNumber(originY, "origin_y"),
    spacing_x: positiveNumber(spacingX, "spacing_x"),
    spacing_y: positiveNumber(spacingY, "spacing_y"),
    columns: positiveInteger(columns, "columns"),
    rows: positiveInteger(rows, "rows"),
  };
}

function placementArgs(args) {
  const output = {};
  for (const key of Object.keys(placementOptions)) {
    if (args[key] !== undefined) output[key] = args[key];
  }
  return output;
}

function createToolHandlers(options = {}) {
  const cwd = options.cwd || process.cwd();
  const helper = options.helper || ((command, args) => callPowerShellHelper(command, args, options.helperOptions || {}));

  async function planDesktopIconLayout(args = {}, forceApply = false) {
    const inputPath = args.input_path ? resolvePath(args.input_path, cwd) : null;
    const outputPath = resolvePath(args.output_path || `desktop-icons-optimized-${args.mode || "islands"}.json`, cwd);
    const plannerArgs = {
      ...args,
      preferences_path: args.preferences_path ? resolvePath(args.preferences_path, cwd) : undefined,
    };
    const layout = inputPath ? readJson(inputPath) : await helper("get_layout_snapshot", {});
    const plan = planLayout(layout.icons, plannerOptions(plannerArgs, layout));
    writeJson(outputPath, plan);

    const result = {
      ok: true,
      mode: plan.mode,
      input_path: inputPath,
      output_path: outputPath,
      count: plan.icons.length,
      grid: plan.grid,
      summary: plan.summary,
    };

    if (forceApply || args.apply) {
      const useIndex = args.use_index !== undefined ? args.use_index : !inputPath;
      const placement = await helper("apply_layout", { icons: plan.icons, use_index: useIndex, ...placementArgs(args) });
      result.ok = Boolean(placement.ok);
      result.placement = placement;
    }
    return result;
  }

  return {
    schemas: toolSchemas,
    async call(name, args = {}) {
      switch (name) {
        case "list_desktop_icons":
          return helper("list_icons", {});
        case "describe_desktop_icon_grid":
          return helper("describe_grid", args);
        case "diagnose_desktop_icon_host":
          return helper("diagnose_host", {});
        case "list_desktop_displays":
          return helper("list_displays", {});
        case "move_desktop_icon":
          return helper("move_icon", args);
        case "arrange_desktop_icons_grid": {
          const snapshot = await helper("get_layout_snapshot", args);
          const icons = args.order_by === "name"
            ? [...snapshot.icons].sort((a, b) => a.name.localeCompare(b.name))
            : snapshot.icons;
          const grid = gridFromSnapshot(snapshot, args, icons.length);
          const columns = grid.columns;
          if (icons.length > grid.columns * grid.rows) {
            throw new Error(`Not enough grid cells for ${icons.length} icons in ${grid.columns}x${grid.rows} grid`);
          }
          const targets = icons.map((icon, index) => ({
            index: icon.index,
            name: icon.name,
            x: grid.origin_x + (index % columns) * grid.spacing_x,
            y: grid.origin_y + Math.floor(index / columns) * grid.spacing_y,
          }));
          const placement = await helper("apply_layout", { icons: targets, use_index: true, ...placementArgs(args) });
          return { ...placement, grid, icons: targets };
        }
        case "plan_desktop_icon_layout":
          return planDesktopIconLayout(args, false);
        case "plan_and_apply_desktop_icon_layout":
          return planDesktopIconLayout(args, true);
        case "set_desktop_snap_to_grid":
          return helper("set_snap_to_grid", args);
        case "save_desktop_icon_layout": {
          const snapshot = await helper("get_layout_snapshot", {});
          const targetPath = resolvePath(args.path || "desktop-icons-layout.json", cwd);
          writeJson(targetPath, snapshot);
          return { ok: true, path: targetPath, count: snapshot.icons.length };
        }
        case "restore_desktop_icon_layout": {
          const layout = readJson(resolvePath(args.path, cwd));
          const placement = await helper("apply_layout", { icons: layout.icons, use_index: false, ...placementArgs(args) });
          return { ...placement, path: resolvePath(args.path, cwd) };
        }
        default:
          throw new Error(`Unknown tool: ${name}`);
      }
    },
  };
}

module.exports = { createToolHandlers, toolSchemas };
