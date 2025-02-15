# GitHub Desktop 자동 커밋 스크립트
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
            git commit -m "자동 커밋: $timestamp"
            
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
