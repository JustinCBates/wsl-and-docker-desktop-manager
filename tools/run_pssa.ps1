Param(
    [string]$Path = '.'
)

try {
    $errors = Invoke-ScriptAnalyzer -Path $Path -Recurse -IncludeRule 'PSAvoidUsingWriteHost' -Severity Warning,Error
    if ($errors) {
        $errors | Select-Object FilePath,Line,RuleName,Message | Format-Table -AutoSize
    } else {
        Write-Output "No PSAvoidUsingWriteHost findings in $Path"
    }
} catch {
    Write-Error "Invoke-ScriptAnalyzer failed: $_"
    exit 1
}
