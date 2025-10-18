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
import queue

# Emoji/icon helper for menu presentation
try:
    from src.ui.icons import get_icon, list_palette
except Exception:
    # Fail gracefully if UI icons aren't available; provide fallbacks
    def get_icon(name: str) -> str:  # type: ignore
        return ""

    def list_palette() -> list:  # type: ignore
        return []


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

        # Prefer the UI-driven orchestrator (non-invasive). Fall back to legacy script if unavailable.
        try:
            self._run_flow_and_show_events('install', {'dry_run': False, 'yes': True})
        except Exception:
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

        try:
            # run uninstall orchestrator (perform actions)
            self._run_flow_and_show_events('uninstall', {'dry_run': False, 'yes': True})
        except Exception:
            # fallback to legacy script
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

        try:
            self._run_flow_and_show_events('install', {'dry_run': False, 'targets': ['wsl']})
        except Exception:
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

        try:
            self._run_flow_and_show_events('install', {'dry_run': False, 'targets': ['docker']})
        except Exception:
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

        try:
            self._run_flow_and_show_events('backup', {'dry_run': False, 'log_path': backup_path})
        except Exception:
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

        confirm = questionary.confirm(f"Restore Docker data from {backup_path}?" ).ask()
        if not confirm:
            print("Restore cancelled.")
            return

        try:
            self._run_flow_and_show_events('restore', {'dry_run': False, 'log_path': backup_path})
        except Exception:
            self.run_powershell_script("restore", "Restoring Docker data...", 
                                     backup_path=backup_path, force=True)

    def show_main_menu(self):
        """Display and handle the main menu."""
        while True:
            print("\n" + "=" * 60)
            # use centralized icon palette for the header
            header_icon = get_icon('whale')
            print(f"{header_icon} WSL & Docker Desktop Manager - MVP")
            print("=" * 60)

            try:
                # decorate choices with icons where available
                choices = [
                    f"{get_icon('install')} Install",
                    f"{get_icon('uninstall')} Uninstall",
                    f"{get_icon('status')} Check Status",
                    f"{get_icon('backup')} Backup",
                    f"{get_icon('exit')} ❌ Exit",
                ]

                choice = questionary.select(
                    "What would you like to do?",
                    choices=choices,
                ).ask()
            except KeyboardInterrupt:
                # Handle Ctrl+C gracefully
                print("\n👋 Goodbye!")
                return

            # Handle case where user presses Ctrl+C or ESC during selection
            if choice is None:
                print("👋 Goodbye!")
                return

            # Normalize by checking suffixes to keep compatibility with icon prefixes
            if choice is not None and choice.strip().endswith("❌ Exit"):
                print("👋 Goodbye!")
                return

            if choice is not None and choice.strip().endswith("Install"):
                # Hand off to the install orchestrator to drive the next steps
                try:
                    mod = __import__('src.install.install_orchestrator', fromlist=['main'])
                    if hasattr(mod, 'main'):
                        res = mod.main(interactive=True)
                        # print results if any
                        if res is None:
                            print("Install orchestrator completed.")
                        else:
                            results = res if isinstance(res, list) else [res]
                            for r in results:
                                try:
                                    d = r.to_dict()
                                    print(f"- {d.get('name')} : {d.get('status')} - {d.get('message')}")
                                except Exception:
                                    print(repr(r))
                    else:
                        print("Install orchestrator entrypoint not found")
                except Exception:
                    # fallback to legacy full install script
                    self.fresh_installation()
            elif choice is not None and choice.strip().endswith("Uninstall"):
                try:
                    mod = __import__('src.uninstall.uninstall_orchestrator', fromlist=['main'])
                    if hasattr(mod, 'main'):
                        res = mod.main(interactive=True)
                        if res is None:
                            print("Uninstall orchestrator completed.")
                        else:
                            results = res if isinstance(res, list) else [res]
                            for r in results:
                                try:
                                    d = r.to_dict()
                                    print(f"- {d.get('name')} : {d.get('status')} - {d.get('message')}")
                                except Exception:
                                    print(repr(r))
                    else:
                        print("Uninstall orchestrator entrypoint not found")
                except Exception:
                    # fallback to legacy system reset behavior
                    self.system_reset()
            elif choice is not None and choice.strip().endswith("Check Status"):
                # status is read-only; delegate to existing status check
                try:
                    # prefer adapter/flow if available
                    self._run_flow_and_show_events('status', {'dry_run': True})
                except Exception:
                    self.show_system_status()
            elif choice is not None and choice.strip().endswith("Backup"):
                # delegate to backup orchestrator or fallback
                try:
                    # ask for path like before
                    backup_path = questionary.text("Backup path (default: C:\\DockerBackup):", default="C:\\DockerBackup").ask()
                    if not backup_path:
                        print("Backup cancelled.")
                    else:
                        confirm = questionary.confirm(f"Backup Docker data to {backup_path}?").ask()
                        if not confirm:
                            print("Backup cancelled.")
                        else:
                            mod = __import__('src.backup.backup_orchestrator', fromlist=['backup_sequence'])
                            if hasattr(mod, 'backup_sequence'):
                                seq = mod.backup_sequence(dry_run=False)
                                for r in seq:
                                    try:
                                        d = r.to_dict()
                                        print(f"- {d.get('name')} : {d.get('status')} - {d.get('message')}")
                                    except Exception:
                                        print(repr(r))
                            else:
                                # fallback to script
                                self.run_powershell_script("backup", "Backing up Docker data...", backup_path=backup_path, force=True)
                except Exception:
                    print("Backup failed: falling back to legacy script")

    def _run_flow_and_show_events(self, flow_name: str, options: dict):
        """Run a named UI flow in background and print events from its queue.

        Uses src.ui.threaded_runner.run_flow_in_thread if available. This is a
        *best-effort* integration: any failure falls back to legacy behavior.
        """
        try:
            # lazy import to avoid hard dependency when UI code isn't present
            tr = __import__('src.ui.threaded_runner', fromlist=['run_flow_in_thread'])
            run_flow = getattr(tr, 'run_flow_in_thread')
        except Exception:
            raise

        q = queue.Queue()
        th = run_flow(flow_name, options, q)

        # Drain the queue until we see a run-end or error event, printing events.
        while True:
            try:
                ev_type, ev = q.get(timeout=0.1)
            except Exception:
                # thread may still be running; check if it's alive
                if not th.is_alive():
                    break
                continue

            # simple textual rendering of events
            if ev_type == 'run-start':
                print(f"▶️  Flow started: {ev.get('flow')}")
            elif ev_type == 'step-start':
                print(f"  → Step start: {ev.get('step_id') or ev.get('name')}")
            elif ev_type == 'step-end':
                print(f"  ← Step end: {ev.get('step_id') or ev.get('name')} status={ev.get('status')}")
            elif ev_type == 'run-end':
                print(f"✅ Flow finished: {ev.get('flow')} - results: {len(ev.get('results', []))}")
                break
            elif ev_type == 'error':
                print(f"❌ Flow error: {ev.get('error')}")
                break

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
