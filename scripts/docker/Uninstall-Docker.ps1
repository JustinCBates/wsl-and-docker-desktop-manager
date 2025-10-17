param(
    [string]$BackupPath = "C:\DockerBackup",
    [switch]$Force = $false
)

# Set error handling
$ErrorActionPreference = "Stop"

function Write-Phase {
    param([string]$Message)
    Write-Output "`n📋 Docker Uninstall: $Message"
}

function Test-AdminRights {
    return ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Stop-DockerProcesses {
    Write-Phase "Stopping Docker processes"
    
    try {
        $dockerProcesses = @(
            "Docker Desktop",
            "dockerd",
            "docker-proxy",
            "vpnkit",
            "com.docker.*"
        )
        
        foreach ($processName in $dockerProcesses) {
            $processes = Get-Process -Name $processName -ErrorAction SilentlyContinue
            if ($processes) {
                Write-Output "Stopping $processName processes..."
                $processes | Stop-Process -Force
            }
        }
        
        # Stop Docker Desktop service if running
        $dockerService = Get-Service -Name "*docker*" -ErrorAction SilentlyContinue
        if ($dockerService) {
            Write-Output "Stopping Docker services..."
            $dockerService | Stop-Service -Force
        }
        
        Write-Output "✅ Docker processes stopped"
    }
    catch {
        Write-Warning "Error stopping Docker processes: $_"
    }
}

function Backup-DockerData {
    Write-Phase "Backing up Docker data"
    
    try {
        if (-not (Test-Path $BackupPath)) {
            New-Item -Path $BackupPath -ItemType Directory -Force | Out-Null
        }
        
        $dockerDataPath = "$env:USERPROFILE\.docker"
        $dockerAppDataPath = "$env:LOCALAPPDATA\Docker"
        
        if (Test-Path $dockerDataPath) {
            Write-Output "Backing up Docker user data..."
            $backupUserPath = Join-Path $BackupPath "docker-user-data"
            Copy-Item $dockerDataPath $backupUserPath -Recurse -Force
        }
        
        if (Test-Path $dockerAppDataPath) {
            Write-Output "Backing up Docker app data..."
            $backupAppPath = Join-Path $BackupPath "docker-app-data"
            Copy-Item $dockerAppDataPath $backupAppPath -Recurse -Force
        }
        
        Write-Output "✅ Docker data backed up to: $BackupPath"
    }
    catch {
        Write-Warning "Error backing up Docker data: $_"
    }
}

function Uninstall-DockerDesktop {
    Write-Phase "Uninstalling Docker Desktop"
    
    try {
        # Try to find Docker Desktop in installed programs
        $dockerProgram = Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -like "*Docker Desktop*" }
        
        if ($dockerProgram) {
            Write-Output "Uninstalling Docker Desktop via WMI..."
            $dockerProgram.Uninstall() | Out-Null
        } else {
            # Try alternative uninstall methods
            $uninstallPaths = @(
                "${env:ProgramFiles}\Docker\Docker\Docker Desktop Installer.exe",
                "${env:ProgramFiles(x86)}\Docker\Docker\Docker Desktop Installer.exe"
            )
            
            $installerPath = $uninstallPaths | Where-Object { Test-Path $_ } | Select-Object -First 1
            
            if ($installerPath) {
                Write-Output "Uninstalling Docker Desktop via installer..."
                $uninstallArgs = @("uninstall", "--quiet")
                Start-Process -FilePath $installerPath -ArgumentList $uninstallArgs -Wait
            } else {
                Write-Warning "Docker Desktop installer not found. Proceeding with manual cleanup..."
            }
        }
        
        Write-Output "✅ Docker Desktop uninstalled"
    }
    catch {
        Write-Warning "Error during Docker Desktop uninstall: $_"
    }
}

function Remove-DockerFiles {
    Write-Phase "Cleaning up Docker files"
    
    try {
        $dockerPaths = @(
            "$env:USERPROFILE\.docker",
            "$env:LOCALAPPDATA\Docker",
            "$env:APPDATA\Docker",
            "$env:ProgramFiles\Docker",
            "$env:ProgramFiles(x86)\Docker",
            "$env:PROGRAMDATA\Docker"
        )
        
        foreach ($path in $dockerPaths) {
            if (Test-Path $path) {
                Write-Output "Removing: $path"
                try {
                    Remove-Item $path -Recurse -Force
                }
                catch {
                    Write-Warning "Could not remove $path : $_"
                }
            }
        }
        
        # Remove Docker from PATH if present
        $currentPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
        if ($currentPath -like "*Docker*") {
            Write-Output "Cleaning Docker from system PATH..."
            $newPath = ($currentPath -split ';' | Where-Object { $_ -notlike "*Docker*" }) -join ';'
            [Environment]::SetEnvironmentVariable("PATH", $newPath, "Machine")
        }
        
        Write-Output "✅ Docker files cleaned up"
    }
    catch {
        Write-Warning "Some Docker files could not be removed: $_"
    }
}

function Remove-DockerServices {
    Write-Phase "Removing Docker services"
    
    try {
        $dockerServices = Get-Service -Name "*docker*" -ErrorAction SilentlyContinue
        
        foreach ($service in $dockerServices) {
            try {
                Write-Output "Removing service: $($service.Name)"
                Stop-Service $service.Name -Force -ErrorAction SilentlyContinue
                & sc.exe delete $service.Name
            }
            catch {
                Write-Warning "Could not remove service $($service.Name): $_"
            }
        }
        
        Write-Output "✅ Docker services removed"
    }
    catch {
        Write-Warning "Error removing Docker services: $_"
    }
}

# Main uninstallation logic
try {
    Write-Phase "Docker Uninstallation Started"
    
    if (-not (Test-AdminRights)) {
        throw "This script requires administrator privileges"
    }
    
    # Check if Docker is installed
    $dockerInstalled = $false
    try {
        & docker --version 2>$null | Out-Null
        $dockerInstalled = $LASTEXITCODE -eq 0
    }
    catch {
        $dockerInstalled = $false
    }
    
    if (-not $dockerInstalled -and -not $Force) {
        Write-Output "✅ Docker is not installed"
        exit 0
    }
    
    # Backup Docker data
    Backup-DockerData
    
    # Stop Docker processes
    Stop-DockerProcesses
    
    # Uninstall Docker Desktop
    Uninstall-DockerDesktop
    
    # Remove services
    Remove-DockerServices
    
    # Clean up files
    Remove-DockerFiles
    
    Write-Phase "Docker uninstallation completed successfully"
    Write-Output "`nDocker Desktop has been completely removed from your system."
    Write-Output "Your Docker data has been backed up to: $BackupPath"
    
    exit 0
}
catch {
    Write-Error "Docker uninstallation failed: $_"
    exit 1
}