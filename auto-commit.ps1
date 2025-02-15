
# PowerShell 스크립트 인코딩 설정
$PSDefaultParameterValues['*:Encoding'] = 'utf8'
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$ErrorActionPreference = "Stop"

# Git 환경 변수 설정
$env:LANG = "ko_KR.UTF-8"
$env:LC_ALL = "ko_KR.UTF-8"
$env:GIT_COMMITTER_ENCODING = "UTF-8"
$env:GIT_AUTHOR_ENCODING = "UTF-8"

# 저장소 경로
$repoPath = "D:\nCrom_server\xampp8.2\htdocs"
Set-Location $repoPath

# 로그 파일 설정
$logFile = "git-sync.log"

while ($true) {
    try {
        # 변경사항 확인 (출력 제한)
        $status = git -c advice.statusHints=false status --porcelain
        if ($status) {
            # Git 설정 확인 및 설정
            git config --global core.quotepath off
            git config --global i18n.commitencoding utf-8
            git config --global i18n.logoutputencoding utf-8
            git config --global core.precomposeunicode true
            
            # 모든 변경사항 스테이징
            git add .
            
            # 현재 시간으로 커밋
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $commitMessage = "[자동] $timestamp 에 변경사항 감지"
            
            # 커밋 실행 (UTF-8 메시지 사용)
            git -c i18n.commitencoding=utf-8 commit -m $commitMessage | Out-Null
            
            # GitHub로 푸시 (출력 제한)
            git -c advice.statusHints=false push origin main --quiet
            
            # 로그 파일에 기록
            $message = "====================`n"
            $message += "시간: $timestamp`n"
            $message += "상태: 성공`n"
            $message += "메시지: $commitMessage`n"
            $message += "====================`n"
            Add-Content -Path $logFile -Value $message -Encoding UTF8
            
            # 콘솔에 출력
            Write-Output "-------------------"
            Write-Output "시간: $timestamp"
            Write-Output "상태: 성공"
            Write-Output "메시지: $commitMessage"
            Write-Output "-------------------"
        }
        
        # 30초 대기
        Start-Sleep -Seconds 30
    }
    catch {
        $errorMsg = "====================`n"
        $errorMsg += "시간: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n"
        $errorMsg += "상태: 오류`n"
        $errorMsg += "메시지: $_`n"
        $errorMsg += "====================`n"
        
        # 로그 파일에 기록
        Add-Content -Path $logFile -Value $errorMsg -Encoding UTF8
        
        # 콘솔에 출력
        Write-Output "-------------------"
        Write-Output "상태: 오류"
        Write-Output "메시지: $_"
        Write-Output "-------------------"
        
        Start-Sleep -Seconds 10
    }
}
