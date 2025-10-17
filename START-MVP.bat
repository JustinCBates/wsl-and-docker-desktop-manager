@echo off
REM WSL & Docker Desktop Manager - MVP Launcher
REM Activates virtual environment and runs the menu system

cd /d "%~dp0"

echo Starting WSL ^& Docker Desktop Manager - MVP...
echo.

REM Check if virtual environment exists
if not exist ".venv\Scripts\activate.bat" (
    echo Error: Virtual environment not found!
    echo Please run: python -m venv .venv
    echo Then install dependencies: .venv\Scripts\activate ^&^& pip install questionary
    pause
    exit /b 1
)

REM Activate virtual environment and run the program
call .venv\Scripts\activate.bat
python wsl_docker_manager_mvp.py

REM Keep window open if there was an error
if errorlevel 1 (
    echo.
    echo Program exited with error code %errorlevel%
    pause
)

REM Deactivate virtual environment
call .venv\Scripts\deactivate.bat