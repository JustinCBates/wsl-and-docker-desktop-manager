"""Simple demo to exercise the UI adapter and progress_cb without an interactive UI.

Run: python scripts/ui_demo.py
"""
from src.ui import adapter


def ui_cb(event, event_type):
    print(f"EVENT {event_type}: {event}")


def main():
    print("Running uninstall (dry-run) with progress callback...")
    results = adapter.run_flow('uninstall', dry_run=True, progress_cb=ui_cb)
    print("Final results:")
    for r in results:
        try:
            print(f" - {r.name}: {r.status} - {getattr(r, 'message', '')}")
        except Exception:
            print(r)


if __name__ == '__main__':
    main()
