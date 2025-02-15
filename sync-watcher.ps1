
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
        Write-Host "Checking for GitHub changes..." -ForegroundColor Cyan
        git fetch origin
        $localHash = git rev-parse HEAD
        $remoteHash = git rev-parse origin/main
        
        if ($localHash -ne $remoteHash) {
            Write-Host "GitHub changes detected. Syncing..." -ForegroundColor Yellow
            git stash push -u -m "Local changes stashed before pull"
            git pull origin main --rebase
            $stashList = git stash list
            if ($stashList) {
                git stash pop
            }
            Write-Host "GitHub sync completed" -ForegroundColor Green
            return $true
        }
        return $false
    } catch {
        Write-Host "Error during GitHub sync: $_" -ForegroundColor Red
        return $false
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

        # 변경 사항을 즉시 커밋하고 푸시
        if (Test-Path $path) {
            Write-Host "Adding changes..." -ForegroundColor Yellow
            
            # 먼저 untracked 파일인지 확인
            $gitStatus = git status --porcelain "$path"
            Write-Host "Git status for $path : $gitStatus" -ForegroundColor Cyan
            
            # 강제로 git add 실행 (-f 옵션 사용)
            git add -f "$path"
            
            $status = git status --porcelain
            if ($status) {
                $relativePath = (Resolve-Path -Relative $path).TrimStart(".\")
                $commitMessage = "Update: $relativePath"
                
                Write-Host "Committing changes..." -ForegroundColor Yellow
                git -c i18n.commitencoding=utf-8 -c i18n.logoutputencoding=utf-8 commit -m $commitMessage
                
                Write-Host "Pushing changes..." -ForegroundColor Yellow
                git pull origin main --rebase
                git push origin main -f
                
                Write-Host "Changes synced successfully" -ForegroundColor Green
            }
        }
        elseif ($changeType -eq "Deleted") {
            Write-Host "File deleted: $path" -ForegroundColor Yellow
            git rm -f "$path"
            
            $commitMessage = "Delete: $((Split-Path $path -Leaf))"
            git -c i18n.commitencoding=utf-8 -c i18n.logoutputencoding=utf-8 commit -m $commitMessage
            git pull origin main --rebase
            git push origin main -f
            
            Write-Host "File deletion synced to GitHub" -ForegroundColor Green
        }
    } catch {
        Write-Host "Error syncing changes: $_" -ForegroundColor Red
        
        # 에러 발생 시 git 상태 출력
        Write-Host "Git Status:" -ForegroundColor Yellow
        git status
    }
}

# Change event handler
$action = {
    $path = $Event.SourceEventArgs.FullPath
    $changeType = $Event.SourceEventArgs.ChangeType
    
    # Ignore node_modules changes
    if ($path -like "*node_modules*") {
        return
    }
    
    # Ignore .git folder changes
    if ($path -like "*.git*") {
        return
    }
    
    Write-Host "Change detected: $changeType - $path" -ForegroundColor Yellow
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
        # GitHub 변경사항 체크 (매 1초마다)
        $now = Get-Date
        if (($now - $script:lastGitCheck).TotalSeconds -ge 1) {
            $script:lastGitCheck = $now
            if (Check-GitHubChanges) {
                Write-Host "Remote changes applied successfully" -ForegroundColor Green
            }
        }
        
        Wait-Event -Timeout 1
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
