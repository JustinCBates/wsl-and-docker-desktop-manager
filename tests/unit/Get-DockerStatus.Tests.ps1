<# Clean Pester v3-compatible tests for Docker status and helpers #>

$statusModulePath = Join-Path $PSScriptRoot "..\..\scripts\status\Get-DockerStatus.ps1"

Describe "Get-DockerStatus" {
    Context "When Docker is not installed" {
        BeforeAll {
            Mock Get-Command { return $null }
            Mock docker { throw 'docker not found' }
            . $statusModulePath
        }

        It "Should report Docker as not installed" {
            $result = Get-DockerStatus
            $result.Installed | Should Be $false
        }

        It "Should have version as 'Not installed'" {
            $result = Get-DockerStatus
            $result.Version.Version | Should Be "Not installed"
        }
    }

    Context "When Docker is installed but not running" {
        BeforeAll {
            Mock Get-Command { return @{ Name = 'docker' } }
            Mock docker { throw "Docker is not running" }
            . $statusModulePath
            $global:LASTEXITCODE = 1
        }

        It "Should detect Docker installation" {
            $result = Get-DockerStatus
            $result.Installed | Should Be $true
        }

        It "Should return not running when docker command fails" {
            $result = Get-DockerStatus
            $result.Running | Should Be $false
        }
    }

    Context "When Docker is installed and running" {
        BeforeAll {
            Mock Get-Command { return @{ Name = 'docker' } }
            Mock docker {
                if ($args -contains "version") {
                    return "Docker version 24.0.5, build ced0996"
                }
                elseif ($args -contains "info") {
                    return @"
Client:
 Version:           24.0.5
 API version:       1.43
Server:
 Containers: 5
  Running: 2
  Paused: 0
  Stopped: 3
"@
                }
            }
            . $statusModulePath
            $global:LASTEXITCODE = 0
        }

        It "Should detect Docker as running" {
            $result = Get-DockerStatus
            $result.Running | Should Be $true
        }

        It "Should parse version information correctly" {
            $result = Get-DockerStatus
            $result.Version.ClientVersion | Should Match '^[0-9]+\.[0-9]+\.[0-9]+'
        }
    }
}

Describe "Get-DockerContainer" {
    Context "When containers exist" {
        BeforeAll {
            Mock docker {
                return @"
CONTAINER ID   IMAGE          STATUS
abc123         nginx:latest   Up 5 minutes
def456         redis:alpine   Exited (0) 10 minutes ago
"@
            }
            . $statusModulePath
        }

        It "Should return container information" {
            $result = Get-DockerContainer
            $result | Should Not BeNullOrEmpty
        }
    }

    Context "When no containers exist" {
        BeforeAll {
            Mock docker { return "" }
            . $statusModulePath
        }

        It "Should handle no containers gracefully" {
            { Get-DockerContainer } | Should Not Throw
        }
    }
}

Describe "Get-DockerImage" {
    Context "When images exist" {
        BeforeAll {
            Mock docker {
                return @"
REPOSITORY    TAG       IMAGE ID       CREATED        SIZE
nginx         latest    abc123def456   2 days ago     142MB
redis         alpine    789ghi012jkl   5 days ago     32.3MB
"@
            }
            . $statusModulePath
        }

        It "Should return image information" {
            $result = Get-DockerImage
            $result | Should Not BeNullOrEmpty
        }
    }
}

Describe "Get-DockerVolume" {
    Context "When volumes exist" {
        BeforeAll {
            Mock docker {
                return @"
DRIVER    VOLUME NAME
local     mydata
local     postgres_data
"@
            }
            . $statusModulePath
        }

        It "Should return volume information" {
            $result = Get-DockerVolume
            $result | Should Not BeNullOrEmpty
        }
    }
}
