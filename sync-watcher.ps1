
# Real-time Git Sync Script
# PowerShell 기본 인코딩 설정
$PSDefaultParameterValues['*:Encoding'] = 'utf8'
[System.Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
chcp 65001 | Out-Null

# Git 설정을 스크립트 실행 시점에 강제로 적용
git config --global core.quotepath off
git config --global i18n.commitencoding utf-8
git config --global i18n.logoutputencoding utf-8
git config --global core.precomposeunicode true
git config --global core.autocrlf false

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
$watcher.NotifyFilter = [System.IO.NotifyFilters]::FileName -bor [System.IO.NotifyFilters]::LastWrite -bor [System.IO.NotifyFilters]::Size -bor [System.IO.NotifyFilters]::CreationTime

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
        # Ignore .git directory changes
        if ($path -like "*.git*") {
            return
        }

        Write-Host "Processing $changeType for path: $path" -ForegroundColor Cyan

        # Git 환경 변수 설정
        $env:LANG = "en_US.UTF-8"
        $env:LC_ALL = "en_US.UTF-8"
        $env:GIT_COMMITTER_NAME = "nCrom"
        $env:GIT_COMMITTER_EMAIL = "realpano@naver.com"

        # PowerShell의 기본 인코딩을 UTF-8로 설정
        $PSDefaultParameterValues['*:Encoding'] = 'utf8'
        [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
        $OutputEncoding = [System.Text.Encoding]::UTF8

        # 파일이 삭제된 경우
        if ($changeType -eq "Deleted") {
            Write-Host "File deleted: $path" -ForegroundColor Yellow
            
            # Git에서 파일 삭제 및 커밋
            git rm "$path"
            $commitMessage = "Delete: $((Get-Item $path).Name)"
            git -c i18n.commitencoding=utf-8 -c i18n.logoutputencoding=utf-8 commit -m $commitMessage
            git push origin main
            
            Write-Host "File deletion synced to GitHub" -ForegroundColor Green
        }
        # 파일이 생성되거나 수정된 경우
        elseif (($changeType -eq "Created" -or $changeType -eq "Changed") -and (Test-Path $path)) {
            Write-Host "Adding changes..." -ForegroundColor Yellow
            
            # 변경된 파일만 추가
            git add "$path"
            
            # Check if there are changes to commit
            $status = git status --porcelain
            if ($status) {
                # Get the relative path for the commit message
                $relativePath = (Resolve-Path -Relative $path).TrimStart(".\")
                $commitMessage = "Update: $relativePath"
                
                # Commit and push changes with UTF-8 encoding
                Write-Host "Committing changes..." -ForegroundColor Yellow
                git -c i18n.commitencoding=utf-8 -c i18n.logoutputencoding=utf-8 commit -m $commitMessage
                
                Write-Host "Pushing changes..." -ForegroundColor Yellow
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
    
    # 딜레이를 100ms로 줄임
    if (($now - $script:lastSync).TotalMilliseconds -lt 100) {
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
        # GitHub 변경사항 체크 주기를 1초로 줄임
        if (($now - $script:lastGitCheck).TotalSeconds -ge 1) {
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
