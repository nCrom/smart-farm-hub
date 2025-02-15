
# PowerShell 기본 인코딩 설정
$ErrorActionPreference = "Stop"
$PSDefaultParameterValues['*:Encoding'] = 'utf8'
[System.Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
chcp 65001 | Out-Null

# Git 설정
git config --global core.quotepath off
git config --global i18n.commitencoding utf-8
git config --global i18n.logoutputencoding utf-8
git config --global core.precomposeunicode true
git config --global core.autocrlf false

# 감시할 경로 설정
$watchPath = "."
$filter = "*.*"

# 파일 변경 감지 함수
function Sync-GitChanges {
    param(
        [string]$changeType,
        [string]$path
    )
    
    if ($path -like "*.git*" -or $path -like "*복사본*" -or $path -like "*node_modules*") {
        return
    }

    Write-Host "`n변경 감지: $changeType - $path" -ForegroundColor Cyan

    try {
        $env:LANG = "en_US.UTF-8"
        $env:LC_ALL = "en_US.UTF-8"

        if (Test-Path $path) {
            git add $path
            git commit -m "Update: $((Split-Path $path -Leaf))"
        } else {
            git rm $path
            git commit -m "Delete: $((Split-Path $path -Leaf))"
        }

        git pull --rebase origin main
        git push origin main
        Write-Host "동기화 완료" -ForegroundColor Green
    }
    catch {
        Write-Host "오류 발생: $_" -ForegroundColor Red
        Write-Host "Git 상태:" -ForegroundColor Yellow
        git status
    }
}

# 메인 스크립트 시작
Write-Host "Git 실시간 동기화 시작..." -ForegroundColor Green

$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $watchPath
$watcher.Filter = $filter
$watcher.IncludeSubdirectories = $true
$watcher.EnableRaisingEvents = $true

$handlers = @()

$handlers += Register-ObjectEvent $watcher Created -Action {
    Sync-GitChanges "Created" $Event.SourceEventArgs.FullPath
}

$handlers += Register-ObjectEvent $watcher Changed -Action {
    Sync-GitChanges "Changed" $Event.SourceEventArgs.FullPath
}

$handlers += Register-ObjectEvent $watcher Deleted -Action {
    Sync-GitChanges "Deleted" $Event.SourceEventArgs.FullPath
}

$handlers += Register-ObjectEvent $watcher Renamed -Action {
    Sync-GitChanges "Renamed" $Event.SourceEventArgs.FullPath
}

Write-Host "파일 감시 시작. 중지하려면 Ctrl+C를 누르세요." -ForegroundColor Green

try {
    git pull origin main
    while ($true) { Start-Sleep -Seconds 1 }
}
catch {
    Write-Host "프로그램 종료: $_" -ForegroundColor Red
}
finally {
    $handlers | ForEach-Object {
        Unregister-Event -SourceIdentifier $_.Name
        Remove-Job -Id $_.Id -Force
    }
    $watcher.Dispose()
    Write-Host "모니터링 종료" -ForegroundColor Yellow
}