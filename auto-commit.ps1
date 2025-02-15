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
            
            # 커밋 실행 (출력 제한)
            git -c advice.statusHints=false commit -m "Auto commit: $timestamp" | Out-Null
            
            # GitHub로 푸시 (출력 제한)
            git -c advice.statusHints=false push origin main --quiet
            
            Write-Output "============================================="
            Write-Output "새로운 변경사항이 커밋되었습니다"
            Write-Output "시간: $timestamp"
            Write-Output "============================================="
        }
        
        # 30초 대기
        Start-Sleep -Seconds 30
    }
    catch {
        Write-Output "============================================="
        Write-Output "오류가 발생했습니다"
        Write-Output "$_"
        Write-Output "============================================="
        Start-Sleep -Seconds 10
    }
}
