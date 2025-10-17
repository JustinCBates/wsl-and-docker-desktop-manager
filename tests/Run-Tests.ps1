#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.0.0" }

<#
.SYNOPSIS
    Comprehensive test runner with integrated linting and todo list generation
.DESCRIPTION
    Executes all unit and integration tests, runs linters across all file types,
    and automatically populates a todo list with any issues found.
#>

param(
    [switch]$SkipTests = $false,
    [switch]$SkipLinting = $false,
    [switch]$UpdateTodoList = $true,
    [ValidateSet("All", "Unit", "Integration")]
    [string]$TestType = "All",
    [switch]$Detailed = $false
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path $PSScriptRoot -Parent

# Results tracking
$script:lintingIssues = @()
$script:testResults = $null

function Write-TestHeader {
    param([string]$Title)
    Write-Host "`n" -NoNewline
    Write-Host "=" * 80 -ForegroundColor Cyan
    Write-Host "  $Title" -ForegroundColor Green
    Write-Host "=" * 80 -ForegroundColor Cyan
}

function Write-TestSection {
    param([string]$Message)
    Write-Host "`n>> $Message" -ForegroundColor Yellow
}

function Get-LintingIssues {
    Write-TestHeader "RUNNING COMPREHENSIVE LINTING"
    
    $issues = @()
    
    # PowerShell Linting
    Write-TestSection "Linting PowerShell files..."
    $psFiles = Get-ChildItem -Path $projectRoot -Recurse -Filter *.ps1 -Exclude "*.Tests.ps1" |
        Where-Object { $_.FullName -notlike "*\tests\*" -and $_.FullName -notlike "*\.venv\*" }
    
    foreach ($file in $psFiles) {
        $results = Invoke-ScriptAnalyzer -Path $file.FullName -Severity Warning,Error
        foreach ($result in $results) {
            $issues += [PSCustomObject]@{
                File = $file.Name
                Line = $result.Line
                Severity = $result.Severity
                Rule = $result.RuleName
                Message = $result.Message
                Type = "PowerShell"
            }
        }
    }
    
    # Python Linting
    Write-TestSection "Linting Python files..."
    $pyFiles = Get-ChildItem -Path $projectRoot -Filter *.py
    foreach ($file in $pyFiles) {
        try {
            $pylintOutput = & python -m pylint $file.FullName --output-format=json 2>&1 | Out-String
            if ($pylintOutput -and $pylintOutput.Trim() -ne "[]") {
                $pylintResults = $pylintOutput | ConvertFrom-Json -ErrorAction SilentlyContinue
                foreach ($result in $pylintResults) {
                    if ($result.type -ne "convention" -and $result.type -ne "refactor") {
                        $issues += [PSCustomObject]@{
                            File = $file.Name
                            Line = $result.line
                            Severity = $result.type
                            Rule = $result.'message-id'
                            Message = $result.message
                            Type = "Python"
                        }
                    }
                }
            }
        }
        catch {
            Write-Warning "Failed to lint $($file.Name): $_"
        }
    }
    
    # Batch File Validation
    Write-TestSection "Validating Batch files..."
    $batFiles = Get-ChildItem -Path $projectRoot -Recurse -Filter *.bat
    foreach ($file in $batFiles) {
        # Basic syntax check - looking for common issues
        $content = Get-Content $file.FullName -Raw
        if ($content -match '@echo\s+[^o]') {
            $issues += [PSCustomObject]@{
                File = $file.Name
                Line = 1
                Severity = "Warning"
                Rule = "BatchSyntax"
                Message = "Consider using @echo off for cleaner output"
                Type = "Batch"
            }
        }
    }
    
    return $issues
}

function New-TodoListFromIssues {
    param(
        [Parameter(Mandatory)]
        [array]$Issues,
        [Parameter()]
        [object]$TestResults
    )
    
    Write-TestSection "Generating Todo List from Issues..."
    
    $todos = @()
    $todoId = 1
    
    # Group linting issues by rule for better organization
    $groupedIssues = $Issues | Group-Object -Property Rule
    
    foreach ($group in $groupedIssues) {
        $rule = $group.Name
        $count = $group.Count
        $affectedFiles = ($group.Group | Select-Object -ExpandProperty File -Unique) -join ", "
        $sampleMessage = $group.Group[0].Message
        
        $priority = switch ($group.Group[0].Severity) {
            "Error" { "high" }
            "error" { "high" }
            "Warning" { "medium" }
            "warning" { "medium" }
            default { "low" }
        }
        
        $todos += [PSCustomObject]@{
            id = $todoId++
            title = "Fix $rule ($count instance$(if($count -gt 1){'s'}))"
            description = "$sampleMessage | Affected files: $affectedFiles"
            status = "not-started"
            priority = $priority
        }
    }
    
    # Add test failures if any
    if ($TestResults -and $TestResults.FailedCount -gt 0) {
        $todos += [PSCustomObject]@{
            id = $todoId++
            title = "Fix $($TestResults.FailedCount) failing test$(if($TestResults.FailedCount -gt 1){'s'})"
            description = "Tests failed in: $($TestResults.Failed.Path -join ', ')"
            status = "not-started"
            priority = "high"
        }
    }
    
    return $todos
}

function Export-TodoListFile {
    param([array]$Todos)
    
    $todoFile = Join-Path $projectRoot "TODO.md"
    $content = @"
# Todo List - Generated $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

"@
    
    # Group by priority
    $highPriority = $Todos | Where-Object priority -eq "high"
    $mediumPriority = $Todos | Where-Object priority -eq "medium"
    $lowPriority = $Todos | Where-Object priority -eq "low"
    
    if ($highPriority) {
        $content += "`n## High Priority`n`n"
        foreach ($todo in $highPriority) {
            $content += "- [ ] **$($todo.title)**`n"
            $content += "  - $($todo.description)`n`n"
        }
    }
    
    if ($mediumPriority) {
        $content += "`n## Medium Priority`n`n"
        foreach ($todo in $mediumPriority) {
            $content += "- [ ] $($todo.title)`n"
            $content += "  - $($todo.description)`n`n"
        }
    }
    
    if ($lowPriority) {
        $content += "`n## Low Priority`n`n"
        foreach ($todo in $lowPriority) {
            $content += "- [ ] $($todo.title)`n"
            $content += "  - $($todo.description)`n`n"
        }
    }
    
    Set-Content -Path $todoFile -Value $content -Encoding UTF8
    Write-Host "`n✅ Todo list exported to: $todoFile" -ForegroundColor Green
}

# Main execution
try {
    Write-TestHeader "WSL & DOCKER MANAGER - TEST & QUALITY SUITE"
    
    # Run Tests
    if (-not $SkipTests) {
        Write-TestSection "Running Pester Tests..."
        
        $pesterConfig = New-PesterConfiguration
        $pesterConfig.Run.Path = $PSScriptRoot
        $pesterConfig.Output.Verbosity = if ($Detailed) { "Detailed" } else { "Normal" }
        $pesterConfig.TestResult.Enabled = $true
        $pesterConfig.TestResult.OutputPath = Join-Path $PSScriptRoot "TestResults.xml"
        
        if ($TestType -eq "Unit") {
            $pesterConfig.Run.Path = Join-Path $PSScriptRoot "unit"
        }
        elseif ($TestType -eq "Integration") {
            $pesterConfig.Run.Path = Join-Path $PSScriptRoot "integration"
        }
        
        $script:testResults = Invoke-Pester -Configuration $pesterConfig
        
        Write-Host "`n📊 TEST SUMMARY:" -ForegroundColor Cyan
        Write-Host "  Total: $($testResults.TotalCount)" -ForegroundColor White
        Write-Host "  Passed: $($testResults.PassedCount)" -ForegroundColor Green
        Write-Host "  Failed: $($testResults.FailedCount)" -ForegroundColor $(if($testResults.FailedCount -gt 0){"Red"}else{"Green"})
        Write-Host "  Skipped: $($testResults.SkippedCount)" -ForegroundColor Yellow
    }
    
    # Run Linting
    if (-not $SkipLinting) {
        $script:lintingIssues = Get-LintingIssues
        
        Write-Host "`n📋 LINTING SUMMARY:" -ForegroundColor Cyan
        $errorCount = ($lintingIssues | Where-Object Severity -in "Error","error").Count
        $warningCount = ($lintingIssues | Where-Object Severity -in "Warning","warning").Count
        
        Write-Host "  Errors: $errorCount" -ForegroundColor $(if($errorCount -gt 0){"Red"}else{"Green"})
        Write-Host "  Warnings: $warningCount" -ForegroundColor $(if($warningCount -gt 0){"Yellow"}else{"Green"})
        
        if ($Detailed -and $lintingIssues.Count -gt 0) {
            Write-Host "`n  Top Issues:" -ForegroundColor White
            $topIssues = $lintingIssues | Group-Object Rule | Sort-Object Count -Descending | Select-Object -First 5
            foreach ($issue in $topIssues) {
                Write-Host "    - $($issue.Name): $($issue.Count) occurrences" -ForegroundColor Gray
            }
        }
    }
    
    # Generate Todo List
    if ($UpdateTodoList -and ($lintingIssues.Count -gt 0 -or ($testResults -and $testResults.FailedCount -gt 0))) {
        $todos = New-TodoListFromIssues -Issues $lintingIssues -TestResults $testResults
        Export-TodoListFile -Todos $todos
    }
    
    # Exit with appropriate code
    $hasErrors = ($lintingIssues | Where-Object Severity -in "Error","error").Count -gt 0
    $hasFailedTests = $testResults -and $testResults.FailedCount -gt 0
    
    if ($hasErrors -or $hasFailedTests) {
        Write-Host "`n❌ QUALITY CHECK FAILED" -ForegroundColor Red
        exit 1
    }
    else {
        Write-Host "`n✅ QUALITY CHECK PASSED" -ForegroundColor Green
        exit 0
    }
}
catch {
    Write-Host "`n❌ ERROR: $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}
