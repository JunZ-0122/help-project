@echo off
setlocal
set "LAUNCHER=%~dp0tools\hvigor_wrapper_launcher.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -File "%LAUNCHER%" %*
exit /b %ERRORLEVEL%
