# Desktop Icon MCP

Local MCP server for arranging Windows desktop icons from Codex.

It exposes tools that read the desktop `SysListView32` owned by Explorer and
send standard ListView messages to move icons. No packages are required.

## Tools

- `list_desktop_icons` - list icon names, indexes, and current `x`/`y` positions.
- `describe_desktop_icon_grid` - report the detected ListView grid, including rects, origin, spacing, rows, columns, occupied cells, and optional full cell map.
- `diagnose_desktop_icon_host` - inspect Progman/WorkerW host windows if icon discovery fails.
- `list_desktop_displays` - list active monitors, primary screen bounds, virtual screen bounds, and monitor work areas.
- `move_desktop_icon` - move one icon by `index` or exact `name`.
- `arrange_desktop_icons_grid` - arrange all icons in a grid.
- `set_desktop_snap_to_grid` - toggle ListView snap-to-grid.
- `save_desktop_icon_layout` - save the current layout to JSON.
- `restore_desktop_icon_layout` - restore a saved layout by icon name.

## Codex config

This project includes a local Codex config at `.codex/config.toml`:

```toml
[mcp_servers.desktop-icons]
command = "powershell.exe"
args = [
  "-NoProfile",
  "-ExecutionPolicy",
  "Bypass",
  "-File",
  ".\\desktop_icon_mcp.ps1"
]
```

Restart Codex after opening this project so it loads the MCP server. Then you can ask Codex things like:

```text
Покажи список иконок рабочего стола.
Расставь иконки рабочего стола сеткой с отступом 20 и сортировкой по имени.
Передвинь иконку "Корзина" в координаты x=16 y=16.
Сохрани текущую раскладку иконок в C:\Users\Андрей\Desktop\layout.json.
Восстанови раскладку из C:\Users\Андрей\Desktop\layout.json.
```

## Deterministic optimizer

`optimize_desktop_islands.js` converts abstract layout preferences into a deterministic layout JSON. It does not move icons by itself; use `restore_desktop_icon_layout` after reviewing the output.

```powershell
node optimize_desktop_islands.js --input desktop-icons-layout.json --output desktop-icons-optimized-islands.json --mode islands
node optimize_desktop_islands.js --input desktop-icons-layout.json --output desktop-icons-optimized-lines.json --mode lines
node optimize_desktop_islands.js --input desktop-icons-layout.json --output desktop-icons-optimized-columns.json --mode columns
node optimize_desktop_islands.js --input desktop-icons-layout.json --output desktop-icons-optimized-corners.json --mode corners
```

Modes:

- `islands` - compact category blocks.
- `lines` - category rows.
- `columns` - category columns.
- `corners` - important blocks anchored to screen corners.

Preferences can be overridden with a JSON file:

```powershell
node optimize_desktop_islands.js --mode islands --preferences preferences.json
```

The preference file can override block anchors, directions, widths, priorities, or explicit `cells`:

```json
{
  "blocks": [
    { "id": "non_games", "anchor": "left", "direction": "down", "width": 2, "priority": 10 },
    { "id": "bottom_right", "anchor": "bottom-right", "direction": "left", "width": 2, "priority": 10 }
  ]
}
```

## Notes

- Run Codex in the same Windows user session where Explorer owns the desktop.
- If Windows has "Auto arrange icons" enabled, Explorer can immediately move
  icons again. Disable it from the desktop context menu before using exact
  placement.
- Coordinates are ListView coordinates, not DPI-independent CSS pixels.
- `describe_desktop_icon_grid` reports both viewport rows/columns and icon extents. On multi-monitor or recently disconnected-monitor setups, Explorer can keep icon coordinates outside the current primary screen bounds, so icon extents are often more useful than `SM_CXSCREEN`/`SM_CYSCREEN` alone.
- Restoring a layout matches icons by exact visible name. If there are duplicate
  names, use `move_desktop_icon` with an index for exact one-off moves.
- MCP server changes require a commit and a Codex restart before the running session sees updated tool code or schemas.
