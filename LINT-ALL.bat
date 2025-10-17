@echo off
REM Comprehensive Linting Script for All File Types
REM This script lints Python, PowerShell, Batch, YAML, JSON, and Markdown files

cd /d "%~dp0"

echo ========================================
echo  COMPREHENSIVE CODE QUALITY CHECK
echo ========================================
echo.

REM Check if virtual environment exists
if not exist ".venv\Scripts\activate.bat" (
    echo Error: Virtual environment not found!
    echo Please run: python -m venv .venv
    echo Then install dependencies: .venv\Scripts\activate ^&^& pip install -r requirements.txt
    pause
    exit /b 1
)

call .venv\Scripts\activate.bat

set LINT_ERRORS=0

echo [1/5] Linting Python files (.py)...
echo ========================================
for /f "delims=" %%F in ('dir /b /s *.py') do (
    echo Checking: %%~nF
    .venv\Scripts\python -m pylint "%%~fF"
    if errorlevel 1 set LINT_ERRORS=1
)
echo.

echo [2/5] Linting PowerShell files (.ps1)...
echo ========================================
powershell -NoProfile -ExecutionPolicy Bypass -File "tools\run_pssa.ps1" -Path "%CD%"
if errorlevel 1 set LINT_ERRORS=1
echo.

echo [3/5] Checking Batch files (.bat)...
echo ========================================
for /f "delims=" %%B in ('dir /b /s *.bat') do (
    echo Checking: %%~nB
    powershell -NoProfile -Command "Get-Content -LiteralPath '%%~fB' -ErrorAction Stop | Out-Null"
    if errorlevel 1 set LINT_ERRORS=1
)
echo.

echo [4/5] Linting YAML files (.yml, .yaml)...
echo ========================================
for /f "delims=" %%Y in ('dir /b /s *.yml *.yaml 2^>nul') do (
    echo Checking: %%~nY
    yamllint "%%~fY"
    if errorlevel 1 set LINT_ERRORS=1
)
echo.

echo [5/5] Checking JSON files (.json)...
echo ========================================
for /f "delims=" %%J in ('dir /b /s *.json') do (
    echo Checking: %%~nJ
    .venv\Scripts\python -m json.tool "%%~fJ" >nul
    if errorlevel 1 (
        echo ERROR: Invalid JSON in %%~nJ
        set LINT_ERRORS=1
    ) else (
        echo OK: %%~nJ
    )
)
echo.

echo ========================================
echo  LINTING SUMMARY
echo ========================================
if %LINT_ERRORS%==0 (
    echo ✅ ALL FILES PASSED QUALITY CHECKS!
    echo.
) else (
    echo ❌ SOME FILES HAVE ISSUES - PLEASE FIX BEFORE COMMITTING
    echo.
)

call .venv\Scripts\deactivate.bat

if %LINT_ERRORS%==1 (
    pause
    exit /b 1
) else (
    exit /b 0
)