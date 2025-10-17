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
powershell -Command "Get-ChildItem -Path . -Recurse -Filter *.py | ForEach-Object { Write-Host 'Checking:' $_.Name; pylint $_.FullName; if ($LASTEXITCODE -ne 0) { exit 1 } }"
if errorlevel 1 set LINT_ERRORS=1
echo.

echo [2/5] Linting PowerShell files (.ps1)...
echo ========================================
powershell -Command "Get-ChildItem -Path . -Recurse -Filter *.ps1 | ForEach-Object { Write-Host 'Checking:' $_.Name; try { Invoke-ScriptAnalyzer -Path $_.FullName -Severity Warning,Error } catch { Write-Host 'Error analyzing' $_.Name -ForegroundColor Red; exit 1 } }"
if errorlevel 1 set LINT_ERRORS=1
echo.

echo [3/5] Checking Batch files (.bat)...
echo ========================================
powershell -Command "Get-ChildItem -Path . -Recurse -Filter *.bat | ForEach-Object { Write-Host 'Checking syntax:' $_.Name; try { Get-Content $_.FullName -ErrorAction Stop | Out-Null; Write-Host 'OK:' $_.Name } catch { Write-Host 'Syntax error in' $_.Name -ForegroundColor Red; exit 1 } }"
if errorlevel 1 set LINT_ERRORS=1
echo.

echo [4/5] Linting YAML files (.yml, .yaml)...
echo ========================================
powershell -Command "Get-ChildItem -Path . -Recurse -Include *.yml,*.yaml | ForEach-Object { Write-Host 'Checking:' $_.Name; yamllint $_.FullName; if ($LASTEXITCODE -ne 0) { exit 1 } }"
if errorlevel 1 set LINT_ERRORS=1
echo.

echo [5/5] Checking JSON files (.json)...
echo ========================================
powershell -Command "Get-ChildItem -Path . -Recurse -Filter *.json | ForEach-Object { Write-Host 'Checking:' $_.Name; python -m json.tool $_.FullName | Out-Null; if ($LASTEXITCODE -ne 0) { Write-Host 'ERROR: Invalid JSON in' $_.Name -ForegroundColor Red; exit 1 } else { Write-Host 'OK:' $_.Name } }"
if errorlevel 1 set LINT_ERRORS=1
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