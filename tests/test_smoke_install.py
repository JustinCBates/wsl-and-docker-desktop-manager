def test_import_package():
    import importlib
    mod = importlib.import_module("wsl_and_docker_desktop_manager")
    assert mod is not None
