# Git 실시간 동기화 스크립트
$ErrorActionPreference = "Stop"

# 인코딩 설정
$PSDefaultParameterValues['*:Encoding'] = 'utf8'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

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
    param($changeType, $path)
    
    if ($path -like "*.git*" -or $path -like "*node_modules*") {
        Write-Host "무시된 파일: $path" -ForegroundColor Gray
        return
    }

    Write-Host "`n변경 감지: [$changeType] $path" -ForegroundColor Cyan

    try {
        # 변경 사항 확인
        $status = git status --porcelain
        if (-not $status) {
            Write-Host "변경 사항 없음" -ForegroundColor Gray
            return
        }

        Write-Host "변경 사항:" -ForegroundColor Yellow
        git status --short

        # 파일 처리
        if (Test-Path $path) {
            Write-Host "파일 추가 중..." -ForegroundColor Yellow
            git add "$path"
            git commit -m "변경: $((Split-Path $path -Leaf))"
        }
        else {
            Write-Host "파일 삭제 중..." -ForegroundColor Yellow
            git rm "$path"
            git commit -m "삭제: $((Split-Path $path -Leaf))"
        }
        
        # 원격 저장소 동기화
        Write-Host "원격 저장소와 동기화 중..." -ForegroundColor Yellow
        git pull --rebase origin main
        git push origin main
        
        Write-Host "동기화 완료" -ForegroundColor Green
    }
    catch {
        Write-Host "오류 발생:" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        Write-Host "`nGit 상태:" -ForegroundColor Yellow
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

$handlers += Register-ObjectEvent $watcher "Created" -Action {
    Sync-Changes "생성됨" $Event.SourceEventArgs.FullPath
}

$handlers += Register-ObjectEvent $watcher "Changed" -Action {
    Sync-Changes "수정됨" $Event.SourceEventArgs.FullPath
}

$handlers += Register-ObjectEvent $watcher "Deleted" -Action {
    Sync-Changes "삭제됨" $Event.SourceEventArgs.FullPath
}

Write-Host "Git 실시간 동기화 시작 (Ctrl+C로 종료)" -ForegroundColor Green
Write-Host "감시 중인 경로: $(Resolve-Path $watchPath)" -ForegroundColor Yellow

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