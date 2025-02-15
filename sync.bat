
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
echo 종료하려면 Ctrl+C를 누르세요.

:LOOP
git pull origin main

rem 변경 사항 체크 및 동기화
for /f "tokens=*" %%a in ('git status --porcelain') do (
    git add .
    git commit -m "Update: Auto sync"
    git pull --rebase origin main
    git push origin main
    echo 동기화 완료
)

timeout /t 5 > nul
goto LOOP