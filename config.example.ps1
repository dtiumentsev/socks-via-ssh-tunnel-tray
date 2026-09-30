# Copy this file to config.ps1 and update values for your environment.
# config.ps1 is intentionally excluded from Git.

$SshTunnelConfig = @{
    SshPath    = "$env:WINDIR\System32\OpenSSH\ssh.exe"
    KeyPath    = "$env:USERPROFILE\.ssh\id_rsa"
    SshHost    = "tunnel-user@ssh.example.net"
    RemotePort = 22

    BindAddress = "127.0.0.1"
    LocalPort  = 1080

    ReconnectDelaySeconds = 5
    CheckIntervalMs       = 1000
}