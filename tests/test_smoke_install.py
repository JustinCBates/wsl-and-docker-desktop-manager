def test_import_package():
    # Import a canonical module to ensure src/ modules are importable
    from src.install import install_orchestrator
    assert hasattr(install_orchestrator, 'main')
