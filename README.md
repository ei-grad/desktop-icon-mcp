# Desktop Icon MCP

Local MCP server for arranging Windows desktop icons from Codex.

It exposes tools that read the desktop `SysListView32` owned by Explorer and
send standard ListView messages to move icons. No packages are required.

## Tools

- `list_desktop_icons` - list icon names, indexes, and current `x`/`y` positions.
- `diagnose_desktop_icon_host` - inspect Progman/WorkerW host windows if icon discovery fails.
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

## Notes

- Run Codex in the same Windows user session where Explorer owns the desktop.
- If Windows has "Auto arrange icons" enabled, Explorer can immediately move
  icons again. Disable it from the desktop context menu before using exact
  placement.
- Coordinates are ListView coordinates, not DPI-independent CSS pixels.
- Restoring a layout matches icons by exact visible name. If there are duplicate
  names, use `move_desktop_icon` with an index for exact one-off moves.
