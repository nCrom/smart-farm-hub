@echo off
chcp 65001 > nul
set LANG=en_US.UTF-8
set LC_ALL=en_US.UTF-8
set GIT_COMMITTER_ENCODING=UTF-8
set GIT_AUTHOR_ENCODING=UTF-8
set GIT_TERMINAL_PROMPT=0
powershell -NoProfile -ExecutionPolicy Bypass -NoExit -Command "& {$OutputEncoding = [Console]::OutputEncoding = [System.Text.Encoding]::UTF8; & '%~dp0auto-commit.ps1'}"
pause
