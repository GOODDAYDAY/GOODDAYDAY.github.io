@echo off
setlocal enabledelayedexpansion

REM ============================================
REM PlantUML SVG Generator - Windows
REM Generates SVG files from all .puml files
REM ============================================

set "SCRIPT_DIR=%~dp0"
set "PROJECT_ROOT=%SCRIPT_DIR%.."
set "IMAGES_DIR=%PROJECT_ROOT%\static\images"
set "PLANTUML_JAR=%IMAGES_DIR%\plantuml.jar"
set "PLANTUML_URL=https://github.com/plantuml/plantuml/releases/download/v1.2024.7/plantuml-1.2024.7.jar"

REM Check if Java is installed
where java >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Java is not installed or not in PATH
    echo Please install Java and try again
    exit /b 1
)

REM Download PlantUML if not exists
if not exist "%PLANTUML_JAR%" (
    echo [INFO] PlantUML jar not found, downloading...
    curl -L -o "%PLANTUML_JAR%" "%PLANTUML_URL%"
    if %ERRORLEVEL% neq 0 (
        echo [ERROR] Failed to download PlantUML
        exit /b 1
    )
    echo [INFO] PlantUML downloaded successfully
)

REM Process each subdirectory
echo [INFO] Scanning for .puml files in %IMAGES_DIR%...
set "COUNT=0"

for /d %%D in ("%IMAGES_DIR%\*") do (
    if exist "%%D\*.puml" (
        echo [INFO] Processing folder: %%~nxD
        for %%F in ("%%D\*.puml") do (
            echo   - Generating: %%~nxF
            java -jar "%PLANTUML_JAR%" -tsvg "%%F"
            set /a COUNT+=1
        )
    )
)

echo [INFO] Done! Generated %COUNT% SVG files.
