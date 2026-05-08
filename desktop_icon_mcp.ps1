$ErrorActionPreference = "Stop"

Add-Type -TypeDefinition @"
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Runtime.InteropServices;
using System.Text;

public static class DesktopIcons {
    const int PROCESS_VM_OPERATION = 0x0008;
    const int PROCESS_VM_READ = 0x0010;
    const int PROCESS_VM_WRITE = 0x0020;
    const int PROCESS_QUERY_INFORMATION = 0x0400;
    const int MEM_COMMIT = 0x1000;
    const int MEM_RESERVE = 0x2000;
    const int MEM_RELEASE = 0x8000;
    const int PAGE_READWRITE = 0x04;
    const int LVM_FIRST = 0x1000;
    const int LVM_GETITEMCOUNT = LVM_FIRST + 4;
    const int LVM_GETITEMTEXTW = LVM_FIRST + 115;
    const int LVM_GETITEMPOSITION = LVM_FIRST + 16;
    const int LVM_SETITEMPOSITION = LVM_FIRST + 15;
    const int LVM_GETITEMSPACING = LVM_FIRST + 51;
    const int LVM_GETEXTENDEDLISTVIEWSTYLE = LVM_FIRST + 55;
    const int LVM_SETEXTENDEDLISTVIEWSTYLE = LVM_FIRST + 54;
    const int LVS_EX_SNAPTOGRID = 0x00080000;
    const int LVIF_TEXT = 0x0001;
    const int MAX_TEXT = 512;
    const int SMTO_NORMAL = 0x0000;
    const int SM_CXSCREEN = 0;
    const int SM_CYSCREEN = 1;
    const int SM_XVIRTUALSCREEN = 76;
    const int SM_YVIRTUALSCREEN = 77;
    const int SM_CXVIRTUALSCREEN = 78;
    const int SM_CYVIRTUALSCREEN = 79;
    const int SM_CMONITORS = 80;
    const int MONITORINFOF_PRIMARY = 0x00000001;

    [StructLayout(LayoutKind.Sequential)]
    public struct POINT {
        public int X;
        public int Y;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct RECT {
        public int Left;
        public int Top;
        public int Right;
        public int Bottom;
    }

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct MONITORINFOEX {
        public int cbSize;
        public RECT rcMonitor;
        public RECT rcWork;
        public int dwFlags;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)]
        public string szDevice;
    }

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct LVITEM {
        public uint mask;
        public int iItem;
        public int iSubItem;
        public uint state;
        public uint stateMask;
        public IntPtr pszText;
        public int cchTextMax;
        public int iImage;
        public IntPtr lParam;
        public int iIndent;
        public int iGroupId;
        public uint cColumns;
        public IntPtr puColumns;
        public IntPtr piColFmt;
        public int iGroup;
    }

    public class IconInfo {
        public int index { get; set; }
        public string name { get; set; }
        public int x { get; set; }
        public int y { get; set; }
    }

    public class WindowInfo {
        public string handle { get; set; }
        public string className { get; set; }
        public List<string> childClasses { get; set; }
    }

    public class RectInfo {
        public int left { get; set; }
        public int top { get; set; }
        public int right { get; set; }
        public int bottom { get; set; }
        public int width { get; set; }
        public int height { get; set; }
    }

    public class DisplayInfo {
        public string handle { get; set; }
        public string deviceName { get; set; }
        public bool primary { get; set; }
        public RectInfo monitor_rect { get; set; }
        public RectInfo work_rect { get; set; }
    }

    public class DisplaySnapshot {
        public int monitor_count { get; set; }
        public RectInfo primary_screen { get; set; }
        public RectInfo virtual_screen { get; set; }
        public List<DisplayInfo> monitors { get; set; }
    }

    delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);
    delegate bool EnumChildProc(IntPtr hWnd, IntPtr lParam);
    delegate bool MonitorEnumProc(IntPtr hMonitor, IntPtr hdcMonitor, ref RECT lprcMonitor, IntPtr dwData);

    [DllImport("user32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    static extern IntPtr FindWindow(string lpClassName, string lpWindowName);

    [DllImport("user32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    static extern IntPtr FindWindowEx(IntPtr hwndParent, IntPtr hwndChildAfter, string lpszClass, string lpszWindow);

    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    static extern int GetClassName(IntPtr hWnd, StringBuilder lpClassName, int nMaxCount);

    [DllImport("user32.dll")]
    static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);

    [DllImport("user32.dll")]
    static extern bool EnumChildWindows(IntPtr hWndParent, EnumChildProc lpEnumFunc, IntPtr lParam);

    [DllImport("user32.dll")]
    static extern IntPtr SendMessage(IntPtr hWnd, int msg, IntPtr wParam, IntPtr lParam);

    [DllImport("user32.dll", SetLastError = true)]
    static extern IntPtr SendMessageTimeout(IntPtr hWnd, int msg, IntPtr wParam, IntPtr lParam, int flags, int timeout, out IntPtr result);

    [DllImport("user32.dll")]
    static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint processId);

    [DllImport("user32.dll")]
    static extern bool GetWindowRect(IntPtr hWnd, out RECT rect);

    [DllImport("user32.dll")]
    static extern bool GetClientRect(IntPtr hWnd, out RECT rect);

    [DllImport("user32.dll")]
    static extern int GetSystemMetrics(int nIndex);

    [DllImport("user32.dll")]
    static extern bool EnumDisplayMonitors(IntPtr hdc, IntPtr lprcClip, MonitorEnumProc lpfnEnum, IntPtr dwData);

    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    static extern bool GetMonitorInfo(IntPtr hMonitor, ref MONITORINFOEX lpmi);

    [DllImport("kernel32.dll", SetLastError = true)]
    static extern IntPtr OpenProcess(int dwDesiredAccess, bool bInheritHandle, uint dwProcessId);

    [DllImport("kernel32.dll", SetLastError = true)]
    static extern bool CloseHandle(IntPtr hObject);

    [DllImport("kernel32.dll", SetLastError = true)]
    static extern IntPtr VirtualAllocEx(IntPtr hProcess, IntPtr lpAddress, UIntPtr dwSize, int flAllocationType, int flProtect);

    [DllImport("kernel32.dll", SetLastError = true)]
    static extern bool VirtualFreeEx(IntPtr hProcess, IntPtr lpAddress, UIntPtr dwSize, int dwFreeType);

    [DllImport("kernel32.dll", SetLastError = true)]
    static extern bool WriteProcessMemory(IntPtr hProcess, IntPtr lpBaseAddress, IntPtr lpBuffer, int nSize, out UIntPtr lpNumberOfBytesWritten);

    [DllImport("kernel32.dll", SetLastError = true)]
    static extern bool ReadProcessMemory(IntPtr hProcess, IntPtr lpBaseAddress, IntPtr lpBuffer, int nSize, out UIntPtr lpNumberOfBytesRead);

    static Exception Win32(string name) {
        return new Win32Exception(Marshal.GetLastWin32Error(), name + " failed");
    }

    static RectInfo ToRectInfo(RECT rect) {
        return new RectInfo {
            left = rect.Left,
            top = rect.Top,
            right = rect.Right,
            bottom = rect.Bottom,
            width = rect.Right - rect.Left,
            height = rect.Bottom - rect.Top
        };
    }

    static RectInfo RectFromMetrics(int left, int top, int width, int height) {
        return new RectInfo {
            left = left,
            top = top,
            right = left + width,
            bottom = top + height,
            width = width,
            height = height
        };
    }

    static string ClassName(IntPtr hwnd) {
        var sb = new StringBuilder(256);
        GetClassName(hwnd, sb, sb.Capacity);
        return sb.ToString();
    }

    static IntPtr Child(IntPtr parent, string cls) {
        return FindWindowEx(parent, IntPtr.Zero, cls, null);
    }

    public static IntPtr FindDesktopListView() {
        IntPtr progman = FindWindow("Progman", null);
        if (progman != IntPtr.Zero) {
            IntPtr timeoutResult;
            SendMessageTimeout(progman, 0x052C, IntPtr.Zero, IntPtr.Zero, SMTO_NORMAL, 1000, out timeoutResult);

            IntPtr defView = Child(progman, "SHELLDLL_DefView");
            if (defView != IntPtr.Zero) {
                IntPtr listView = Child(defView, "SysListView32");
                if (listView != IntPtr.Zero) return listView;
            }
        }

        IntPtr found = IntPtr.Zero;
        EnumWindows((hwnd, param) => {
            if (ClassName(hwnd) == "WorkerW") {
                IntPtr defView = Child(hwnd, "SHELLDLL_DefView");
                if (defView != IntPtr.Zero) {
                    IntPtr listView = Child(defView, "SysListView32");
                    if (listView != IntPtr.Zero) {
                        found = listView;
                        return false;
                    }
                }
            }
            return true;
        }, IntPtr.Zero);

        if (found == IntPtr.Zero) throw new Exception("Cannot find the Windows desktop icon ListView.");
        return found;
    }

    public static List<WindowInfo> DiagnoseDesktopHosts() {
        var windows = new List<WindowInfo>();
        EnumWindows((hwnd, param) => {
            string cls = ClassName(hwnd);
            if (cls == "Progman" || cls == "WorkerW") {
                var info = new WindowInfo {
                    handle = "0x" + hwnd.ToInt64().ToString("X"),
                    className = cls,
                    childClasses = new List<string>()
                };
                EnumChildWindows(hwnd, (child, childParam) => {
                    info.childClasses.Add(ClassName(child));
                    return true;
                }, IntPtr.Zero);
                windows.Add(info);
            }
            return true;
        }, IntPtr.Zero);
        return windows;
    }

    public static DisplaySnapshot Displays() {
        var monitors = new List<DisplayInfo>();
        EnumDisplayMonitors(IntPtr.Zero, IntPtr.Zero, (IntPtr monitor, IntPtr hdc, ref RECT rect, IntPtr data) => {
            var info = new MONITORINFOEX();
            info.cbSize = Marshal.SizeOf(typeof(MONITORINFOEX));
            info.szDevice = new string('\0', 32);
            if (GetMonitorInfo(monitor, ref info)) {
                monitors.Add(new DisplayInfo {
                    handle = "0x" + monitor.ToInt64().ToString("X"),
                    deviceName = (info.szDevice ?? "").TrimEnd('\0'),
                    primary = (info.dwFlags & MONITORINFOF_PRIMARY) != 0,
                    monitor_rect = ToRectInfo(info.rcMonitor),
                    work_rect = ToRectInfo(info.rcWork)
                });
            }
            return true;
        }, IntPtr.Zero);

        int primaryWidth = GetSystemMetrics(SM_CXSCREEN);
        int primaryHeight = GetSystemMetrics(SM_CYSCREEN);
        int virtualX = GetSystemMetrics(SM_XVIRTUALSCREEN);
        int virtualY = GetSystemMetrics(SM_YVIRTUALSCREEN);
        int virtualWidth = GetSystemMetrics(SM_CXVIRTUALSCREEN);
        int virtualHeight = GetSystemMetrics(SM_CYVIRTUALSCREEN);
        return new DisplaySnapshot {
            monitor_count = GetSystemMetrics(SM_CMONITORS),
            primary_screen = RectFromMetrics(0, 0, primaryWidth, primaryHeight),
            virtual_screen = RectFromMetrics(virtualX, virtualY, virtualWidth, virtualHeight),
            monitors = monitors
        };
    }

    static IntPtr OpenExplorerProcess(IntPtr hwnd) {
        uint pid;
        GetWindowThreadProcessId(hwnd, out pid);
        if (pid == 0) throw new Exception("Cannot discover Explorer process for desktop ListView.");
        IntPtr process = OpenProcess(PROCESS_VM_OPERATION | PROCESS_VM_READ | PROCESS_VM_WRITE | PROCESS_QUERY_INFORMATION, false, pid);
        if (process == IntPtr.Zero) throw Win32("OpenProcess");
        return process;
    }

    public static int Count(IntPtr hwnd) {
        return SendMessage(hwnd, LVM_GETITEMCOUNT, IntPtr.Zero, IntPtr.Zero).ToInt32();
    }

    public static string GetText(IntPtr hwnd, int index) {
        IntPtr process = OpenExplorerProcess(hwnd);
        IntPtr remote = IntPtr.Zero;
        IntPtr localItem = IntPtr.Zero;
        try {
            int itemSize = Marshal.SizeOf(typeof(LVITEM));
            int textBytes = MAX_TEXT * 2;
            remote = VirtualAllocEx(process, IntPtr.Zero, (UIntPtr)(itemSize + textBytes), MEM_COMMIT | MEM_RESERVE, PAGE_READWRITE);
            if (remote == IntPtr.Zero) throw Win32("VirtualAllocEx");

            var item = new LVITEM();
            item.mask = LVIF_TEXT;
            item.iItem = index;
            item.iSubItem = 0;
            item.pszText = IntPtr.Add(remote, itemSize);
            item.cchTextMax = MAX_TEXT;

            localItem = Marshal.AllocHGlobal(itemSize);
            Marshal.StructureToPtr(item, localItem, false);
            UIntPtr written;
            if (!WriteProcessMemory(process, remote, localItem, itemSize, out written)) throw Win32("WriteProcessMemory");

            SendMessage(hwnd, LVM_GETITEMTEXTW, (IntPtr)index, remote);

            IntPtr textBuffer = Marshal.AllocHGlobal(textBytes);
            try {
                UIntPtr read;
                if (!ReadProcessMemory(process, IntPtr.Add(remote, itemSize), textBuffer, textBytes, out read)) throw Win32("ReadProcessMemory");
                return Marshal.PtrToStringUni(textBuffer) ?? "";
            } finally {
                Marshal.FreeHGlobal(textBuffer);
            }
        } finally {
            if (localItem != IntPtr.Zero) Marshal.FreeHGlobal(localItem);
            if (remote != IntPtr.Zero) VirtualFreeEx(process, remote, UIntPtr.Zero, MEM_RELEASE);
            CloseHandle(process);
        }
    }

    public static POINT GetPosition(IntPtr hwnd, int index) {
        IntPtr process = OpenExplorerProcess(hwnd);
        IntPtr remote = IntPtr.Zero;
        try {
            int pointSize = Marshal.SizeOf(typeof(POINT));
            remote = VirtualAllocEx(process, IntPtr.Zero, (UIntPtr)pointSize, MEM_COMMIT | MEM_RESERVE, PAGE_READWRITE);
            if (remote == IntPtr.Zero) throw Win32("VirtualAllocEx");
            SendMessage(hwnd, LVM_GETITEMPOSITION, (IntPtr)index, remote);

            IntPtr localPoint = Marshal.AllocHGlobal(pointSize);
            try {
                UIntPtr read;
                if (!ReadProcessMemory(process, remote, localPoint, pointSize, out read)) throw Win32("ReadProcessMemory");
                return (POINT)Marshal.PtrToStructure(localPoint, typeof(POINT));
            } finally {
                Marshal.FreeHGlobal(localPoint);
            }
        } finally {
            if (remote != IntPtr.Zero) VirtualFreeEx(process, remote, UIntPtr.Zero, MEM_RELEASE);
            CloseHandle(process);
        }
    }

    public static List<IconInfo> List() {
        IntPtr hwnd = FindDesktopListView();
        int count = Count(hwnd);
        var icons = new List<IconInfo>();
        for (int i = 0; i < count; i++) {
            POINT point = GetPosition(hwnd, i);
            icons.Add(new IconInfo { index = i, name = GetText(hwnd, i), x = point.X, y = point.Y });
        }
        return icons;
    }

    public static void Move(IntPtr hwnd, int index, int x, int y) {
        int packed = (x & 0xFFFF) | ((y & 0xFFFF) << 16);
        SendMessage(hwnd, LVM_SETITEMPOSITION, (IntPtr)index, (IntPtr)packed);
    }

    public static int ResolveIndex(IntPtr hwnd, int index, string name) {
        int count = Count(hwnd);
        if (index >= 0) {
            if (index >= count) throw new Exception("Icon index " + index + " is out of range.");
            return index;
        }
        if (String.IsNullOrWhiteSpace(name)) throw new Exception("Pass either index or name.");
        int found = -1;
        for (int i = 0; i < count; i++) {
            if (String.Equals(GetText(hwnd, i), name, StringComparison.CurrentCultureIgnoreCase)) {
                if (found >= 0) throw new Exception("Multiple desktop icons are named '" + name + "'; use index instead.");
                found = i;
            }
        }
        if (found < 0) throw new Exception("Cannot find desktop icon named '" + name + "'.");
        return found;
    }

    public static int[] Spacing(IntPtr hwnd) {
        int packed = SendMessage(hwnd, LVM_GETITEMSPACING, IntPtr.Zero, IntPtr.Zero).ToInt32();
        int x = packed & 0xFFFF;
        int y = (packed >> 16) & 0xFFFF;
        if (x <= 0 || y <= 0) return new int[] { 96, 96 };
        return new int[] { x, y };
    }

    public static RectInfo WindowRect(IntPtr hwnd) {
        RECT rect;
        if (GetWindowRect(hwnd, out rect)) return ToRectInfo(rect);
        int width = GetSystemMetrics(SM_CXSCREEN);
        int height = GetSystemMetrics(SM_CYSCREEN);
        return new RectInfo { left = 0, top = 0, right = width, bottom = height, width = width, height = height };
    }

    public static RectInfo ClientRect(IntPtr hwnd) {
        RECT rect;
        if (GetClientRect(hwnd, out rect)) return ToRectInfo(rect);
        int width = GetSystemMetrics(SM_CXSCREEN);
        int height = GetSystemMetrics(SM_CYSCREEN);
        return new RectInfo { left = 0, top = 0, right = width, bottom = height, width = width, height = height };
    }

    public static int DesktopWidth(IntPtr hwnd) {
        RectInfo rect = ClientRect(hwnd);
        if (rect.width > 0) return rect.width;
        return GetSystemMetrics(SM_CXSCREEN);
    }

    public static int DesktopHeight(IntPtr hwnd) {
        RectInfo rect = ClientRect(hwnd);
        if (rect.height > 0) return rect.height;
        return GetSystemMetrics(SM_CYSCREEN);
    }

    public static void SetSnapToGrid(IntPtr hwnd, bool enabled) {
        int style = SendMessage(hwnd, LVM_GETEXTENDEDLISTVIEWSTYLE, IntPtr.Zero, IntPtr.Zero).ToInt32();
        int newStyle = enabled ? (style | LVS_EX_SNAPTOGRID) : (style & ~LVS_EX_SNAPTOGRID);
        SendMessage(hwnd, LVM_SETEXTENDEDLISTVIEWSTYLE, (IntPtr)LVS_EX_SNAPTOGRID, (IntPtr)newStyle);
    }
}
"@

function New-RpcResult($Id, $Result) {
    [ordered]@{ jsonrpc = "2.0"; id = $Id; result = $Result }
}

function New-RpcError($Id, [int]$Code, [string]$Message) {
    [ordered]@{ jsonrpc = "2.0"; id = $Id; error = [ordered]@{ code = $Code; message = $Message } }
}

function New-ToolContent($Data) {
    [ordered]@{
        content = @(
            [ordered]@{
                type = "text"
                text = ($Data | ConvertTo-Json -Depth 20 -Compress:$false)
            }
        )
    }
}

function Get-ArgValue($Arguments, [string]$Name, $Default = $null) {
    if ($null -ne $Arguments -and $Arguments.PSObject.Properties.Name -contains $Name) {
        return $Arguments.$Name
    }
    return $Default
}

function New-DesktopIconGrid($hwnd, $Arguments, $Icons = $null) {
    if ($null -eq $Icons) {
        $Icons = @([DesktopIcons]::List())
    } else {
        $Icons = @($Icons)
    }

    $spacing = [DesktopIcons]::Spacing($hwnd)
    $clientRect = [DesktopIcons]::ClientRect($hwnd)
    $windowRect = [DesktopIcons]::WindowRect($hwnd)

    $minX = $null
    $minY = $null
    foreach ($icon in $Icons) {
        if ($null -eq $minX -or [int]$icon.x -lt $minX) { $minX = [int]$icon.x }
        if ($null -eq $minY -or [int]$icon.y -lt $minY) { $minY = [int]$icon.y }
    }
    if ($null -eq $minX) { $minX = 0 }
    if ($null -eq $minY) { $minY = 0 }

    $originXArg = Get-ArgValue $Arguments "origin_x" $null
    if ($null -eq $originXArg) { $originXArg = Get-ArgValue $Arguments "margin_x" $null }
    $originYArg = Get-ArgValue $Arguments "origin_y" $null
    if ($null -eq $originYArg) { $originYArg = Get-ArgValue $Arguments "margin_y" $null }

    $originX = if ($null -eq $originXArg) { [int]$minX } else { [int]$originXArg }
    $originY = if ($null -eq $originYArg) { [int]$minY } else { [int]$originYArg }
    $stepX = [int](Get-ArgValue $Arguments "spacing_x" $spacing[0])
    $stepY = [int](Get-ArgValue $Arguments "spacing_y" $spacing[1])
    if ($stepX -le 0) { $stepX = 1 }
    if ($stepY -le 0) { $stepY = 1 }

    $maxIconCol = 0
    $maxIconRow = 0
    foreach ($icon in $Icons) {
        $col = [int][Math]::Round(([double]([int]$icon.x - $originX)) / $stepX)
        $row = [int][Math]::Round(([double]([int]$icon.y - $originY)) / $stepY)
        if ($col -gt $maxIconCol) { $maxIconCol = $col }
        if ($row -gt $maxIconRow) { $maxIconRow = $row }
    }

    $columnsArg = Get-ArgValue $Arguments "columns" $null
    if ($null -eq $columnsArg) {
        $viewportColumns = [Math]::Max(1, [int][Math]::Floor(([double]([DesktopIcons]::DesktopWidth($hwnd) - $originX)) / $stepX))
        $columns = [Math]::Max($viewportColumns, $maxIconCol + 1)
    } else {
        $columns = [Math]::Max(1, [int]$columnsArg)
    }

    $rowsArg = Get-ArgValue $Arguments "rows" $null
    if ($null -eq $rowsArg) {
        $viewportRows = [Math]::Max(1, [int][Math]::Floor(([double]([DesktopIcons]::DesktopHeight($hwnd) - $originY)) / $stepY))
        $rows = [Math]::Max($viewportRows, $maxIconRow + 1)
    } else {
        $rows = [Math]::Max(1, [int]$rowsArg)
    }

    $occupied = New-Object System.Collections.Generic.List[object]
    $outside = New-Object System.Collections.Generic.List[object]
    $occupiedKeys = @{}
    foreach ($icon in $Icons) {
        $col = [int][Math]::Round(([double]([int]$icon.x - $originX)) / $stepX)
        $row = [int][Math]::Round(([double]([int]$icon.y - $originY)) / $stepY)
        $expectedX = $originX + ($col * $stepX)
        $expectedY = $originY + ($row * $stepY)
        $snapped = ([Math]::Abs([int]$icon.x - $expectedX) -le 2) -and ([Math]::Abs([int]$icon.y - $expectedY) -le 2)
        $inside = $snapped -and $col -ge 0 -and $row -ge 0 -and $col -lt $columns -and $row -lt $rows
        $cell = [ordered]@{
            index = [int]$icon.index
            name = [string]$icon.name
            x = [int]$icon.x
            y = [int]$icon.y
            col = [int]$col
            row = [int]$row
            expected_x = [int]$expectedX
            expected_y = [int]$expectedY
            snapped = [bool]$snapped
            inside = [bool]$inside
        }
        if ($inside) {
            $occupied.Add($cell)
            $occupiedKeys["$col,$row"] = $true
        } else {
            $outside.Add($cell)
        }
    }

    $grid = [ordered]@{
        origin_x = [int]$originX
        origin_y = [int]$originY
        spacing_x = [int]$stepX
        spacing_y = [int]$stepY
        columns = [int]$columns
        rows = [int]$rows
        viewport_columns = [int]([Math]::Max(1, [int][Math]::Floor(([double]([DesktopIcons]::DesktopWidth($hwnd) - $originX)) / $stepX)))
        viewport_rows = [int]([Math]::Max(1, [int][Math]::Floor(([double]([DesktopIcons]::DesktopHeight($hwnd) - $originY)) / $stepY)))
        icon_extent_columns = [int]($maxIconCol + 1)
        icon_extent_rows = [int]($maxIconRow + 1)
        total_slots = [int]($columns * $rows)
        last_x = [int]($originX + (($columns - 1) * $stepX))
        last_y = [int]($originY + (($rows - 1) * $stepY))
        icon_count = [int]$Icons.Count
        occupied_slots = [int]$occupiedKeys.Count
        free_slots = [int](($columns * $rows) - $occupiedKeys.Count)
    }

    $result = [ordered]@{
        desktop = [ordered]@{
            client_rect = $clientRect
            window_rect = $windowRect
            displays = [DesktopIcons]::Displays()
        }
        grid = $grid
        occupied_cells = $occupied
        outside_icons = $outside
    }

    if ([bool](Get-ArgValue $Arguments "include_cells" $false)) {
        $cells = New-Object System.Collections.Generic.List[object]
        for ($row = 0; $row -lt $rows; $row++) {
            for ($col = 0; $col -lt $columns; $col++) {
                $key = "$col,$row"
                $names = @()
                foreach ($icon in $occupied) {
                    if ([int]$icon.col -eq $col -and [int]$icon.row -eq $row) {
                        $names += [string]$icon.name
                    }
                }
                $cells.Add([ordered]@{
                    col = [int]$col
                    row = [int]$row
                    x = [int]($originX + ($col * $stepX))
                    y = [int]($originY + ($row * $stepY))
                    occupied = [bool]$occupiedKeys.ContainsKey($key)
                    icons = $names
                })
            }
        }
        $result.cells = $cells
    }

    return $result
}

function Invoke-Tool([string]$Name, $Arguments) {
    switch ($Name) {
        "list_desktop_icons" {
            return @{ icons = [DesktopIcons]::List() }
        }
        "describe_desktop_icon_grid" {
            $hwnd = [DesktopIcons]::FindDesktopListView()
            return (New-DesktopIconGrid $hwnd $Arguments)
        }
        "diagnose_desktop_icon_host" {
            return @{ windows = [DesktopIcons]::DiagnoseDesktopHosts() }
        }
        "list_desktop_displays" {
            return @{ displays = [DesktopIcons]::Displays() }
        }
        "move_desktop_icon" {
            $hwnd = [DesktopIcons]::FindDesktopListView()
            $indexArg = Get-ArgValue $Arguments "index" -1
            $nameArg = Get-ArgValue $Arguments "name" $null
            $index = [DesktopIcons]::ResolveIndex($hwnd, [int]$indexArg, [string]$nameArg)
            $x = [int](Get-ArgValue $Arguments "x")
            $y = [int](Get-ArgValue $Arguments "y")
            [DesktopIcons]::Move($hwnd, $index, $x, $y)
            return @{ ok = $true; icon = @{ index = $index; name = [DesktopIcons]::GetText($hwnd, $index); x = $x; y = $y } }
        }
        "arrange_desktop_icons_grid" {
            $hwnd = [DesktopIcons]::FindDesktopListView()
            $icons = @([DesktopIcons]::List())
            $orderBy = [string](Get-ArgValue $Arguments "order_by" "current")
            if ($orderBy -eq "name") {
                $icons = @($icons | Sort-Object -Property name)
            }

            $gridInfo = New-DesktopIconGrid $hwnd $Arguments $icons
            $grid = $gridInfo.grid
            $originX = [int]$grid.origin_x
            $originY = [int]$grid.origin_y
            $stepX = [int]$grid.spacing_x
            $stepY = [int]$grid.spacing_y
            $columns = [int]$grid.columns

            $moved = New-Object System.Collections.Generic.List[object]
            for ($i = 0; $i -lt $icons.Count; $i++) {
                $x = $originX + (($i % $columns) * $stepX)
                $y = $originY + ([Math]::Floor($i / $columns) * $stepY)
                [DesktopIcons]::Move($hwnd, [int]$icons[$i].index, [int]$x, [int]$y)
                $moved.Add([ordered]@{ index = $icons[$i].index; name = $icons[$i].name; x = [int]$x; y = [int]$y })
            }
            return @{ ok = $true; count = $moved.Count; grid = $grid; icons = $moved }
        }
        "set_desktop_snap_to_grid" {
            $hwnd = [DesktopIcons]::FindDesktopListView()
            $enabled = [bool](Get-ArgValue $Arguments "enabled" $true)
            [DesktopIcons]::SetSnapToGrid($hwnd, $enabled)
            return @{ ok = $true; enabled = $enabled }
        }
        "save_desktop_icon_layout" {
            $path = [string](Get-ArgValue $Arguments "path" "desktop-icons-layout.json")
            $resolved = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($path)
            $payload = [ordered]@{ version = 1; icons = [DesktopIcons]::List() }
            $payload | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $resolved -Encoding UTF8
            return @{ ok = $true; path = $resolved; count = $payload.icons.Count }
        }
        "restore_desktop_icon_layout" {
            $path = [string](Get-ArgValue $Arguments "path")
            $resolved = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($path)
            $payload = Get-Content -LiteralPath $resolved -Raw -Encoding UTF8 | ConvertFrom-Json
            $hwnd = [DesktopIcons]::FindDesktopListView()
            $current = @{}
            foreach ($icon in [DesktopIcons]::List()) {
                $current[$icon.name.ToLowerInvariant()] = $icon
            }
            $moved = New-Object System.Collections.Generic.List[object]
            $missing = New-Object System.Collections.Generic.List[string]
            foreach ($icon in $payload.icons) {
                $key = ([string]$icon.name).ToLowerInvariant()
                if (-not $current.ContainsKey($key)) {
                    $missing.Add([string]$icon.name)
                    continue
                }
                $target = $current[$key]
                [DesktopIcons]::Move($hwnd, [int]$target.index, [int]$icon.x, [int]$icon.y)
                $moved.Add([ordered]@{ name = $icon.name; x = [int]$icon.x; y = [int]$icon.y })
            }
            return @{ ok = $true; moved = $moved; missing = $missing }
        }
        default {
            throw "Unknown tool: $Name"
        }
    }
}

$toolSchemas = @(
    [ordered]@{ name = "list_desktop_icons"; description = "List Windows desktop icons with their ListView index and x/y position."; inputSchema = @{ type = "object"; properties = @{}; additionalProperties = $false } },
    [ordered]@{ name = "describe_desktop_icon_grid"; description = "Describe the desktop ListView grid: rects, origin, spacing, rows, columns, occupied cells, and optional full cell map."; inputSchema = @{ type = "object"; properties = @{ origin_x = @{ type = "integer" }; origin_y = @{ type = "integer" }; margin_x = @{ type = "integer" }; margin_y = @{ type = "integer" }; spacing_x = @{ type = "integer" }; spacing_y = @{ type = "integer" }; columns = @{ type = "integer" }; rows = @{ type = "integer" }; include_cells = @{ type = "boolean"; default = $false } }; additionalProperties = $false } },
    [ordered]@{ name = "diagnose_desktop_icon_host"; description = "Show Progman and WorkerW windows and child classes for desktop icon host troubleshooting."; inputSchema = @{ type = "object"; properties = @{}; additionalProperties = $false } },
    [ordered]@{ name = "list_desktop_displays"; description = "List active Windows display monitors, primary and virtual screen bounds, and work areas."; inputSchema = @{ type = "object"; properties = @{}; additionalProperties = $false } },
    [ordered]@{ name = "move_desktop_icon"; description = "Move one desktop icon by exact ListView index or exact icon name."; inputSchema = @{ type = "object"; properties = @{ index = @{ type = "integer" }; name = @{ type = "string" }; x = @{ type = "integer" }; y = @{ type = "integer" } }; required = @("x", "y"); additionalProperties = $false } },
    [ordered]@{ name = "arrange_desktop_icons_grid"; description = "Arrange desktop icons into the detected or specified ListView grid."; inputSchema = @{ type = "object"; properties = @{ origin_x = @{ type = "integer" }; origin_y = @{ type = "integer" }; margin_x = @{ type = "integer" }; margin_y = @{ type = "integer" }; spacing_x = @{ type = "integer" }; spacing_y = @{ type = "integer" }; columns = @{ type = "integer" }; rows = @{ type = "integer" }; order_by = @{ type = "string"; enum = @("current", "name"); default = "current" } }; additionalProperties = $false } },
    [ordered]@{ name = "set_desktop_snap_to_grid"; description = "Enable or disable the desktop ListView snap-to-grid style."; inputSchema = @{ type = "object"; properties = @{ enabled = @{ type = "boolean"; default = $true } }; additionalProperties = $false } },
    [ordered]@{ name = "save_desktop_icon_layout"; description = "Save the current desktop icon layout to a JSON file."; inputSchema = @{ type = "object"; properties = @{ path = @{ type = "string"; default = "desktop-icons-layout.json" } }; additionalProperties = $false } },
    [ordered]@{ name = "restore_desktop_icon_layout"; description = "Restore desktop icon positions from a JSON file saved by save_desktop_icon_layout."; inputSchema = @{ type = "object"; properties = @{ path = @{ type = "string" } }; required = @("path"); additionalProperties = $false } }
)

while ($null -ne ($line = [Console]::In.ReadLine())) {
    if ([string]::IsNullOrWhiteSpace($line)) { continue }
    $id = $null
    try {
        $request = $line | ConvertFrom-Json
        $id = $request.id
        switch ([string]$request.method) {
            "initialize" {
                $protocol = "2024-11-05"
                if ($null -ne $request.params.protocolVersion) { $protocol = [string]$request.params.protocolVersion }
                $response = New-RpcResult $id ([ordered]@{
                    protocolVersion = $protocol
                    capabilities = @{ tools = @{} }
                    serverInfo = @{ name = "desktop-icon-mcp"; version = "0.1.0" }
                })
            }
            "notifications/initialized" {
                $response = $null
            }
            "tools/list" {
                $response = New-RpcResult $id @{ tools = $toolSchemas }
            }
            "tools/call" {
                $result = Invoke-Tool ([string]$request.params.name) $request.params.arguments
                $response = New-RpcResult $id (New-ToolContent $result)
            }
            default {
                $response = New-RpcError $id -32601 "Unknown method: $($request.method)"
            }
        }
    } catch {
        $response = New-RpcError $id -32603 $_.Exception.Message
    }

    if ($null -ne $response) {
        [Console]::Out.WriteLine(($response | ConvertTo-Json -Depth 30 -Compress))
        [Console]::Out.Flush()
    }
}
