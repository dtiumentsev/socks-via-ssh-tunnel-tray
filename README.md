# SOCKS via SSH Tunnel Tray

A lightweight Windows PowerShell controller for a local SSH SOCKS5 tunnel.

## Features

- SSH dynamic forwarding on `127.0.0.1`
- System tray status icon
- Automatic reconnect after SSH termination
- Manual start, stop, reconnect, and exit actions
- No persistent CMD window
- Single-instance protection through a named mutex
- Per-domain routing with FoxyProxy

## Architecture

Chrome
  │
  ├── Обычные домены ─────────────────────► Direct connection
  │
  └── api.example.dev
          │
          ▼
     FoxyProxy pattern rule
          │
          ▼
     SOCKS5: 127.0.0.1:1080
          │
          ▼
     ssh.exe (-D dynamic forwarding)
          │
          ▼
     VPS / SSH host
          │
          ▼
     api.example.dev

## Requirements

- Windows 10/11
- OpenSSH Client
- PowerShell 5.1+
- VPS with key-based SSH access
- Chrome/Chromium and FoxyProxy Extension

## Installation

1. Clone the repository.
2. Copy `config.example.ps1` to `config.ps1`.
3. Edit `config.ps1`.
4. Run `Start-SocksTunnelTray.vbs`.

## FoxyProxy setup

Configure SOCKS5:
- Host: `127.0.0.1`
- Port: `1080`

Create URL patterns only for selected domains.

## Verification

[commands]

## Security notes

[bullets]

## License

MIT