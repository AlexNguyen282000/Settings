
Describe "New-PSSession basic test" -Tag @("CI") {
    It "New-PSSession should not crash powershell" {
        try {
            New-PSSession -ComputerName nonexistcomputer -Authentication Basic
            throw "New-PSSession should throw"
        } catch {
            $_.FullyQualifiedErrorId | Should Be "InvalidOperation,Microsoft.PowerShell.Commands.NewPSSessionCommand"
        }
    }
}

Describe "JEA session Transcript script test" -Tag @("Feature", 'RequireAdminOnWindows') {
    BeforeAll {
        Enable-PSRemoting -SkipNetworkProfileCheck
    }

    It "Configuration name should be in the transcript header" {
        [string] $RoleCapDirectory = (New-Item -Path "$TestDrive\RoleCapability" -ItemType Directory -Force).FullName
        [string] $PSSessionConfigFile = "$RoleCapDirectory\TestConfig.pssc"
        [string] $transScriptFile = "$RoleCapDirectory\*.txt"
        try
        {
            New-PSSessionConfigurationFile -Path $PSSessionConfigFile -TranscriptDirectory $RoleCapDirectory -SessionType RestrictedRemoteServer
            Register-PSSessionConfiguration -Name JEA -Path $PSSessionConfigFile -Force -ErrorAction SilentlyContinue
            $scriptBlock = {Enter-PSSession -ComputerName Localhost -ConfigurationName JEA; Exit-PSSession}
            # Invoke the script block in a different PowerShell instance to that when TestDrive tries to delete $RoleCapDirectory,
            # the transcription has finished and the files are not locked.
            [powershell]::Create().AddScript($scriptBlock).Invoke()
            $headerFile = Get-ChildItem $transScriptFile | Sort-Object LastWriteTime | Select-Object -Last 1
            $header = Get-Content $headerFile | Out-String
            $header | Should Match "Configuration Name: JEA"
        }
        finally
        {
            Unregister-PSSessionConfiguration -Name JEA -Force -ErrorAction SilentlyContinue
        }
    }

}

Describe "JEA session Get-Help test" -Tag @("CI", 'RequireAdminOnWindows') {
    BeforeAll {
        Enable-PSRemoting -SkipNetworkProfileCheck
    }

    It "Get-Help should work in JEA sessions" {
        [string] $RoleCapDirectory = (New-Item -Path "$TestDrive\RoleCapability" -ItemType Directory -Force).FullName
        [string] $PSSessionConfigFile = "$RoleCapDirectory\TestConfig.pssc"
        try
        {
            New-PSSessionConfigurationFile -Path $PSSessionConfigFile -TranscriptDirectory $RoleCapDirectory -SessionType RestrictedRemoteServer
            Register-PSSessionConfiguration -Name JEA -Path $PSSessionConfigFile -Force -ErrorAction SilentlyContinue
            $scriptBlock = {Enter-PSSession -ComputerName Localhost -ConfigurationName JEA; Get-Help Get-Command; Exit-PSSession}
            # Invoke the script block in a different PowerShell instance to that when TestDrive tries to delete $RoleCapDirectory,
            # the transcription has finished and the files are not locked.
            $helpContent = [powershell]::Create().AddScript($scriptBlock).Invoke()
            $helpContent | Should Not Be $null
        }
        finally
        {
            Unregister-PSSessionConfiguration -Name JEA -Force -ErrorAction SilentlyContinue
            Remove-Item $RoleCapDirectory -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

Describe "Remoting loopback tests" -Tags @('CI', 'RequireAdminOnWindows') {
    BeforeAll {
        Enable-PSRemoting -SkipNetworkProfileCheck
        $endPoint = (Get-PSSessionConfiguration -Name "PowerShell.$(${PSVersionTable}.GitCommitId)").Name
        $disconnectedSession = New-PSSession -ConfigurationName $endPoint -ComputerName localhost | Disconnect-PSSession
        $closedSession = New-PSSession -ConfigurationName $endPoint -ComputerName localhost
        $closedSession.Runspace.Close()
        $openSession = New-PSSession -ConfigurationName $endPoint

        $ParameterError = @(
            @{
                parameters = @{
                    'InDisconnectedSession' = $true
                    'AsJob'                 = $true
                    'ScriptBlock'           = {1}
                    'ComputerName'          = 'localhost'
                    'ConfigurationName'     = $endpoint
                }
                expectedError = 'System.InvalidOperationException,Microsoft.PowerShell.Commands.InvokeCommandCommand'
                title = 'Cannot use InDisconnectedState and AsJob together'
            },
            @{
                parameters = @{
                    'ScriptBlock'          = {1}
                    'SessionName'          = 'SomeSessionName'
                }
                expectedError = 'System.InvalidOperationException,Microsoft.PowerShell.Commands.InvokeCommandCommand'
                title = 'Cannot use SessionName without InDisconnectedSession'
            },
            @{
                parameters = @{
                    'ScriptBlock' = { 1 }
                    'Session' = $disconnectedSession
                    'ErrorAction' = 'Stop'
                }
                expectedError = 'InvokeCommandCommandInvalidSessionState,Microsoft.PowerShell.Commands.InvokeCommandCommand'
                title = 'Cannot use Invoke-Command on a disconnected session'
            }
            @{
                parameters = @{
                    'ScriptBlock' = { 1 }
                    'Session' = $closedSession
                    'ErrorAction' = 'Stop'
                }
                expectedError = 'InvokeCommandCommandInvalidSessionState,Microsoft.PowerShell.Commands.InvokeCommandCommand'
                title = 'Cannot use Invoke-Command on a closed session'
            }
            )

            function script:ValidateSessionInfo($session, $state)
            {
                $session.ComputerName | Should BeExactly 'localhost'
                $session.ConfigurationName | Should BeExactly $endPoint
                $session.State | Should Be $state
            }
    }

    AfterAll {
        Remove-PSSession $disconnectedSession,$closedSession,$openSession -ErrorAction SilentlyContinue
    }

    It 'Can connect to default endpoint' {
        $session = New-PSSession -ConfigurationName $endPoint
        ValidateSessionInfo -session $session -state 'Opened'
        $session | Remove-PSSession -ErrorAction SilentlyContinue
    }

    It 'Can execute command in a disconnected session' {
        $session = Invoke-Command -InDisconnectedSession -ComputerName 'localhost' -ScriptBlock { 1+1 } -ConfigurationName $endPoint

        ValidateSessionInfo -session $session -state 'Disconnected'

        $result = Receive-PSSession -Session $session
        $result | Should Be 2
        $result.PSComputerName | Should BeExactly 'localhost'

        $session | Remove-PSSession -ErrorAction SilentlyContinue
    }

    It 'Can disconnect and connect to PSSession' {
        $session = New-PSSession -ConfigurationName $endPoint

        ValidateSessionInfo -session $session -state 'Opened'
        Disconnect-PSSession -Session $session

        ValidateSessionInfo -session $session -state 'Disconnected'
        Connect-PSSession -Session $session

        $result = Invoke-Command -Session $session -ScriptBlock { 1 + 1 }
        $result | Should Be 2
        $result.PSComputerName | Should BeExactly 'localhost'

        $session | Remove-PSSession -ErrorAction SilentlyContinue
    }

    It 'Can export and import PSSession' {
        $name = Get-Random
        $commandName = 'Add-Number'

        Invoke-Command -Session $openSession -ScriptBlock { function Add-Number ($number1, $number2) { $number1 + $number2 } }

        $null = Export-PSSession -OutputModule $name -Force -Session $openSession -CommandName $commandName
        $imported = Import-PSSession -Module $name -Session $openSession

        $imported.ExportedCommands.Keys | Should BeExactly $commandName
        Remove-Item "function:\$commandName" -ErrorAction SilentlyContinue -Force
    }

    It "<title>" -TestCases $ParameterError {
        param($parameters, $expectedError)

        { Invoke-Command @parameters } | ShouldBeErrorId $expectedError
    }

    It 'Can execute command if one of the sessions is available' {
        try
        {
            $result = Invoke-Command -Session $openSession,$disconnectedSession,$closedSession -ScriptBlock { 1+1 } -ErrorAction SilentlyContinue
        }
        catch
        {
            if($_.FullyQualifiedErrorId -ne 'InvokeCommandCommandInvalidSessionState,Microsoft.PowerShell.Commands.InvokeCommandCommand')
            {
                # We expect the error from $disconnectedSession and $closedSession. Hence, throw otherwise.
                throw $_
            }
        }

        $result.Count | Should Be 1
        $result | Should Be 2
    }

    It 'Can execute command without creating new scope' {
        $result = Invoke-Command -NoNewScope -ScriptBlock { 1 + 1 }
        $result | Should Be 2
    }

    It 'Can execute command from a file' {
        '1 + 1' | Out-File $testdrive/remotingscript.ps1
        $result = Invoke-Command -FilePath $testdrive/remotingscript.ps1 -Session $openSession
        $result | Should Be 2
    }

    It 'Can invoke-command as job' {
        $result = Invoke-Command -ScriptBlock { 1 + 1 } -Session $openSession -AsJob | Wait-Job | Receive-Job
        $result | Should Be 2
    }

    It 'Can connect to all disconnected sessions by name' {
        $connectionNames = @("DiscPSS$(Get-Random)", "DiscPSS$(Get-Random)")
        $connectionNames | ForEach-Object { $null = New-PSSession -ComputerName localhost -ConfigurationName $endpoint -Name $_ | Disconnect-PSSession}

        Connect-PSSession -ComputerName localhost -Name $connectionNames
        $sessions = Get-PSSession -Name $connectionNames
        $sessions | ForEach-Object {
            ValidateSessionInfo -session $_ -state 'Opened'
         }

        $sessions | Remove-PSSession -ErrorAction SilentlyContinue
    }

    It 'Can pass values through $using' {
        $number = 100
        $result = Invoke-Command -Session $openSession -ScriptBlock { $using:number }
        $result | Should Be 100
    }
}
