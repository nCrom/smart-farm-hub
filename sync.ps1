
# Real-time Git Sync Script
# PowerShell 기본 인코딩 설정
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
$watchPath = Resolve-Path "."
$filter = "*.*"

Write-Host "실시간 Git 동기화 시작: $watchPath" -ForegroundColor Green

# FileSystemWatcher 객체 생성
$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $watchPath
$watcher.Filter = $filter
$watcher.IncludeSubdirectories = $true
$watcher.EnableRaisingEvents = $true
$watcher.NotifyFilter = [System.IO.NotifyFilters]::FileName -bor [System.IO.NotifyFilters]::LastWrite -bor [System.IO.NotifyFilters]::Size

# 변경사항 동기화 함수
function Sync-Changes {
    param($changeType, $path)
    try {
        # .git 디렉토리, 복사본 파일, node_modules 무시
        if ($path -like "*.git*" -or $path -like "*복사본*" -or $path -like "*node_modules*") {
            return
        }

        Write-Host "`n변경 감지: $changeType - $path" -ForegroundColor Cyan

        # Git 환경 변수 설정
        $env:LANG = "en_US.UTF-8"
        $env:LC_ALL = "en_US.UTF-8"

        if (Test-Path $path) {
            # 파일 추가/수정의 경우
            git add "$path"
            git commit -m "Update: $((Split-Path $path -Leaf))"
        }
        else {
            # 파일 삭제의 경우
            git rm "$path"
            git commit -m "Delete: $((Split-Path $path -Leaf))"
        }

        # 원격 저장소와 동기화
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

# 이벤트 핸들러 등록
$action = {
    $path = $Event.SourceEventArgs.FullPath
    $changeType = $Event.SourceEventArgs.ChangeType
    
    if ($path -like "*node_modules*" -or $path -like "*.git*" -or $path -like "*복사본*") {
        return
    }
    
    Sync-Changes $changeType $path
}

# 이벤트 등록
$handlers = . {
    Register-ObjectEvent -InputObject $watcher -EventName Created -Action $action
    Register-ObjectEvent -InputObject $watcher -EventName Changed -Action $action
    Register-ObjectEvent -InputObject $watcher -EventName Deleted -Action $action
    Register-ObjectEvent -InputObject $watcher -EventName Renamed -Action $action
}

Write-Host "실시간 파일 감시 시작. 중지하려면 Ctrl+C를 누르세요." -ForegroundColor Green

try {
    # 초기 상태 동기화
    Write-Host "원격 저장소와 초기 동기화 중..." -ForegroundColor Yellow
    git pull origin main
    
    # 이벤트 대기
    while ($true) {
        Wait-Event -Timeout 1
        Get-Job | Where-Object { $_.State -eq 'Completed' } | Remove-Job
    }
}
finally {
    # 정리
    $handlers | ForEach-Object {
        Unregister-Event -SourceIdentifier $_.Name
    }
    Get-Job | Remove-Job -Force
    $watcher.Dispose()
    Write-Host "모니터링 종료" -ForegroundColor Yellow
}
