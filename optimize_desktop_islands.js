const fs = require("fs");

const DEFAULT_CATALOG = {
  non_games: [
    "Этот компьютер",
    "Native Access",
    "Roblox Studio",
    "Steam 360 Video Player",
    "SteamVR",
    "Inkscape",
    "GitHub Desktop",
    "Visual Studio Code",
    "Battery 4",
    "Guitar Rig 7",
    "Kontakt 8",
    "Controller Editor",
    "Maschine 3",
    "Massive",
    "Reaktor 6",
  ],
  bottom_right: ["Корзина", "WinDirStat"],
  rpg_action_rpg: [
    "The Witcher Enhanced Edition Director's Cut",
    "Diablo IV",
    "Clair Obscur Expedition 33",
    "Fallout",
    "Path of Exile 2",
    "Mass Effect™ издание Legendary",
    "STAR WARS™ Knights of the Old Republic™ II The Sith Lords™",
    "Valkyria Chronicles™",
    "Indivisible",
    "Battle Chef Brigade",
    "Hades II",
  ],
  strategy_sim: [
    "Heroes of Might and Magic 3 Complete",
    "VCMI",
    "Europa Universalis IV",
    "Sid Meier's Civilization VI",
    "Crusader Kings II",
    "Hearts of Iron IV",
    "Stellaris",
    "Total War ATTILA",
    "Total War EMPIRE - Definitive Edition",
    "StarCraft II",
    "Warhammer 40,000 Dawn of War II - Anniversary Edition",
    "Sins of a Solar Empire Trinity",
    "Factorio",
    "Cities Skylines",
    "Dungeons 3",
    "Majesty 2 Collection",
    "Tooth and Tail",
    "Halcyon 6 Starbase Commander (CLASSIC)",
    "EVE Online",
  ],
  shooters_action: [
    "DOOM (1993)",
    "Descent 3",
    "HITMAN™",
    "Grand Theft Auto V",
    "S.T.A.L.K.E.R. - Call of Prypiat - Enhanced Edition",
    "Counter-Strike",
    "Sniper Elite 3",
    "Hotline Miami",
    "Unreal Tournament",
    "Unreal Gold",
    "SUPERHOT VR",
    "The Ascent",
    "Deep Rock Galactic Survivor",
  ],
  platform_puzzle_explore: [
    "Celeste",
    "Ori and the Will of the Wisps",
    "Trine 5 A Clockwork Conspiracy",
    "Portal",
    "Portal 2",
    "Transistor",
    "Sonic Mania",
    "Crayon Physics Deluxe",
    "Q.U.B.E. 2",
    "Wuppo - Definitive Edition",
    "Valheim",
    "No Man's Sky",
  ],
  racing_fighting_party: [
    "DIRT 5",
    "Need for Speed™ Heat",
    "Need for Speed™ Payback",
    "Garfield Kart",
    "Mortal Kombat 11",
    "Brawlhalla",
    "Dota 2",
    "Among Us",
    "It Takes Two",
    "Split Fiction",
    "Unrailed!",
    "Teeworlds",
    "Ticket to Ride",
    "Carcassonne The Official Board Game",
    "Roblox Player",
    "Blizzard Arcade Collection",
    "Luanti",
  ],
};

const MODE_PRESETS = {
  custom: {
    blocks: [],
  },
  islands: {
    blocks: [
      { id: "non_games", anchor: "left", direction: "down", width: 2, priority: 10 },
      { id: "bottom_right", anchor: "bottom-right", direction: "left", width: 2, priority: 9 },
      { id: "rpg_action_rpg", anchor: "content-top-left", direction: "right", width: 3, priority: 5 },
      { id: "strategy_sim", anchor: "top-right", direction: "right", width: 5, priority: 5 },
      { id: "shooters_action", anchor: "middle-left", direction: "right", width: 5, priority: 4 },
      { id: "platform_puzzle_explore", anchor: "middle-right", direction: "right", width: 4, priority: 4 },
      { id: "racing_fighting_party", anchor: "bottom-left", direction: "right", width: 6, priority: 3 },
    ],
  },
  lines: {
    blocks: [
      { id: "non_games", anchor: "left", direction: "down", width: 2, priority: 10 },
      { id: "bottom_right", anchor: "bottom-right", direction: "left", width: 2, priority: 9 },
      { id: "rpg_action_rpg", anchor: "content-top", direction: "right", width: 8, priority: 5 },
      { id: "strategy_sim", anchor: "upper-middle", direction: "right", width: 8, priority: 5 },
      { id: "shooters_action", anchor: "middle", direction: "right", width: 8, priority: 4 },
      { id: "platform_puzzle_explore", anchor: "lower-middle", direction: "right", width: 8, priority: 4 },
      { id: "racing_fighting_party", anchor: "bottom", direction: "right", width: 8, priority: 3 },
    ],
  },
  columns: {
    blocks: [
      { id: "non_games", anchor: "left", direction: "down", width: 2, priority: 10 },
      { id: "bottom_right", anchor: "bottom-right", direction: "left", width: 2, priority: 9 },
      { id: "rpg_action_rpg", anchor: "content-top-left", direction: "down", width: 2, priority: 5 },
      { id: "strategy_sim", anchor: "top-middle", direction: "down", width: 3, priority: 5 },
      { id: "shooters_action", anchor: "top-right", direction: "down", width: 2, priority: 4 },
      { id: "platform_puzzle_explore", anchor: "middle-right", direction: "down", width: 2, priority: 4 },
      { id: "racing_fighting_party", anchor: "bottom", direction: "right", width: 8, priority: 3 },
    ],
  },
  corners: {
    blocks: [
      { id: "non_games", anchor: "top-left", direction: "down", width: 2, priority: 10 },
      { id: "bottom_right", anchor: "bottom-right", direction: "left", width: 2, priority: 10 },
      { id: "strategy_sim", anchor: "top-right", direction: "left", width: 4, priority: 7 },
      { id: "rpg_action_rpg", anchor: "top-left", direction: "right", width: 3, priority: 6 },
      { id: "shooters_action", anchor: "bottom-left", direction: "right", width: 4, priority: 5 },
      { id: "platform_puzzle_explore", anchor: "middle-right", direction: "down", width: 3, priority: 4 },
      { id: "racing_fighting_party", anchor: "bottom", direction: "right", width: 6, priority: 3 },
    ],
  },
};

function parseArgs(argv) {
  const args = { input: "desktop-icons-layout.json", output: "desktop-icons-optimized-layout.json", mode: "islands" };
  for (let i = 2; i < argv.length; i++) {
    const arg = argv[i];
    if (arg === "--input") args.input = argv[++i];
    else if (arg === "--output") args.output = argv[++i];
    else if (arg === "--mode") args.mode = argv[++i];
    else if (arg === "--preferences") args.preferences = argv[++i];
    else if (arg === "--columns") args.columns = Number(argv[++i]);
    else if (arg === "--rows") args.rows = Number(argv[++i]);
    else if (arg === "--origin-x") args.originX = Number(argv[++i]);
    else if (arg === "--origin-y") args.originY = Number(argv[++i]);
    else if (arg === "--spacing-x") args.spacingX = Number(argv[++i]);
    else if (arg === "--spacing-y") args.spacingY = Number(argv[++i]);
    else if (arg === "--help") args.help = true;
    else throw new Error(`Unknown argument: ${arg}`);
  }
  return args;
}

function readJson(path) {
  return JSON.parse(fs.readFileSync(path, "utf8").replace(/^\uFEFF/, ""));
}

function numberOrUndefined(value) {
  const number = Number(value);
  return Number.isFinite(number) ? number : undefined;
}

function assertPositiveInteger(value, name) {
  if (!Number.isInteger(value) || value <= 0) throw new Error(`${name} must be a positive integer`);
}

function assertPositiveNumber(value, name) {
  if (!Number.isFinite(value) || value <= 0) throw new Error(`${name} must be a positive number`);
}

function minPositiveDelta(values, fallback) {
  const sorted = [...new Set(values)].sort((a, b) => a - b);
  let best = Infinity;
  for (let i = 1; i < sorted.length; i++) best = Math.min(best, sorted[i] - sorted[i - 1]);
  return Number.isFinite(best) && best > 0 ? best : fallback;
}

function sequence(origin, spacing, count) {
  return Array.from({ length: count }, (_, index) => origin + index * spacing);
}

function gridFromIcons(icons, options = {}) {
  if (options.grid?.xs?.length && options.grid?.ys?.length) {
    return { xs: [...options.grid.xs], ys: [...options.grid.ys] };
  }
  const gridOriginX = numberOrUndefined(options.grid?.origin_x);
  const gridOriginY = numberOrUndefined(options.grid?.origin_y);
  const gridSpacingX = numberOrUndefined(options.grid?.spacing_x);
  const gridSpacingY = numberOrUndefined(options.grid?.spacing_y);
  const gridColumns = numberOrUndefined(options.grid?.columns);
  const gridRows = numberOrUndefined(options.grid?.rows);
  if (
    gridOriginX !== undefined &&
    gridOriginY !== undefined &&
    gridSpacingX !== undefined &&
    gridSpacingY !== undefined &&
    gridColumns !== undefined &&
    gridRows !== undefined
  ) {
    assertPositiveNumber(gridSpacingX, "grid.spacing_x");
    assertPositiveNumber(gridSpacingY, "grid.spacing_y");
    assertPositiveInteger(gridColumns, "grid.columns");
    assertPositiveInteger(gridRows, "grid.rows");
    return {
      xs: sequence(gridOriginX, gridSpacingX, gridColumns),
      ys: sequence(gridOriginY, gridSpacingY, gridRows),
    };
  }
  return {
    xs: buildAxis(icons.map((icon) => icon.x), options.originX, options.spacingX, options.columns),
    ys: buildAxis(icons.map((icon) => icon.y), options.originY, options.spacingY, options.rows),
  };
}

function buildAxis(values, requestedOrigin, requestedSpacing, requestedCount) {
  const unique = [...new Set(values)].sort((a, b) => a - b);
  if (requestedCount !== undefined) assertPositiveInteger(requestedCount, "axis count");
  if (requestedSpacing !== undefined) assertPositiveNumber(requestedSpacing, "axis spacing");
  const origin = Number.isFinite(requestedOrigin) ? requestedOrigin : (unique[0] ?? 0);
  const spacing = Number.isFinite(requestedSpacing) ? requestedSpacing : minPositiveDelta(unique, 152);
  const inferredCount = unique.length ? Math.floor((unique[unique.length - 1] - origin) / spacing) + 1 : 0;
  const count = Math.max(1, requestedCount || inferredCount || unique.length);
  return sequence(origin, spacing, count);
}

function mergePreferences(mode, preferences) {
  if (!MODE_PRESETS[mode]) throw new Error(`Unknown layout mode: ${mode}`);
  const base = JSON.parse(JSON.stringify(MODE_PRESETS[mode] || MODE_PRESETS.islands));
  if (!preferences) return base;
  const override = typeof preferences === "string" ? readJson(preferences) : preferences;
  const byId = new Map(base.blocks.map((block) => [block.id, block]));
  for (const block of override.blocks || []) byId.set(block.id, { ...(byId.get(block.id) || {}), ...block });
  return { ...base, ...override, blocks: [...byId.values()] };
}

function classifyIcons(icons, catalog) {
  const categoryByName = new Map();
  for (const [category, names] of Object.entries(catalog)) {
    for (const name of names) categoryByName.set(name, category);
  }
  const groups = {};
  for (const icon of icons) {
    const category = categoryByName.get(icon.name) || "uncategorized";
    (groups[category] ||= []).push(icon);
  }
  for (const items of Object.values(groups)) items.sort((a, b) => a.index - b.index);
  return groups;
}

function anchorCell(anchor, cols, rows) {
  const points = {
    left: [0, 0],
    "top-left": [0, 0],
    "content-top-left": [2, 0],
    top: [0, 0],
    "content-top": [2, 0],
    "top-middle": [Math.floor(cols / 2) - 1, 0],
    "top-right": [Math.max(2, cols - 5), 0],
    "upper-middle": [2, Math.max(0, Math.floor(rows * 0.2))],
    middle: [2, Math.floor(rows / 2)],
    "middle-left": [2, Math.floor(rows / 2)],
    "middle-right": [Math.max(2, cols - 4), Math.floor(rows / 2)],
    "lower-middle": [2, Math.max(0, Math.floor(rows * 0.65))],
    bottom: [1, rows - 2],
    "bottom-left": [1, rows - 3],
    "bottom-right": [cols - 1, rows - 1],
  };
  const [col, row] = points[anchor] || points.top;
  return [Math.max(0, Math.min(cols - 1, col)), Math.max(0, Math.min(rows - 1, row))];
}

function candidateCells(block, count, cols, rows) {
  if (block.cells) {
    return block.cells.map((cell, index) => {
      if (!Array.isArray(cell) || cell.length !== 2) throw new Error(`Block ${block.id} cell ${index} must be [col,row]`);
      const [col, row] = cell;
      if (!Number.isInteger(col) || !Number.isInteger(row)) throw new Error(`Block ${block.id} cell ${index} must use integer coordinates`);
      if (col < 0 || col >= cols || row < 0 || row >= rows) throw new Error(`Block ${block.id} cell ${index} is outside the ${cols}x${rows} grid`);
      return [col, row];
    });
  }
  const [startCol, startRow] = anchorCell(block.anchor, cols, rows);
  const width = Math.max(1, block.width || Math.ceil(Math.sqrt(count)));
  const cells = [];
  for (let offset = 0; cells.length < Math.max(count, cols * rows); offset++) {
    const lane = offset % width;
    const depth = Math.floor(offset / width);
    let col = startCol;
    let row = startRow;
    if (block.direction === "down") {
      col = startCol + lane;
      row = startRow + depth;
    } else if (block.direction === "left") {
      col = startCol - lane;
      row = startRow + depth;
    } else if (block.direction === "up-left") {
      col = startCol - lane;
      row = startRow - depth;
    } else {
      col = startCol + lane;
      row = startRow + depth;
    }
    if (col >= 0 && col < cols && row >= 0 && row < rows) cells.push([col, row]);
    if (offset > cols * rows * 2) break;
  }
  return cells;
}

function nearestFreeCell(preferred, used, cols, rows) {
  let best = null;
  let bestScore = Infinity;
  for (let row = 0; row < rows; row++) {
    for (let col = 0; col < cols; col++) {
      const key = `${col},${row}`;
      if (used.has(key)) continue;
      const score = Math.abs(col - preferred[0]) * 10 + Math.abs(row - preferred[1]);
      if (score < bestScore) {
        bestScore = score;
        best = [col, row];
      }
    }
  }
  if (!best) throw new Error("No free cells left");
  return best;
}

function iconKey(icon) {
  return `${icon.index}\u001f${icon.name}`;
}

function planLayout(icons, options) {
  const { xs, ys } = gridFromIcons(icons, options);
  if (icons.length > xs.length * ys.length) throw new Error(`Not enough grid cells for ${icons.length} icons in ${xs.length}x${ys.length} grid`);
  const groups = classifyIcons(icons, options.catalog || DEFAULT_CATALOG);
  const used = new Set();
  const planned = new Map();
  const blocks = [...options.blocks].sort((a, b) => (b.priority || 0) - (a.priority || 0));

  for (const block of blocks) {
    const items = groups[block.id] || [];
    const cells = candidateCells(block, items.length, xs.length, ys.length);
    for (let i = 0; i < items.length; i++) {
      const preferred = cells[i] || anchorCell(block.anchor, xs.length, ys.length);
      const [col, row] = used.has(`${preferred[0]},${preferred[1]}`)
        ? nearestFreeCell(preferred, used, xs.length, ys.length)
        : preferred;
      used.add(`${col},${row}`);
      planned.set(iconKey(items[i]), { ...items[i], x: xs[col], y: ys[row], col, row, category: block.id });
    }
  }

  const remaining = icons.filter((icon) => !planned.has(iconKey(icon))).sort((a, b) => a.index - b.index);
  for (const icon of remaining) {
    const [col, row] = nearestFreeCell(anchorCell("bottom", xs.length, ys.length), used, xs.length, ys.length);
    used.add(`${col},${row}`);
    planned.set(iconKey(icon), { ...icon, x: xs[col], y: ys[row], col, row, category: "uncategorized" });
  }

  const outputIcons = [...planned.values()].sort((a, b) => a.index - b.index);
  const summary = {};
  for (const icon of outputIcons) summary[icon.category] = (summary[icon.category] || 0) + 1;
  return { version: 1, mode: options.mode, grid: { xs, ys, columns: xs.length, rows: ys.length }, icons: outputIcons, summary };
}

function main() {
  const args = parseArgs(process.argv);
  if (args.help) {
    console.log("Usage: node optimize_desktop_islands.js --input layout.json --output planned.json --mode islands|lines|columns|corners [--preferences prefs.json] [--columns N --rows N --origin-x X --origin-y Y --spacing-x X --spacing-y Y]");
    return;
  }
  const data = readJson(args.input);
  const prefs = mergePreferences(args.mode, args.preferences);
  const planned = planLayout(data.icons, { ...prefs, mode: args.mode, grid: data.grid, columns: args.columns, rows: args.rows, originX: args.originX, originY: args.originY, spacingX: args.spacingX, spacingY: args.spacingY });
  fs.writeFileSync(args.output, JSON.stringify(planned, null, 2), "utf8");
  console.log(`wrote ${args.output}`);
  console.log(`mode: ${args.mode}`);
  console.log(`grid: ${planned.grid.columns} columns x ${planned.grid.rows} rows`);
  console.log(JSON.stringify(planned.summary, null, 2));
}

if (require.main === module) main();

module.exports = { planLayout, mergePreferences, DEFAULT_CATALOG, MODE_PRESETS };
