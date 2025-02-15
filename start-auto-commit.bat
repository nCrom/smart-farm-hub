@echo off
chcp 65001 > nul
set GIT_TERMINAL_PROMPT=0
powershell -NoProfile -ExecutionPolicy Bypass -NoExit -Command "& {$OutputEncoding = [Console]::OutputEncoding = [System.Text.Encoding]::UTF8; & '%~dp0auto-commit.ps1'}"
pause
