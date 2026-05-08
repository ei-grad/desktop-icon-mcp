# Desktop Icon MCP

Model Context Protocol server for reading, planning, and arranging Windows
desktop icons. The server is distributed as a Node.js package and uses a
PowerShell helper for Explorer/ListView Win32 operations.

## Requirements

- Windows desktop session with Explorer running.
- Node.js 18+ on `PATH`.
- PowerShell available as `powershell.exe`.

## MCP Tools

- `list_desktop_icons` - list icon names, indexes, and current `x`/`y` positions.
- `describe_desktop_icon_grid` - report ListView rects, display metadata, grid, occupied cells, and optional full cell map.
- `diagnose_desktop_icon_host` - inspect Progman/WorkerW host windows.
- `list_desktop_displays` - list active display monitors, active primary/virtual bounds, and raw system-metric diagnostics.
- `list_desktop_screenshot_formats` - report screenshot formats supported by the current helper runtime.
- `capture_desktop_screenshot` - capture the desktop ListView to compressed JPG by default without including foreground windows.
- `move_desktop_icon` - move one icon by `index` or exact `name`.
- `arrange_desktop_icons_grid` - arrange all icons in a grid with stabilization and verification.
- `plan_desktop_icon_layout` - run the deterministic JS optimizer, optionally applying the planned layout.
- `plan_and_apply_desktop_icon_layout` - high-level alias that plans and applies in one call.
- `set_desktop_snap_to_grid` - toggle ListView snap-to-grid.
- `save_desktop_icon_layout` - save the current layout to JSON.
- `restore_desktop_icon_layout` - restore a saved layout by icon name.

Mutating tools return placement diagnostics including `ok`, `mismatches`,
`missing`, `duplicates`, `auto_arrange_was_enabled`, and
`auto_arrange_restored`.

## Installation

Use the published npm package from your MCP client config:

```toml
[mcp_servers.desktop-icons]
command = "npx"
args = ["-y", "desktop-icon-mcp"]
```

For local development, clone the repository:

```powershell
git clone https://github.com/ei-grad/desktop-icon-mcp.git
```

Then point your MCP client at the local entrypoint:

```toml
[mcp_servers.desktop-icons]
command = "node"
args = ["C:\\path\\to\\desktop-icon-mcp\\bin\\desktop-icon-mcp.js"]
```

Publishing uses GitHub Actions trusted publishing with npm provenance. See
`docs/publishing.md`.

## Architecture

- `bin/desktop-icon-mcp.js` starts the MCP server.
- `src/server.js` handles JSON-RPC.
- `src/tools.js` owns public MCP tool schemas and handlers.
- `src/planner.js` contains the deterministic layout optimizer.
- `src/powershell-helper.js` invokes the helper with UTF-8 JSON over stdin/stdout.
- `scripts/desktop_icon_helper.ps1` performs Windows Explorer/ListView reads and writes.

The helper command contract is intentionally small:

```text
list_icons
describe_grid
diagnose_host
list_displays
list_screenshot_formats
capture_screenshot
move_icon
set_snap_to_grid
get_layout_snapshot
apply_layout
get_styles
set_auto_arrange
```

`capture_desktop_screenshot` renders the desktop icon ListView HWND with
`PrintWindow`; it is intentionally not a screen capture, so foreground windows
are not copied into the image. It writes `desktop-screenshot.jpg` by default and
accepts `path`, `format` (`jpg`, `jpeg`, `png`, or `webp`), and `quality`
arguments. Use `list_desktop_screenshot_formats` to see what the current helper
runtime can actually write. WebP requires a system `System.Drawing` encoder;
otherwise the helper returns a clear encoder error. The result includes the
written file path, capture method, desktop window handle, rect metadata, format,
quality, byte size, supported formats, and display diagnostics.

## Deterministic Optimizer

The optimizer converts abstract placement preferences into concrete grid cells.
It supports modes:

- `custom`
- `islands`
- `lines`
- `columns`
- `corners`

When two or more groups are present, each group is planned as a dense island
with a one-cell empty frame around its bounding box. The planner treats that
gap as a hard constraint and then prefers layouts that spread group islands as
far apart as the grid allows, including using free desktop corners. If no
layout can satisfy the gap, the planner fails with a clear message to reduce
the number of groups or choose a different layout mode/preferences.

From MCP, use `plan_desktop_icon_layout`:

```json
{
  "mode": "corners",
  "output_path": "desktop-icons-optimized-corners.json",
  "columns": 12,
  "rows": 9
}
```

Use `plan_and_apply_desktop_icon_layout` when the planned result should be
applied immediately. Without `input_path`, the tool captures the current
desktop first. With `input_path`, it plans from a saved layout JSON.

CLI usage:

```powershell
node optimize_desktop_islands.js --input desktop-icons-layout.json --output desktop-icons-optimized-islands.json --mode islands
node bin\desktop-icon-plan.js --input desktop-icons-layout.json --output desktop-icons-optimized-corners.json --mode corners
```

Preferences can override block anchors, directions, widths, priorities, or
explicit cells:

```json
{
  "blocks": [
    { "id": "non_games", "anchor": "left", "direction": "down", "width": 2, "priority": 10 },
    { "id": "bottom_right", "anchor": "bottom-right", "direction": "left", "width": 2, "priority": 10 }
  ]
}
```

For sparse saved layouts, pass grid bounds explicitly so corner modes use the
intended desktop extent rather than only occupied icon coordinates:

```powershell
node bin\desktop-icon-plan.js --mode corners --columns 12 --rows 9 --origin-x 28 --origin-y 2 --spacing-x 152 --spacing-y 222
```

## Display Handling

The helper sets process DPI awareness before any Win32 desktop/display calls.
Without this, Windows can virtualize a 3840x2160 desktop as 1920x1080 for a
DPI-unaware PowerShell process, while Explorer icon coordinates still use the
larger coordinate space.

Display metadata is derived from `EnumDisplayMonitors`, which reports active
visible monitors. `primary_screen` and `virtual_screen` are computed from those
active monitor rectangles, so a disconnected first display should not determine
the usable desktop size. Raw `GetSystemMetrics` values are still returned as
`system_primary_screen`, `system_virtual_screen`, and `system_monitor_count` for
diagnostics.

Grid sizing prefers the desktop ListView client rect. If that is unavailable,
fallbacks use the active primary monitor derived from `EnumDisplayMonitors`.

## Tests

```powershell
npm test
node test_optimizer.js
node test_tools.js
node smoke_test_js.js
```

Helper smoke tests that need the real Explorer desktop should be run outside the
sandbox in the active Windows user session. Non-mutating live checks:

```powershell
'{"command":"list_displays","args":{}}' | powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\desktop_icon_helper.ps1
'{"command":"diagnose_host","args":{}}' | powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\desktop_icon_helper.ps1
```

## Notes

- If Windows has "Auto arrange icons" enabled, Explorer can move icons back.
  Apply/restore tools disable it by default during exact placement and leave it
  disabled after successful exact placement unless `restore_auto_arrange` is true.
- Coordinates are ListView coordinates, not DPI-independent CSS pixels.
- Restoring a layout matches icons by exact visible name. Duplicate names should
  be moved with explicit indexes.
- Generated layout JSON files are local machine state and should stay untracked.
