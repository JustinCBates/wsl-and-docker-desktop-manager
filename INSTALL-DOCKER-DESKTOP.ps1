<#
ARCHIVE STUB: INSTALL-DOCKER-DESKTOP.ps1

This implementation used to live at the repository root. The canonical
interactive UI is now `MANAGER.ps1`. Heavy implementations should be placed
under `scripts/` and invoked from the manager when ready.

This stub is safe and non-destructive. Run MANAGER.ps1 to use the mocked UI.
#>

Write-Output "This script has been archived. Use MANAGER.ps1 as the canonical entrypoint."
exit 0
# Wait for Docker to restart
Start-Sleep -Seconds 30

$verificationTests = @(
    @{
        Name = "Docker Version"
        Command = { docker --version }
        Expected = "Docker version"
    },
    @{
        Name = "Docker Info"
        Command = { docker info --format '{{.ServerVersion}}' }
        Expected = $null
    },
    @{
        Name = "WSL Integration"
        Command = { docker context ls }
        Expected = "default"
    },
    @{
        Name = "Container Test"
        Command = { docker run --rm hello-world }
        Expected = "Hello from Docker!"
    }
)

$allTestsPassed = $true

foreach ($test in $verificationTests) {
    Write-Information "  ðŸ§ª Testing: $($test.Name)..." -Tags Info
    try {
        $result = & $test.Command 2>&1
        if ($test.Expected -and $result -match $test.Expected) {
            Write-Information "    âœ… $($test.Name) - PASSED" -Tags Success
        } elseif (-not $test.Expected -and $result) {
            Write-Information "    âœ… $($test.Name) - PASSED" -Tags Success
        } else {
            Write-Error "    âŒ $($test.Name) - FAILED"
            Write-Information "    Output: $result" -Tags Info
            $allTestsPassed = $false
        }
    } catch {
        Write-Error "    âŒ $($test.Name) - ERROR: $_"
        $allTestsPassed = $false
    }
}

# 8. Create Docker management utilities
Write-Information "`nðŸ“ Creating Docker management utilities..." -Tags Phase

$utilsPath = "c:\Users\justi\OneDrive\Desktop\LocalRepos\devcontainer_server_docker"

# Docker cleanup script
$dockerCleanupScript = @"
# Docker Cleanup and Optimization Script
# Run this regularly to maintain Docker health and save disk space

Write-Information "ðŸ§¹ Docker Cleanup Starting..." -Tags Title

# Stop all containers
Write-Information "ðŸ›‘ Stopping all containers..." -Tags Info
docker stop `$(docker ps -aq) 2>`$null

# Remove stopped containers
Write-Information "ðŸ—‘ï¸  Removing stopped containers..." -Tags Info
docker container prune -f

# Remove unused images
Write-Information "ðŸ–¼ï¸  Removing unused images..." -Tags Info
docker image prune -f

# Remove unused volumes
Write-Information "ðŸ’¾ Removing unused volumes..." -Tags Info
docker volume prune -f

# Remove unused networks
Write-Information "ðŸŒ Removing unused networks..." -Tags Info
docker network prune -f

# Build cache cleanup
Write-Information "ðŸ”¨ Cleaning build cache..." -Tags Info
docker builder prune -f

# System cleanup (aggressive)
Write-Information "ðŸ§½ Running system cleanup..." -Tags Info
docker system prune -f

# Show disk usage
Write-Information "ðŸ“Š Current Docker disk usage:" -Tags Info
docker system df

Write-Information "âœ… Docker cleanup completed!" -Tags Success
"@

# Docker monitoring script
$dockerMonitorScript = @"
# Docker Monitoring Script
# Shows detailed information about Docker resource usage

Write-Information "ðŸ“Š Docker System Monitoring" -Tags Title

# Docker version and info
Write-Information "`nðŸ³ Docker Version:" -Tags Info
docker --version

Write-Information "`nâš™ï¸  Docker System Info:" -Tags Info
docker info --format "table {{.Name}}: {{.ServerVersion}}"

# Container status
Write-Information "`nðŸ“¦ Container Status:" -Tags Info
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Image usage
Write-Information "`nðŸ–¼ï¸  Image Usage:" -Tags Info
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"

# Volume usage
Write-Information "`nðŸ’¾ Volume Usage:" -Tags Info
docker volume ls --format "table {{.Name}}\t{{.Driver}}"

# Network usage
Write-Information "`nðŸŒ Network Usage:" -Tags Info
docker network ls --format "table {{.Name}}\t{{.Driver}}\t{{.Scope}}"

# Disk usage
Write-Information "`nðŸ’½ Disk Usage:" -Tags Info
docker system df

# Resource usage (if available)
Write-Information "`nðŸ”„ Resource Usage:" -Tags Info
try {
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}"
} catch {
    Write-Information "No running containers to monitor" -Tags Info
}

Write-Information "`nâœ… Monitoring completed!" -Tags Success
"@

# Save utility scripts
try {
    $dockerCleanupScript | Out-File -FilePath (Join-Path $utilsPath "DOCKER-CLEANUP.ps1") -Encoding UTF8
    $dockerMonitorScript | Out-File -FilePath (Join-Path $utilsPath "DOCKER-MONITOR.ps1") -Encoding UTF8
    Write-Information "  âœ… Docker utility scripts created" -Tags Success
} catch {
    Write-Warning "  âš ï¸  Failed to create utility scripts: $_"
}

# 9. Summary
Write-Information "`nâœ… Docker Desktop installation completed!" -Tags Success

if ($allTestsPassed) {
    Write-Information "ðŸŽ‰ All verification tests passed!" -Tags Success
} else {
    Write-Warning "âš ï¸  Some tests failed - manual configuration may be needed"
}

Write-Information "`nðŸ“Š Installation Summary:" -Tags Info
Write-Information "  ðŸ³ Docker Desktop: Installed with WSL 2 backend" -Tags Info
Write-Information "  ðŸ§ WSL Integration: Ubuntu-22.04 enabled" -Tags Info
Write-Information "  ðŸ’¾ Data Location: $DockerDataPath" -Tags Info
Write-Information "  âš™ï¸  Configuration: Optimized for development" -Tags Info
if ($EnableKubernetes) {
    Write-Information "  â˜¸ï¸  Kubernetes: Enabled" -Tags Info
} else {
    Write-Information "  â˜¸ï¸  Kubernetes: Disabled (for better performance)" -Tags Info
}

Write-Information "`nðŸ”§ Available Tools:" -Tags Info
Write-Information "  ðŸ§¹ Cleanup: DOCKER-CLEANUP.ps1" -Tags Info
Write-Information "  ðŸ“Š Monitor: DOCKER-MONITOR.ps1" -Tags Info

Write-Information "`nðŸ”„ Next Steps:" -Tags Info
Write-Information "1. Run the data restoration script to recover your containers" -Tags Info
Write-Information "2. Test your VPS environment" -Tags Info
Write-Information "3. Configure any additional Docker settings as needed" -Tags Info

Write-Warning "`nðŸ’¡ Pro Tips:"
Write-Information "- Use 'docker system df' to monitor disk usage" -Tags Info
Write-Information "- Run DOCKER-CLEANUP.ps1 regularly to save space" -Tags Info
Write-Information "- Check DOCKER-MONITOR.ps1 for system health" -Tags Info
Write-Information "- WSL 2 provides better performance than Hyper-V" -Tags Info

Write-Information "`nðŸš€ Ready to restore your Docker data!" -Tags Success