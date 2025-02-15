# GitHub Desktop 자동 커밋 스크립트
$OutputEncoding = [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$env:LC_ALL = 'ko_KR.UTF-8'
$env:LANG = 'ko_KR.UTF-8'
[Console]::InputEncoding = [Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Git 인코딩 설정
git config --global core.quotepath off
git config --global i18n.commitencoding utf-8
git config --global i18n.logoutputencoding utf-8
git config --global core.precomposeunicode true

$ErrorActionPreference = "Stop"

# 저장소 경로
$repoPath = "D:\nCrom_server\xampp8.2\htdocs"
Set-Location $repoPath

while ($true) {
    try {
        # 변경사항 확인
        $status = git status --porcelain
        if ($status) {
            # 모든 변경사항 스테이징
            git add .
            
            # 현재 시간으로 커밋
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $commitMsg = "자동 커밋: $timestamp"
            $commitMsg | Out-File -FilePath "$env:TEMP\commit_msg.txt" -Encoding utf8
            git commit -F "$env:TEMP\commit_msg.txt"
            Remove-Item "$env:TEMP\commit_msg.txt"
            
            # GitHub로 푸시
            git push origin main
            
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
