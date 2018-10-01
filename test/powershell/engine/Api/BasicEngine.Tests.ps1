# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.
Describe 'Basic engine APIs' -Tags "CI" {
    Context 'powershell::Create' {
        It 'can create default instance' {
            [powershell]::Create() | Should -Not -BeNullOrEmpty
        }

        It "can load the default snapin 'Microsoft.WSMan.Management'" -skip:(-not $IsWindows) {
            $ps = [powershell]::Create()
            $ps.AddScript("Get-Command -Name Test-WSMan") > $null

            $result = $ps.Invoke()
            $result.Count | Should -Be 1
            $result[0].Source | Should -BeExactly "Microsoft.WSMan.Management"
        }
    }

    Context 'executioncontext' {
        It 'args are passed correctly' {
            $result = $ExecutionContext.SessionState.InvokeCommand.InvokeScript('"`$args:($args); `$input:($input)"', 1, 2, 3)
            $result | Should -BeExactly '$args:(1 2 3); $input:()'
        }
    }
}

Describe "Clean up open Runspaces when exit powershell process" -Tags "Feature" {
    It "PowerShell process should not freeze at exit" {
        $command = @'
-c $rs = [runspacefactory]::CreateRunspacePool(1,5)
$rs.Open()
$ps = [powershell]::Create()
$ps.RunspacePool = $rs
$null = $ps.AddScript(1).Invoke()
write-host should_not_hang_at_exit
exit
'@
        $process = Start-Process pwsh -ArgumentList $command -PassThru
        Wait-UntilTrue -sb { $process.HasExited } -TimeoutInMilliseconds 5000 -IntervalInMilliseconds 1000 > $null

        $expect = "powershell process exits in 5 seconds"
        if (-not $process.HasExited) {
            Stop-Process -InputObject $process -Force -ErrorAction SilentlyContinue
            "powershell process doesn't exit in 5 seconds" | Should -Be $expect
        } else {
            $expect | Should -Be $expect
        }
    }
}

Describe "EndInvoke() should return a collection of results" {
    BeforeAll {
        $ps = [powershell]::Create()
        $ps.AddScript("'Hello'; Sleep 1; 'World'") > $null
    }

    It "BeginInvoke() and then EndInvoke() should return a collection of results" {
        $async = $ps.BeginInvoke()
        $result = $ps.EndInvoke($async)

        $result.Count | Should -BeExactly 2
        $result[0] | Should -BeExactly "Hello"
        $result[1] | Should -BeExactly "World"
    }

    It "BeginInvoke() and then EndInvoke() should return a collection of results after a previous Stop() call" {
        $async = $ps.BeginInvoke()
        Start-Sleep -Milliseconds 300
        $ps.Stop()

        $async = $ps.BeginInvoke()
        $result = $ps.EndInvoke($async)

        $result.Count | Should -BeExactly 2
        $result[0] | Should -BeExactly "Hello"
        $result[1] | Should -BeExactly "World"
    }

    It "BeginInvoke() and then EndInvoke() should return a collection of results after a previous BeginStop()/EndStop() call" {
        $asyncInvoke = $ps.BeginInvoke()
        Start-Sleep -Milliseconds 300
        $asyncStop = $ps.BeginStop($null, $null)
        $ps.EndStop($asyncStop)

        $asyncInvoke = $ps.BeginInvoke()
        $result = $ps.EndInvoke($asyncInvoke)

        $result.Count | Should -BeExactly 2
        $result[0] | Should -BeExactly "Hello"
        $result[1] | Should -BeExactly "World"
    }
}
