param(
    [string]$BackupPath = "C:\DockerBackup",
    [switch]$Force = $false
)

# Set error handling
$ErrorActionPreference = "Stop"

function Write-Phase {
    param([string]$Message)
    Write-Output "`n📋 Restore: $Message"
}

function Test-DockerRunning {
    try {
        & docker info 2>$null | Out-Null
        return $LASTEXITCODE -eq 0
    }
    catch {
        return $false
    }
}

function Test-BackupValid {
    param([string]$BackupDir)
    
    try {
        $manifestPath = Join-Path $BackupDir "backup-manifest.json"
        if (-not (Test-Path $manifestPath)) {
            return $false
        }
        
        $requiredDirs = @("images", "volumes", "config")
        foreach ($dir in $requiredDirs) {
            $dirPath = Join-Path $BackupDir $dir
            if (-not (Test-Path $dirPath)) {
                return $false
            }
        }
        
        return $true
    }
    catch {
        return $false
    }
}

function Show-BackupInfo {
    param([string]$BackupDir)
    
    try {
        $manifestPath = Join-Path $BackupDir "backup-manifest.json"
        if (Test-Path $manifestPath) {
            $manifest = Get-Content $manifestPath | ConvertFrom-Json
            
            Write-Output "`n📋 Backup Information:"
            Write-Output "  Backup Date: $($manifest.BackupDate)"
            Write-Output "  Original Computer: $($manifest.SystemInfo.ComputerName)"
            Write-Output "  Original User: $($manifest.SystemInfo.UserName)"
            Write-Output "  Docker Version: $($manifest.DockerVersion)"
            Write-Output ""
        }
    }
    catch {
        Write-Warning "Could not read backup manifest"
    }
}

function Restore-DockerImages {
    param([string]$BackupDir)
    
    Write-Phase "Restoring Docker images"
    
    try {
        $imagesBackupPath = Join-Path $BackupDir "images"
        $imageListFile = Join-Path $imagesBackupPath "image-list.txt"
        
        if (-not (Test-Path $imageListFile)) {
            Write-Output "No image list found, skipping image restore"
            return
        }
        
        $imageList = Get-Content $imageListFile
        if (-not $imageList) {
            Write-Output "No images to restore"
            return
        }
        
        Write-Output "Restoring $($imageList.Count) Docker images..."
        
        foreach ($image in $imageList) {
            $safeImageName = $image -replace '[/\\:*?"<>|]', '_'
            $imagePath = Join-Path $imagesBackupPath "$safeImageName.tar"
            
            if (Test-Path $imagePath) {
                Write-Output "Restoring image: $image"
                & docker load -i $imagePath
                
                if ($LASTEXITCODE -ne 0) {
                    Write-Warning "Failed to restore image: $image"
                }
            } else {
                Write-Warning "Image backup file not found: $imagePath"
            }
        }
        
        Write-Output "✅ Docker images restored"
    }
    catch {
        Write-Warning "Error restoring Docker images: $_"
    }
}

function Restore-DockerVolumes {
    param([string]$BackupDir)
    
    Write-Phase "Restoring Docker volumes"
    
    try {
        $volumesBackupPath = Join-Path $BackupDir "volumes"
        $volumeFiles = Get-ChildItem $volumesBackupPath -Filter "*.tar" -ErrorAction SilentlyContinue
        
        if (-not $volumeFiles) {
            Write-Output "No volume backups found"
            return
        }
        
        Write-Output "Restoring $($volumeFiles.Count) Docker volumes..."
        
        foreach ($volumeFile in $volumeFiles) {
            $volumeName = [System.IO.Path]::GetFileNameWithoutExtension($volumeFile.Name)
            
            Write-Output "Restoring volume: $volumeName"
            
            # Create the volume first
            & docker volume create $volumeName 2>$null
            
            # Restore volume data using a temporary container
            & docker run --rm -v "${volumeName}:/data" -v "${volumesBackupPath}:/backup" alpine tar -xzf "/backup/$($volumeFile.Name)" -C /data
            
            if ($LASTEXITCODE -ne 0) {
                Write-Warning "Failed to restore volume: $volumeName"
            }
        }
        
        Write-Output "✅ Docker volumes restored"
    }
    catch {
        Write-Warning "Error restoring Docker volumes: $_"
    }
}

function Restore-DockerConfigs {
    param([string]$BackupDir)
    
    Write-Phase "Restoring Docker configuration"
    
    try {
        $configBackupPath = Join-Path $BackupDir "config"
        
        # Restore Docker user configuration
        $dockerUserConfigBackup = Join-Path $configBackupPath "docker-user-config"
        if (Test-Path $dockerUserConfigBackup) {
            $dockerConfigPath = "$env:USERPROFILE\.docker"
            
            if (Test-Path $dockerConfigPath) {
                if (-not $Force) {
                    Write-Output "Docker user configuration already exists. Use -Force to overwrite."
                } else {
                    Write-Output "Restoring Docker user configuration..."
                    Remove-Item $dockerConfigPath -Recurse -Force
                    Copy-Item $dockerUserConfigBackup $dockerConfigPath -Recurse -Force
                }
            } else {
                Write-Output "Restoring Docker user configuration..."
                Copy-Item $dockerUserConfigBackup $dockerConfigPath -Recurse -Force
            }
        }
        
        # Restore Docker Desktop configuration
        $dockerDesktopConfigBackup = Join-Path $configBackupPath "docker-desktop-config"
        if (Test-Path $dockerDesktopConfigBackup) {
            $dockerDesktopConfig = "$env:APPDATA\Docker"
            
            if (Test-Path $dockerDesktopConfig) {
                if (-not $Force) {
                    Write-Output "Docker Desktop configuration already exists. Use -Force to overwrite."
                } else {
                    Write-Output "Restoring Docker Desktop configuration..."
                    Remove-Item $dockerDesktopConfig -Recurse -Force
                    Copy-Item $dockerDesktopConfigBackup $dockerDesktopConfig -Recurse -Force
                }
            } else {
                Write-Output "Restoring Docker Desktop configuration..."
                Copy-Item $dockerDesktopConfigBackup $dockerDesktopConfig -Recurse -Force
            }
        }
        
        Write-Output "✅ Docker configuration restored"
    }
    catch {
        Write-Warning "Error restoring Docker configuration: $_"
    }
}

# Main restore logic
try {
    Write-Phase "Docker Data Restore Started"
    
    # Validate backup directory
    if (-not (Test-Path $BackupPath)) {
        throw "Backup directory not found: $BackupPath"
    }
    
    if (-not (Test-BackupValid -BackupDir $BackupPath)) {
        throw "Invalid or corrupted backup directory: $BackupPath"
    }
    
    # Show backup information
    Show-BackupInfo -BackupDir $BackupPath
    
    # Check if Docker is running
    if (-not (Test-DockerRunning)) {
        throw "Docker is not running. Please start Docker Desktop and try again."
    }
    
    # Confirm restore operation
    if (-not $Force) {
        Write-Output "⚠️  This will restore Docker data from backup and may overwrite existing data."
        $confirm = Read-Host "Do you want to continue? (y/N)"
        if ($confirm -ne 'y' -and $confirm -ne 'Y') {
            Write-Output "Restore operation cancelled"
            exit 0
        }
    }
    
    # Restore Docker images
    Restore-DockerImages -BackupDir $BackupPath
    
    # Restore Docker volumes
    Restore-DockerVolumes -BackupDir $BackupPath
    
    # Restore Docker configurations
    Restore-DockerConfigs -BackupDir $BackupPath
    
    Write-Phase "Docker data restore completed successfully"
    Write-Output "📁 Restored from: $BackupPath"
    Write-Output "`n🔄 Docker Desktop may need to be restarted to apply configuration changes."
    Write-Output "Your Docker environment has been restored from backup."
    
    exit 0
}
catch {
    Write-Error "Docker restore failed: $_"
    exit 1
}