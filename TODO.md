# Repository TODO (auto-generated snapshot)

Last updated: 2025-10-17

## Completed
- Fix PSUseBOMForUnicodeEncodedFile — completed
- Fix PSUseSingularNouns — completed
- Add ShouldProcess support — completed
- Fix minor lint issues — completed

## In progress
- Replace Write-Host across repo — in progress (bulk of interactive scripts converted; final sweep in progress)
- Update batch lint scripts to use run_pssa helper — in progress (LINT-ALL.bat and LINT-CODE.bat updated)

## Pending
- Regenerate TODO from analyzer runs and commit — pending
- Run tests and final analyzer pass — pending
- Investigate remaining non-Write-Host warnings (PSShouldProcess, PSReviewUnusedParameter, PSUseDeclaredVarsMoreThanAssignments, PSAvoidUsingCmdletAliases) — pending

## Notes
- A helper script `tools\run_pssa.ps1` was added to run Invoke-ScriptAnalyzer safely and avoid one-liner quoting problems.
- Documentation files and batch files may still contain `Write-Host` examples; these are intentionally preserved in docs unless you want them changed.

If you want me to proceed I will run Pester tests next and then a final analyzer pass across the three workspace repos. If any test failures or linter findings remain, I'll add specific fixes to the TODO and apply them.