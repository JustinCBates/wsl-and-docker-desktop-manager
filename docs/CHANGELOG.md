# Changelog

All notable changes to the WSL & Docker Desktop Manager will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-10-16

### Added
- Initial release of WSL & Docker Desktop Manager
- Complete backup and restore functionality for Docker data
- Automated uninstallation scripts for Docker Desktop and WSL
- WSL 2 installation with dynamic disk allocation
- Docker Desktop reinstallation with WSL 2 backend optimization
- Master orchestration script for complete reinstallation process
- Comprehensive documentation and troubleshooting guides
- Windows 11 specific optimizations and compatibility
- Built-in monitoring and maintenance utilities
- Error handling and rollback capabilities
- Safety checks and verification tests

### Features
-- **BACKUP-DOCKER-DATA.ps1**: REMOVED - backup functionality intentionally removed from the codebase
- **UNINSTALL-DOCKER-DESKTOP.ps1**: Clean Docker Desktop removal
- **UNINSTALL-WSL.ps1**: Complete WSL uninstallation with backup
- **INSTALL-WSL2-DYNAMIC.ps1**: WSL 2 installation with dynamic storage
- **INSTALL-DOCKER-DESKTOP.ps1**: Optimized Docker Desktop installation
- **MASTER-REINSTALL.ps1**: Full process orchestration
- **COMPLETE-REINSTALL-GUIDE.md**: Detailed step-by-step documentation

### Windows 11 Optimizations
- Dynamic VHDX allocation for WSL 2 storage
- Optimized .wslconfig for Windows 11
- Enhanced performance settings for Docker Desktop
- Secure Boot and TPM 2.0 compatibility
- Windows Defender integration

### Safety Features
- Comprehensive data backups before any changes
- Automatic restoration scripts generation
- Step-by-step verification and health checks
- Rollback capabilities for failed installations
- Conservative default settings for reliability