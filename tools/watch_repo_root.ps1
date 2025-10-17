<#
.SYNOPSIS
  Watch repository root for new top-level directories and warn (optional desktop toast).

.DESCRIPTION
  Long-running PowerShell script that uses FileSystemWatcher to monitor the repository root
  for new top-level directories. Prints a console warning and optionally creates a desktop
  toast if the BurntToast module is available. Designed to be run as a background job or
  started on logon for persistent notifications.

.EXAMPLE
  pwsh -File .\tools\watch_repo_root.ps1
#>

param(
    [string]$RepoRoot = (Get-Location).Path,
    [string[]]$Allow = @('src','docs','tools','tests','.github','.vscode'),
    [switch]$Toast
)

Set-StrictMode -Version Latest

if ($Toast) {
    try {
        Import-Module BurntToast -ErrorAction Stop | Out-Null
    } catch {
        Write-Host "BurntToast module not found; desktop toasts disabled." -ForegroundColor Yellow
        $Toast = $false
    }
}

Write-Host "Watching repository root: $RepoRoot" -ForegroundColor Cyan
Write-Host "Allowed top-level names: $($Allow -join ', ')" -ForegroundColor Cyan

$fsw = New-Object System.IO.FileSystemWatcher $RepoRoot
$fsw.IncludeSubdirectories = $false
$fsw.NotifyFilter = [System.IO.NotifyFilters]'DirectoryName'
$fsw.EnableRaisingEvents = $true

Register-ObjectEvent $fsw Created -SourceIdentifier RepoWatcherCreated -Action {
    try {
        $path = $Event.SourceEventArgs.FullPath
        if (Test-Path $path -PathType Container) {
            $rel = $path.Substring($RepoRoot.Length).TrimStart('\','/')
            if ($rel -and -not $rel.Contains('\') -and -not $rel.Contains('/')) {
                if ($Allow -contains $rel) {
                    return
                }
                $msg = "WARNING: new top-level directory created: $rel"
                Write-Host $msg -ForegroundColor Yellow
                if ($Toast) { New-BurntToastNotification -Text 'Repo Watcher', $msg }
            }
        }
    } catch {
        Write-Host "Watcher error: $_" -ForegroundColor Red
    }
}

Write-Host "Press Ctrl+C to stop watcher." -ForegroundColor Green
try { while ($true) { Start-Sleep -Seconds 3600 } } finally { Unregister-Event -SourceIdentifier RepoWatcherCreated -ErrorAction SilentlyContinue }
