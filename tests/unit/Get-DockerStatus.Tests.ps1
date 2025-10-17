BeforeAll {
    # Import the status module
    $statusModulePath = Join-Path $PSScriptRoot "..\..\scripts\status\Get-DockerStatus.ps1"
    . $statusModulePath
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
        
        It "Should have version as 'Not installed'" {
            $result = Test-DockerInstalled
            $result.Version | Should -Be "Not installed"
        }
    }
    
    Context "When Docker is installed but not running" {
        BeforeAll {
            Mock Test-Path { return $true }
            Mock docker { throw "Docker is not running" }
        }
        
        It "Should detect Docker installation" {
            $result = Test-DockerInstalled
            $result.Available | Should -Be $true
        }
        
        It "Should return not running when docker command fails" {
            $result = Test-DockerRunning
            $result.Running | Should -Be $false
        }
    }
    
    Context "When Docker is installed and running" {
        BeforeAll {
            Mock Test-Path { return $true }
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
            $global:LASTEXITCODE = 0
        }
        
        It "Should detect Docker as running" {
            $result = Test-DockerRunning
            $result.Running | Should -Be $true
        }
        
        It "Should parse version information correctly" {
            $result = Test-DockerInstalled
            $result.ClientVersion | Should -Match "24.0.5"
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
        }
        
        It "Should return container information" {
            $result = Get-DockerContainer
            $result | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "When no containers exist" {
        BeforeAll {
            Mock docker { return "" }
        }
        
        It "Should handle no containers gracefully" {
            { Get-DockerContainer } | Should -Not -Throw
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
        }
        
        It "Should return image information" {
            $result = Get-DockerImage
            $result | Should -Not -BeNullOrEmpty
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
        }
        
        It "Should return volume information" {
            $result = Get-DockerVolume
            $result | Should -Not -BeNullOrEmpty
        }
    }
}
