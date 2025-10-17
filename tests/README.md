# Test Framework Documentation

## Overview

This comprehensive test framework provides:
- **Unit Tests**: Fast, isolated tests for individual functions
- **Integration Tests**: Real-world scenario validation
- **Automated Linting**: Multi-language code quality checks
- **Todo List Generation**: Automatic issue tracking from linter output

## Quick Start

### Prerequisites

```powershell
# Install Pester 5.x
Install-Module -Name Pester -MinimumVersion 5.0.0 -Force -SkipPublisherCheck

# Install PSScriptAnalyzer for PowerShell linting
Install-Module -Name PSScriptAnalyzer -Force

# Ensure Python environment with pylint
pip install pylint
```

### Running Tests

```powershell
# Run all tests and linting (generates TODO.md)
.\tests\Run-Tests.ps1

# Run only unit tests
.\tests\Run-Tests.ps1 -TestType Unit

# Run only integration tests  
.\tests\Run-Tests.ps1 -TestType Integration

# Skip tests, run linting only
.\tests\Run-Tests.ps1 -SkipTests

# Skip linting, run tests only
.\tests\Run-Tests.ps1 -SkipLinting

# Detailed output
.\tests\Run-Tests.ps1 -Detailed

# Don't update todo list
.\tests\Run-Tests.ps1 -UpdateTodoList:$false
```

## Directory Structure

```
tests/
├── Run-Tests.ps1              # Main test runner with linting integration
├── README.md                  # This file
├── TestResults.xml            # Generated: Pester test results
├── unit/                      # Unit tests (fast, mocked)
│   ├── Get-DockerStatus.Tests.ps1
│   ├── Get-WSLStatus.Tests.ps1
│   └── Install-Orchestrator.Tests.ps1
├── integration/               # Integration tests (slow, real system)
│   └── SystemIntegration.Tests.ps1
└── fixtures/                  # Test data and mock configurations
```

## Writing Tests

### Unit Test Example

```powershell
BeforeAll {
    # Import module to test
    . "$PSScriptRoot\..\..\scripts\status\Get-DockerStatus.ps1"
}

Describe "Get-DockerStatus" {
    Context "When Docker is not installed" {
        BeforeAll {
            Mock Test-Path { return $false }
        }
        
        It "Should return Docker as not available" {
            $result = Test-DockerInstalled
            $result.Available | Should -Be $false
        }
    }
}
```

### Integration Test Example

```powershell
Describe "System Status Integration" -Tag "Integration" {
    It "Should return comprehensive status object" {
        $status = Get-SystemStatus
        $status | Should -Not -BeNullOrEmpty
        $status.WSL | Should -Not -BeNullOrEmpty
        $status.Docker | Should -Not -BeNullOrEmpty
    }
}
```

## Linting Integration

The test runner automatically:
1. Scans all PowerShell files with PSScriptAnalyzer
2. Lints Python files with pylint
3. Validates Batch file syntax
4. Groups issues by rule/severity
5. Generates prioritized TODO.md file

### Linting Output

Issues are categorized by:
- **High Priority**: Errors and critical warnings
- **Medium Priority**: Standard warnings
- **Low Priority**: Style issues and conventions

### Todo List Format

Generated `TODO.md` includes:
- Issue count by rule
- Affected files
- Sample error messages
- Priority levels
- Test failures (if any)

## Test Tags

Use tags to organize test execution:

```powershell
# Run only integration tests
Invoke-Pester -Path .\tests -Tag "Integration"

# Exclude slow tests
Invoke-Pester -Path .\tests -ExcludeTag "Slow"

# Run specific test groups
Invoke-Pester -Path .\tests -Tag "Unit","Fast"
```

## CI/CD Integration

### GitHub Actions Example

```yaml
- name: Run Tests
  run: |
    .\tests\Run-Tests.ps1 -Detailed
    if ($LASTEXITCODE -ne 0) { exit 1 }

- name: Upload Test Results
  uses: actions/upload-artifact@v3
  with:
    name: test-results
    path: tests/TestResults.xml
```

### Pre-Commit Hook

```powershell
# .git/hooks/pre-commit
.\tests\Run-Tests.ps1 -TestType Unit -SkipLinting
if ($LASTEXITCODE -ne 0) {
    Write-Host "Tests failed! Commit aborted." -ForegroundColor Red
    exit 1
}
```

## Best Practices

### Unit Tests
- ✅ Mock external dependencies
- ✅ Test one thing at a time
- ✅ Use descriptive test names
- ✅ Keep tests fast (<100ms each)
- ❌ Don't access real system resources

### Integration Tests
- ✅ Test real workflows
- ✅ Use `-Tag "Integration"` for filtering
- ✅ Accept slower execution
- ✅ Clean up test artifacts
- ❌ Don't modify production data

### Linting
- ✅ Fix critical errors before committing
- ✅ Address warnings gradually
- ✅ Use SuppressMessage for intentional exceptions
- ✅ Run linting before pull requests
- ❌ Don't ignore persistent warnings

## Troubleshooting

### Pester Not Found
```powershell
Install-Module -Name Pester -Force -SkipPublisherCheck
Import-Module Pester -MinimumVersion 5.0.0
```

### PSScriptAnalyzer Missing
```powershell
Install-Module -Name PSScriptAnalyzer -Force
```

### Python Linting Issues
```powershell
# Ensure pylint is installed
python -m pip install --upgrade pylint

# Verify installation
python -m pylint --version
```

### Test Failures
```powershell
# Run with detailed output
.\tests\Run-Tests.ps1 -Detailed

# Check TestResults.xml for details
Get-Content .\tests\TestResults.xml
```

## Extending the Framework

### Adding New Tests

1. Create test file: `tests/unit/MyModule.Tests.ps1`
2. Follow naming convention: `<ModuleName>.Tests.ps1`
3. Use Pester 5 syntax (BeforeAll, Context, It)
4. Run to verify: `Invoke-Pester -Path tests/unit/MyModule.Tests.ps1`

### Adding Linters

Edit `Run-Tests.ps1` and add to `Get-LintingIssues` function:

```powershell
# Example: Add JSON linting
$jsonFiles = Get-ChildItem -Path $projectRoot -Filter *.json
foreach ($file in $jsonFiles) {
    try {
        Get-Content $file.FullName | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        $issues += [PSCustomObject]@{
            File = $file.Name
            Line = 0
            Severity = "Error"
            Rule = "JSONSyntax"
            Message = $_.Exception.Message
            Type = "JSON"
        }
    }
}
```

## Performance Metrics

Typical execution times:
- Unit tests: ~5-10 seconds
- Integration tests: ~30-60 seconds
- PowerShell linting: ~10-15 seconds
- Python linting: ~2-5 seconds
- Total: ~1-2 minutes for full suite

## Support

For issues or questions:
1. Check test output with `-Detailed` flag
2. Review generated `TODO.md` for action items
3. Inspect `TestResults.xml` for test details
4. Check PowerShell error messages for stack traces
