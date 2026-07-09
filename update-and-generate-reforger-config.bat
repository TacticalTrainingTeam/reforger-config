@echo off

echo Updating repository...
git pull
if %ERRORLEVEL% neq 0 (
    echo Git pull failed.
    pause
    exit /b %ERRORLEVEL%
)

echo Generating Reforger config...
powershell -ExecutionPolicy Bypass -File .\generate_config.ps1
if %ERRORLEVEL% neq 0 (
    echo Configuration generation failed.
    pause
    exit /b %ERRORLEVEL%
)

echo Done.
pause