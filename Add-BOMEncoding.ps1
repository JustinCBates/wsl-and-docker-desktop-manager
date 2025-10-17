# Add UTF-8 BOM to PowerShell files
# This fixes PSUseBOMForUnicodeEncodedFile warnings

$files = @(
    "INSTALL-DOCKER-DESKTOP.ps1",
    "INSTALL-WSL2-DYNAMIC.ps1",
    "MASTER-REINSTALL-v2.ps1",
    "MASTER-REINSTALL.ps1",
    "UNINSTALL-DOCKER-DESKTOP.ps1",
    "UNINSTALL-WSL.ps1",
    "scripts\Install-Orchestrator.ps1",
    "scripts\Uninstall-Orchestrator.ps1",
    "scripts\backup\Backup-Data.ps1",
    "scripts\backup\Restore-Data.ps1",
    "scripts\docker\Install-Docker.ps1",
    "scripts\docker\Uninstall-Docker.ps1",
    "scripts\status\Get-SystemStatus.ps1",
    "scripts\wsl\Install-WSL.ps1",
    "scripts\wsl\Uninstall-WSL.ps1"
)

$projectRoot = $PSScriptRoot
$utf8WithBom = New-Object System.Text.UTF8Encoding $true

$successCount = 0
$errorCount = 0

foreach ($file in $files) {
    $fullPath = Join-Path $projectRoot $file
    
    if (Test-Path $fullPath) {
        try {
            $content = Get-Content -Path $fullPath -Raw
            [System.IO.File]::WriteAllText($fullPath, $content, $utf8WithBom)
            Write-Host "âœ… Added BOM to: $file" -ForegroundColor Green
            $successCount++
        }
        catch {
            Write-Host "âŒ Failed to process: $file - $_" -ForegroundColor Red
            $errorCount++
        }
    }
    else {
        Write-Host "âš ï¸  File not found: $file" -ForegroundColor Yellow
        $errorCount++
    }
}

Write-Host "`n=== SUMMARY ===" -ForegroundColor Cyan
Write-Host "Successfully processed: $successCount files" -ForegroundColor Green
Write-Host "Errors: $errorCount files" -ForegroundColor $(if($errorCount -gt 0){"Red"}else{"Green"})
