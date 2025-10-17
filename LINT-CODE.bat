@echo off
REM Python Linting Script
REM Runs pylint on Python files with consistent configuration

cd /d "%~dp0"

if not exist ".venv\Scripts\activate.bat" (
    echo Error: Virtual environment not found!
    echo Please run: python -m venv .venv
    echo Then install dependencies: .venv\Scripts\activate ^&^& pip install -r requirements.txt
    pause
    exit /b 1
)

call .venv\Scripts\activate.bat

echo Running pylint on Python files...
echo.

if "%1"=="" (
    echo Linting all Python files in project...
    for /f "delims=" %%F in ('dir /b /s *.py') do (
        echo ========================
        echo Checking: %%~nF
        echo ========================
        .venv\Scripts\python -m pylint "%%~fF"
    )
    echo.
) else (
    echo Linting: %1
    pylint %1
)

echo.
echo Linting complete!
pause

call .venv\Scripts\deactivate.bat