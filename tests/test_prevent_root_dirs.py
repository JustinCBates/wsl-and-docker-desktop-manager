import importlib.util
import os
from pathlib import Path


def load_module(path: Path):
    spec = importlib.util.spec_from_file_location("prevent_root_dirs", str(path))
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def test_detects_new_top_level_dir(tmp_path, monkeypatch):
    # No existing top-level dirs created
    script = Path("tools/acl/prevent_root_dirs.py")
    mod = load_module(script)

    # Simulate git showing an added file under newtop/file.txt
    monkeypatch.setattr(mod.subprocess, "check_output", lambda *a, **k: b"A\tnewtop/file.txt\n")

    # Change cwd to tmp path so os.listdir returns empty set
    monkeypatch.chdir(tmp_path)

    rc = mod.main()
    assert rc == 1


def test_allows_existing_top_level_dir(tmp_path, monkeypatch):
    # Create an existing top-level dir 'src'
    (tmp_path / "src").mkdir()
    script = Path("tools/acl/prevent_root_dirs.py")
    mod = load_module(script)

    # Simulate git showing an added file under src/new.py (top-level is 'src' which exists)
    monkeypatch.setattr(mod.subprocess, "check_output", lambda *a, **k: b"A\tsrc/new.py\n")

    monkeypatch.chdir(tmp_path)

    rc = mod.main()
    assert rc == 0
