#!/usr/bin/env python3
"""
WSL & Docker Desktop Manager - MVP Menu System
Simple Questionary-based interface for managing WSL and Docker Desktop installations.
"""

import os
import subprocess
import sys
from pathlib import Path

import questionary


class WSLDockerManager:
    """Simple menu-driven manager for WSL and Docker Desktop operations."""

    def __init__(self):
        self.script_dir = Path(__file__).parent

    def check_admin_privileges(self):
        """Check if running with administrator privileges."""
        try:
            return os.access(sys.executable, os.W_OK) and \
                   subprocess.run(['net', 'session'], capture_output=True,
                                text=True, check=False).returncode == 0
        except (OSError, subprocess.SubprocessError):
            return False

    def run_powershell_script(self, phase, description="", backup_path=None, force=False, skip_backup=False):
        """Execute the main PowerShell script with specified phase and options."""
        script_path = self.script_dir / "MASTER-REINSTALL-v2.ps1"

        if not script_path.exists():
            print(f"❌ Error: Script MASTER-REINSTALL-v2.ps1 not found!")
            return False

        if not self.check_admin_privileges():
            print("⚠️  Administrator privileges required for this operation.")
            print("Please run this program as Administrator.")
            return False

        print(f"🔄 {description}")
        print(f"Executing: {script_path} -Phase {phase}")
        print("-" * 50)

        try:
            # Build PowerShell command arguments
            cmd_args = [
                'powershell.exe',
                '-ExecutionPolicy', 'Bypass',
                '-File', str(script_path),
                '-Phase', phase
            ]
            
            # Add optional parameters
            if backup_path:
                cmd_args.extend(['-BackupPath', backup_path])
            if force:
                cmd_args.append('-Force')
            if skip_backup:
                cmd_args.append('-SkipBackup')

            # Execute PowerShell script
            result = subprocess.run(cmd_args, capture_output=False, text=True, check=False)

            if result.returncode == 0:
                print(f"✅ {description} completed successfully!")
            else:
                print(f"❌ {description} encountered errors (exit code: {result.returncode})")

            return result.returncode == 0

        except (OSError, subprocess.SubprocessError) as exc:
            print(f"❌ Error executing PowerShell script: {exc}")
            return False

    def show_system_status(self):
        """Display current WSL and Docker Desktop status using the comprehensive status script."""
        print("🔍 System Status Check")
        print("-" * 50)

        try:
            # Use the comprehensive system status script
            script_path = self.script_dir / "scripts" / "status" / "Get-SystemStatus.ps1"
            
            if not script_path.exists():
                print(f"❌ Status script not found: {script_path}")
                return

            result = subprocess.run([
                'powershell.exe',
                '-ExecutionPolicy', 'Bypass',
                '-File', str(script_path),
                '-ShowDetails'
            ], capture_output=True, text=True, check=False)

            if result.returncode == 0:
                print(result.stdout)
                print("✅ Status check completed successfully!")
            else:
                print("⚠️ Status check completed with warnings:")
                print(result.stdout)
                if result.stderr:
                    print("Errors:")
                    print(result.stderr)

        except (OSError, subprocess.SubprocessError) as exc:
            print(f"❌ Error running status check: {exc}")
            
            # Fallback to basic status check
            print("\nFalling back to basic status check...")
            self._basic_status_check()

    def _basic_status_check(self):
        """Basic fallback status check."""
        print("WSL Status:")
        try:
            result = subprocess.run(['wsl', '--list', '--verbose'],
                                  capture_output=True, text=True, check=False)
            if result.returncode == 0:
                print(result.stdout)
            else:
                print("❌ WSL not installed or not accessible")
        except (OSError, subprocess.SubprocessError):
            print("❌ WSL command not found")

        print("\nDocker Desktop Status:")
        try:
            result = subprocess.run(['docker', '--version'],
                                  capture_output=True, text=True, check=False)
            if result.returncode == 0:
                print(f"✅ {result.stdout.strip()}")

                # Check if Docker daemon is running
                daemon_result = subprocess.run(['docker', 'info'],
                                             capture_output=True, text=True, check=False)
                if daemon_result.returncode == 0:
                    print("✅ Docker daemon is running")
                else:
                    print("⚠️  Docker is installed but daemon is not running")
            else:
                print("❌ Docker not installed or not accessible")
        except (OSError, subprocess.SubprocessError):
            print("❌ Docker command not found")

        print("-" * 50)

    def fresh_installation(self):
        """Perform fresh installation of WSL and Docker Desktop."""
        print("🚀 Fresh Installation")
        print("This will install WSL2 and Docker Desktop with Microsoft's recommended defaults:")
        print("• WSL2 with Ubuntu 22.04 LTS")
        print("• Docker Desktop with 50% RAM allocation")
        print("• All available processors")
        print("• Automatic memory reclaim enabled")
        print()

        confirm = questionary.confirm("Do you want to proceed with fresh installation?").ask()
        if not confirm:
            print("Installation cancelled.")
            return

        self.run_powershell_script("install-both", "Fresh installation in progress...", force=True)

    def system_reset(self):
        """Reset existing WSL and Docker Desktop installation."""
        print("🔄 System Reset")
        print("This will completely reset your WSL and Docker Desktop installation:")
        print("• Uninstall existing WSL distributions")
        print("• Uninstall Docker Desktop")
        print("• Reinstall with fresh Microsoft defaults")
        print()

        long_confirm_message = ("⚠️  This will remove all existing WSL distributions "
                              "and Docker data. Continue?")
        confirm = questionary.confirm(long_confirm_message).ask()
        if not confirm:
            print("System reset cancelled.")
            return

        backup_confirm = questionary.confirm("Do you want to backup Docker data first?").ask()
        skip_backup = not backup_confirm

        self.run_powershell_script("complete-reinstall", "System reset in progress...", 
                                 skip_backup=skip_backup, force=True)

    def install_wsl_only(self):
        """Install WSL only."""
        print("🔧 WSL Installation")
        print("This will install:")
        print("• WSL2 with latest kernel")
        print("• Virtual Machine Platform feature")
        print()

        confirm = questionary.confirm("Do you want to proceed with WSL installation?").ask()
        if not confirm:
            print("WSL installation cancelled.")
            return

        self.run_powershell_script("install-wsl", "WSL installation in progress...")

    def install_docker_only(self):
        """Install Docker Desktop only."""
        print("🐳 Docker Desktop Installation")
        print("This will install:")
        print("• Docker Desktop with WSL2 backend")
        print("• Docker CLI and Docker Compose")
        print()

        confirm = questionary.confirm("Do you want to proceed with Docker installation?").ask()
        if not confirm:
            print("Docker installation cancelled.")
            return

        self.run_powershell_script("install-docker", "Docker installation in progress...")

    def backup_docker_data(self):
        """Backup Docker data."""
        print("💾 Docker Data Backup")
        print("This will backup:")
        print("• Docker images")
        print("• Docker volumes")
        print("• Docker configuration")
        print()

        backup_path = questionary.text("Backup path (default: C:\\DockerBackup):", 
                                     default="C:\\DockerBackup").ask()
        if not backup_path:
            print("Backup cancelled.")
            return

        confirm = questionary.confirm(f"Backup Docker data to {backup_path}?").ask()
        if not confirm:
            print("Backup cancelled.")
            return

        self.run_powershell_script("backup", "Backing up Docker data...", 
                                 backup_path=backup_path, force=True)

    def restore_docker_data(self):
        """Restore Docker data from backup."""
        print("📁 Docker Data Restore")
        print("This will restore:")
        print("• Docker images")
        print("• Docker volumes") 
        print("• Docker configuration")
        print()

        backup_path = questionary.text("Backup path (default: C:\\DockerBackup):", 
                                     default="C:\\DockerBackup").ask()
        if not backup_path:
            print("Restore cancelled.")
            return

        confirm = questionary.confirm(f"Restore Docker data from {backup_path}?").ask()
        if not confirm:
            print("Restore cancelled.")
            return

        self.run_powershell_script("restore", "Restoring Docker data...", 
                                 backup_path=backup_path, force=True)

    def show_main_menu(self):
        """Display and handle the main menu."""
        while True:
            print("\n" + "=" * 60)
            print("🐳 WSL & Docker Desktop Manager - MVP")
            print("=" * 60)

            try:
                choice = questionary.select(
                    "What would you like to do?",
                    choices=[
                        "🚀 Fresh Installation (WSL + Docker)",
                        "� Install WSL Only", 
                        "🐳 Install Docker Only",
                        "�🔄 System Reset (Complete Reinstall)",
                        "💾 Backup Docker Data",
                        "📁 Restore Docker Data",
                        "🔍 Status Check",
                        "❌ Exit"
                    ]
                ).ask()
            except KeyboardInterrupt:
                # Handle Ctrl+C gracefully
                print("\n👋 Goodbye!")
                return

            # Handle case where user presses Ctrl+C or ESC during selection
            if choice is None:
                print("👋 Goodbye!")
                return

            if choice == "❌ Exit":
                print("👋 Goodbye!")
                return

            if choice == "🚀 Fresh Installation (WSL + Docker)":
                self.fresh_installation()
            elif choice == "🔧 Install WSL Only":
                self.install_wsl_only()
            elif choice == "🐳 Install Docker Only":
                self.install_docker_only()
            elif choice == "🔄 System Reset (Complete Reinstall)":
                self.system_reset()
            elif choice == "💾 Backup Docker Data":
                self.backup_docker_data()
            elif choice == "📁 Restore Docker Data":
                self.restore_docker_data()
            elif choice == "🔍 Status Check":
                self.show_system_status()

            # Only pause if not exiting
            try:
                input("\nPress Enter to continue...")
            except KeyboardInterrupt:
                print("\n👋 Goodbye!")
                return


def main():
    """Main entry point."""
    try:
        manager = WSLDockerManager()
        manager.show_main_menu()
    except KeyboardInterrupt:
        print("\n👋 Goodbye!")
    except (OSError, ImportError, AttributeError) as exc:
        print(f"\n❌ System error: {exc}")
        input("Press Enter to exit...")
        sys.exit(1)
    except Exception as exc:  # pylint: disable=broad-except
        print(f"\n❌ Unexpected error: {exc}")
        input("Press Enter to exit...")
        sys.exit(1)

    # Ensure clean exit
    sys.exit(0)


if __name__ == "__main__":
    main()
