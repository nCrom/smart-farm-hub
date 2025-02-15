 # 실시간 Git 동기화 스크립트
# PowerShell 스크립트 인코딩 설정
$PSDefaultParameterValues['*:Encoding'] = 'utf8'
[System.Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$watchPath = "."
$filter = "*.*"
$lastSync = Get-Date
$lastGitCheck = Get-Date

# 출력 인코딩을 UTF-8로 설정
Write-Host "PowerShell 콘솔 코드 페이지를 UTF-8로 변경합니다..."
$originalCP = [System.Console]::OutputEncoding
try {
    [System.Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $Host.UI.RawUI.OutputEncoding = [System.Text.Encoding]::UTF8
    chcp 65001 | Out-Null
    Write-Host "인코딩이 UTF-8로 설정되었습니다."
} catch {
    Write-Host "인코딩 설정 중 오류 발생: $_"
    [System.Console]::OutputEncoding = $originalCP
}

# FileSystemWatcher 객체 생성
$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $watchPath
$watcher.Filter = $filter
$watcher.IncludeSubdirectories = $true
$watcher.EnableRaisingEvents = $true

# GitHub 변경사항 확인 함수
function Check-GitHubChanges {
    try {
        git fetch origin
        $status = git status
        if ($status -like "*Your branch is behind*") {
            Write-Host "GitHub 변경사항 감지. 동기화 중..." -ForegroundColor Yellow
            git pull origin main --rebase
            Write-Host "GitHub 동기화 완료" -ForegroundColor Green
        }
    } catch {
        Write-Host "GitHub 동기화 중 오류 발생: $_" -ForegroundColor Red
    }
}

# 변경 이벤트 처리
$action = {
    $path = $Event.SourceEventArgs.FullPath
    $changeType = $Event.SourceEventArgs.ChangeType
    $now = Get-Date
    
    # node_modules 폴더 변경은 무시
    if ($path -like "*node_modules*") {
        return
    }
    
    # .git 폴더 변경은 무시
    if ($path -like "*.git*") {
        return
    }
    
    # 마지막 동기화로부터 0.5초 이상 지났는지 확인
    if (($now - $script:lastSync).TotalMilliseconds -lt 500) {
        return
    }
    
    $script:lastSync = $now
    Write-Host "로컬 변경 감지: $path ($changeType)" -ForegroundColor Cyan
    
    # Git 명령어 실행
    Start-ThreadJob -ScriptBlock {
        $env:LC_ALL = 'ko_KR.UTF-8'
        git add .
        $commitMessage = "자동 동기화: $using:changeType - $((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))"
        $commitMessage = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::UTF8.GetBytes($commitMessage))
        git -c i18n.logoutputencoding=utf-8 commit -m $commitMessage
        git push origin main
    }
}

# 이벤트 등록
$handlers = . {
    Register-ObjectEvent -InputObject $watcher -EventName Created -Action $action
    Register-ObjectEvent -InputObject $watcher -EventName Changed -Action $action
    Register-ObjectEvent -InputObject $watcher -EventName Deleted -Action $action
    Register-ObjectEvent -InputObject $watcher -EventName Renamed -Action $action
}

Write-Host "실시간 파일 변경 감지 시작... (종료하려면 Ctrl+C를 누르세요)" -ForegroundColor Green
try {
    do {
        $now = Get-Date
        # 2초마다 GitHub 변경사항 확인
        if (($now - $script:lastGitCheck).TotalSeconds -ge 2) {
            $script:lastGitCheck = $now
            Check-GitHubChanges
        }
        
        Wait-Event -Timeout 0.1
        # 백그라운드 작업 정리
        Get-Job | Where-Object { $_.State -eq 'Completed' } | Remove-Job
    } while ($true)
} finally {
    # 정리
    $handlers | ForEach-Object {
        Unregister-Event -SourceIdentifier $_.Name
    }
    Get-Job | Remove-Job -Force
    $watcher.Dispose()
    Write-Host "감지 종료" -ForegroundColor Yellow
    # 원래 인코딩으로 복원
    [System.Console]::OutputEncoding = $originalCP
}