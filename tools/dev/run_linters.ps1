<# Run ruff against the src directory. #>
param()

python -m ruff check src || exit $LASTEXITCODE
& "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)\..\run_linters.ps1" @Args
