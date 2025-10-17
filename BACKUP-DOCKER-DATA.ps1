<#
ARCHIVE STUB: BACKUP-DOCKER-DATA.ps1

The implementation previously lived here but has been removed from the
repository root. MANAGER.ps1 is now the single canonical entrypoint. The
functional implementations live under `scripts/` (or will be added there).

This stub is intentionally safe and non-destructive. Run `MANAGER.ps1` to
access the UI and mocked flows.
#>

Write-Output "This script has been removed from the repository root. Use MANAGER.ps1 as the canonical entrypoint."
exit 0
<##
SYNOPSIS
    Minimal, test-friendly Docker backup helper (MVP)

DESCRIPTION
    This lightweight version provides a Backup-DockerData function that
    enumerates containers/images/volumes by calling docker and returns a
    structured result suitable for unit testing. It does not perform any
    writes or call exit so tests can mock underlying commands.
#>

[CmdletBinding()]
param()

function Write-Phase {
    param([string]$Phase, [string]$Message)
    Write-Output @{ Phase = $Phase; Message = $Message }
}

function Backup-DockerData {
    param(
        [string]$BackupPath = 'C:\DockerBackup',
        [switch]$SkipImages,
        [switch]$SkipVolumes
    )

    $result = [ordered]@{
        BackupPath = $BackupPath
        Containers = @()
        Images = @()
        Volumes = @()
        SkippedImages = $SkipImages.IsPresent
        SkippedVolumes = $SkipVolumes.IsPresent
        Success = $true
        Messages = @()
    }

    # Get containers
    try {
        $out = & docker ps -a --format "{{.Names}}" 2>$null
        if ($out) { $result.Containers = ($out | Where-Object { $_ -and $_.Trim() -ne '' } | ForEach-Object { $_.Trim() }) }
    }
    catch {
        $result.Success = $false
        $result.Messages += "Failed to list containers: $($_.Exception.Message)"
    }

    if (-not $SkipImages) {
        try {
            $out = & docker images --format "{{.Repository}}:{{.Tag}}" 2>$null
            if ($out) { $result.Images = ($out | Where-Object { $_ -and $_ -notmatch '<none>' } | ForEach-Object { $_.Trim() }) }
        }
        catch {
            $result.Success = $false
            $result.Messages += "Failed to list images: $($_.Exception.Message)"
        }
    }

    if (-not $SkipVolumes) {
        try {
            $out = & docker volume ls --format "{{.Name}}" 2>$null
            if ($out) { $result.Volumes = ($out | Where-Object { $_ -and $_.Trim() -ne '' } | ForEach-Object { $_.Trim() }) }
        }
        catch {
            $result.Success = $false
            $result.Messages += "Failed to list volumes: $($_.Exception.Message)"
        }
    }

    return $result
}

# Functions available when dot-sourced
# Docker Data Backup Script
# Run this BEFORE uninstalling Docker Desktop to preserve your containers, images, and volumes
# This script will backup your VPS environment and other Docker resources

param(
    [string]$BackupPath = "C:\DockerBackup\$(Get-Date -Format 'yyyy-MM-dd-HHmm')",
    [switch]$SkipImages = $false,
    [switch]$SkipVolumes = $false
)

Write-Information "ðŸ”„ Docker Data Backup Starting..." -Tags Title
Write-Information "Backup Location: $BackupPath" -Tags Info

# Create backup directory
New-Item -ItemType Directory -Path $BackupPath -Force | Out-Null

# Check if Docker is running
try {
    docker version | Out-Null
    Write-Information "âœ… Docker is running" -Tags Success
} catch {
    Write-Error "âŒ Docker is not running or not accessible"
    Write-Warning "Please start Docker Desktop and try again"
    exit 1
}

# Function to run docker commands with error handling
function Invoke-DockerCommand {
    param([string]$Command)
    try {
        & ([ScriptBlock]::Create($Command))
        return $true
    } catch {
        Write-Warning "âš ï¸  Command failed: $Command"
        Write-Error "Error: $_"
        return $false
    }
}

# 1. Export VPS containers (if they exist)
Write-Information "`nðŸ³ Backing up VPS containers..." -Tags Info
$vpsContainers = @("ubuntu-vps", "debian-vps", "rocky-vps", "centos-vps", "alpine-vps", "opensuse-vps", "arch-vps", "slackware-vps")

foreach ($container in $vpsContainers) {
    if (docker ps -a --format "{{.Names}}" | Select-String -Pattern "^$container$") {
    Write-Information "  ðŸ“¦ Exporting $container..." -Tags Info
        $exportPath = Join-Path $BackupPath "$container.tar"
        if (Invoke-DockerCommand "docker export $container -o `"$exportPath`"") {
            Write-Information "  âœ… $container exported successfully" -Tags Success
        }
    } else {
    Write-Information "  â­ï¸  $container not found, skipping" -Tags Info
    }
}

# 2. Save Docker images (optional, can be large)
if (-not $SkipImages) {
    Write-Information "`nðŸ–¼ï¸  Backing up Docker images..." -Tags Info
    $images = docker images --format "{{.Repository}}:{{.Tag}}" | Where-Object { $_ -notmatch "<none>" }
    
    if ($images) {
        $imagesPath = Join-Path $BackupPath "images"
        New-Item -ItemType Directory -Path $imagesPath -Force | Out-Null
        <##
        SYNOPSIS
            Minimal, test-friendly Docker backup helper (MVP)

        DESCRIPTION
            This lightweight version provides a Backup-DockerData function that
            enumerates containers/images/volumes by calling docker and returns a
            structured result suitable for unit testing. It does not perform any
            writes or call exit so tests can mock underlying commands.
        #>

        function Write-Phase {
            param([string]$Phase, [string]$Message)
            Write-Output @{ Phase = $Phase; Message = $Message }
        }

        function Backup-DockerData {
            param(
                [string]$BackupPath = 'C:\DockerBackup',
                [switch]$SkipImages,
                [switch]$SkipVolumes
            )

            $result = [ordered]@{
                BackupPath = $BackupPath
                Containers = @()
                Images = @()
                Volumes = @()
                SkippedImages = $SkipImages.IsPresent
                SkippedVolumes = $SkipVolumes.IsPresent
                Success = $true
                Messages = @()
            }

            # Get containers
            try {
                $out = & docker ps -a --format "{{.Names}}" 2>$null
                if ($out) { $result.Containers = ($out | Where-Object { $_ -and $_.Trim() -ne '' } | ForEach-Object { $_.Trim() }) }
            }
            catch {
                $result.Success = $false
                $result.Messages += "Failed to list containers: $($_.Exception.Message)"
            }

            if (-not $SkipImages) {
                try {
                    $out = & docker images --format "{{.Repository}}:{{.Tag}}" 2>$null
                    if ($out) { $result.Images = ($out | Where-Object { $_ -and $_ -notmatch '<none>' } | ForEach-Object { $_.Trim() }) }
                }
                catch {
                    $result.Success = $false
                    $result.Messages += "Failed to list images: $($_.Exception.Message)"
                }
            }

            if (-not $SkipVolumes) {
                try {
                    $out = & docker volume ls --format "{{.Name}}" 2>$null
                    if ($out) { $result.Volumes = ($out | Where-Object { $_ -and $_.Trim() -ne '' } | ForEach-Object { $_.Trim() }) }
                }
                catch {
                    $result.Success = $false
                    $result.Messages += "Failed to list volumes: $($_.Exception.Message)"
                }
            }

            return $result
        }

        # Minimal module: do not execute any script logic when dot-sourced. Only
        # declare functions. This file is intentionally small so tests can dot-source
        # and mock docker calls without side-effects.
