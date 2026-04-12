configuration Main {
    param(
        [string[]]$NodeName = 'localhost'
    )

    Import_DscResource -ModuleName PSDesiredStateConfiguration
    
    node $NodeName {
        # Enable Windows features needed for web server
        WindowsFeature NetFramework45 {
            Name   = "NET-Framework-45-Core"
            Ensure = "Present"
        }

        # Install Chocolatey package manager
        Script InstallChocolatey {
            GetScript = {
                $chocoPath = "$env:ProgramData\chocolatey\choco.exe"
                if (Test-Path $chocoPath) {
                    return @{ Result = $true }
                }
                return @{ Result = $false }
            }
            TestScript = {
                $chocoPath = "$env:ProgramData\chocolatey\choco.exe"
                Test-Path $chocoPath
            }
            SetScript = {
                Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
                [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
                Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
                $env:Path += ";$env:ProgramData\chocolatey\bin"
                refreshenv
            }
        }

        # Install Python 3.11
        Script InstallPython {
            GetScript = {
                $pythonPath = "C:\Python311\python.exe"
                if (Test-Path $pythonPath) {
                    $version = & $pythonPath --version 2>&1
                    return @{ Result = $version }
                }
                return @{ Result = "Not installed" }
            }
            TestScript = {
                $pythonPath = "C:\Python311\python.exe"
                Test-Path $pythonPath
            }
            SetScript = {
                & "$env:ProgramData\chocolatey\bin\choco.exe" install python311 -y --params "/InstallDir:C:\Python311"
                $env:Path = "C:\Python311;C:\Python311\Scripts;$env:Path"
                [Environment]::SetEnvironmentVariable("Path", $env:Path, "Machine")
            }
            DependsOn = "[Script]InstallChocolatey"
        }

        # Install Redis using Chocolatey
        Script InstallRedis {
            GetScript = {
                $redisPath = "C:\Program Files\Redis\redis-server.exe"
                if (Test-Path $redisPath) {
                    return @{ Result = "Installed" }
                }
                return @{ Result = "Not installed" }
            }
            TestScript = {
                $redisPath = "C:\Program Files\Redis\redis-server.exe"
                Test-Path $redisPath
            }
            SetScript = {
                & "$env:ProgramData\chocolatey\bin\choco.exe" install redis-64 -y
            }
            DependsOn = "[Script]InstallChocolatey"
        }

        # Install required Python packages
        Script InstallPythonDependencies {
            GetScript = {
                $pipPath = "C:\Python311\Scripts\pip.exe"
                if (Test-Path $pipPath) {
                    return @{ Result = "pip found" }
                }
                return @{ Result = "pip not found" }
            }
            TestScript = {
                $pipPath = "C:\Python311\Scripts\pip.exe"
                Test-Path $pipPath
            }
            SetScript = {
                & "C:\Python311\Scripts\pip.exe" install --upgrade pip
                & "C:\Python311\Scripts\pip.exe" install redis>=4.7.0
            }
            DependsOn = "[Script]InstallPython"
        }

        # Create app directory
        File AppDirectory {
            DestinationPath = "C:\app"
            Type            = "Directory"
            Ensure          = "Present"
        }

        # Copy app.py from local path (will be uploaded)
        Script CopyAppFiles {
            GetScript = {
                $appPath = "C:\app\app.py"
                if (Test-Path $appPath) {
                    return @{ Result = "File exists" }
                }
                return @{ Result = "File missing" }
            }
            TestScript = {
                # Check if app.py exists and has content
                $appPath = "C:\app\app.py"
                if (Test-Path $appPath) {
                    $fileSize = (Get-Item $appPath).Length
                    return $fileSize -gt 0
                }
                return $false
            }
            SetScript = {
                # App file should be copied by custom script extension
                Write-Verbose "App files copied by custom script"
            }
            DependsOn = "[File]AppDirectory"
        }

        # Set environment variables for app
        Environment RedisHost {
            Name   = "REDIS_HOST"
            Value  = "localhost"
            Ensure = "Present"
            Target = @("Process", "Machine")
        }

        Environment RedisPort {
            Name   = "REDIS_PORT"
            Value  = "6379"
            Ensure = "Present"
            Target = @("Process", "Machine")
        }

        # Create startup batch script
        File StartupScript {
            DestinationPath = "C:\app\start-app.bat"
            Type            = "File"
            Contents        = @"
@echo off
cd /d C:\app
C:\Python311\python.exe app.py
"@
            Ensure          = "Present"
            DependsOn       = "[File]AppDirectory"
        }

        # Create Windows Scheduled Task to start app on boot
        Script ScheduleAppStart {
            GetScript = {
                $task = Get-ScheduledTask -TaskName "StartPythonApp" -ErrorAction SilentlyContinue
                if ($task) {
                    return @{ Result = "Task exists" }
                }
                return @{ Result = "Task missing" }
            }
            TestScript = {
                $task = Get-ScheduledTask -TaskName "StartPythonApp" -ErrorAction SilentlyContinue
                $null -ne $task
            }
            SetScript = {
                $action = New-ScheduledTaskAction -Execute "C:\app\start-app.bat"
                $trigger = New-ScheduledTaskTrigger -AtStartup
                $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
                Register-ScheduledTask -TaskName "StartPythonApp" -Action $action -Trigger $trigger -Settings $settings -RunLevel Highest -User "NT AUTHORITY\SYSTEM" -Force
            }
            DependsOn = "[File]StartupScript"
        }

        # Configure Firewall rules
        Script ConfigureFirewall {
            GetScript = {
                $rule = Get-NetFirewallRule -DisplayName "Allow Python App Port" -ErrorAction SilentlyContinue
                return @{ Result = ($null -ne $rule).ToString() }
            }
            TestScript = {
                $rule = Get-NetFirewallRule -DisplayName "Allow Python App Port" -ErrorAction SilentlyContinue
                $null -ne $rule
            }
            SetScript = {
                New-NetFirewallRule -DisplayName "Allow Python App Port" `
                    -Direction Inbound -Action Allow -Protocol TCP -LocalPort 8000 `
                    -Group "Python App" -ErrorAction SilentlyContinue | Out-Null
                    
                New-NetFirewallRule -DisplayName "Allow Redis Port" `
                    -Direction Inbound -Action Allow -Protocol TCP -LocalPort 6379 `
                    -Group "Redis" -ErrorAction SilentlyContinue | Out-Null
            }
        }

        # Start Redis service
        Service RedisService {
            Name        = "Redis"
            State       = "Running"
            StartupType = "Automatic"
            DependsOn   = "[Script]InstallRedis"
        }

        # Start Python app via scheduled task
        Script StartApp {
            GetScript = {
                $appProcess = Get-Process python -ErrorAction SilentlyContinue
                return @{ Result = ($null -ne $appProcess).ToString() }
            }
            TestScript = {
                $appProcess = Get-Process python -ErrorAction SilentlyContinue
                $null -ne $appProcess
            }
            SetScript = {
                # Trigger the scheduled task
                Start-ScheduledTask -TaskName "StartPythonApp"
            }
            DependsOn = "[Script]ScheduleAppStart"
        }
    }
}
