@echo off
chcp 65001 > nul
set LANG=ko_KR.UTF-8
set LC_ALL=ko_KR.UTF-8
set GIT_COMMITTER_ENCODING=utf-8
set GIT_AUTHOR_ENCODING=utf-8
set GIT_TERMINAL_PROMPT=0
powershell -NoProfile -ExecutionPolicy Bypass -NoExit -Command "& {$PSDefaultParameterValues['*:Encoding'] = 'utf8'; [Console]::OutputEncoding = [System.Text.Encoding]::UTF8; & '%~dp0auto-commit.ps1'}"
pause
