@echo off
REM ============================================
REM Hugo Local Dev Server (with drafts)
REM ============================================

set "SCRIPT_DIR=%~dp0"
set "PROJECT_ROOT=%SCRIPT_DIR%.."

cd /d "%PROJECT_ROOT%"
echo Starting Hugo dev server with drafts...
echo Site will be available at http://localhost:1313
echo Press Ctrl+C to stop.
echo.
hugo server --buildDrafts --disableFastRender
