
@echo off
chcp 65001 > nul
setlocal enabledelayedexpansion

rem Git 설정
git config --global core.quotepath off
git config --global i18n.commitencoding utf-8
git config --global i18n.logoutputencoding utf-8
git config --global core.precomposeunicode true

rem 환경 변수 설정
set LANG=ko_KR.UTF-8
set LC_ALL=ko_KR.UTF-8

echo Git 실시간 동기화 시작...
echo 현재 폴더: %CD%
echo.

rem Git 저장소 확인
if not exist .git (
    echo 오류: Git 저장소를 찾을 수 없습니다.
    echo 이 스크립트는 Git 저장소 폴더에서 실행해야 합니다.
    pause
    exit /b 1
)

echo Git 저장소 확인 완료
echo 동기화를 시작합니다...
echo 종료하려면 Ctrl+C를 누르세요.
echo.

:LOOP
echo 원격 저장소와 동기화 중...
git pull origin main
if errorlevel 1 (
    echo 오류: Pull 작업 실패
    pause
    exit /b 1
)

rem 변경 사항 체크 및 동기화
for /f "tokens=*" %%a in ('git status --porcelain') do (
    echo 변경사항 발견, 커밋 중...
    git add .
    git commit -m "Update: Auto sync"
    
    echo Rebase 수행 중...
    git pull --rebase origin main
    
    echo 변경사항 Push 중...
    git push origin main
    
    echo 동기화 완료
    echo.
)

echo 5초 후 다시 확인합니다...
timeout /t 5 > nul
goto LOOP