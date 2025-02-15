@echo off
chcp 65001 > nul
set PYTHONIOENCODING=utf-8
set LANG=ko_KR.UTF-8
powershell -NoProfile -ExecutionPolicy Bypass -NoExit -Command "& {$OutputEncoding = [Console]::OutputEncoding = [System.Text.Encoding]::UTF8; & '%~dp0auto-commit.ps1'}"
pause
