Param(
    [string]$AvdName = "Pixel_9_Pro",
    [int]$AppiumPort = 4723,
    [string]$WdioScript = "wdio"
)

function Stop-Appium() {
    Write-Host "Checking for process on port $AppiumPort..."
    try {
        # Use netstat to reliably find PIDs listening on the Appium port
        $lines = & netstat -ano 2>$null
        $pids = @()
        foreach ($line in $lines) {
            if ($line -match ":$AppiumPort\b") {
                $parts = ($line -split '\s+') | Where-Object { $_ -ne '' }
                if ($parts.Count -ge 1) {
                    $pidStr = $parts[-1]
                    if ($pidStr -match '^\d+$') { $pids += [int]$pidStr }
                }
            }
        }

        $pids = $pids | Select-Object -Unique
        foreach ($pidToStop in $pids) {
            try {
                Write-Host "Stopping process $pidToStop on port $AppiumPort"
                Stop-Process -Id $pidToStop -Force -ErrorAction SilentlyContinue
                # wait up to 5s for it to exit
                $sw = [Diagnostics.Stopwatch]::StartNew()
                while ($sw.Elapsed.TotalSeconds -lt 5) {
                    Start-Sleep -Milliseconds 200
                    $exists = Get-Process -Id $pidToStop -ErrorAction SilentlyContinue
                    if (-not $exists) { break }
                }
                if ($exists) { Write-Host "Process $pidToStop did not exit after stop attempt." }
            } catch {
                Write-Host ("Error stopping pid {0}: {1}" -f $pidToStop, $_) -ForegroundColor Yellow
            }
        }

        # Also try to stop processes whose command line contains 'appium' (node/appium server)
        try {
            $procs = Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -and ($_.CommandLine -match 'appium') }
            foreach ($p in $procs) {
                try {
                    Write-Host "Stopping process $($p.ProcessId) (cmd contains 'appium')"
                    Stop-Process -Id $p.ProcessId -Force -ErrorAction SilentlyContinue
                } catch {
                    Write-Host ("Could not stop process {0}: {1}" -f $($p.ProcessId), $_) -ForegroundColor Yellow
                }
            }
        } catch {
        }
    } catch {
        Write-Host ("Stop-Appium encountered an error: {0}" -f $_) -ForegroundColor Yellow
    }
}

function Start-Appium() {
    Write-Host "Ensuring Appium is running on port $AppiumPort..."
    # If something is already listening on the Appium port, assume Appium is running and skip start
    try {
        $existing = Get-NetTCPConnection -LocalPort $AppiumPort -ErrorAction SilentlyContinue
        if ($existing) {
            $pid = $existing.OwningProcess
            Write-Host "Port $AppiumPort is already in use by pid $pid. Skipping Appium start."
            try {
                $proc = Get-Process -Id $pid -ErrorAction SilentlyContinue
                if ($proc) { return @{ Process = $proc; Started = $false } }
            } catch { }
            return @{ Process = $null; Started = $false }
        }
    } catch {
        # if Get-NetTCPConnection unavailable or fails, fall back to process name check
        $proc = Get-Process -Name appium -ErrorAction SilentlyContinue
        if ($proc) { Write-Host "Found 'appium' process running. Skipping start."; return @{ Process = $proc; Started = $false } }
    }

    $cmd = "npx appium --port $AppiumPort"
    try {
        Write-Host "Launching Appium via cmd.exe: $cmd"
        $p = Start-Process -FilePath cmd.exe -ArgumentList "/c", $cmd -WindowStyle Hidden -PassThru -ErrorAction Stop
    } catch {
        Write-Host "Start-Process failed when launching Appium. Error details:" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        if ($_.Exception.InnerException) { Write-Host $_.Exception.InnerException.Message -ForegroundColor Red }
        exit 3
    }
    Start-Sleep -Seconds 2
    return @{ Process = $p; Started = $true }
}

function Start-Emulator($name) {
    if (-not $name) { Write-Error "AVD name empty"; exit 1 }
    Write-Host "Starting emulator: $name"
    try {
        $emCmd = Get-Command emulator -ErrorAction SilentlyContinue
        # Use cmd.exe to start emulator to avoid executing platform-specific script shims
        $cmd = "emulator -avd $name"
        Write-Host "Launching emulator via cmd.exe: $cmd"
        $p = Start-Process -FilePath cmd.exe -ArgumentList "/c", $cmd -WindowStyle Hidden -PassThru
        return @{ Process = $p; Started = $true }
    } catch {
        Write-Error "Failed to start emulator: $_"
        exit 4
    }
}

function Wait-For-Device([int]$timeoutSeconds = 300) {
    Write-Host "Waiting for device to be available (timeout ${timeoutSeconds}s)..."
    $sw = [Diagnostics.Stopwatch]::StartNew()
    while ($sw.Elapsed.TotalSeconds -lt $timeoutSeconds) {
        $devices = & adb devices 2>$null | Select-String "device$"
        if ($devices) { break }
        Start-Sleep -Seconds 2
    }
    if ($sw.Elapsed.TotalSeconds -ge $timeoutSeconds) { Write-Error "Device not available"; exit 2 }
    Write-Host "Device detected. Waiting for boot completion..."
    $boot = ""
    while ($boot -ne "1") {
        Start-Sleep -Seconds 2
        $boot = (& adb shell getprop sys.boot_completed 2>$null).Trim()
        Write-Host "boot_completed=$boot"
    }
    Write-Host "Device boot completed."
}

# Ensure Appium is running first. Start only if not already running.
$appiumInfo = Start-Appium
$appiumStarted = $false
if ($appiumInfo -is [hashtable]) {
    if ($appiumInfo.Started) {
        $appiumStarted = $true
        Write-Host "Appium started."
    } else {
        Write-Host "Appium already running; will not start a new instance."
    }
} elseif ($appiumInfo) {
    # legacy: Start-Appium returned a process object
    Write-Host "Appium process detected."
}

Write-Host "Preparing emulator '$AvdName'..."
# Determine if a device is already available
$deviceSerial = $null
$adbList = (& adb devices 2>$null)
foreach ($line in $adbList) {
    if ($line -match '^(.+)\s+device$') {
        $deviceSerial = $Matches[1].Trim()
        break
    }
}

$emulatorStarted = $false
if ($deviceSerial) {
    Write-Host "Device already connected: $deviceSerial. Skipping emulator start."
} else {
    # Clean up any leftover emulator/device processes before starting
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
    $cleanup = Join-Path $scriptDir 'cleanup-emulator-processes.ps1'
    if (Test-Path $cleanup) {
        Write-Host "Running cleanup script: $cleanup"
        & $cleanup
    } else {
        Write-Host "Cleanup script not found at $cleanup; continuing without cleanup"
    }

    Write-Host "Starting emulator '$AvdName'..."
    $emInfo = Start-Emulator -name $AvdName
    if ($emInfo -and $emInfo.Started) { $emulatorStarted = $true }

    Wait-For-Device -timeoutSeconds 300

    # capture device serial after boot
    $adbList = (& adb devices 2>$null)
    foreach ($line in $adbList) {
        if ($line -match '^(.+)\s+device$') {
            $deviceSerial = $Matches[1].Trim()
            break
        }
    }
    Start-Sleep -Seconds 2
}

Write-Host "Running tests via 'npm run $WdioScript'..."
npm run $WdioScript
$testExit = $LASTEXITCODE

Write-Host "Tests finished with exit code $testExit"
if ($appiumStarted) {
    Write-Host "Stopping Appium server (we started it)..."
    Stop-Appium
} else {
    Write-Host "Appium was already running before this script; leaving it running."
}

# If we started the emulator, shut it down now
if ($emulatorStarted) {
    Write-Host "Shutting down emulator we started (serial: $deviceSerial)..."
    try {
        $killed = $false
        if ($deviceSerial) {
            Write-Host "Attempting 'adb -s $deviceSerial emu kill' (3 tries)"
            for ($i = 0; $i -lt 3; $i++) {
                & adb -s $deviceSerial emu kill 2>$null
                Start-Sleep -Seconds 1
                $list = (& adb devices 2>$null) -join "`n"
                if ($list -notmatch [regex]::Escape($deviceSerial)) { $killed = $true; break }
            }
        } else {
            Write-Host "No device serial found; attempting generic 'adb emu kill' (3 tries)"
            for ($i = 0; $i -lt 3; $i++) {
                & adb emu kill 2>$null
                Start-Sleep -Seconds 1
                $list = (& adb devices 2>$null) -join "`n"
                if ($list -notmatch 'device') { $killed = $true; break }
            }
        }

        if (-not $killed) {
            Write-Host "adb emu kill did not remove device; falling back to killing emulator processes by command line"
            try {
                $all = Get-CimInstance Win32_Process -ErrorAction SilentlyContinue
                $candidates = $all | Where-Object {
                    ($_.CommandLine -and ($_.CommandLine -match "-avd\s+$AvdName")) -or
                    ($_.CommandLine -and ($_.CommandLine -match 'emulator')) -or
                    ($_.Name -match 'qemu')
                }
                foreach ($c in $candidates) {
                    try {
                        $pid = $c.ProcessId
                        Write-Host ("Stopping emulator process {0} pid {1} (cmd: {2})" -f $c.Name, $pid, ($c.CommandLine -replace '\\s+',' '))
                        Stop-Process -Id $pid -Force -ErrorAction SilentlyContinue
                        Start-Sleep -Milliseconds 300
                        $still = Get-Process -Id $pid -ErrorAction SilentlyContinue
                        if ($still) {
                            Write-Host ("Process {0} still running; attempting taskkill /F /T" -f $pid)
                            Start-Process -FilePath cmd.exe -ArgumentList "/c", "taskkill /PID $pid /F /T" -WindowStyle Hidden -Wait -ErrorAction SilentlyContinue | Out-Null
                            Start-Sleep -Milliseconds 300
                        }
                    } catch {
                        Write-Host ("Could not stop emulator process {0}: {1}" -f $c.ProcessId, $_) -ForegroundColor Yellow
                    }
                }
            } catch {
                Write-Host ("Fallback emulator kill encountered an error: {0}" -f $_) -ForegroundColor Yellow
            }
        }
    } catch {
        Write-Host ("Error shutting down emulator: {0}" -f $_) -ForegroundColor Yellow
    }
} else {
    Write-Host "Emulator was already running before this script; leaving it running."
}

exit $testExit
