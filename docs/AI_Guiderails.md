# Development guide rails

These are repository-level constraints and rules to guide development for the MVP. They are intentionally strict to keep changes focused and reviewable.

- Documentation-only policy: any non-code documentation created by the assistant must be placed in the `docs/` directory. The assistant may also edit the root `README.md`, and `README.md` files located in the `src/`, `tools/`, and `tests/` directories.
- No code outside `src/`, `tests/`, or `tools/`: the assistant must not create or modify source code files outside the `src/`, `tests/`, and `tools/` directories unless you (the repo owner) explicitly approve and provide a reason.
- Tests framework deferred: references to Pester or other test frameworks are considered backlog items. Test framework selection and CI wiring will be addressed after core UI flows are validated with mocks.
- Single root orchestrator: there should be one canonical orchestrator entrypoint located at the repository root (for example `orchestrator.ps1` or `orchestrator.sh`). This orchestrator coordinates high-level tasks. A bootstrap script for initializing the Python environment and dependencies (for example `init-python.sh`) may also exist at the repo root.
- Mocks-first approach: initial implementations for UI testing will use mock functions inside `src/` only. These mocks must be inert and clearly labeled.
- Ask before global changes: if any change requires adding files outside `src/`, `tests/`, or `tools/`, the assistant must request explicit permission and provide a justification.

### Placement of new code

- Do not create new top-level directories (for example `scripts/orchestrator/`) without explicit approval. If a shared library or helper is required for the orchestrator, place it under `src/` by default. For example, the StepRunner library should live at `src/orchestrator/StepRunner.ps1` (or a similar path under `src/`) unless you approve an alternative location and provide a rationale.

Additions that deviate from these placement rules require your sign-off.

---

Notes:
- I extracted these rules from `docs/spec.md` into this file so they can be referenced, edited, and versioned separately. The `spec.md` now links to this file.
- If you'd like the guide rails renamed (for example `CONTRIBUTING_AI.md` or `AI_GUIDELINES.md`) I can rename the file and update the link in `docs/spec.md`.
