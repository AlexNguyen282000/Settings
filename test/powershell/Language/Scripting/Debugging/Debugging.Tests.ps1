# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

$script1 = @'
'aaa'.ToString() > $null
'aa' > $null
"a" 2> $null | ForEach-Object { $_ }
'bb' > $null
'bb'.ToSTring() > $null
'bbb'
'@

$script2 = @'
$test = 1..2
switch ($test)
{
    default {}
}
'@

$script3 = @'
$test = 2
for ("string".Length;
     $test -gt 0; $test--) { }
'@

$script4 = @'
"line 1"
"line 2"
"line 3"
'@

Describe "Breakpoints when set should be hit" -tag "CI" {
    Context "Basic tests" {
        BeforeAll {
            $path = Setup -PassThru -File TestScript_1.ps1 -Content $script1
            $bps = 1..6 | ForEach-Object { set-psbreakpoint -script $path -line $_ -Action { continue } }
        }

        AfterAll {
            $bps | Remove-PSBreakPoint
        }

        It "A redirected breakpoint is hit" {
            & $path
            foreach ( $bp in $bps ) {
                $bp.HitCount | Should -Be 1
            }
        }
    }

    Context "Break point on switch condition should be hit only when enumerating it" {
        BeforeAll {
            $path = Setup -PassThru -File TestScript_2.ps1 -Content $script2
            $breakpoint = Set-PSBreakpoint -Script $path -Line 2 -Action { continue }
        }

        AfterAll {
            Remove-PSBreakpoint -Breakpoint $breakpoint
        }

        It "switch condition should be hit 3 times" {
            ## MoveNext() will be called on the condition for 3 times
            & $path
            $breakpoint.HitCount | Should -Be 3
        }
    }

    Context "Break point on for-statement initializer should be hit" {
        BeforeAll {
            $path = Setup -PassThru -File TestScript_3.ps1 -Content $script3
            $breakpoint = Set-PSBreakpoint -Script $path -Line 2 -Action { continue }
        }

        AfterAll {
            Remove-PSBreakpoint -Breakpoint $breakpoint
        }

        It "for-statement initializer should be hit once" {
            & $path
            $breakpoint.HitCount | Should -Be 1
        }
    }
}

Describe "It should be possible to reset runspace debugging" -tag "Feature" {
    BeforeAll {
        $scriptPath = Setup -PassThru -File TestScript_2.ps1 -Content $script4
        $iss = [initialsessionstate]::CreateDefault2();
        $rs = [runspacefactory]::CreateRunspace($iss)
        $rs.Name = "TestRunspaceDebuggerReset"
        $rs.Open()
        $rs | Enable-RunspaceDebug

        $debuggerBeforeReset = $rs.Debugger

        # Create PowerShell to run script.
        $ps = [powershell]::Create()
        $ps.Runspace = $rs

        # Set breakpoints in runspace.
        $result = $ps.AddScript("Set-PSBreakpoint -Script '$scriptPath' -line 1").Invoke()
        $ps.Commands.Clear()
        $result = $ps.AddScript("Set-PSBreakpoint -Script '$scriptPath' -line 3").Invoke()
        $ps.Commands.Clear()
        $breakpoints = $ps.AddScript("Get-PSBreakpoint").Invoke()

        # Run script file until breakpoint hit.
        $ar = $ps.AddScript("$scriptPath").BeginInvoke()
        $completed = Wait-UntilTrue { $rs.Debugger.InBreakPoint -eq $true } -timeout 10000 -interval 200
        $ps.Stop()
        $rs.ResetRunspaceState()
    }
    AfterAll {
        if ( $null -ne $ps ) { $ps.Dispose() }
        if ( $null -ne $ss ) { $rs.Dispose() }
    }
    It "2 breakpoints should have been set" {
        $breakpoints.Count | Should -Be 2
    }
    It "The breakpoint Should have been hit" {
        $completed | Should -BeTrue
    }
    It "The reset debugger should not be in a breakpoint" {
        $rs.Debugger.InBreakPoint | Should -BeFalse
    }
    It "The reset debugger should not be active" {
        $rs.Debugger.IsActive | Should -BeFalse
    }
    It "The reset debugger mode should be set to 'Default'" {
        $rs.Debugger.DebugMode | Should -Be "Default"
    }
    It "The debugger should be the same before and after the reset" {
        $rs.Debugger | Should -Be $debuggerBeforeReset
    }
    It "The breakpoints should be gone after reset" {
        $ps.Commands.clear()
        $ps.AddCommand("Get-PSBreakpoint").Invoke() | Should -BeNullOrEmpty
    }
    It "The script should run without a break" {
        $ps.Commands.Clear()
        $ps.addscript($scriptPath).Invoke().Count | Should -Be 3
    }
}
