"""Main orchestrator for the WSL & Docker Desktop Manager.

This orchestrator handles the main menu and delegates to specific orchestrators
for install, uninstall, status, and backup operations.
"""

import os
import sys
from pathlib import Path

# Add src directory to path for imports
src_path = os.path.dirname(os.path.abspath(__file__))
if src_path not in sys.path:
    sys.path.insert(0, src_path)

from ui.ui_library import render_header, render_selection_menu, get_icon_color
from step_result import StepResult


class MainOrchestrator:
    """Main menu orchestrator that delegates to specific operation orchestrators."""
    
    def __init__(self):
        self.script_dir = Path(__file__).parent.parent

    def show_main_menu(self) -> StepResult:
        """Display and handle the main menu loop."""
        while True:
            try:
                # Main menu choices with icons
                choices = [
                    "🚀 Install",
                    "🔄 Uninstall", 
                    "🔍 Check Status",
                    "💾 Backup",
                    "❌ Exit"
                ]

                choice = render_selection_menu(
                    title="WSL & Docker Desktop Manager - MVP",
                    choices=choices,
                    icon="🐋",
                    icon_color=get_icon_color("🐋"),
                    prompt="What would you like to do?"
                )

                if choice is None or "Exit" in choice:
                    print("👋 Goodbye!")
                    return StepResult.now(name="main_orchestrator", status="Success", message="User exited application")

                # Delegate to specific orchestrators
                if "Install" in choice:
                    result = self._handle_install()
                elif "Uninstall" in choice:
                    result = self._handle_uninstall()
                elif "Check Status" in choice:
                    result = self._handle_status()
                elif "Backup" in choice:
                    result = self._handle_backup()
                else:
                    continue

                # Handle orchestrator results (most orchestrators manage their own UI flow)
                if result and result.status == "Error":
                    print(f"❌ Operation failed: {result.message}")
                    input("Press Enter to continue...")

            except KeyboardInterrupt:
                print("\n👋 Goodbye!")
                return StepResult.now(name="main_orchestrator", status="Cancelled", message="User cancelled via Ctrl+C")
            except Exception as e:
                print(f"❌ Main menu error: {str(e)}")
                input("Press Enter to continue...")

    def _handle_install(self) -> StepResult:
        """Delegate to install orchestrator."""
        try:
            from install.install_orchestrator import main as install_main
            return install_main(interactive=True)
        except ImportError as e:
            return StepResult.now(name="install_delegate", status="Error", 
                                message=f"Install orchestrator not available: {str(e)}")
        except Exception as e:
            return StepResult.now(name="install_delegate", status="Error", 
                                message=f"Install operation failed: {str(e)}")

    def _handle_uninstall(self) -> StepResult:
        """Delegate to uninstall orchestrator."""
        try:
            from uninstall.uninstall_orchestrator import main as uninstall_main
            return uninstall_main(interactive=True)
        except ImportError as e:
            return StepResult.now(name="uninstall_delegate", status="Error", 
                                message=f"Uninstall orchestrator not available: {str(e)}")
        except Exception as e:
            return StepResult.now(name="uninstall_delegate", status="Error", 
                                message=f"Uninstall operation failed: {str(e)}")

    def _handle_status(self) -> StepResult:
        """Delegate to status orchestrator."""
        try:
            from status.status_orchestrator import main as status_main
            return status_main(interactive=True)
        except ImportError as e:
            return StepResult.now(name="status_delegate", status="Error", 
                                message=f"Status orchestrator not available: {str(e)}")
        except Exception as e:
            return StepResult.now(name="status_delegate", status="Error", 
                                message=f"Status check failed: {str(e)}")

    def _handle_backup(self) -> StepResult:
        """Delegate to backup orchestrator."""
        try:
            from backup.backup_orchestrator import main as backup_main
            return backup_main(interactive=True)
        except ImportError as e:
            return StepResult.now(name="backup_delegate", status="Error", 
                                message=f"Backup orchestrator not available: {str(e)}")
        except Exception as e:
            return StepResult.now(name="backup_delegate", status="Error", 
                                message=f"Backup operation failed: {str(e)}")


def main(interactive: bool = True) -> StepResult:
    """Main entry point for the main orchestrator.
    
    Args:
        interactive: If True, show interactive menu. If False, return immediately.
        
    Returns:
        StepResult indicating the outcome of the main orchestrator.
    """
    if not interactive:
        return StepResult.now(name="main_orchestrator", status="Success", 
                            message="Main orchestrator (non-interactive mode)")
    
    orchestrator = MainOrchestrator()
    return orchestrator.show_main_menu()


if __name__ == "__main__":
    try:
        result = main(interactive=True)
        if result.status == "Error":
            sys.exit(1)
    except KeyboardInterrupt:
        print("\n👋 Goodbye!")
        sys.exit(0)
    except Exception as e:
        print(f"❌ Main orchestrator failed: {str(e)}")
        sys.exit(1)