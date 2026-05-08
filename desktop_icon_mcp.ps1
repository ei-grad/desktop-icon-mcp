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
    const int GWL_STYLE = -16;
    const int LVS_AUTOARRANGE = 0x0100;
    const int LVS_EX_SNAPTOGRID = 0x00080000;
    const int LVIF_TEXT = 0x0001;
    const int WM_SETREDRAW = 0x000B;
    const int RDW_INVALIDATE = 0x0001;
    const int RDW_ALLCHILDREN = 0x0080;
    const int RDW_UPDATENOW = 0x0100;
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
    const uint PW_RENDERFULLCONTENT = 0x00000002;
    static bool dpiAwarenessAttempted = false;

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
        public bool active { get; set; }
        public bool primary { get; set; }
        public RectInfo monitor_rect { get; set; }
        public RectInfo work_rect { get; set; }
    }

    public class DisplaySnapshot {
        public int monitor_count { get; set; }
        public int active_monitor_count { get; set; }
        public int system_monitor_count { get; set; }
        public RectInfo primary_screen { get; set; }
        public RectInfo virtual_screen { get; set; }
        public RectInfo system_primary_screen { get; set; }
        public RectInfo system_virtual_screen { get; set; }
        public List<DisplayInfo> monitors { get; set; }
    }

    delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);
    delegate bool EnumChildProc(IntPtr hWnd, IntPtr lParam);
    delegate bool MonitorEnumProc(IntPtr hMonitor, IntPtr hdcMonitor, ref RECT lprcMonitor, IntPtr dwData);

    [DllImport("user32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    static extern IntPtr FindWindow(string lpClassName, string lpWindowName);

    [DllImport("user32.dll", SetLastError = true)]
    static extern bool SetProcessDPIAware();

    [DllImport("user32.dll", SetLastError = true)]
    static extern bool SetProcessDpiAwarenessContext(IntPtr dpiContext);

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
    static extern int GetWindowLong(IntPtr hWnd, int nIndex);

    [DllImport("user32.dll", SetLastError = true)]
    static extern int SetWindowLong(IntPtr hWnd, int nIndex, int dwNewLong);

    [DllImport("user32.dll")]
    static extern bool RedrawWindow(IntPtr hWnd, IntPtr lprcUpdate, IntPtr hrgnUpdate, uint flags);

    [DllImport("user32.dll", SetLastError = true)]
    static extern IntPtr SendMessageTimeout(IntPtr hWnd, int msg, IntPtr wParam, IntPtr lParam, int flags, int timeout, out IntPtr result);

    [DllImport("user32.dll")]
    static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint processId);

    [DllImport("user32.dll")]
    static extern bool GetWindowRect(IntPtr hWnd, out RECT rect);

    [DllImport("user32.dll")]
    static extern bool GetClientRect(IntPtr hWnd, out RECT rect);

    [DllImport("user32.dll", SetLastError = true)]
    static extern bool PrintWindow(IntPtr hwnd, IntPtr hdcBlt, uint nFlags);

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

    static RectInfo UnionMonitorRects(List<DisplayInfo> monitors) {
        if (monitors.Count == 0) return null;
        int left = monitors[0].monitor_rect.left;
        int top = monitors[0].monitor_rect.top;
        int right = monitors[0].monitor_rect.right;
        int bottom = monitors[0].monitor_rect.bottom;
        foreach (DisplayInfo monitor in monitors) {
            if (monitor.monitor_rect.left < left) left = monitor.monitor_rect.left;
            if (monitor.monitor_rect.top < top) top = monitor.monitor_rect.top;
            if (monitor.monitor_rect.right > right) right = monitor.monitor_rect.right;
            if (monitor.monitor_rect.bottom > bottom) bottom = monitor.monitor_rect.bottom;
        }
        return new RectInfo {
            left = left,
            top = top,
            right = right,
            bottom = bottom,
            width = right - left,
            height = bottom - top
        };
    }

    static RectInfo PrimaryMonitorRect(List<DisplayInfo> monitors, RectInfo fallback) {
        foreach (DisplayInfo monitor in monitors) {
            if (monitor.primary) return monitor.monitor_rect;
        }
        if (monitors.Count > 0) return monitors[0].monitor_rect;
        return fallback;
    }

    static string ClassName(IntPtr hwnd) {
        var sb = new StringBuilder(256);
        GetClassName(hwnd, sb, sb.Capacity);
        return sb.ToString();
    }

    static IntPtr Child(IntPtr parent, string cls) {
        return FindWindowEx(parent, IntPtr.Zero, cls, null);
    }

    public static void EnsureDpiAwareness() {
        if (dpiAwarenessAttempted) return;
        dpiAwarenessAttempted = true;
        try {
            if (SetProcessDpiAwarenessContext(new IntPtr(-4))) return;
        } catch (EntryPointNotFoundException) {
        } catch {
        }
        try {
            SetProcessDPIAware();
        } catch {
        }
    }

    public static IntPtr FindDesktopListView() {
        EnsureDpiAwareness();
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
        EnsureDpiAwareness();
        var monitors = new List<DisplayInfo>();
        EnumDisplayMonitors(IntPtr.Zero, IntPtr.Zero, (IntPtr monitor, IntPtr hdc, ref RECT rect, IntPtr data) => {
            var info = new MONITORINFOEX();
            info.cbSize = Marshal.SizeOf(typeof(MONITORINFOEX));
            info.szDevice = new string('\0', 32);
            if (GetMonitorInfo(monitor, ref info)) {
                monitors.Add(new DisplayInfo {
                    handle = "0x" + monitor.ToInt64().ToString("X"),
                    deviceName = (info.szDevice ?? "").TrimEnd('\0'),
                    active = true,
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
        RectInfo systemPrimary = RectFromMetrics(0, 0, primaryWidth, primaryHeight);
        RectInfo systemVirtual = RectFromMetrics(virtualX, virtualY, virtualWidth, virtualHeight);
        RectInfo activeVirtual = UnionMonitorRects(monitors);
        if (activeVirtual == null) activeVirtual = systemVirtual;
        return new DisplaySnapshot {
            monitor_count = monitors.Count,
            active_monitor_count = monitors.Count,
            system_monitor_count = GetSystemMetrics(SM_CMONITORS),
            primary_screen = PrimaryMonitorRect(monitors, systemPrimary),
            virtual_screen = activeVirtual,
            system_primary_screen = systemPrimary,
            system_virtual_screen = systemVirtual,
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
        EnsureDpiAwareness();
        RECT rect;
        if (GetWindowRect(hwnd, out rect)) return ToRectInfo(rect);
        RectInfo screen = Displays().primary_screen;
        int width = screen.width;
        int height = screen.height;
        return new RectInfo { left = 0, top = 0, right = width, bottom = height, width = width, height = height };
    }

    public static RectInfo ClientRect(IntPtr hwnd) {
        EnsureDpiAwareness();
        RECT rect;
        if (GetClientRect(hwnd, out rect)) return ToRectInfo(rect);
        RectInfo screen = Displays().primary_screen;
        int width = screen.width;
        int height = screen.height;
        return new RectInfo { left = 0, top = 0, right = width, bottom = height, width = width, height = height };
    }

    public static bool RenderWindowToDeviceContext(IntPtr hwnd, IntPtr hdc) {
        EnsureDpiAwareness();
        return PrintWindow(hwnd, hdc, PW_RENDERFULLCONTENT);
    }

    public static int DesktopWidth(IntPtr hwnd) {
        RectInfo rect = ClientRect(hwnd);
        if (rect.width > 0) return rect.width;
        return Displays().primary_screen.width;
    }

    public static int DesktopHeight(IntPtr hwnd) {
        RectInfo rect = ClientRect(hwnd);
        if (rect.height > 0) return rect.height;
        return Displays().primary_screen.height;
    }

    public static void SetSnapToGrid(IntPtr hwnd, bool enabled) {
        int style = SendMessage(hwnd, LVM_GETEXTENDEDLISTVIEWSTYLE, IntPtr.Zero, IntPtr.Zero).ToInt32();
        int newStyle = enabled ? (style | LVS_EX_SNAPTOGRID) : (style & ~LVS_EX_SNAPTOGRID);
        SendMessage(hwnd, LVM_SETEXTENDEDLISTVIEWSTYLE, (IntPtr)LVS_EX_SNAPTOGRID, (IntPtr)newStyle);
    }

    public static bool SnapToGrid(IntPtr hwnd) {
        int style = SendMessage(hwnd, LVM_GETEXTENDEDLISTVIEWSTYLE, IntPtr.Zero, IntPtr.Zero).ToInt32();
        return (style & LVS_EX_SNAPTOGRID) != 0;
    }

    public static bool AutoArrange(IntPtr hwnd) {
        int style = GetWindowLong(hwnd, GWL_STYLE);
        return (style & LVS_AUTOARRANGE) != 0;
    }

    public static void SetAutoArrange(IntPtr hwnd, bool enabled) {
        int style = GetWindowLong(hwnd, GWL_STYLE);
        int newStyle = enabled ? (style | LVS_AUTOARRANGE) : (style & ~LVS_AUTOARRANGE);
        if (newStyle != style) SetWindowLong(hwnd, GWL_STYLE, newStyle);
    }

    public static void SetRedraw(IntPtr hwnd, bool enabled) {
        SendMessage(hwnd, WM_SETREDRAW, enabled ? (IntPtr)1 : IntPtr.Zero, IntPtr.Zero);
        if (enabled) RedrawWindow(hwnd, IntPtr.Zero, IntPtr.Zero, RDW_INVALIDATE | RDW_ALLCHILDREN | RDW_UPDATENOW);
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

function Test-HasArg($Arguments, [string]$Name) {
    return ($null -ne $Arguments) -and ($Arguments.PSObject.Properties.Name -contains $Name) -and ($null -ne $Arguments.$Name)
}

function Get-BoolArg($Arguments, [string]$Name, [bool]$Default) {
    $value = Get-ArgValue $Arguments $Name $null
    if ($null -eq $value) { return $Default }
    if ($value -is [bool]) { return [bool]$value }
    if ($value -is [string]) { return [bool]::Parse($value) }
    return [bool]$value
}

function Resolve-DesktopScreenshotTarget($Arguments) {
    [DesktopIcons]::EnsureDpiAwareness()
    $hwnd = [DesktopIcons]::FindDesktopListView()
    $rect = [DesktopIcons]::WindowRect($hwnd)
    $clientRect = [DesktopIcons]::ClientRect($hwnd)

    if ($null -eq $rect -or [int]$rect.width -le 0 -or [int]$rect.height -le 0) {
        throw "Cannot determine desktop screenshot bounds."
    }

    return [ordered]@{
        hwnd = $hwnd
        handle = "0x" + $hwnd.ToInt64().ToString("X")
        source = "desktop_listview"
        rect = [ordered]@{
            left = [int]$rect.left
            top = [int]$rect.top
            right = [int]$rect.right
            bottom = [int]$rect.bottom
            width = [int]$rect.width
            height = [int]$rect.height
        }
        client_rect = [ordered]@{
            left = [int]$clientRect.left
            top = [int]$clientRect.top
            right = [int]$clientRect.right
            bottom = [int]$clientRect.bottom
            width = [int]$clientRect.width
            height = [int]$clientRect.height
        }
        displays = [DesktopIcons]::Displays()
    }
}

function Resolve-DesktopScreenshotFormat($Arguments, [string]$ResolvedPath) {
    $value = [string](Get-ArgValue $Arguments "format" "")
    if ([string]::IsNullOrWhiteSpace($value)) {
        switch ([IO.Path]::GetExtension($ResolvedPath).ToLowerInvariant()) {
            ".png" { return "png" }
            ".webp" { return "webp" }
            default { return "jpg" }
        }
    }

    switch ($value.Trim().ToLowerInvariant()) {
        "jpg" { return "jpg" }
        "jpeg" { return "jpg" }
        "png" { return "png" }
        "webp" { return "webp" }
        default { throw "format must be 'jpg', 'jpeg', 'png', or 'webp'." }
    }
}

function Get-DesktopScreenshotQuality($Arguments) {
    $quality = [int](Get-ArgValue $Arguments "quality" 82)
    if ($quality -lt 1 -or $quality -gt 100) {
        throw "quality must be an integer from 1 to 100."
    }
    return $quality
}

function Get-ImageEncoder([string]$MimeType) {
    foreach ($encoder in [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders()) {
        if ([string]::Equals($encoder.MimeType, $MimeType, [StringComparison]::OrdinalIgnoreCase)) {
            return $encoder
        }
    }
    throw "No System.Drawing encoder available for $MimeType."
}

function Get-DesktopScreenshotFormats {
    Add-Type -AssemblyName System.Drawing

    $definitions = @(
        [ordered]@{ name = "jpg"; aliases = @("jpeg"); mime_type = "image/jpeg"; extensions = @(".jpg", ".jpeg"); lossy = $true; quality_supported = $true; default_quality = 82 },
        [ordered]@{ name = "png"; aliases = @(); mime_type = "image/png"; extensions = @(".png"); lossy = $false; quality_supported = $false; default_quality = $null },
        [ordered]@{ name = "webp"; aliases = @(); mime_type = "image/webp"; extensions = @(".webp"); lossy = $true; quality_supported = $true; default_quality = 82 }
    )

    $formats = New-Object System.Collections.Generic.List[object]
    $supported = New-Object System.Collections.Generic.List[string]
    foreach ($definition in $definitions) {
        $encoder = $null
        $errorMessage = $null
        try {
            $encoder = Get-ImageEncoder ([string]$definition.mime_type)
        } catch {
            $errorMessage = $_.Exception.Message
        }

        $isSupported = $null -ne $encoder
        if ($isSupported) { $supported.Add([string]$definition.name) }
        $formats.Add([ordered]@{
            name = [string]$definition.name
            aliases = @($definition.aliases)
            mime_type = [string]$definition.mime_type
            extensions = @($definition.extensions)
            supported = [bool]$isSupported
            source = if ($isSupported) { "system_drawing_encoder" } else { "missing_encoder" }
            encoder = if ($isSupported) { [string]$encoder.FormatDescription } else { $null }
            lossy = [bool]$definition.lossy
            quality_supported = [bool]$definition.quality_supported
            default_quality = $definition.default_quality
            error = $errorMessage
        })
    }

    return [ordered]@{
        default_format = "jpg"
        default_quality = 82
        formats = $formats
        supported_formats = @($supported)
    }
}

function Save-DesktopScreenshotBitmap($Bitmap, [string]$Path, [string]$Format, [int]$Quality) {
    if ($Format -eq "png") {
        $Bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
        return [ordered]@{ format = "png"; mime_type = "image/png"; quality = $null }
    }

    $mimeType = if ($Format -eq "webp") { "image/webp" } else { "image/jpeg" }
    $encoder = Get-ImageEncoder $mimeType
    $encoderParameter = $null
    $encoderParameters = $null
    try {
        $encoderParameter = [System.Drawing.Imaging.EncoderParameter]::new([System.Drawing.Imaging.Encoder]::Quality, [long]$Quality)
        $encoderParameters = [System.Drawing.Imaging.EncoderParameters]::new(1)
        $encoderParameters.Param[0] = $encoderParameter
        $Bitmap.Save($Path, $encoder, $encoderParameters)
    } finally {
        if ($null -ne $encoderParameters) { $encoderParameters.Dispose() }
        if ($null -ne $encoderParameter) { $encoderParameter.Dispose() }
    }

    return [ordered]@{ format = $Format; mime_type = $mimeType; quality = [int]$Quality }
}

function Invoke-DesktopScreenshot($Arguments) {
    [DesktopIcons]::EnsureDpiAwareness()
    Add-Type -AssemblyName System.Drawing

    $formatHint = [string](Get-ArgValue $Arguments "format" "jpg")
    $defaultExtension = switch ($formatHint.Trim().ToLowerInvariant()) {
        "png" { "png" }
        "webp" { "webp" }
        default { "jpg" }
    }
    $path = [string](Get-ArgValue $Arguments "path" "desktop-screenshot.$defaultExtension")
    if ([string]::IsNullOrWhiteSpace($path)) { throw "path must not be empty." }
    $resolved = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($path)
    $directory = [IO.Path]::GetDirectoryName($resolved)
    if (-not [string]::IsNullOrWhiteSpace($directory) -and -not (Test-Path -LiteralPath $directory)) {
        [void](New-Item -ItemType Directory -Path $directory -Force)
    }

    $format = Resolve-DesktopScreenshotFormat $Arguments $resolved
    $quality = Get-DesktopScreenshotQuality $Arguments
    $capture = Resolve-DesktopScreenshotTarget $Arguments
    $rect = $capture.rect
    $bitmap = $null
    $graphics = $null
    $hdc = [IntPtr]::Zero
    try {
        $bitmap = New-Object System.Drawing.Bitmap -ArgumentList @([int]$rect.width, [int]$rect.height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
        $graphics.Clear([System.Drawing.Color]::Transparent)
        $hdc = $graphics.GetHdc()
        $rendered = [DesktopIcons]::RenderWindowToDeviceContext($capture.hwnd, $hdc)
        $graphics.ReleaseHdc($hdc)
        $hdc = [IntPtr]::Zero
        if (-not $rendered) { throw "PrintWindow failed while rendering the desktop ListView." }
        $saveInfo = Save-DesktopScreenshotBitmap $bitmap $resolved $format $quality
    } finally {
        if ($hdc -ne [IntPtr]::Zero -and $null -ne $graphics) { $graphics.ReleaseHdc($hdc) }
        if ($null -ne $graphics) { $graphics.Dispose() }
        if ($null -ne $bitmap) { $bitmap.Dispose() }
    }

    $file = Get-Item -LiteralPath $resolved
    return [ordered]@{
        ok = $true
        path = $resolved
        source = [string]$capture.source
        handle = [string]$capture.handle
        capture_method = "PrintWindow"
        rect = $rect
        client_rect = $capture.client_rect
        width = [int]$rect.width
        height = [int]$rect.height
        format = [string]$saveInfo.format
        mime_type = [string]$saveInfo.mime_type
        quality = $saveInfo.quality
        bytes = [int64]$file.Length
        supported_formats = @((Get-DesktopScreenshotFormats).supported_formats)
        displays = $capture.displays
    }
}

function New-IconLookup($Icons) {
    $byName = @{}
    $byIndex = @{}
    $nameCounts = @{}
    $duplicateKeys = @{}
    $duplicates = New-Object System.Collections.Generic.List[string]
    foreach ($icon in $Icons) {
        $key = ([string]$icon.name).ToLowerInvariant()
        $byIndex[[int]$icon.index] = $icon
        if (-not $nameCounts.ContainsKey($key)) { $nameCounts[$key] = 0 }
        $nameCounts[$key] = [int]$nameCounts[$key] + 1
        if ($byName.ContainsKey($key)) {
            if (-not $duplicateKeys.ContainsKey($key)) {
                $duplicates.Add([string]$icon.name)
                $duplicateKeys[$key] = $true
            }
            continue
        }
        $byName[$key] = $icon
    }
    return [ordered]@{ by_name = $byName; by_index = $byIndex; name_counts = $nameCounts; duplicates = $duplicates }
}

function Test-IconPositionMatch($Current, $Target, [int]$Tolerance) {
    return ([Math]::Abs([int]$Current.x - [int]$Target.x) -le $Tolerance) -and ([Math]::Abs([int]$Current.y - [int]$Target.y) -le $Tolerance)
}

function Test-HasProperty($Object, [string]$Name) {
    return ($null -ne $Object) -and ($Object.PSObject.Properties.Name -contains $Name)
}

function Add-UniqueString($List, $Seen, [string]$Value) {
    $key = $Value.ToLowerInvariant()
    if (-not $Seen.ContainsKey($key)) {
        $List.Add($Value)
        $Seen[$key] = $true
    }
}

function New-DesktopLayoutSnapshot($hwnd) {
    $icons = @([DesktopIcons]::List())
    $gridInfo = New-DesktopIconGrid $hwnd @{} $icons
    return [ordered]@{ version = 1; icons = $icons; grid = $gridInfo.grid }
}

function Find-NodeExecutable() {
    $command = Get-Command node -ErrorAction SilentlyContinue
    if ($null -eq $command) {
        throw "Cannot find Node.js executable 'node'. plan_desktop_icon_layout requires Node.js 18+ on PATH, or use optimize_desktop_islands.js manually."
    }
    return $command.Source
}

function Add-NodeArgIfPresent($NodeArgs, $Arguments, [string]$ArgumentName, [string]$CliName) {
    if (Test-HasArg $Arguments $ArgumentName) {
        $NodeArgs.Add($CliName)
        $NodeArgs.Add([string]$Arguments.$ArgumentName)
    }
}

function Invoke-DesktopLayoutPlanner($Arguments) {
    $mode = [string](Get-ArgValue $Arguments "mode" "islands")
    $inputProvided = Test-HasArg $Arguments "input_path"
    $outputPath = [string](Get-ArgValue $Arguments "output_path" "desktop-icons-optimized-$mode.json")
    $resolvedOutput = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($outputPath)
    $tempInput = $null
    $hwnd = [IntPtr]::Zero

    if ($inputProvided) {
        $resolvedInput = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath([string]$Arguments.input_path)
    } else {
        $hwnd = [DesktopIcons]::FindDesktopListView()
        $snapshot = New-DesktopLayoutSnapshot $hwnd
        $tempInput = Join-Path ([IO.Path]::GetTempPath()) ("desktop-icons-input-" + [Guid]::NewGuid().ToString("N") + ".json")
        $snapshot | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $tempInput -Encoding UTF8
        $resolvedInput = $tempInput
    }

    $node = Find-NodeExecutable
    $planner = Join-Path $PSScriptRoot "optimize_desktop_islands.js"
    if (-not (Test-Path -LiteralPath $planner)) { throw "Cannot find optimizer script at $planner." }

    $nodeArgs = New-Object System.Collections.Generic.List[string]
    $nodeArgs.Add($planner)
    $nodeArgs.Add("--input")
    $nodeArgs.Add($resolvedInput)
    $nodeArgs.Add("--output")
    $nodeArgs.Add($resolvedOutput)
    $nodeArgs.Add("--mode")
    $nodeArgs.Add($mode)
    if (Test-HasArg $Arguments "preferences_path") {
        $nodeArgs.Add("--preferences")
        $nodeArgs.Add($ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath([string]$Arguments.preferences_path))
    }
    Add-NodeArgIfPresent $nodeArgs $Arguments "columns" "--columns"
    Add-NodeArgIfPresent $nodeArgs $Arguments "rows" "--rows"
    Add-NodeArgIfPresent $nodeArgs $Arguments "origin_x" "--origin-x"
    Add-NodeArgIfPresent $nodeArgs $Arguments "origin_y" "--origin-y"
    Add-NodeArgIfPresent $nodeArgs $Arguments "spacing_x" "--spacing-x"
    Add-NodeArgIfPresent $nodeArgs $Arguments "spacing_y" "--spacing-y"

    try {
        $plannerOutput = & $node @nodeArgs 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "Optimizer failed with exit code $LASTEXITCODE`: $($plannerOutput -join "`n")"
        }
        $planned = Get-Content -LiteralPath $resolvedOutput -Raw -Encoding UTF8 | ConvertFrom-Json
        $result = [ordered]@{
            ok = $true
            mode = $mode
            input_path = $resolvedInput
            output_path = $resolvedOutput
            count = [int]$planned.icons.Count
            grid = $planned.grid
            summary = $planned.summary
            planner_output = @($plannerOutput)
        }

        if (Get-BoolArg $Arguments "apply" $false) {
            if ($hwnd -eq [IntPtr]::Zero) { $hwnd = [DesktopIcons]::FindDesktopListView() }
            $useIndexDefault = -not $inputProvided
            $useIndex = if (Test-HasArg $Arguments "use_index") { Get-BoolArg $Arguments "use_index" $useIndexDefault } else { $useIndexDefault }
            $placement = Invoke-DesktopIconPlacement $hwnd @($planned.icons) $Arguments $useIndex
            $result["ok"] = [bool]$placement.ok
            $result["placement"] = $placement
        }
        return $result
    } finally {
        if ($null -ne $tempInput -and (Test-Path -LiteralPath $tempInput)) {
            Remove-Item -LiteralPath $tempInput -Force
        }
    }
}

function Resolve-PlacementIcon($Target, $Lookup, [bool]$UseIndexIfAvailable) {
    $name = [string]$Target.name
    $key = $name.ToLowerInvariant()
    $hasIndex = Test-HasProperty $Target "index"
    if ($UseIndexIfAvailable -and $hasIndex) {
        $index = [int]$Target.index
        if ($Lookup.by_index.ContainsKey($index)) {
            $indexed = $Lookup.by_index[$index]
            if ([string]$indexed.name -eq $name) {
                return [ordered]@{ status = "ok"; icon = $indexed }
            }
        }
    }
    if (-not $Lookup.by_name.ContainsKey($key)) {
        return [ordered]@{ status = "missing"; icon = $null }
    }
    if ($Lookup.name_counts.ContainsKey($key) -and [int]$Lookup.name_counts[$key] -gt 1) {
        return [ordered]@{ status = "duplicate"; icon = $null }
    }
    return [ordered]@{ status = "ok"; icon = $Lookup.by_name[$key] }
}

function Test-DesktopIconPlacement($Targets, $Lookup, [int]$Tolerance, [bool]$UseIndexIfAvailable) {
    $mismatches = New-Object System.Collections.Generic.List[object]
    $missing = New-Object System.Collections.Generic.List[string]
    $duplicates = New-Object System.Collections.Generic.List[string]
    $missingKeys = @{}
    $duplicateKeys = @{}
    foreach ($target in $Targets) {
        $resolved = Resolve-PlacementIcon $target $Lookup $UseIndexIfAvailable
        if ($resolved.status -eq "missing") {
            Add-UniqueString $missing $missingKeys ([string]$target.name)
            continue
        }
        if ($resolved.status -eq "duplicate") {
            Add-UniqueString $duplicates $duplicateKeys ([string]$target.name)
            continue
        }
        $current = $resolved.icon
        if (-not (Test-IconPositionMatch $current $target $Tolerance)) {
            $mismatches.Add([ordered]@{
                name = [string]$target.name
                index = if (Test-HasProperty $target "index") { [int]$target.index } else { $null }
                expected_x = [int]$target.x
                expected_y = [int]$target.y
                actual_x = [int]$current.x
                actual_y = [int]$current.y
            })
        }
    }
    return [ordered]@{ missing = $missing; duplicates = $duplicates; mismatches = $mismatches }
}

function Invoke-DesktopIconPlacement($hwnd, $Targets, $Arguments, [bool]$UseIndexIfAvailable = $false) {
    $targets = @($Targets)
    $passes = [Math]::Max(1, [int](Get-ArgValue $Arguments "passes" 3))
    $settleMs = [Math]::Max(0, [int](Get-ArgValue $Arguments "settle_ms" 250))
    $tolerance = [Math]::Max(0, [int](Get-ArgValue $Arguments "tolerance" 2))
    $verify = Get-BoolArg $Arguments "verify" $true
    $disableRedraw = Get-BoolArg $Arguments "disable_redraw" $true
    $disableAutoArrange = Get-BoolArg $Arguments "disable_auto_arrange" $true
    $restoreAutoArrange = Get-BoolArg $Arguments "restore_auto_arrange" $false
    $autoArrangeWasEnabled = [DesktopIcons]::AutoArrange($hwnd)
    $redrawDisabled = $false
    $autoArrangeDisabled = $false
    $autoArrangeRestored = $false
    $placementSucceeded = $false
    $moved = New-Object System.Collections.Generic.List[object]
    $missing = New-Object System.Collections.Generic.List[string]
    $duplicateNames = New-Object System.Collections.Generic.List[string]
    $mismatches = New-Object System.Collections.Generic.List[object]
    $completedPasses = 0

    try {
        if ($disableAutoArrange -and $autoArrangeWasEnabled) {
            [DesktopIcons]::SetAutoArrange($hwnd, $false)
            $autoArrangeDisabled = $true
        }
        if ($disableRedraw) {
            [DesktopIcons]::SetRedraw($hwnd, $false)
            $redrawDisabled = $true
        }

        for ($pass = 1; $pass -le $passes; $pass++) {
            $completedPasses = $pass
            $lookup = New-IconLookup ([DesktopIcons]::List())
            $passState = Test-DesktopIconPlacement $targets $lookup $tolerance $UseIndexIfAvailable
            $missing = $passState.missing
            $duplicateNames = $passState.duplicates

            foreach ($target in $targets) {
                $resolved = Resolve-PlacementIcon $target $lookup $UseIndexIfAvailable
                if ($resolved.status -ne "ok") { continue }
                $current = $resolved.icon
                if (Test-IconPositionMatch $current $target $tolerance) { continue }
                [DesktopIcons]::Move($hwnd, [int]$current.index, [int]$target.x, [int]$target.y)
                $moved.Add([ordered]@{
                    pass = [int]$pass
                    name = [string]$target.name
                    from_x = [int]$current.x
                    from_y = [int]$current.y
                    x = [int]$target.x
                    y = [int]$target.y
                })
            }

            if ($settleMs -gt 0) { Start-Sleep -Milliseconds $settleMs }
            if ($verify) {
                $verifyLookup = New-IconLookup ([DesktopIcons]::List())
                $verifyState = Test-DesktopIconPlacement $targets $verifyLookup $tolerance $UseIndexIfAvailable
                $missing = $verifyState.missing
                $duplicateNames = $verifyState.duplicates
                $mismatches = $verifyState.mismatches
                if ($missing.Count -eq 0 -and $duplicateNames.Count -eq 0 -and $mismatches.Count -eq 0) { break }
            }
        }

        if ($verify) {
            if ($settleMs -gt 0) { Start-Sleep -Milliseconds $settleMs }
            $finalLookup = New-IconLookup ([DesktopIcons]::List())
            $finalState = Test-DesktopIconPlacement $targets $finalLookup $tolerance $UseIndexIfAvailable
            $missing = $finalState.missing
            $duplicateNames = $finalState.duplicates
            $mismatches = $finalState.mismatches
        }
        $placementSucceeded = ($missing.Count -eq 0) -and ($duplicateNames.Count -eq 0) -and ((-not $verify) -or $mismatches.Count -eq 0)
    } finally {
        if ($redrawDisabled) { [DesktopIcons]::SetRedraw($hwnd, $true) }
        if ($autoArrangeDisabled -and $autoArrangeWasEnabled -and ($restoreAutoArrange -or -not $placementSucceeded)) {
            [DesktopIcons]::SetAutoArrange($hwnd, $true)
            $autoArrangeRestored = $true
        }
    }

    return [ordered]@{
        ok = [bool]$placementSucceeded
        count = [int]$targets.Count
        passes = [int]$completedPasses
        moved = $moved
        missing = $missing
        duplicates = $duplicateNames
        mismatches = $mismatches
        auto_arrange_was_enabled = [bool]$autoArrangeWasEnabled
        auto_arrange_disabled = [bool]$autoArrangeDisabled
        auto_arrange_restored = [bool]$autoArrangeRestored
        redraw_suppressed = [bool]$disableRedraw
    }
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
            styles = [ordered]@{
                auto_arrange = [DesktopIcons]::AutoArrange($hwnd)
                snap_to_grid = [DesktopIcons]::SnapToGrid($hwnd)
            }
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

            $targets = New-Object System.Collections.Generic.List[object]
            for ($i = 0; $i -lt $icons.Count; $i++) {
                $x = $originX + (($i % $columns) * $stepX)
                $y = $originY + ([Math]::Floor($i / $columns) * $stepY)
                $targets.Add([ordered]@{ index = $icons[$i].index; name = $icons[$i].name; x = [int]$x; y = [int]$y })
            }
            $placement = Invoke-DesktopIconPlacement $hwnd $targets $Arguments $true
            $placement["grid"] = $grid
            $placement["icons"] = $targets
            return $placement
        }
        "plan_desktop_icon_layout" {
            return (Invoke-DesktopLayoutPlanner $Arguments)
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
            $hwnd = [DesktopIcons]::FindDesktopListView()
            $payload = New-DesktopLayoutSnapshot $hwnd
            $payload | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $resolved -Encoding UTF8
            return @{ ok = $true; path = $resolved; count = $payload.icons.Count }
        }
        "restore_desktop_icon_layout" {
            $path = [string](Get-ArgValue $Arguments "path")
            $resolved = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($path)
            $payload = Get-Content -LiteralPath $resolved -Raw -Encoding UTF8 | ConvertFrom-Json
            $hwnd = [DesktopIcons]::FindDesktopListView()
            $placement = Invoke-DesktopIconPlacement $hwnd @($payload.icons) $Arguments $false
            $placement["path"] = $resolved
            return $placement
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
    [ordered]@{ name = "arrange_desktop_icons_grid"; description = "Arrange desktop icons into the detected or specified ListView grid, with optional stabilization passes and verification."; inputSchema = @{ type = "object"; properties = @{ origin_x = @{ type = "integer" }; origin_y = @{ type = "integer" }; margin_x = @{ type = "integer" }; margin_y = @{ type = "integer" }; spacing_x = @{ type = "integer" }; spacing_y = @{ type = "integer" }; columns = @{ type = "integer" }; rows = @{ type = "integer" }; order_by = @{ type = "string"; enum = @("current", "name"); default = "current" }; passes = @{ type = "integer"; default = 3 }; settle_ms = @{ type = "integer"; default = 250 }; tolerance = @{ type = "integer"; default = 2 }; verify = @{ type = "boolean"; default = $true }; disable_redraw = @{ type = "boolean"; default = $true }; disable_auto_arrange = @{ type = "boolean"; default = $true }; restore_auto_arrange = @{ type = "boolean"; default = $false } }; additionalProperties = $false } },
    [ordered]@{ name = "plan_desktop_icon_layout"; description = "Plan a deterministic desktop icon layout with the JavaScript optimizer, optionally applying it with stabilized placement."; inputSchema = @{ type = "object"; properties = @{ mode = @{ type = "string"; enum = @("custom", "islands", "lines", "columns", "corners"); default = "islands" }; input_path = @{ type = "string" }; output_path = @{ type = "string" }; preferences_path = @{ type = "string" }; apply = @{ type = "boolean"; default = $false }; use_index = @{ type = "boolean" }; origin_x = @{ type = "integer" }; origin_y = @{ type = "integer" }; spacing_x = @{ type = "integer" }; spacing_y = @{ type = "integer" }; columns = @{ type = "integer" }; rows = @{ type = "integer" }; passes = @{ type = "integer"; default = 3 }; settle_ms = @{ type = "integer"; default = 250 }; tolerance = @{ type = "integer"; default = 2 }; verify = @{ type = "boolean"; default = $true }; disable_redraw = @{ type = "boolean"; default = $true }; disable_auto_arrange = @{ type = "boolean"; default = $true }; restore_auto_arrange = @{ type = "boolean"; default = $false } }; additionalProperties = $false } },
    [ordered]@{ name = "set_desktop_snap_to_grid"; description = "Enable or disable the desktop ListView snap-to-grid style."; inputSchema = @{ type = "object"; properties = @{ enabled = @{ type = "boolean"; default = $true } }; additionalProperties = $false } },
    [ordered]@{ name = "save_desktop_icon_layout"; description = "Save the current desktop icon layout to a JSON file."; inputSchema = @{ type = "object"; properties = @{ path = @{ type = "string"; default = "desktop-icons-layout.json" } }; additionalProperties = $false } },
    [ordered]@{ name = "restore_desktop_icon_layout"; description = "Restore desktop icon positions from a JSON file saved by save_desktop_icon_layout, with stabilization passes and post-restore verification."; inputSchema = @{ type = "object"; properties = @{ path = @{ type = "string" }; passes = @{ type = "integer"; default = 3 }; settle_ms = @{ type = "integer"; default = 250 }; tolerance = @{ type = "integer"; default = 2 }; verify = @{ type = "boolean"; default = $true }; disable_redraw = @{ type = "boolean"; default = $true }; disable_auto_arrange = @{ type = "boolean"; default = $true }; restore_auto_arrange = @{ type = "boolean"; default = $false } }; required = @("path"); additionalProperties = $false } }
)

if (-not $script:DesktopIconMcpNoLoop) {
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
}
