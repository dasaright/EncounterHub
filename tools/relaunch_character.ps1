# Relaunch one character's bot through the Encounter Hub window (row Stop -> Yes -> wait -> row Launch).
# The hub runs elevated, so run this elevated too. Output goes to -LogPath.
param(
    [Parameter(Mandatory = $true)][string]$Character,
    [string]$LogPath = "$env:TEMP\encounterhub_relaunch.log"
)
$ErrorActionPreference = 'Stop'
Start-Transcript -Path $LogPath -Force | Out-Null
try {
    Add-Type -AssemblyName UIAutomationClient, UIAutomationTypes
    $AE = [System.Windows.Automation.AutomationElement]
    $Scope = [System.Windows.Automation.TreeScope]
    $Invoke = [System.Windows.Automation.InvokePattern]::Pattern

    function Get-HubWindow {
        $ids = @(Get-Process EncounterHub -ErrorAction SilentlyContinue | ForEach-Object Id)
        $AE::RootElement.FindAll($Scope::Children, [System.Windows.Automation.Condition]::TrueCondition) |
            Where-Object { $ids -contains $_.Current.ProcessId -and $_.Current.Name -like 'Encounter Hub*' } |
            Select-Object -First 1
    }
    Add-Type @'
using System; using System.Runtime.InteropServices;
public static class HubInput {
    [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
    [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
    [DllImport("user32.dll")] public static extern bool GetCursorPos(out POINT p);
    [DllImport("user32.dll")] public static extern void mouse_event(uint f, uint x, uint y, uint d, IntPtr e);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int c);
    [DllImport("user32.dll")] public static extern bool IsIconic(IntPtr h);
    [DllImport("user32.dll")] public static extern IntPtr WindowFromPoint(POINT p);
    [DllImport("user32.dll")] public static extern IntPtr GetAncestor(IntPtr h, uint flags);
    [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr h, IntPtr after, int x, int y, int cx, int cy, uint flags);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
    [DllImport("user32.dll")] public static extern void keybd_event(byte vk, byte scan, uint flags, IntPtr extra);
    public struct POINT { public int X; public int Y; }
}
'@
    [HubInput]::SetProcessDPIAware() | Out-Null

    # Qt does not expose the per-row cell buttons to UI Automation, so click the
    # centre of the cell at (row of $Character, column whose header is $caption).
    function Click-RowCell($hub, [string]$caption) {
        # Hub 2.3+ has tabs; only the visible tab is exposed, so show the Bots tab first.
        $tab = $hub.FindFirst($Scope::Descendants, (New-Object System.Windows.Automation.AndCondition(
            (New-Object System.Windows.Automation.PropertyCondition($AE::ControlTypeProperty, [System.Windows.Automation.ControlType]::TabItem)),
            (New-Object System.Windows.Automation.PropertyCondition($AE::NameProperty, 'Bots')))))
        if ($tab) {
            $select = $tab.GetCurrentPattern([System.Windows.Automation.SelectionItemPattern]::Pattern)
            if (-not $select.Current.IsSelected) { $select.Select(); Start-Sleep -Milliseconds 500 }
        }
        $cell = $hub.FindFirst($Scope::Descendants, (New-Object System.Windows.Automation.PropertyCondition($AE::NameProperty, $Character)))
        if (-not $cell) { throw "Row for '$Character' not found in the hub" }
        $header = $hub.FindFirst($Scope::Descendants, (New-Object System.Windows.Automation.AndCondition(
            (New-Object System.Windows.Automation.PropertyCondition($AE::ControlTypeProperty, [System.Windows.Automation.ControlType]::Header)),
            (New-Object System.Windows.Automation.PropertyCondition($AE::NameProperty, $caption)))))
        if (-not $header) { throw "Column '$caption' not found in the hub" }
        $hwnd = [IntPtr]$hub.Current.NativeWindowHandle
        # Restore only a minimized hub (SW_RESTORE on a maximized window changes the layout).
        if ([HubInput]::IsIconic($hwnd)) { [HubInput]::ShowWindow($hwnd, 9) | Out-Null }
        # An Alt tap lifts Windows' foreground lock so SetForegroundWindow is honoured.
        [HubInput]::keybd_event(0x12, 0, 0, [IntPtr]::Zero); [HubInput]::keybd_event(0x12, 0, 2, [IntPtr]::Zero)
        [HubInput]::SetForegroundWindow($hwnd) | Out-Null
        try { $hub.SetFocus() } catch {}
        # Other always-on-top windows (e.g. TacoBot) can cover the hub: raise the hub
        # above them for the click, and drop it back to normal z-order afterwards.
        [HubInput]::SetWindowPos($hwnd, [IntPtr](-1), 0, 0, 0, 0, 0x0003) | Out-Null  # HWND_TOPMOST, NOSIZE|NOMOVE
        Start-Sleep -Milliseconds 500
        # Measure only after the window is raised and settled, so the layout is final.
        $row = $cell.Current.BoundingRectangle; $col = $header.Current.BoundingRectangle
        $x = [int]($col.Left + $col.Width / 2); $y = [int]($row.Top + $row.Height / 2)
        # The table is wider than a normal hub window: when the cell is scrolled outside the
        # window, maximize the hub for this click and restore it afterwards.
        $maximized = $false
        $win = $hub.Current.BoundingRectangle
        if ($x -ge $win.Right -or $x -le $win.Left -or $y -ge $win.Bottom -or $y -le $win.Top) {
            [HubInput]::ShowWindow($hwnd, 3) | Out-Null; $maximized = $true  # SW_MAXIMIZE
            Start-Sleep -Milliseconds 800
            $row = $cell.Current.BoundingRectangle; $col = $header.Current.BoundingRectangle
            $x = [int]($col.Left + $col.Width / 2); $y = [int]($row.Top + $row.Height / 2)
        }
        # Never click blind: the top-level window under the point must be the hub itself.
        $pt = New-Object HubInput+POINT; $pt.X = $x; $pt.Y = $y
        $top = [HubInput]::GetAncestor([HubInput]::WindowFromPoint($pt), 2)  # GA_ROOT
        if ($top -ne $hwnd) {
            if ($maximized) { [HubInput]::ShowWindow($hwnd, 9) | Out-Null }
            [HubInput]::SetWindowPos($hwnd, [IntPtr](-2), 0, 0, 0, 0, 0x0003) | Out-Null
            throw "Another window covers the hub at ($x,$y); not clicking"
        }
        $p = New-Object HubInput+POINT; [HubInput]::GetCursorPos([ref]$p) | Out-Null
        [HubInput]::SetCursorPos($x, $y) | Out-Null
        Start-Sleep -Milliseconds 100
        [HubInput]::mouse_event(0x2, 0, 0, 0, [IntPtr]::Zero); Start-Sleep -Milliseconds 60
        [HubInput]::mouse_event(0x4, 0, 0, 0, [IntPtr]::Zero)
        Start-Sleep -Milliseconds 100
        [HubInput]::SetCursorPos($p.X, $p.Y) | Out-Null
        Start-Sleep -Milliseconds 300
        if ($maximized) { [HubInput]::ShowWindow($hwnd, 9) | Out-Null }  # SW_RESTORE
        [HubInput]::SetWindowPos($hwnd, [IntPtr](-2), 0, 0, 0, 0, 0x0003) | Out-Null  # HWND_NOTOPMOST
        "Clicked $caption for $Character at ($x,$y)"
    }
    function Get-BotPid {
        $bot = Get-Process Encounter_ReBuilt -ErrorAction SilentlyContinue |
            Where-Object { $_.MainWindowTitle -eq "Encounter Re:Built - $Character" } |
            Select-Object -First 1 -ExpandProperty Id
        if ($bot) { return $bot }
        # A bot whose startup failed keeps a generic title; find it through its game client.
        $gw = Get-Process Gw -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowTitle -like "*$Character*" }
        foreach ($g in $gw) {
            $parent = (Get-CimInstance Win32_Process -Filter "ProcessId=$($g.Id)").ParentProcessId
            if ($parent -and (Get-Process -Id $parent -ErrorAction SilentlyContinue).ProcessName -eq 'Encounter_ReBuilt') { return $parent }
        }
        return $null
    }

    $hub = Get-HubWindow
    if (-not $hub) { throw 'Encounter Hub window not found' }

    $old = Get-BotPid
    # Always stop the row first: a bot whose startup failed has a generic title and no game
    # client, so it cannot be identified here, but the hub still owns it and ignores Launch.
    # Stopping a row with nothing running is harmless.
    $allBefore = @(Get-Process Encounter_ReBuilt -ErrorAction SilentlyContinue | ForEach-Object Id)
    if ($true) {
        if ($old) { "Stopping $Character (bot PID $old)" } else { "Stopping $Character's hub row (no identifiable bot)" }
        $confirmed = $false
        for ($attempt = 1; $attempt -le 3 -and -not $confirmed; $attempt++) {
        Click-RowCell (Get-HubWindow) 'Stop'
        for ($i = 0; $i -lt 15 -and -not $confirmed; $i++) {
            Start-Sleep -Milliseconds 300
            # Only accept a Yes button from the hub's own confirmation dialog.
            $hubPid = (Get-HubWindow).Current.ProcessId
            $yes = $AE::RootElement.FindAll($Scope::Descendants, (New-Object System.Windows.Automation.OrCondition(
                (New-Object System.Windows.Automation.PropertyCondition($AE::NameProperty, '&Yes')),
                (New-Object System.Windows.Automation.PropertyCondition($AE::NameProperty, 'Yes'))))) |
                Where-Object { $_.Current.ProcessId -eq $hubPid } | Select-Object -First 1
            if ($yes) { $yes.GetCurrentPattern($Invoke).Invoke(); $confirmed = $true; 'Confirmed stop' }
        }
        if (-not $confirmed) { "No confirmation after Stop click (attempt $attempt); retrying" }
        }
        if (-not $confirmed) { throw 'Stop confirmation dialog not found' }
        if ($old) {
            $deadline = (Get-Date).AddSeconds(90)
            while ((Get-Process -Id $old -ErrorAction SilentlyContinue) -and (Get-Date) -lt $deadline) { Start-Sleep -Seconds 1 }
            if (Get-Process -Id $old -ErrorAction SilentlyContinue) { throw "Bot PID $old did not exit within 90s" }
            'Bot exited; waiting for its game client to close and the server session to end'
            Start-Sleep -Seconds 25
        } else {
            Start-Sleep -Seconds 5
            $gone = @($allBefore | Where-Object { -not (Get-Process -Id $_ -ErrorAction SilentlyContinue) })
            if ($gone.Count) { "Stopped unidentified bot PID(s) $($gone -join ', '); waiting for the server session to end"; Start-Sleep -Seconds 20 }
            else { "Nothing was running for $Character" }
        }
    }

    $before = @(Get-Process Encounter_ReBuilt -ErrorAction SilentlyContinue | ForEach-Object Id)
    for ($attempt = 1; $attempt -le 3; $attempt++) {
        Click-RowCell (Get-HubWindow) 'Launch'
        $t = (Get-Date).AddSeconds(15)
        $new = $null
        while (-not $new -and (Get-Date) -lt $t) {
            Start-Sleep -Seconds 1
            $new = Get-Process Encounter_ReBuilt -ErrorAction SilentlyContinue | Where-Object { $before -notcontains $_.Id } | Select-Object -First 1
        }
        if ($new) { "Bot process started (PID $($new.Id))"; break }
        "No bot process after Launch click (attempt $attempt)"
    }
    $deadline = (Get-Date).AddSeconds(120)
    while (-not (Get-BotPid) -and (Get-Date) -lt $deadline) { Start-Sleep -Seconds 2 }
    if (Get-BotPid) { "Started: bot PID $(Get-BotPid)" } else { 'Launch sent, but the bot window has not shown the character yet' }
} catch {
    "ERROR: $($_.Exception.Message)"
} finally {
    Stop-Transcript | Out-Null
}
