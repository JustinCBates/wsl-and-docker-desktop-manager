# tools/protect documentation (development)

This document describes the `tools/protect` helper scripts included in the repository. These are developer-side utilities intended to assist with repository hygiene and protective operations. They live under `tools/protect/` and are for maintainers.

Included scripts

- `tools/protect/prevent_root_dirs.py` — checks paths and prevents accidental operations on root directories. Usage:

```powershell
python tools/protect/prevent_root_dirs.py --path C:\some\path
```

What it does
- The script validates input paths and refuses to proceed when the path appears to be a system root (for example `C:\` or `/`). It is a safety check used by other helper scripts to prevent destructive operations.

Integrations
- The `tools/acl` and `tools/elevate` helpers integrate safety checks from `tools/protect` before making changes to ACLs or running elevated commands.

Developer notes
- These scripts are small helpers and not part of the runtime package. They live under `tools/` per the repository guiderails.
- If you need expanded functionality (interactive prompts, logging to a file), I can add examples and unit tests in a follow-up.
