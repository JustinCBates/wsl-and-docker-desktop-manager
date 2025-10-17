# Temporary clean copy of Docker status tests for local runs

$statusModulePath = Join-Path $PSScriptRoot "..\..\scripts\status\Get-DockerStatus.ps1"

Describe "Get-DockerStatus - clean" {
    Context "When Docker is not installed" {
        BeforeAll {
            Mock Get-Command { return $null }
            Mock docker { throw 'docker not found' }
            . $statusModulePath
        }
        It "reports not installed" { (Get-DockerStatus).Installed | Should Be $false }
    }

    Context "When Docker installed and running" {
        BeforeAll {
            Mock Get-Command { return @{ Name = 'docker' } }
            Mock docker {
                if ($args -contains 'version') { return 'Docker version 24.0.5, build ced0996' }
                elseif ($args -contains 'info') {
                    return @"
Client:
 Version:           24.0.5
"@
                }
            }
            . $statusModulePath
            $global:LASTEXITCODE = 0
        }
        It "detects running" { (Get-DockerStatus).Running | Should Be $true }
    It "parses version" { (Get-DockerStatus).Version.ClientVersion | Should Match '^[0-9]+\.[0-9]+\.[0-9]+' }
    }
}
