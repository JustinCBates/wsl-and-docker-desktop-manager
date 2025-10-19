"""Uninstall orchestrator using StepRunner and StepResult (mocks-first).

This orchestrator composes small provider functions and returns a list of StepResult objects.
"""
import os
import sys

# Add parent src directory to path for imports
src_path = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if src_path not in sys.path:
    sys.path.insert(0, src_path)

from step_runner import StepRunner
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
from .docker.uninstall_docker import uninstall_docker
from .wsl.uninstall_wsl import unregister_wsl
import subprocess
import sys
import os


def _run_elevated_script(script_path: str, args=None) -> StepResult:
    """Run a script with UAC elevation using the repository helper and return a StepResult."""
    args = args or []
    repo_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
    helper = os.path.join(repo_root, 'tools', 'elevate', 'run_elevated.py')
    if not os.path.exists(helper):
        return StepResult(name=os.path.basename(script_path), status='Error', message='elevate helper missing', error='helper not found')
    cmd = [sys.executable, helper, script_path] + args
    try:
        proc = subprocess.run(cmd, check=False)
        if proc.returncode == 0:
            return StepResult(name=os.path.basename(script_path), status='Ok', message='elevated action completed')
        return StepResult(name=os.path.basename(script_path), status='Failed', message='elevated action failed', error=f'exit {proc.returncode}')
    except Exception as e:
        return StepResult(name=os.path.basename(script_path), status='Error', message='exception during elevation', error=str(e))

def uninstall_sequence(yes: bool = False, dry_run: bool = True, progress_cb=None):
    """Run uninstall sequence. Optional progress_cb(event_dict, event_type) will be called if provided."""
    runner = StepRunner(dry_run=dry_run)
    results = []

    def _emit(event: dict, event_type: str):
        if not progress_cb:
            return
        try:
            progress_cb(event, event_type)
        except Exception:
            # never let UI callback failures abort the orchestrator
            pass

    repo_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))

    # stop_docker: no-op placeholder
    _emit({"step_id": "stop_docker", "name": "stop_docker"}, "step-start")
    res = runner.invoke("stop_docker", None)
    _emit({"step_id": "stop_docker", "status": getattr(res, 'status', 'Unknown')}, "step-end")
    results.append(res)

    # uninstall_docker: requires explicit yes
    if dry_run:
        _emit({"step_id": "uninstall_docker", "name": "uninstall_docker"}, "step-start")
        res = runner.invoke("uninstall_docker", uninstall_docker, yes_required=True, yes=yes)
        _emit({"step_id": "uninstall_docker", "status": getattr(res, 'status', 'Unknown')}, "step-end")
        results.append(res)
    else:
        # call elevated PowerShell uninstall script (mock placeholder)
        script = os.path.join(repo_root, 'tools', 'protect', 'uninstall_docker.ps1')
        _emit({"step_id": "uninstall_docker", "name": "uninstall_docker"}, "step-start")
        res = runner.invoke("uninstall_docker", lambda: _run_elevated_script(script), yes_required=True, yes=yes)
        _emit({"step_id": "uninstall_docker", "status": getattr(res, 'status', 'Unknown')}, "step-end")
        results.append(res)

    # unregister_wsl: requires explicit yes
    if dry_run:
        _emit({"step_id": "unregister_wsl", "name": "unregister_wsl"}, "step-start")
        res = runner.invoke("unregister_wsl", unregister_wsl, yes_required=True, yes=yes)
        _emit({"step_id": "unregister_wsl", "status": getattr(res, 'status', 'Unknown')}, "step-end")
        results.append(res)
    else:
        script = os.path.join(repo_root, 'tools', 'protect', 'unregister_wsl.ps1')
        _emit({"step_id": "unregister_wsl", "name": "unregister_wsl"}, "step-start")
        res = runner.invoke("unregister_wsl", lambda: _run_elevated_script(script), yes_required=True, yes=yes)
        _emit({"step_id": "unregister_wsl", "status": getattr(res, 'status', 'Unknown')}, "step-end")
        results.append(res)

    return results


def main(dry_run: bool = True, yes: bool = False, log_path: str = None, targets=None, progress_cb=None, interactive: bool = False):
    """Top-level entrypoint for the uninstall orchestrator.

    If interactive=True and `questionary` is available, show uninstall options menu.
    Otherwise use provided args. Returns StepResult objects.
    """
    if interactive:
        try:
            # Show uninstall options menu with UI library
            uninstall_choices = [
                "🔄 Complete System Reset",
                "🗑️ Remove WSL Only", 
                "🐳 Remove Docker Only",
                "🔙 Back to Main Menu"
            ]
            
            choice = render_selection_menu(
                title="Uninstall Options",
                choices=uninstall_choices,
                icon="🔄",
                icon_color=get_icon_color("🔄"),
                prompt="Choose uninstall option:"
            )
            
            if choice is None or "Back to Main Menu" in choice:
                return StepResult.now(name="uninstall_orchestrator", status="Cancelled", message="User cancelled uninstall")
            
            if "Complete System Reset" in choice:
                return _handle_complete_reset()
            elif "Remove WSL Only" in choice:
                return _handle_wsl_only_removal()
            elif "Remove Docker Only" in choice:
                return _handle_docker_only_removal()
                
        except Exception as e:
            return StepResult.now(name="uninstall_orchestrator", status="Error", message=f"UI error: {str(e)}")

    return uninstall_sequence(yes=yes, dry_run=dry_run, progress_cb=progress_cb)


def _handle_complete_reset():
    """Handle complete system reset with user confirmation."""
    try:
        import questionary  # type: ignore
        
        # Render header with UI library
        render_header("Complete System Reset", icon="🔄", icon_color=get_icon_color("🔄"))
        print("This will completely remove WSL and Docker Desktop:")
        print("• Uninstall all WSL distributions")
        print("• Uninstall Docker Desktop")
        print("• Remove all associated data")
        print("⚠️  WARNING: This action is destructive and cannot be undone!")
        print()
        
        # Get user confirmation for destructive action
        confirm = questionary.confirm("Do you want to proceed with complete system reset?").ask()
        if not confirm:
            return StepResult.now(name="complete_reset", status="Cancelled", message="System reset cancelled by user")
        
        # Ask about dry-run
        dry_run = questionary.confirm("Dry-run (no changes)?", default=True).ask()
        yes = not dry_run  # If not dry-run, then yes to destructive actions
        
        results = uninstall_sequence(yes=yes, dry_run=dry_run)
        return results if isinstance(results, StepResult) else StepResult.now(name="complete_reset", status="Success", message="Complete reset completed")
        
    except Exception as e:
        return StepResult.now(name="complete_reset", status="Error", message=f"Complete reset failed: {str(e)}")


def _handle_wsl_only_removal():
    """Handle WSL-only removal."""
    try:
        import questionary  # type: ignore
        
        print("🗑️ Remove WSL Only")
        print("This will remove WSL distributions while keeping Docker Desktop:")
        print("• Unregister all WSL distributions")
        print("• Keep Docker Desktop installation")
        print()
        
        confirm = questionary.confirm("Do you want to proceed with WSL removal?").ask()
        if not confirm:
            return StepResult.now(name="wsl_removal", status="Cancelled", message="WSL removal cancelled by user")
        
        dry_run = questionary.confirm("Dry-run (no changes)?", default=True).ask()
        
        # TODO: Implement WSL-only removal logic
        return StepResult.now(name="wsl_removal", status="Success", message="MOCK: WSL removal completed")
        
    except Exception as e:
        return StepResult.now(name="wsl_removal", status="Error", message=f"WSL removal failed: {str(e)}")


def _handle_docker_only_removal():
    """Handle Docker-only removal."""
    try:
        import questionary  # type: ignore
        
        print("🐳 Remove Docker Only")
        print("This will remove Docker Desktop while keeping WSL:")
        print("• Uninstall Docker Desktop")
        print("• Keep WSL distributions")
        print()
        
        confirm = questionary.confirm("Do you want to proceed with Docker removal?").ask()
        if not confirm:
            return StepResult.now(name="docker_removal", status="Cancelled", message="Docker removal cancelled by user")
        
        dry_run = questionary.confirm("Dry-run (no changes)?", default=True).ask()
        
        # TODO: Implement Docker-only removal logic
        return StepResult.now(name="docker_removal", status="Success", message="MOCK: Docker removal completed")
        
    except Exception as e:
        return StepResult.now(name="docker_removal", status="Error", message=f"Docker removal failed: {str(e)}")
