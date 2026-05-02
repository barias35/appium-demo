<#
Stops/kills common emulator-related processes to ensure a clean start.
This script is safe to run repeatedly; it ignores missing processes.
#>
Write-Host "Cleaning up emulator-related processes..."

try {
    $names = @('emulator', 'emulator64-*', 'emulator64-arm', 'qemu-system*', 'adb', 'adb.exe')
    foreach ($pattern in $names) {
        $procs = Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -like $pattern }
        foreach ($p in $procs) {
            try {
                Write-Host "Stopping process $($p.ProcessName) (pid $($p.Id))"
                Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue
            } catch {
                Write-Host "Could not stop pid $($p.Id): $_"
            }
        }
    }

    # Ensure adb server is stopped and restarted cleanly
    if (Get-Command adb -ErrorAction SilentlyContinue) {
        Write-Host "Killing adb server..."
        & adb kill-server 2>$null
        Start-Sleep -Milliseconds 300
    }
} catch {
    Write-Host "Cleanup encountered an error: $_"
}

Write-Host "Cleanup complete."
