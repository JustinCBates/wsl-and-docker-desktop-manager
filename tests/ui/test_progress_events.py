def test_progress_events(monkeypatch):
    from src.ui import adapter

    events = []

    def cb(event, event_type):
        events.append((event_type, event))

    # Run the uninstall flow in dry-run which uses the uninstall_orchestrator
    res = adapter.run_flow('uninstall', dry_run=True, progress_cb=cb)
    # adapter normalizes to a list
    assert isinstance(res, list)
    # progress events should include step-start and step-end for at least one step
    types = [t for t, _ in events]
    assert 'step-start' in types and 'step-end' in types
