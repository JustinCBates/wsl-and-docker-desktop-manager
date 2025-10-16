# 🐳🐧 WSL & Docker Desktop Manager for Windows 11

A comprehensive PowerShell toolkit for managing Docker Desktop and WSL 2 installations on Windows 11, with support for dynamic disk allocation and optimized storage management.

## 🎯 Purpose

This repository provides automated scripts to safely:
- **Backup** Docker containers, images, and volumes
- **Uninstall** Docker Desktop and WSL completely
- **Reinstall** WSL 2 with dynamic disk allocation (expandable storage)
- **Reinstall** Docker Desktop with optimized WSL 2 backend
- **Restore** all your Docker data seamlessly

Perfect for when you need to:
- 💾 **Expand Docker storage** beyond fixed disk limitations
- 🚀 **Improve performance** with WSL 2 backend optimization
- 🧹 **Clean install** Docker and WSL for troubleshooting
- 📦 **Migrate** to better storage configuration

## 🖥️ Windows 11 Compatibility

✅ **Fully tested and optimized for Windows 11**
- Windows 11 Home, Pro, Enterprise, and Education
- Supports both Intel and AMD processors
- Compatible with Secure Boot and TPM 2.0
- Works with Windows 11 Insider builds

### Windows 11 Specific Features
- **Enhanced WSL 2 integration** with Windows 11 improvements
- **Better memory management** using Windows 11 optimizations
- **Improved virtualization** with Windows 11 Hyper-V enhancements
- **Native GPU support** for Docker containers (if available)

## 📋 Prerequisites

### System Requirements
- **Windows 11** (any edition)
- **8GB RAM minimum** (16GB recommended for Docker workloads)
- **20GB free disk space** (for the reinstallation process)
- **Administrator privileges** required
- **Stable internet connection** for downloads

### Required Features (Automatically Enabled)
- Windows Subsystem for Linux (WSL)
- Virtual Machine Platform
- Hyper-V (optional, for advanced scenarios)

## 🚀 Quick Start

### Option 1: Complete Automated Process (Recommended)
```powershell
# Run PowerShell as Administrator
.\MASTER-REINSTALL.ps1 -Phase all
```

### Option 2: Step-by-Step Manual Process
```powershell
# 1. Backup your Docker data
.\BACKUP-DOCKER-DATA.ps1

# 2. Uninstall Docker Desktop
.\UNINSTALL-DOCKER-DESKTOP.ps1

# 3. Uninstall WSL (requires restart)
.\UNINSTALL-WSL.ps1

# 4. After restart - Install WSL 2 with dynamic disk
.\INSTALL-WSL2-DYNAMIC.ps1

# 5. Install Docker Desktop with WSL 2 backend
.\INSTALL-DOCKER-DESKTOP.ps1

# 6. Restore your data
# (Navigate to backup folder and run RESTORE-DOCKER-DATA.ps1)
```

## 📁 Script Overview

| Script | Purpose | Estimated Time |
|--------|---------|----------------|
| `MASTER-REINSTALL.ps1` | 🎛️ Orchestrates entire process | 2-3 hours |
| `BACKUP-DOCKER-DATA.ps1` | 💾 Backs up containers, images, volumes | 15-30 min |
| `UNINSTALL-DOCKER-DESKTOP.ps1` | 🗑️ Completely removes Docker Desktop | 10-15 min |
| `UNINSTALL-WSL.ps1` | 🗑️ Removes WSL and all distributions | 10-15 min |
| `INSTALL-WSL2-DYNAMIC.ps1` | 🔧 Installs WSL 2 with dynamic storage | 20-30 min |
| `INSTALL-DOCKER-DESKTOP.ps1` | 🐳 Installs Docker with WSL 2 backend | 15-20 min |
| `COMPLETE-REINSTALL-GUIDE.md` | 📖 Comprehensive documentation | N/A |

## 🎛️ Master Script Options

The `MASTER-REINSTALL.ps1` script supports various phases and options:

### Individual Phases
```powershell
# Run only specific phases
.\MASTER-REINSTALL.ps1 -Phase backup
.\MASTER-REINSTALL.ps1 -Phase uninstall-docker
.\MASTER-REINSTALL.ps1 -Phase uninstall-wsl
.\MASTER-REINSTALL.ps1 -Phase install-wsl
.\MASTER-REINSTALL.ps1 -Phase install-docker
.\MASTER-REINSTALL.ps1 -Phase restore
```

### Customization Options
```powershell
# Custom backup location
.\MASTER-REINSTALL.ps1 -BackupPath "D:\DockerBackup"

# Skip backup (if you have your own)
.\MASTER-REINSTALL.ps1 -SkipBackup

# Automated mode (no prompts)
.\MASTER-REINSTALL.ps1 -AutoConfirm

# Force operations (skip safety checks)
.\MASTER-REINSTALL.ps1 -Force
```

## 🔧 Windows 11 Specific Optimizations

### Dynamic Disk Allocation
- **Starts small**: Initial 20GB VHDX file
- **Grows automatically**: Expands up to 100GB+ as needed
- **Sparse allocation**: Only uses actual disk space consumed
- **Easy compaction**: Built-in tools to reclaim unused space

### Performance Optimizations
```powershell
# Optimized .wslconfig for Windows 11
[wsl2]
memory=4GB                    # Adjust based on your system
processors=2                  # Adjust based on your CPU
swap=2GB                     # Swap file for memory overflow
localhostForwarding=true     # Enable localhost forwarding
kernelCommandLine=cgroup_no_v1=all systemd.unified_cgroup_hierarchy=1

[experimental]
sparseVhd=true              # Dynamic disk allocation
autoMemoryReclaim=dropcache # Automatic memory management
```

### Docker Desktop Configuration
- **WSL 2 backend**: Superior performance vs Hyper-V
- **Resource limits**: Optimized for Windows 11
- **GPU support**: Ready for CUDA/DirectML workloads
- **File sharing**: Improved bind mount performance

## 💾 Storage Management

### Disk Usage Monitoring
```powershell
# Check Docker disk usage
docker system df

# Check WSL disk usage
wsl df -h

# Monitor container resources
docker stats
```

### Regular Maintenance
```powershell
# Weekly cleanup (automated)
.\DOCKER-CLEANUP.ps1

# Monthly disk compaction
wsl --shutdown
.\compact-wsl-disk.ps1  # Found in WSL scripts folder
```

## 🛡️ Safety Features

### Comprehensive Backups
- **Container exports**: All running and stopped containers
- **Image archives**: Docker images (optional, can be large)
- **Volume backups**: Persistent data and configurations
- **Configuration files**: Docker daemon.json, .wslconfig

### Error Handling
- **Rollback capabilities**: Automatic restoration if installation fails
- **Verification tests**: Health checks at each step
- **Detailed logging**: Full output capture for troubleshooting
- **Safe defaults**: Conservative settings that work reliably

### Windows 11 Security
- **Secure Boot compatible**: Works with Windows 11 security features
- **TPM 2.0 ready**: Compatible with hardware security requirements
- **Windows Defender**: Exclusions automatically configured
- **UAC compliant**: Proper elevation handling

## 🧪 Testing and Verification

After installation, the scripts automatically verify:

### ✅ WSL 2 Health Check
```powershell
wsl --status                 # WSL system status
wsl --list --verbose         # Distribution versions
wsl echo "Hello from WSL!"   # Basic functionality
```

### ✅ Docker Health Check
```powershell
docker --version             # Docker version
docker info | findstr "WSL"  # WSL backend confirmation
docker run --rm hello-world  # Container functionality
```

### ✅ Integration Test
```powershell
# Test Docker in WSL
wsl docker --version
wsl docker ps

# Test file sharing
echo "test" | docker run --rm -i alpine cat
```

## 🔧 Customization for Different Systems

### For Development Machines
```powershell
# Higher resource allocation
.\INSTALL-WSL2-DYNAMIC.ps1 -MaxDiskSizeGB 200
.\INSTALL-DOCKER-DESKTOP.ps1 -EnableKubernetes
```

### For Constrained Systems
```powershell
# Lower resource usage
.\INSTALL-WSL2-DYNAMIC.ps1 -InitialDiskSizeGB 10 -MaxDiskSizeGB 50
# Edit .wslconfig to reduce memory allocation
```

### For Multiple Drives
```powershell
# Move WSL to different drive
.\INSTALL-WSL2-DYNAMIC.ps1 -WSLInstallPath "D:\WSL"
.\INSTALL-DOCKER-DESKTOP.ps1 -DockerDataPath "D:\Docker"
```

## 🐛 Troubleshooting

### Common Windows 11 Issues

#### Virtualization Not Enabled
```powershell
# Check if virtualization is enabled in BIOS/UEFI
systeminfo | findstr /i "Hyper-V"

# Enable required Windows features
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform
```

#### WSL Kernel Issues
```powershell
# Manual kernel update
Invoke-WebRequest -Uri "https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi" -OutFile "$env:TEMP\wsl_update_x64.msi"
Start-Process msiexec.exe -ArgumentList "/i", "$env:TEMP\wsl_update_x64.msi", "/quiet" -Wait
```

#### Docker Desktop Won't Start
```powershell
# Reset Docker to factory defaults
"C:\Program Files\Docker\Docker\Docker Desktop.exe" --factory-reset

# Check Windows services
Get-Service com.docker.*
```

### Performance Issues

#### Slow Docker Performance
1. Increase WSL memory allocation in `.wslconfig`
2. Move Docker data to SSD drive
3. Enable Windows 11 performance features in BIOS

#### High Disk Usage
1. Run `.\DOCKER-CLEANUP.ps1` regularly
2. Use `docker system prune` for aggressive cleanup
3. Compact WSL disk with provided scripts

## 📊 Monitoring and Maintenance

### Built-in Monitoring Tools
```powershell
# Docker system monitoring
.\DOCKER-MONITOR.ps1

# Resource usage tracking
docker stats --no-stream

# WSL resource monitoring
wsl cat /proc/meminfo
wsl df -h
```

### Automated Maintenance
Set up scheduled tasks for regular maintenance:
```powershell
# Weekly Docker cleanup
schtasks /create /tn "Docker Cleanup" /tr "PowerShell.exe -File 'C:\path\to\DOCKER-CLEANUP.ps1'" /sc weekly
```

## 🤝 Contributing

Contributions are welcome! Please:
1. **Fork** the repository
2. **Create** a feature branch
3. **Test** on Windows 11 systems
4. **Submit** a pull request with clear description

### Testing Guidelines
- Test on both Intel and AMD systems
- Verify with different Windows 11 editions
- Check compatibility with Windows Insider builds
- Test with various hardware configurations

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

### Getting Help
1. **Check** the [COMPLETE-REINSTALL-GUIDE.md](COMPLETE-REINSTALL-GUIDE.md) for detailed instructions
2. **Review** script output for specific error messages
3. **Search** existing issues in this repository
4. **Create** a new issue with system details and error logs

### System Information for Bug Reports
```powershell
# Gather system information for support
systeminfo > system-info.txt
wsl --status > wsl-status.txt
docker info > docker-info.txt 2>&1
```

## 🏷️ Tags

`windows-11` `wsl2` `docker-desktop` `powershell` `automation` `devops` `containers` `virtualization` `storage-management` `backup-restore`

---

**⚡ Optimized for Windows 11 | 🚀 Enhanced Performance | 💾 Dynamic Storage | 🛡️ Safe & Reliable**