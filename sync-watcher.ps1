
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

Write-Host "Starting Git sync watcher in: $watchPath"

# Create FileSystemWatcher object
$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $watchPath
$watcher.Filter = $filter
$watcher.IncludeSubdirectories = $true
$watcher.EnableRaisingEvents = $true
$watcher.NotifyFilter = [System.IO.NotifyFilters]::FileName -bor [System.IO.NotifyFilters]::LastWrite -bor [System.IO.NotifyFilters]::Size -bor [System.IO.NotifyFilters]::CreationTime

# Sync changes function
function Sync-Changes {
    param($changeType, $path)
    try {
        # Ignore .git directory changes and copy files
        if ($path -like "*.git*" -or $path -like "*복사본*" -or $path -like "*- 복사본*") {
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
            
            # 현재 브랜치의 변경사항을 커밋
            git add -f "$path"
            git commit -m "Update: $((Split-Path $path -Leaf))"
            
            # 원격 저장소의 변경사항 가져와서 리베이스
            Write-Host "Fetching and rebasing with remote..." -ForegroundColor Yellow
            git fetch origin
            git rebase origin/main
            
            # 충돌이 있는지 확인
            $conflicts = git diff --name-only --diff-filter=U
            if ($conflicts) {
                Write-Host "Conflicts detected. Resolving..." -ForegroundColor Yellow
                git checkout --theirs "$path"
                git add "$path"
                git rebase --continue
            }
            
            # 변경사항 푸시
            Write-Host "Pushing changes..." -ForegroundColor Yellow
            git push origin main
            
            Write-Host "Changes synced successfully" -ForegroundColor Green
        }
        elseif ($changeType -eq "Deleted") {
            Write-Host "File deleted: $path" -ForegroundColor Yellow
            
            # 파일 삭제를 커밋
            git rm -f "$path"
            git commit -m "Delete: $((Split-Path $path -Leaf))"
            
            # 원격 저장소와 동기화
            Write-Host "Syncing with remote..." -ForegroundColor Yellow
            git fetch origin
            git rebase origin/main
            git push origin main
            
            Write-Host "Deletion synced successfully" -ForegroundColor Green
        }
    } catch {
        Write-Host "Error syncing changes: $_" -ForegroundColor Red
        Write-Host "Git Status:" -ForegroundColor Yellow
        git status
    }
}

# Change event handler
$action = {
    $path = $Event.SourceEventArgs.FullPath
    $changeType = $Event.SourceEventArgs.ChangeType
    
    # Ignore node_modules changes and copy files
    if ($path -like "*node_modules*" -or $path -like "*복사본*" -or $path -like "*- 복사본*") {
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
    # 이벤트 대기
    while ($true) {
        Wait-Event -Timeout 1
        Get-Job | Where-Object { $_.State -eq 'Completed' } | Remove-Job
    }
} finally {
    # Cleanup
    $handlers | ForEach-Object {
        Unregister-Event -SourceIdentifier $_.Name
    }
    Get-Job | Remove-Job -Force
    $watcher.Dispose()
    Write-Host "Monitoring stopped" -ForegroundColor Yellow
}
