<############################################################################################
 # File: Get-Counter.Tests.ps1
 # Provides Pester tests for the Get-Counter cmdlet.
 ############################################################################################>
Describe "Tests for Get-Counter cmdlet" -Tags "CI" {
    BeforeAll {
        $cmdletName = "Get-Counter"

        . "$PSScriptRoot/CounterTestsCommon.ps1"

        $badName = "bad-name-DAD288C0-72F8-47D3-8C54-C69481B528DF"
        $counterNames = @{
            MemoryBytes = TranslateCounterPath("\Memory\Available Bytes")
            TotalDiskRead = TranslateCounterPath("\PhysicalDisk(_Total)\Disk Read Bytes/sec")
            Unknown = TranslateCounterPath("\Memory\$badName")
            Bad = $badName
        }

        function ValidateParameters($testCase)
        {
            It "$($testCase.Name)" {

                # build up a command
                $counterParam = ""
                if ($testCase.ContainsKey("Counters"))
                {
                    $counterParam = "-Counter `"$($testCase.Counters)`""
                }
                $cmd = "$cmdletName $counterParam $($testCase.Parameters) -ErrorAction Stop"

                try
                {
                    $sb = [scriptblock]::Create($cmd)
                    &$sb
                    throw "Did not throw expected exception"
                }
                catch
                {
                    $_.FullyQualifiedErrorId | Should Be $testCase.ExpectedErrorId
                }
            }
        }
    }

    Context "Validate incorrect parameter usage" {
        $parameterTestCases = @(
            @{
                Name = "Fails when MaxSamples parameter is < 1"
                Counters = $counterNames.MemoryBytes
                Parameters = "-MaxSamples 0"
                ExpectedErrorId = "ParameterArgumentValidationError,Microsoft.PowerShell.Commands.GetCounterCommand"
            }
            @{
                Name = "Fails when MaxSamples parameter is used but no value given"
                Counters = $counterNames.MemoryBytes
                Parameters = "-MaxSamples"
                ExpectedErrorId = "MissingArgument,Microsoft.PowerShell.Commands.GetCounterCommand"
            }
            @{
                Name = "Fails when SampleInterval is < 1"
                Counters = $counterNames.MemoryBytes
                Parameters = "-SampleInterval -2"
                ExpectedErrorId = "ParameterArgumentValidationError,Microsoft.PowerShell.Commands.GetCounterCommand"
            }
            @{
                Name = "Fails when SampleInterval parameter is used but no value given"
                Counters = $counterNames.MemoryBytes
                Parameters = "-SampleInterval"
                ExpectedErrorId = "MissingArgument,Microsoft.PowerShell.Commands.GetCounterCommand"
            }
            @{
                Name = "Fails when given invalid counter path"
                Counters = $counterNames.Bad
                Parameters = ""
                ExpectedErrorId = "CounterApiError,Microsoft.PowerShell.Commands.GetCounterCommand"
            }
            @{
                Name = "Fails when given unknown counter path"
                Counters = $counterNames.Unknown
                Parameters = ""
                ExpectedErrorId = "CounterApiError,Microsoft.PowerShell.Commands.GetCounterCommand"
            }
            @{
                Name = "Fails when Counter parameter is null"
                Counters = "`$null"
                Parameters = ""
                ExpectedErrorId = "CounterApiError,Microsoft.PowerShell.Commands.GetCounterCommand"
            }
            @{
                Name = "Fails when Counter parameter is specified but no names given"
                Parameters = "-Counter"
                ExpectedErrorId = "MissingArgument,Microsoft.PowerShell.Commands.GetCounterCommand"
            }
            @{
                Name = "Fails when given invalid counter path in array"
                Counters = "@($($counterNames.MemoryBytes), $($counterNames.Bad), $($counterNames.TotalDiskRead))"
                Parameters = ""
                ExpectedErrorId = "CounterApiError,Microsoft.PowerShell.Commands.GetCounterCommand"
            }
            @{
                Name = "Fails when ComputerName parameter is invalid"
                Counters = $counterNames.MemoryBytes
                Parameters = "-ComputerName $badName"
                ExpectedErrorId = "CounterApiError,Microsoft.PowerShell.Commands.GetCounterCommand"
            }
            @{
                Name = "Fails when ComputerName parameter is null"
                Counters = $counterNames.MemoryBytes
                Parameters = "-ComputerName `$null"
                ExpectedErrorId = "ParameterArgumentValidationError,Microsoft.PowerShell.Commands.GetCounterCommand"
            }
            @{
                Name = "Fails when ComputerName parameter is used but no name given"
                Counters = $counterNames.MemoryBytes
                Parameters = "-ComputerName"
                ExpectedErrorId = "MissingArgument,Microsoft.PowerShell.Commands.GetCounterCommand"
            }
            @{
                Name = "Fails when given unknown counter set name"
                Parameters = "-ListSet $badName"
                ExpectedErrorId = "NoMatchingCounterSetsFound,Microsoft.PowerShell.Commands.GetCounterCommand"
            }
            @{
                Name = "Fails when given unknown counter set name in array"
                Parameters = "-List @(`"Memory`", `"Processor`", `"$badname`")"
                ExpectedErrorId = "NoMatchingCounterSetsFound,Microsoft.PowerShell.Commands.GetCounterCommand"
            }
            @{
                Name = "Fails when ListSet parameter is null"
                Parameters = "-List `$null"
                ExpectedErrorId = "ParameterArgumentValidationErrorNullNotAllowed,Microsoft.PowerShell.Commands.GetCounterCommand"
            }
            @{
                Name = "Fails when ListSet parameter is used but no name given"
                Parameters = "-ListSet"
                ExpectedErrorId = "MissingArgument,Microsoft.PowerShell.Commands.GetCounterCommand"
            }
            @{
                Name = "Fails when both -Counter and -ListSet parameters are given"
                Counters = $counterNames.MemoryBytes
                Parameters = "-ListSet `"Memory`""
                ExpectedErrorId = "AmbiguousParameterSet,Microsoft.PowerShell.Commands.GetCounterCommand"
            }
        )

        foreach ($testCase in $parameterTestCases)
        {
            ValidateParameters($testCase)
        }
    }

    Context "Get-Counter CounterSet tests" {
        It "Get-Counter with no parameters returns data for a default set of counters" {
            $counterData = Get-Counter
            # At the very least we should get processor and memory
            $counterData.CounterSamples.Length | should BeGreaterThan 1
        }

        It "Can retrieve the specified number of counter samples" {
            $counterPath = TranslateCounterPath("\Memory\Available Bytes")
            $counterCount = 5
            $counterData = Get-Counter -Counter $counterPath -MaxSamples $counterCount
            $counterData.Length | Should Be $counterCount
        }

        It "Can specify the sample interval" {
            $counterPath = TranslateCounterPath("\PhysicalDisk(*)\Current Disk Queue Length")
            $counterCount = 5
            $sampleInterval = 2
            $startTime = Get-Date
            $counterData = Get-Counter -Counter $counterPath -SampleInterval $sampleInterval -MaxSamples $counterCount
            $endTime = Get-Date
            $counterData.Length | Should Be $counterCount
            ($endTime - $startTime).TotalSeconds | Should Not BeLessThan ($counterCount * $sampleInterval)
        }

        It "Can process array of counter names" {
            $counterPaths = @((TranslateCounterPath("\PhysicalDisk(_Total)\Disk Read Bytes/sec")),
                              (TranslateCounterPath("\Memory\Available bytes")))
            $counterData = Get-Counter -Counter $counterPaths
            $counterData.CounterSamples.Length | Should Be $counterPaths.Length
        }
    }

    Context "Get-Counter ListSet tests" {
        It "Can retrieve specified counter set" {
            $counterSetName = "Memory"
            $counterSet = Get-Counter -ListSet $counterSetName
            $counterSet.Length | Should Be 1
            $counterSet.CounterSetName | Should Be $counterSetName
        }

        It "Can process an array of counter set names" {
            $counterSetNames = @("Memory", "Processor")
            $counterSets = Get-Counter -ListSet $counterSetNames
            $counterSets.Length | Should Be 2
            $counterSets[0].CounterSetName | Should Be $counterSetNames[0]
            $counterSets[1].CounterSetName | Should Be $counterSetNames[1]
        }

        It "Can process counter set name with wildcards" {
            $wildcardBase = "roc"
            $counterSetName = "*$wildcardBase*"
            $counterSets = Get-Counter -ListSet $counterSetName
            $counterSets.Length | Should BeGreaterThan 1    # should get at least "Processor" and "Process"
            foreach ($counterSet in $counterSets)
            {
                $counterSet.CounterSetName.ToLower().Contains($wildcardBase.ToLower()) | Should Be $true
            }
        }

        It "Can process counter set name with wildcards in array" {
            $wildcardBases = @("Memory", "roc")
            $counterSetNames = @($wildcardBases[0], ("*" + $wildcardBases[1] + "*"))
            $counterSets = Get-Counter -ListSet $counterSetNames
            $counterSets.Length | Should BeGreaterThan 2    # should get at least "Memory", "Processor" and "Process"
            foreach ($counterSet in $counterSets)
            {
                ($counterSet.CounterSetName.ToLower().Contains($wildcardBases[0].ToLower()) -Or
                 $counterSet.CounterSetName.ToLower().Contains($wildcardBases[1].ToLower())) | Should Be $true
            }
        }
    }
}
