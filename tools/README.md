Local test instructions

This repository's tests are authored for PowerShell 7 (pwsh) and Pester 5. To run them locally on Windows, follow these steps.

1) Install PowerShell 7 (if not installed)

- Recommended: use winget (Windows 10/11)

```powershell
# Open an elevated PowerShell prompt
winget install --id Microsoft.PowerShell -e
```

Or download the MSI from https://aka.ms/powershell and run the installer.

2) Run tests under pwsh

```powershell
# In a regular (non-elevated) PowerShell session
pwsh -NoProfile -Command "& { Install-Module -Name Pester -Scope CurrentUser -Force; Import-Module Pester -Force; Invoke-Pester -Script 'tests' }"
```

3) Alternative: use the helper script

```powershell
pwsh -File tools\run_tests_pwsh.ps1
```

Notes
- CI (GitHub Actions) will also run the tests under `windows-latest` with PowerShell 7 and Pester 5 using `.github/workflows/pwsh-tests.yml`.
- If you cannot install pwsh, tests can be adapted to Pester 3/PowerShell 5 but that requires test syntax changes (I can do that if you prefer).