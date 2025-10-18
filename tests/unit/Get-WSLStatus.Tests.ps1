<# Minimal, clean Pester v3-compatible WSL tests #>

$statusModulePath = Join-Path $PSScriptRoot "..\..\scripts\status\Get-WSLStatus.ps1"

Describe "Get-WSLStatus basic" {
    Context "WSL not installed" {
        BeforeAll { Mock wsl { throw 'wsl command not found' }; . $statusModulePath }
        It "reports not installed" { (Test-WSLInstalled) | Should Be $false }
    }

    Context "WSL version parsing" {
        BeforeAll { Mock wsl { param($a) if ($a -and $a -contains '--version') { $global:LASTEXITCODE = 0; return @"
WSL version: 2.0.9.0
"@ } }; . $statusModulePath }
        It "parses version" { (Get-WSLVersion).Version | Should Match '\d+\.\d+\.\d+' }
    }

    Context "Distribution list parsing" {
        BeforeAll { Mock wsl { return @"
Ubuntu-22.04
docker-desktop
"@ }; . $statusModulePath }
        It "returns distributions" { (Get-WSLDistribution) | Should Contain 'Ubuntu-22.04' }
    }
}
<#
Unit tests for WSL status helpers (Pester v3 compatible)
These tests mock the external wsl and Windows feature commands and dot-source the module
after mocks are in place so Pester can intercept calls.
#>

$statusModulePath = Join-Path $PSScriptRoot "..\..\scripts\status\Get-WSLStatus.ps1"

Describe "Get-WSLStatusHelpers" {
    Context "Test-WSLInstalled when WSL missing" {
        BeforeAll {
            Mock wsl { $global:LASTEXITCODE = 1; throw "wsl command not found" }
            . $statusModulePath
        }

        It "returns False" {
            (Test-WSLInstalled) | Should Be $false
        }
    }

    Context "Get-WSLVersion when present" {
        BeforeAll {
            Mock wsl { param($a) if ($a -contains '--version') { $global:LASTEXITCODE = 0; return @"
WSL version: 2.0.9.0
Kernel version: 5.15.133.1
<#
Unit tests for WSL status helpers (Pester v3 compatible)
These tests mock external commands and dot-source the status module inside each Context
after mocks are in place so Pester can intercept the calls.
#>

$statusModulePath = Join-Path $PSScriptRoot "..\..\scripts\status\Get-WSLStatus.ps1"

Describe "Get-WSLStatusHelpers" {
    Context "Test-WSLInstalled when WSL missing" {
        BeforeAll {
            Mock wsl { $global:LASTEXITCODE = 1; throw "wsl command not found" }
            . $statusModulePath
        }

        It "returns False" {
            (Test-WSLInstalled) | Should Be $false
        }
    }

    Context "Get-WSLVersion when present" {
        BeforeAll {
            Mock wsl { param($a) if ($a -contains '--version') { $global:LASTEXITCODE = 0; return @"
WSL version: 2.0.9.0
Kernel version: 5.15.133.1
<# Minimal, clean Pester v3-compatible WSL tests #>

$statusModulePath = Join-Path $PSScriptRoot "..\..\scripts\status\Get-WSLStatus.ps1"

Describe "Get-WSLStatus basic" {
    Context "WSL not installed" {
        BeforeAll { Mock wsl { throw 'wsl command not found' }; . $statusModulePath }
        It "reports not installed" { (Test-WSLInstalled) | Should Be $false }
    }

    Context "WSL version parsing" {
        BeforeAll { Mock wsl { param($a) if ($a -contains '--version') { return @"
WSL version: 2.0.9.0
"@ } }; . $statusModulePath }
        It "parses version" { (Get-WSLVersion).Version | Should Match '2.0.9.0' }
    }

    Context "Distribution list parsing" {
        BeforeAll { Mock wsl { return @"
Ubuntu-22.04
docker-desktop
"@ }; . $statusModulePath }
        It "returns distributions" { (Get-WSLDistribution) | Should Contain 'Ubuntu-22.04' }
    }
}
            ($result -contains 'Ubuntu-22.04') | Should Be $true
