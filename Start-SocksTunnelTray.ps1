# Start-SocksTunnelTray.ps1
# One file: SSH SOCKS tunnel + auto reconnect + tray icon.
# Save as UTF-8-BOM in Notepad++.

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = "Stop"

$mutexName = "Local\Denis_SocksTunnelTray_v1"
$createdNew = $false

$mutex = New-Object System.Threading.Mutex(
    $true,
    $mutexName,
    [ref]$createdNew
)

if (-not $createdNew) {
    $mutex.Dispose()
    exit 0
}

$configPath = Join-Path $PSScriptRoot "config.ps1"

if (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) {
    [System.Windows.Forms.MessageBox]::Show(
        "Configuration file was not found:`n$configPath`n`n" +
        "Copy config.example.ps1 to config.ps1 and configure it.",
        "SSH SOCKS Tunnel",
        "OK",
        "Error"
    ) | Out-Null

    exit 1
}

. $configPath

$sshPath                 = $SshTunnelConfig.SshPath
$keyPath                 = $SshTunnelConfig.KeyPath
$sshHost                 = $SshTunnelConfig.SshHost
$remotePort              = [int]$SshTunnelConfig.RemotePort
$bindAddress             = $SshTunnelConfig.BindAddress
$port                    = [int]$SshTunnelConfig.LocalPort
$reconnectDelaySeconds   = [int]$SshTunnelConfig.ReconnectDelaySeconds
$checkIntervalMs         = [int]$SshTunnelConfig.CheckIntervalMs

# ---------------------------------------------------------------
# SSH settings
# ---------------------------------------------------------------

$sshPath    = "C:\Windows\System32\OpenSSH\ssh.exe"
$keyPath    = "C:\Users\$env:USERNAME\.ssh\id_rsa"
$sshHost    = "tunneluser@104.223.98.185"
$port       = 1080
$remotePort = 2229

$reconnectDelaySeconds = 5
$checkIntervalMs       = 1000

# ---------------------------------------------------------------
# Icons
# ---------------------------------------------------------------

$iconFolder   = Join-Path $PSScriptRoot "icons"
$iconUpPath   = Join-Path $iconFolder "up.ico"
$iconDownPath = Join-Path $iconFolder "down.ico"

if (-not (Test-Path $sshPath)) {
    [System.Windows.Forms.MessageBox]::Show(
        "ssh.exe not found:`n$sshPath",
        "SSH SOCKS Tunnel"
    ) | Out-Null
    exit 1
}

if (-not (Test-Path $keyPath)) {
    [System.Windows.Forms.MessageBox]::Show(
        "SSH key not found:`n$keyPath",
        "SSH SOCKS Tunnel"
    ) | Out-Null
    exit 1
}

if (-not (Test-Path $iconUpPath)) {
    [System.Windows.Forms.MessageBox]::Show(
        "Icon not found:`n$iconUpPath",
        "SSH SOCKS Tunnel"
    ) | Out-Null
    exit 1
}

if (-not (Test-Path $iconDownPath)) {
    [System.Windows.Forms.MessageBox]::Show(
        "Icon not found:`n$iconDownPath",
        "SSH SOCKS Tunnel"
    ) | Out-Null
    exit 1
}

$iconUp   = New-Object System.Drawing.Icon($iconUpPath)
$iconDown = New-Object System.Drawing.Icon($iconDownPath)

# ---------------------------------------------------------------
# SSH command: preserved from your original working script
# ---------------------------------------------------------------

$arguments = "-4 -i `"$keyPath`" -p $remotePort -D 127.0.0.1:$port -N " +
             "-o ExitOnForwardFailure=yes " +
             "-o ServerAliveInterval=15 " +
             "-o ServerAliveCountMax=3 " +
             "-o ConnectTimeout=10 " +
             "-o StrictHostKeyChecking=accept-new " +
             "-o IdentitiesOnly=yes " +
             $sshHost

# ---------------------------------------------------------------
# Runtime state
# ---------------------------------------------------------------

$script:sshProcess = $null
$script:stopped = $false
$script:lastPortState = $null
$script:nextStartTime = Get-Date


function Is-Port-Listening {
    $listener = Get-NetTCPConnection `
        -LocalPort $port `
        -State Listen `
        -ErrorAction SilentlyContinue

    return ($null -ne $listener)
}

function Update-TrayIcon {
    $alive = Is-Port-Listening

    # Do not reassign icon if port state has not changed.
    # This prevents tray-icon blinking.
    if ($alive -eq $script:lastPortState) {
        return
    }

    $script:lastPortState = $alive

    if ($alive) {
        $tray.Icon = $iconUp
        $tray.Text = "SSH SOCKS: connected (127.0.0.1:$port)"
        $statusItem.Text = "Status: connected"
    }
    else {
        $tray.Icon = $iconDown

        if ($script:stopped) {
            $tray.Text = "SSH SOCKS: stopped"
            $statusItem.Text = "Status: stopped"
        }
        else {
            $tray.Text = "SSH SOCKS: reconnecting..."
            $statusItem.Text = "Status: reconnecting"
        }
    }
}

function Stop-Ssh {
    if ($script:sshProcess -and -not $script:sshProcess.HasExited) {
        Stop-Process `
            -Id $script:sshProcess.Id `
            -Force `
            -ErrorAction SilentlyContinue
    }

    $script:sshProcess = $null
}

function Start-Ssh {
    # Do not start a second SSH if local SOCKS port is already occupied.
    if (Is-Port-Listening) {
        return
    }

    try {
        $script:sshProcess = Start-Process `
            -FilePath $sshPath `
            -ArgumentList $arguments `
            -WindowStyle Hidden `
            -PassThru `
            -ErrorAction Stop
    }
    catch {
        $script:sshProcess = $null
    }
}

# ---------------------------------------------------------------
# Tray icon and menu
# ---------------------------------------------------------------

$tray = New-Object System.Windows.Forms.NotifyIcon
$tray.Icon = $iconDown
$tray.Text = "SSH SOCKS: starting..."
$tray.Visible = $true

$menu = New-Object System.Windows.Forms.ContextMenuStrip

$statusItem = $menu.Items.Add("Status: starting...")
$statusItem.Enabled = $false

$menu.Items.Add("-") | Out-Null

$reconnectItem = $menu.Items.Add("Reconnect now")
$reconnectItem.Add_Click({
    if ($script:stopped) {
        return
    }

    Stop-Ssh
    $script:nextStartTime = Get-Date
    $script:lastPortState = $null
})

$stopItem = $menu.Items.Add("Stop tunnel")
$stopItem.Add_Click({
    $script:stopped = $true
    Stop-Ssh
    $script:lastPortState = $null

    $reconnectItem.Enabled = $false
    $stopItem.Enabled = $false
    $startItem.Enabled = $true

    Update-TrayIcon
})

$startItem = $menu.Items.Add("Start tunnel")
$startItem.Enabled = $false
$startItem.Add_Click({
    $script:stopped = $false
    $script:nextStartTime = Get-Date
    $script:lastPortState = $null

    $reconnectItem.Enabled = $true
    $stopItem.Enabled = $true
    $startItem.Enabled = $false

    Update-TrayIcon
})

$menu.Items.Add("-") | Out-Null

$exitItem = $menu.Items.Add("Exit")
$exitItem.Add_Click({
    $script:stopped = $true

    [System.Windows.Forms.Application]::Exit()
})

$tray.ContextMenuStrip = $menu

$tray.Add_DoubleClick({
    if (Is-Port-Listening) {
        [System.Windows.Forms.MessageBox]::Show(
            "Tunnel is active.`n`nSOCKS5: 127.0.0.1:$port`nSSH PID: $($script:sshProcess.Id)",
            "SSH SOCKS Tunnel",
            "OK",
            "Information"
        ) | Out-Null
    }
    else {
        [System.Windows.Forms.MessageBox]::Show(
            "Tunnel is not active.",
            "SSH SOCKS Tunnel",
            "OK",
            "Warning"
        ) | Out-Null
    }
})

# ---------------------------------------------------------------
# Supervisor timer
# ---------------------------------------------------------------

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = $checkIntervalMs

$timer.Add_Tick({
    # Manual stop disables all reconnects.
    if ($script:stopped) {
        Update-TrayIcon
        return
    }

    # If SSH exited, schedule a new attempt in 5 seconds.
    if ($script:sshProcess -and $script:sshProcess.HasExited) {
        $script:sshProcess = $null
        $script:nextStartTime = (Get-Date).AddSeconds($reconnectDelaySeconds)
    }

    # No active managed SSH and port is free: reconnect when delay expires.
    if (
        -not $script:sshProcess -and
        -not (Is-Port-Listening) -and
        (Get-Date) -ge $script:nextStartTime
    ) {
        Start-Ssh
    }

    Update-TrayIcon
})

# ---------------------------------------------------------------
# Start
# ---------------------------------------------------------------

Start-Ssh
Update-TrayIcon

$timer.Start()

try {
    [System.Windows.Forms.Application]::Run() | Out-Null
}
finally {
    $script:stopped = $true

    if ($timer) {
        $timer.Stop()
        $timer.Dispose()
    }

    Stop-Ssh

    if ($tray) {
        $tray.Visible = $false
        $tray.Dispose()
    }

    if ($iconUp) {
        $iconUp.Dispose()
    }

    if ($iconDown) {
        $iconDown.Dispose()
    }

    if ($mutex) {
        try {
            $mutex.ReleaseMutex()
        }
        catch {
        }

        $mutex.Dispose()
    }
}