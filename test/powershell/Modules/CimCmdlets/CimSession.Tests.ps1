# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

Import-Module HelpersRemoting

try {
    if ( ! $IsWindows ) {
        $PSDefaultParameterValues['it:pending'] = $true
    }

    Describe "New-CimSession" -Tag @("CI") {
        BeforeAll {
            $sessions = @()
        }

        AfterEach {
                $sessions | Remove-CimSession -ErrorAction SilentlyContinue
                $sessions = @()
        }

        It "A cim session can be created" {
            $sessionName = [guid]::NewGuid()
            $session = New-RemoteSession -Name $sessionName -CimSession
            $sessions += $session
            $session.Name | Should -BeExactly $sessionName
            $session.InstanceId  | Should -BeOfType "System.Guid"
        }

        It "A Cim session can be retrieved" {
            $sessionName = [guid]::NewGuid()
            $session = New-RemoteSession -Name $sessionName -CimSession
            $sessions += $session
            (Get-CimSession -Name $sessionName).InstanceId | Should -Be $session.InstanceId
            (Get-CimSession -Id $session.Id).InstanceId | Should -Be $session.InstanceId
            (Get-CimSession -InstanceId $session.InstanceId).InstanceId | Should -Be $session.InstanceId
        }

        It "A cim session can be removed" {
            $sessionName = [guid]::NewGuid()
            $session = New-RemoteSession -Name $sessionName -CimSession
            $sessions += $session
            $session.Name | Should -BeExactly $sessionName
            $session | Remove-CimSession
            Get-CimSession $session.Id -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
        }
    }
}

finally {
    $PSDefaultParameterValues.Remove('it:pending')
}
