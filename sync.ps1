
# Git 실시간 동기화 스크립트
$ErrorActionPreference = "Stop"

# 인코딩 설정
$PSDefaultParameterValues['*:Encoding'] = 'utf8'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
chcp 65001 | Out-Null

# Git 설정
git config --global core.quotepath off
git config --global i18n.commitencoding utf-8
git config --global i18n.logoutputencoding utf-8
git config --global core.precomposeunicode true

# 감시 설정
$watchPath = "."
$filter = "*.*"

# 동기화 함수
function Sync-Changes {
    param (
        [string]$changeType,
        [string]$fullPath
    )
    
    # 무시할 경로 체크
    if ($fullPath -like "*.git*" -or 
        $fullPath -like "*node_modules*" -or 
        $fullPath -like "*복사본*") {
        return
    }

    Write-Host "`n변경 감지: $changeType - $fullPath" -ForegroundColor Cyan

    try {
        # Git 환경변수 설정
        $env:LANG = "en_US.UTF-8"
        $env:LC_ALL = "en_US.UTF-8"

        # 파일 존재 여부에 따른 처리
        if (Test-Path $fullPath) {
            git add $fullPath
            git commit -m "Update: $((Split-Path $fullPath -Leaf))"
        }
        else {
            git rm $fullPath
            git commit -m "Delete: $((Split-Path $fullPath -Leaf))"
        }

        # 원격 저장소 동기화
        git pull --rebase origin main
        git push origin main

        Write-Host "동기화 완료" -ForegroundColor Green
    }
    catch {
        Write-Host "오류 발생: $_" -ForegroundColor Red
        git status
    }
}

# 파일 시스템 감시자 설정
$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $watchPath
$watcher.Filter = $filter
$watcher.IncludeSubdirectories = $true
$watcher.EnableRaisingEvents = $true

# 이벤트 핸들러 등록
$handlers = @()

$handlers += Register-ObjectEvent $watcher Created -Action {
    Sync-Changes "Created" $Event.SourceEventArgs.FullPath
}

$handlers += Register-ObjectEvent $watcher Changed -Action {
    Sync-Changes "Changed" $Event.SourceEventArgs.FullPath
}

$handlers += Register-ObjectEvent $watcher Deleted -Action {
    Sync-Changes "Deleted" $Event.SourceEventArgs.FullPath
}

$handlers += Register-ObjectEvent $watcher Renamed -Action {
    Sync-Changes "Renamed" $Event.SourceEventArgs.FullPath
}

Write-Host "Git 실시간 동기화 시작..." -ForegroundColor Green
Write-Host "종료하려면 Ctrl+C를 누르세요." -ForegroundColor Yellow

try {
    # 초기 동기화
    git pull origin main
    
    # 무한 대기
    while ($true) { Start-Sleep -Seconds 1 }
}
catch {
    Write-Host "`n프로그램 종료됨: $_" -ForegroundColor Red
}
finally {
    # 정리
    $handlers | ForEach-Object {
        Unregister-Event -SourceIdentifier $_.Name
        Remove-Job -Id $_.Id -Force
    }
    $watcher.Dispose()
    Write-Host "`n모니터링 종료됨" -ForegroundColor Yellow
}