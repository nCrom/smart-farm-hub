
# Real-time Git Sync Script
# PowerShell 스크립트 인코딩 설정
$PSDefaultParameterValues['*:Encoding'] = 'utf8'
[System.Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$watchPath = "."
$filter = "*.*"
$lastSync = Get-Date
$lastGitCheck = Get-Date

# Set output encoding to UTF-8
Write-Host "Changing PowerShell console code page to UTF-8..."
$originalCP = [System.Console]::OutputEncoding
try {
    [System.Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $Host.UI.RawUI.OutputEncoding = [System.Text.Encoding]::UTF8
    chcp 65001 | Out-Null
    Write-Host "Encoding set to UTF-8"
} catch {
    Write-Host "Error setting encoding: $_"
    [System.Console]::OutputEncoding = $originalCP
}

# Create FileSystemWatcher object
$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $watchPath
$watcher.Filter = $filter
$watcher.IncludeSubdirectories = $true
$watcher.EnableRaisingEvents = $true

# Check GitHub changes function
function Check-GitHubChanges  {
    try {
        git fetch origin
        $status = git status
        if ($status -like "*Your branch is behind*") {
            Write-Host "GitHub changes detected. Syncing..." -ForegroundColor Yellow
            git pull origin main --rebase
            Write-Host "GitHub sync completed" -ForegroundColor Green
        }
    } catch {
        Write-Host "Error during GitHub sync: $_" -ForegroundColor Red
    }
}

# Change event handler
$action = {
    $path = $Event.SourceEventArgs.FullPath
    $changeType = $Event.SourceEventArgs.ChangeType
    $now = Get-Date
    
    # Ignore node_modules changes
    if ($path -like "*node_modules*") {
        return
    }
    
    # Ignore .git folder changes
    if ($path -like "*.git*") {
        return
    }
    
    # Check if enough time has passed since last sync
    if (($now - $script:lastSync).TotalMilliseconds -lt 500) {
        return
    }
    
    $script:lastSync = $now
    Write-Host "Local change detected: $path ($changeType)" -ForegroundColor Cyan
    
    # Execute Git commands
    Start-ThreadJob -ScriptBlock {
        git add .
        $timestamp = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
        $commitMessage = "Auto sync: $using:changeType - $timestamp"
        git commit -m $commitMessage
        git push origin main
    }
}

# Register events
$handlers = . {
    Register-ObjectEvent -InputObject $watcher -EventName Created -Action $action
    Register-ObjectEvent -InputObject $watcher -EventName Changed -Action $action
    Register-ObjectEvent -InputObject $watcher -EventName Deleted -Action $action
    Register-ObjectEvent -InputObject $watcher -EventName Renamed -Action $action
}

Write-Host "Starting real-time file change detection... (Press Ctrl+C to stop)" -ForegroundColor Green
try {
    do {
        $now = Get-Date
        # Check GitHub changes every 2 seconds
        if (($now - $script:lastGitCheck).TotalSeconds -ge 2) {
            $script:lastGitCheck = $now
            Check-GitHubChanges
        }
        
        Wait-Event -Timeout 0.1
        # Clean up background jobs
        Get-Job | Where-Object { $_.State -eq 'Completed' } | Remove-Job
    } while ($true)
} finally {
    # Cleanup
    $handlers | ForEach-Object {
        Unregister-Event -SourceIdentifier $_.Name
    }
    Get-Job | Remove-Job -Force
    $watcher.Dispose()
    Write-Host "Monitoring stopped" -ForegroundColor Yellow
    # Restore original encoding
    [System.Console]::OutputEncoding = $originalCP
}
