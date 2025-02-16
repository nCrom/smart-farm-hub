
@echo off
chcp 65001
echo Git 파일 감시 시스템 시작
echo.
echo 환경 변수 확인 중...
if not defined GITHUB_TOKEN (
    echo 오류: GITHUB_TOKEN이 설정되지 않았습니다.
    echo 시스템 환경 변수에 GITHUB_TOKEN을 설정해주세요.
    pause
    exit /b 1
)

echo GitHub 토큰 확인 완료
echo.
echo 파일 감시를 시작합니다...
"D:\nCrom_server\xampp8.2\php\php.exe" file_watcher.php
pause
