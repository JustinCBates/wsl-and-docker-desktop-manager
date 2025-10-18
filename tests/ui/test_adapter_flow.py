def test_adapter_calls(monkeypatch):
    from src.ui import adapter

    called = {}

    def fake_main(dry_run=True, yes=False, log_path=None, targets=None):
        called['args'] = dict(dry_run=dry_run, yes=yes, log_path=log_path, targets=targets)
        class R:
            name = 'fake'
            status = 'Success'
        return R()

    monkeypatch.setitem(__import__('sys').modules, 'src.status.status_orchestrator', type('M', (), {'main': staticmethod(fake_main)}))

    res = adapter.run_flow('status', dry_run=True)
    assert isinstance(res, list)
    assert called['args']['dry_run'] is True
