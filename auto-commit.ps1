# GitHub Desktop 자동 커밋 스크립트
# PowerShell 스크립트 인코딩 설정
$PSDefaultParameterValues['*:Encoding'] = 'utf8'
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$env:LC_ALL = 'ko_KR.UTF-8'
$env:LANG = 'ko_KR.UTF-8'
[Console]::InputEncoding = [Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$ErrorActionPreference = "Stop"

# Git 설정
#$env:GIT_TRACE = 1
$env:LANG = "ko_KR.UTF-8"
$env:LC_ALL = "ko_KR.UTF-8"

# 저장소 경로
$repoPath = "D:\nCrom_server\xampp8.2\htdocs"
Set-Location $repoPath

while ($true) {
    try {
        # 변경사항 확인 (출력 제한)
        $status = git -c advice.statusHints=false status --porcelain
        if ($status) {
            # 모든 변경사항 스테이징
            git add .
            
            # 현재 시간으로 커밋
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $commitMsg = "자동 커밋: $timestamp"
            
            # 환경 변수 설정하여 커밋 (출력 제한)
            $env:GIT_COMMITTER_ENCODING = "utf-8"
            $env:GIT_AUTHOR_ENCODING = "utf-8"
            git -c advice.statusHints=false commit -m "$commitMsg" | Out-Null
            
            # GitHub로 푸시 (출력 제한)
            git -c advice.statusHints=false push origin main --quiet
            
            Write-Host "변경사항이 커밋되었습니다: $timestamp" -ForegroundColor Green
        }
        
        # 30초 대기
        Start-Sleep -Seconds 30
    }
    catch {
        Write-Host "오류 발생: $_" -ForegroundColor Red
        Start-Sleep -Seconds 10
    }
}
