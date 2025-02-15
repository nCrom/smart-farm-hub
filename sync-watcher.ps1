
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
                # Get the relative path for the commit message
                $relativePath = (Resolve-Path -Relative $path).TrimStart(".\")
                
                # Create a simple commit message with only ASCII characters
                $commitMessage = "Update: $relativePath"
                
                # Set environment variables for Git
                $env:LANG = "en_US.UTF-8"
                $env:LC_ALL = "en_US.UTF-8"
                
                # Commit and push changes with explicit encoding
                git -c i18n.commitencoding=utf-8 commit -m $commitMessage
                git push origin main
                
                Write-Host "Changes synced successfully" -ForegroundColor Green
            }
        }
    } catch {
        Write-Host "Error