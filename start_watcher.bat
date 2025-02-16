
@echo off
chcp 65001
echo Git 설정을 시작합니다...
"D:\nCrom_server\xampp8.2\php\php.exe" setup.php
if errorlevel 1 (
    echo Git 설정 중 오류가 발생했습니다.
    pause
    exit /b 1
)
echo Git 설정이 완료되었습니다.
echo.
echo 파일 감시를 시작합니다...
"D:\nCrom_server\xampp8.2\php\php.exe" file_watcher.php
pause
