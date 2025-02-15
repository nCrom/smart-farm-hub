# 실시간 Git 동기화 스크립트
$watchPath = "."
$filter = "*.*"
$lastSync = Get-Date

# 출력 인코딩을 UTF-8로 설정
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
chcp 65001 | Out-Null

# FileSystemWatcher 객체 생성
$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $watchPath
$watcher.Filter = $filter
$watcher.IncludeSubdirectories = $true
$watcher.EnableRaisingEvents = $true

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
    Write-Host "변경 감지: $path ($changeType)"
    
    # Git 명령어 실행
    Start-ThreadJob -ScriptBlock {
        git pull origin main --rebase
        git add .
        $env:LC_ALL = 'ko_KR.UTF-8'
        $commitMessage = "자동 동기화: $using:changeType - $((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))"
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

Write-Host "실시간 파일 변경 감지 시작... (종료하려면 Ctrl+C를 누르세요)"
try {
    do {
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
    Write-Host "감지 종료"
}
