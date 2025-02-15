# Real-time Git Sync Script
$PSDefaultParameterValues['*:Encoding'] = 'utf8'
[System.Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$watchPath = Resolve-Path "."
$filter = "*.*"
$lastSync = Get-Date
$lastGitCheck = Get-Date

Write-Host "Starting Git sync watcher in: $watchPath"

# Create FileSystemWatcher object
$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $watchPath
$watcher.Filter = $filter
$watcher.IncludeSubdirectories = $true
$watcher.EnableRaisingEvents = $true
$watcher.NotifyFilter = [System.IO.NotifyFilters]::FileName -bor [System.IO.NotifyFilters]::LastWrite

# Check GitHub changes function
function Check-GitHubChanges {
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

# Sync changes function
function Sync-Changes {
    param($changeType, $path)
    try {
        # Check if file exists and is not in .git directory
        if ((-not $path.Contains(".git")) -and (Test-Path $path)) {
            Write-Host "Processing change: $path ($changeType)" -ForegroundColor Cyan
            
            # Add all changes
            git add .
            
            # Check if there are changes to commit
            $status = git status --porcelain
            if ($status) {
                $timestamp = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
                # Get the relative path for the commit message
                $relativePath = (Resolve-Path -Relative $path).TrimStart(".\")
                
                # Create a descriptive commit message based on the change type
                $action = switch ($changeType) {
                    "Changed" { "Update" }
                    "Created" { "Add" }
                    "Deleted" { "Remove" }
                    "Renamed" { "Rename" }
                    default { "Modify" }
                }
                
                $commitMessage = "$action: Changes in $relativePath at $timestamp"
                
                # Commit and push changes
                git commit -m $commitMessage
                git push origin main
                
                Write-Host "Changes synced successfully" -ForegroundColor Green
            }
        }
    } catch {
        Write-Host "Error syncing changes: $_" -ForegroundColor Red
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
    Sync-Changes $changeType $path
}

# Register events
$handlers = . {
    Register-ObjectEvent -InputObject $watcher -EventName Created -Action $action
    Register-ObjectEvent -InputObject $watcher -EventName Changed -Action $action
    Register-ObjectEvent -InputObject $watcher -EventName Deleted -Action $action
    Register-ObjectEvent -InputObject $watcher -EventName Renamed -Action $action
}

Write-Host "Real-time file monitoring started. Press Ctrl+C to stop." -ForegroundColor Green

try {
    # Initial sync check
    Check-GitHubChanges
    
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
}
