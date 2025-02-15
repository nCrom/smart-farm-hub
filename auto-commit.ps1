# PowerShell 스크립트 인코딩 설정
$PSDefaultParameterValues['*:Encoding'] = 'utf8'
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$ErrorActionPreference = "Stop"

# Git 설정
#$env:GIT_TRACE = 1

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
            # 모든 변경사항 스테이징
            git add .
            
            # 현재 시간으로 커밋
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            
            # 커밋 실행 (출력 제한)
            git -c advice.statusHints=false commit -m "Update: $timestamp" | Out-Null
            
            # GitHub로 푸시 (출력 제한)
            git -c advice.statusHints=false push origin main --quiet
            
            # 로그 파일에 기록
            $message = "====================`n"
            $message += "Time: $timestamp`n"
            $message += "Status: Success`n"
            $message += "====================`n"
            Add-Content -Path $logFile -Value $message -Encoding UTF8
            
            # 콘솔에 출력
            Write-Output "-------------------"
            Write-Output "Time: $timestamp"
            Write-Output "Status: Success"
            Write-Output "-------------------"
        }
        
        # 30초 대기
        Start-Sleep -Seconds 30
    }
    catch {
        $errorMsg = "====================`n"
        $errorMsg += "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n"
        $errorMsg += "Status: Error`n"
        $errorMsg += "Message: $_`n"
        $errorMsg += "====================`n"
        
        # 로그 파일에 기록
        Add-Content -Path $logFile -Value $errorMsg -Encoding UTF8
        
        # 콘솔에 출력
        Write-Output "-------------------"
        Write-Output "Status: Error"
        Write-Output "Message: $_"
        Write-Output "-------------------"
        
        Start-Sleep -Seconds 10
    }
}
