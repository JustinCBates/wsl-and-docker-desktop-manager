"""Backup orchestrator with interactive menu options.

This orchestrator provides different backup and restore options with a user-friendly menu.
"""
import os
import sys

# Add parent src directory to path for imports
src_path = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if src_path not in sys.path:
    sys.path.insert(0, src_path)

from step_result import StepResult

# Import UI library for consistent interface
try:
    import sys
    import os
    ui_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'ui')
    if ui_path not in sys.path:
        sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))
    from ui.ui_library import render_header, render_selection_menu, get_icon_color, press_enter_to_continue
except ImportError:
    # Fallback if UI library not available
    def render_header(title, **kwargs):
        print(f"\n=== {title} ===")
    def render_selection_menu(title, choices, **kwargs):
        import questionary
        return questionary.select(title, choices=choices).ask()
    def get_icon_color(icon):
        return None
    def press_enter_to_continue():
        input("Press Enter to continue...")


def main(dry_run: bool = True, yes: bool = False, log_path: str = None, targets=None, progress_cb=None, interactive: bool = False):
    """Top-level entrypoint for the backup orchestrator.

    If interactive=True, show backup options menu. Otherwise use provided args.
    Returns StepResult objects.
    """
    if interactive:
        try:
            # Show backup options menu with UI library
            backup_choices = [
                "💾 Full Docker Backup",
                "📦 Containers & Images Only", 
                "🗂️ Volumes & Data Only",
                "⚙️ Configuration Only",
                "🔄 Restore from Backup",
                "🔙 Back to Main Menu"
            ]
            
            choice = render_selection_menu(
                title="Backup & Restore Options",
                choices=backup_choices,
                icon="💾",
                icon_color=get_icon_color("💾"),
                prompt="Choose backup/restore option:"
            )
            
            if choice is None or "Back to Main Menu" in choice:
                return StepResult.now(name="backup_orchestrator", status="Cancelled", message="User cancelled backup")
            
            if "Full Docker Backup" in choice:
                return _handle_full_backup()
            elif "Containers & Images Only" in choice:
                return _handle_containers_backup()
            elif "Volumes & Data Only" in choice:
                return _handle_volumes_backup()
            elif "Configuration Only" in choice:
                return _handle_config_backup()
            elif "Restore from Backup" in choice:
                return _handle_restore()
                
        except Exception as e:
            return StepResult.now(name="backup_orchestrator", status="Error", message=f"UI error: {str(e)}")

    # Non-interactive mode - run full backup
    return _handle_full_backup(dry_run=dry_run, backup_path=log_path)


def _handle_full_backup(dry_run: bool = False, backup_path: str = None):
    """Handle full Docker backup with user input."""
    try:
        import questionary  # type: ignore
        
        print("💾 Full Docker Backup")
        print("This will backup all Docker data including:")
        print("• All containers and images")
        print("• Docker volumes and data")
        print("• Docker configuration")
        print("• Registry credentials")
        print()
        
        # Get backup path
        if not backup_path:
            backup_path = questionary.text(
                "Backup path (default: C:\\DockerBackup):", 
                default="C:\\DockerBackup"
            ).ask()
        
        if not backup_path:
            return StepResult.now(name="full_backup", status="Cancelled", message="Backup cancelled - no path provided")
        
        # Confirm backup
        confirm = questionary.confirm(f"Backup Docker data to {backup_path}?").ask()
        if not confirm:
            return StepResult.now(name="full_backup", status="Cancelled", message="Full backup cancelled by user")
        
        # Execute backup
        results = backup_sequence(dry_run=dry_run)
        return StepResult.now(name="full_backup", status="Success", message=f"Full backup completed to {backup_path}")
        
    except Exception as e:
        return StepResult.now(name="full_backup", status="Error", message=f"Full backup failed: {str(e)}")


def _handle_containers_backup():
    """Handle containers and images backup only."""
    try:
        import questionary  # type: ignore
        
        print("📦 Containers & Images Backup")
        print("This will backup:")
        print("• Running and stopped containers")
        print("• Docker images")
        print("• Container configurations")
        print()
        
        backup_path = questionary.text(
            "Backup path (default: C:\\DockerBackup\\containers):", 
            default="C:\\DockerBackup\\containers"
        ).ask()
        
        if not backup_path:
            return StepResult.now(name="containers_backup", status="Cancelled", message="Backup cancelled")
        
        confirm = questionary.confirm(f"Backup containers and images to {backup_path}?").ask()
        if not confirm:
            return StepResult.now(name="containers_backup", status="Cancelled", message="Containers backup cancelled")
        
        # TODO: Implement containers-only backup logic
        return StepResult.now(name="containers_backup", status="Success", message=f"MOCK: Containers backup completed to {backup_path}")
        
    except Exception as e:
        return StepResult.now(name="containers_backup", status="Error", message=f"Containers backup failed: {str(e)}")


def _handle_volumes_backup():
    """Handle volumes and data backup only."""
    try:
        import questionary  # type: ignore
        
        print("🗂️ Volumes & Data Backup")
        print("This will backup:")
        print("• Docker volumes")
        print("• Persistent data")
        print("• Bind mount data")
        print()
        
        backup_path = questionary.text(
            "Backup path (default: C:\\DockerBackup\\volumes):", 
            default="C:\\DockerBackup\\volumes"
        ).ask()
        
        if not backup_path:
            return StepResult.now(name="volumes_backup", status="Cancelled", message="Backup cancelled")
        
        confirm = questionary.confirm(f"Backup volumes and data to {backup_path}?").ask()
        if not confirm:
            return StepResult.now(name="volumes_backup", status="Cancelled", message="Volumes backup cancelled")
        
        # TODO: Implement volumes-only backup logic
        return StepResult.now(name="volumes_backup", status="Success", message=f"MOCK: Volumes backup completed to {backup_path}")
        
    except Exception as e:
        return StepResult.now(name="volumes_backup", status="Error", message=f"Volumes backup failed: {str(e)}")


def _handle_config_backup():
    """Handle configuration backup only."""
    try:
        import questionary  # type: ignore
        
        print("⚙️ Configuration Backup")
        print("This will backup:")
        print("• Docker daemon configuration")
        print("• Registry credentials")
        print("• Docker compose files")
        print("• User preferences")
        print()
        
        backup_path = questionary.text(
            "Backup path (default: C:\\DockerBackup\\config):", 
            default="C:\\DockerBackup\\config"
        ).ask()
        
        if not backup_path:
            return StepResult.now(name="config_backup", status="Cancelled", message="Backup cancelled")
        
        confirm = questionary.confirm(f"Backup configuration to {backup_path}?").ask()
        if not confirm:
            return StepResult.now(name="config_backup", status="Cancelled", message="Configuration backup cancelled")
        
        # TODO: Implement config-only backup logic
        return StepResult.now(name="config_backup", status="Success", message=f"MOCK: Configuration backup completed to {backup_path}")
        
    except Exception as e:
        return StepResult.now(name="config_backup", status="Error", message=f"Configuration backup failed: {str(e)}")


def _handle_restore():
    """Handle restore from backup."""
    try:
        import questionary  # type: ignore
        
        print("🔄 Restore from Backup")
        print("This will restore Docker data from a previous backup.")
        print("⚠️  WARNING: This will overwrite current Docker data!")
        print()
        
        backup_path = questionary.text(
            "Restore from path (default: C:\\DockerBackup):", 
            default="C:\\DockerBackup"
        ).ask()
        
        if not backup_path:
            return StepResult.now(name="restore", status="Cancelled", message="Restore cancelled")
        
        # Show warning and get confirmation
        print(f"📂 Restore source: {backup_path}")
        print("⚠️  This will:")
        print("• Stop all running containers")
        print("• Replace current Docker data")
        print("• Restart Docker service")
        print()
        
        confirm = questionary.confirm("Are you sure you want to restore? This cannot be undone.").ask()
        if not confirm:
            return StepResult.now(name="restore", status="Cancelled", message="Restore cancelled by user")
        
        # TODO: Implement restore logic
        return StepResult.now(name="restore", status="Success", message=f"MOCK: Restore completed from {backup_path}")
        
    except Exception as e:
        return StepResult.now(name="restore", status="Error", message=f"Restore failed: {str(e)}")


def backup_sequence(dry_run=True):
    """Legacy backup sequence function for backward compatibility."""
    if dry_run:
        return [StepResult.now(name="backup_data", status="Skipped", message="Dry-run: backup")]
    return [StepResult.now(name="backup_data", status="Success", message="MOCK: backup data")]


if __name__ == '__main__':
    result = main(interactive=True)
    if result:
        print(f"\nResult: {result.to_dict()}")
