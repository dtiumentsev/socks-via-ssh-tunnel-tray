# Check-SocksPort.ps1
# Show processes listening on TCP port 1080.

$port = 1080

Write-Host ""
Write-Host "Checking TCP port $port..."
Write-Host ""

try {
    $listeners = @(
        Get-NetTCPConnection `
            -LocalPort $port `
            -State Listen `
            -ErrorAction Stop
    )

    if ($listeners.Count -eq 0) {
        Write-Host "No process is listening on TCP port $port."
    }
    else {
        $listeners |
            Select-Object LocalAddress, LocalPort, State, OwningProcess,
                @{Name = "ProcessName"; Expression = {
                    $owner = Get-Process `
                        -Id $_.OwningProcess `
                        -ErrorAction SilentlyContinue

                    if ($owner) {
                        $owner.ProcessName
                    }
                    else {
                        "Unknown"
                    }
                }} |
            Format-Table -AutoSize |
            Out-Host
    }
}
catch {
    Write-Host "Could not check TCP port $port."
    Write-Host "Error: $($_.Exception.Message)"
}

Write-Host ""
Read-Host "Press Enter to close"