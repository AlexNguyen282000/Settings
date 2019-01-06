# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

# This is a Pester test suite to validate the Format-Hex cmdlet in the Microsoft.PowerShell.Utility module.

<#
    Purpose:
        Verify Format-Hex displays the Hexadecimal value for the input data.

    Action:
        Run Format-Hex.

    Expected Result:
        Hexadecimal equivalent of the input data is displayed.
#>

Describe "FormatHex" -tags "CI" {

    BeforeAll {

        $newline = [Environment]::Newline

        Setup -d FormatHexDataDir
        $inputText1 = 'Hello World'
        $inputText2 = 'More text'
        $inputText3 = 'Literal path'
        $inputText4 = 'Now is the winter of our discontent'
        $inputFile1 = setup -f "FormatHexDataDir/SourceFile-1.txt" -content $inputText1 -pass
        $inputFile2 = setup -f "FormatHexDataDir/SourceFile-2.txt" -content $inputText2 -pass
        $inputFile3 = setup -f "FormatHexDataDir/SourceFile literal [3].txt" -content $inputText3 -pass
        $inputFile4 = setup -f "FormatHexDataDir/SourceFile-4.txt" -content $inputText4 -pass

        $certificateProvider = Get-ChildItem Cert:\CurrentUser\My\ -ErrorAction SilentlyContinue
        $thumbprint = $null
        $certProviderAvailable = $false

        if ($certificateProvider.Count -gt 0) {
            $thumbprint = $certificateProvider[0].Thumbprint
            $certProviderAvailable = $true
        }

        $skipTest = ([System.Management.Automation.Platform]::IsLinux -or [System.Management.Automation.Platform]::IsMacOS -or (-not $certProviderAvailable))
    }

    Context "InputObject Paramater" {
        BeforeAll {
            enum TestEnum {
                TestOne = 1; TestTwo = 2; TestThree = 3; TestFour = 4
            }
            Add-Type -TypeDefinition @'
public enum TestSByteEnum : sbyte {
    One   = -1,
    Two   = -2,
    Three = -3,
    Four  = -4
}
'@
        }

        $testCases = @(
            @{
                Name           = "Can process byte type 'fhx -InputObject [byte]5'"
                InputObject    = [byte]5
                Count          = 1
                ExpectedResult = "00000000   05"
            }
            @{
                Name           = "Can process byte[] type 'fhx -InputObject [byte[]](1,2,3,4,5)'"
                InputObject    = [byte[]](1, 2, 3, 4, 5)
                Count          = 1
                ExpectedResult = "00000000   01 02 03 04 05                                   ....."
            }
            @{
                Name           = "Can process int type 'fhx -InputObject 7'"
                InputObject    = 7
                Count          = 1
                ExpectedResult = "00000000   07 00 00 00                                      ...."
            }
            @{
                Name           = "Can process int[] type 'fhx -InputObject [int[]](5,6,7,8)'"
                InputObject    = [int[]](5, 6, 7, 8)
                Count          = 1
                ExpectedResult = "00000000   05 00 00 00 06 00 00 00 07 00 00 00 08 00 00 00  ................"
            }
            @{
                Name           = "Can process int32 type 'fhx -InputObject [int32]2032'"
                InputObject    = [int32]2032
                Count          = 1
                ExpectedResult = "00000000   F0 07 00 00                                      ð..."
            }
            @{
                Name           = "Can process int32[] type 'fhx -InputObject [int32[]](2032, 2033, 2034)'"
                InputObject    = [int32[]](2032, 2033, 2034)
                Count          = 1
                ExpectedResult = "00000000000000000000   F0 07 00 00 F1 07 00 00 F2 07 00 00              ð...ñ...ò..."
            }
            @{
                Name           = "Can process Int64 type 'fhx -InputObject [Int64]9223372036854775807'"
                InputObject    = [Int64]9223372036854775807
                Count          = 1
                ExpectedResult = "00000000000000000000   FF FF FF FF FF FF FF 7F                          ......."
            }
            @{
                Name           = "Can process Int64[] type 'fhx -InputObject [Int64[]](9223372036852,9223372036853)'"
                InputObject    = [Int64[]](9223372036852, 9223372036853)
                Count          = 1
                ExpectedResult = "00000000000000000000   F4 5A D0 7B 63 08 00 00 F5 5A D0 7B 63 08 00 00  ôZÐ{c...õZÐ{c..."
            }
            @{
                Name           = "Can process string type 'fhx -InputObject hello world'"
                InputObject    = "hello world"
                Count          = 1
                ExpectedResult = "00000000000000000000   68 65 6C 6C 6F 20 77 6F 72 6C 64                 hello world"
            }
            @{
                Name                 = "Can process PS-native enum array '[TestEnum[]]('TestOne', 'TestTwo', 'TestThree', 'TestFour') | fhx'"
                InputObject          = [TestEnum[]]('TestOne', 'TestTwo', 'TestThree', 'TestFour')
                Count                = 1
                ExpectedResult       = "00000000000000000000   01 00 00 00 02 00 00 00 03 00 00 00 04 00 00 00  ................"
            }
            @{
                Name                 = "Can process C#-native sbyte enum array '[TestSByteEnum[]]('One', 'Two', 'Three', 'Four') | fhx'"
                InputObject          = [TestSByteEnum[]]('One', 'Two', 'Three', 'Four')
                Count                = 1
                ExpectedResult       = "00000000000000000000   FF FE FD FC                                      .þýü"
            }
        )

        It "<Name>" -TestCase $testCases {

            param ($Name, $InputObject, $Count, $ExpectedResult)

            $result = Format-Hex -InputObject $InputObject

            $result.count | Should -Be $Count
            $result | Should -BeOfType 'Microsoft.PowerShell.Commands.ByteCollection'
            $result.ToString() | Should -MatchExactly $ExpectedResult
        }
    }

    Context "InputObject From Pipeline" {
        BeforeAll {
            enum TestEnum {
                TestOne = 1; TestTwo = 2; TestThree = 3; TestFour = 4
            }
            Add-Type -TypeDefinition @'
public enum TestSByteEnum : sbyte {
    One   = -1,
    Two   = -2,
    Three = -3,
    Four  = -4
}
'@
        }

        $testCases = @(
            @{
                Name           = "Can process byte type '[byte]5 | fhx'"
                InputObject    = [byte]5
                Count          = 1
                ExpectedResult = "00000000000000000000   05"
            }
            @{
                Name           = "Can process byte[] type '[byte[]](1,2) | fhx'"
                InputObject    = [byte[]](1, 2)
                Count          = 1
                ExpectedResult = "00000000000000000000   01 02                                            .."
            }
            @{
                Name           = "Can process int type '7 | fhx'"
                InputObject    = 7
                Count          = 1
                ExpectedResult = "00000000000000000000   07 00 00 00                                      ...."
            }
            @{
                Name           = "Can process int[] type '[int[]](5,6) | fhx'"
                InputObject    = [int[]](5, 6)
                Count          = 1
                ExpectedResult = "00000000000000000000   05 00 00 00 06 00 00 00                          ........"
            }
            @{
                Name           = "Can process int32 type '[int32]2032 | fhx'"
                InputObject    = [int32]2032
                Count          = 1
                ExpectedResult = "00000000000000000000   F0 07 00 00                                      ð..."
            }
            @{
                Name           = "Can process int32[] type '[int32[]](2032, 2033) | fhx'"
                InputObject    = [int32[]](2032, 2033)
                Count          = 1
                ExpectedResult = "00000000000000000000   F0 07 00 00 F1 07 00 00                          ð...ñ..."
            }
            @{
                Name           = "Can process Int64 type '[Int64]9223372036854775807 | fhx'"
                InputObject    = [Int64]9223372036854775807
                Count          = 1
                ExpectedResult = "00000000000000000000   FF FF FF FF FF FF FF 7F                          ......."
            }
            @{
                Name           = "Can process Int64[] type '[Int64[]](9223372036852,9223372036853) | fhx'"
                InputObject    = [Int64[]](9223372036852, 9223372036853)
                Count          = 1
                ExpectedResult = "00000000000000000000   F4 5A D0 7B 63 08 00 00 F5 5A D0 7B 63 08 00 00  ôZÐ{c...õZÐ{c..."
            }
            @{
                Name           = "Can process string type 'hello world | fhx'"
                InputObject    = "hello world"
                Count          = 1
                ExpectedResult = "00000000000000000000   68 65 6C 6C 6F 20 77 6F 72 6C 64                 hello world"
            }
            @{
                Name                 = "Can process jagged array type '[sbyte[]](-15, 18, 21, -5), [byte[]](1, 2, 3, 4, 5, 6) | fhx'"
                InputObject          = [sbyte[]](-15, 18, 21, -5), [byte[]](1, 2, 3, 4, 5, 6)
                Count                = 2
                ExpectedResult       = "00000000000000000000   F1 12 15 FB                                      ñ..û"
                ExpectedSecondResult = "00000000000000000000   01 02 03 04 05 06                                ......"
            }
            @{
                Name                 = "Can process PS-native enum array '[TestEnum[]]('TestOne', 'TestTwo', 'TestThree', 'TestFour') | fhx'"
                InputObject          = [TestEnum[]]('TestOne', 'TestTwo', 'TestThree', 'TestFour')
                Count                = 1
                ExpectedResult       = "00000000000000000000   01 00 00 00 02 00 00 00 03 00 00 00 04 00 00 00  ................"
            }
            @{
                Name                 = "Can process C#-native sbyte enum array '[TestSByteEnum[]]('One', 'Two', 'Three', 'Four') | fhx'"
                InputObject          = [TestSByteEnum[]]('One', 'Two', 'Three', 'Four')
                Count                = 1
                ExpectedResult       = "00000000000000000000   FF FE FD FC                                      .þýü"
            }
        )

        It "<Name>" -Testcase $testCases {

            param ($Name, $InputObject, $Count, $ExpectedResult, $ExpectedSecondResult)

            $result = $InputObject | Format-Hex

            $result.Count | Should -Be $Count
            $result | Should -BeOfType 'Microsoft.PowerShell.Commands.ByteCollection'
            $result[0].ToString() | Should -MatchExactly $ExpectedResult

            if ($result.count -gt 1) {
                $result[1].ToString() | Should -MatchExactly $ExpectedSecondResult
            }
        }
    }

    Context "Path and LiteralPath Parameters" {

        $testDirectory = $inputFile1.DirectoryName

        $testCases = @(
            @{
                Name           = "Can process file content from given file path 'fhx -Path `$inputFile1'"
                PathCase       = $true
                Path           = $inputFile1
                Count          = 1
                ExpectedResult = $inputText1
            }
            @{
                Name                 = "Can process file content from all files in array of file paths 'fhx -Path `$inputFile1, `$inputFile2'"
                PathCase             = $true
                Path                 = @($inputFile1, $inputFile2)
                Count                = 2
                ExpectedResult       = $inputText1
                ExpectedSecondResult = $inputText2
            }
            @{
                Name                 = "Can process file content from all files when resolved to multiple paths 'fhx -Path '`$testDirectory\SourceFile-*''"
                PathCase             = $true
                Path                 = "$testDirectory\SourceFile-*"
                Count                = 2
                ExpectedResult       = $inputText1
                ExpectedSecondResult = $inputText2
            }
            @{
                Name           = "Can process file content from given file path 'fhx -LiteralPath `$inputFile3'"
                Path           = $inputFile3
                Count          = 1
                ExpectedResult = $inputText3
            }
            @{
                Name                 = "Can process file content from all files in array of file paths 'fhx -LiteralPath `$inputFile1, `$inputFile3'"
                Path                 = @($inputFile1, $inputFile3)
                Count                = 2
                ExpectedResult       = $inputText1
                ExpectedSecondResult = $inputText3
            }
        )

        It "<Name>" -TestCase $testCases {

            param ($Name, $PathCase, $Path, $ExpectedResult, $ExpectedSecondResult)

            if ($PathCase) {
                $result = Format-Hex -Path $Path
            } else {
                # LiteralPath
                $result = Format-Hex -LiteralPath $Path
            }

            $result | Should -BeOfType 'Microsoft.PowerShell.Commands.ByteCollection'
            $result[0].ToString() | Should -MatchExactly $ExpectedResult

            if ($result.count -gt 1) {
                $result[1].ToString() | Should -MatchExactly $ExpectedSecondResult
            }
        }

        It 'properly accepts -LiteralPath input from a FileInfo object' {
            $FilePath = 'TestDrive:\FHX-LitPathTest.txt'
            "Hello World!" | Set-Content -Path $FilePath
            $FileObject = Get-Item -Path $FilePath

            $result = $FileObject | Format-Hex
            $ExpectedResult = "00000000000000000000   48 65 6C 6C 6F 20 57 6F 72 6C 64 21 0D 0A        Hello World!.."

            $result[0].ToString() | Should -MatchExactly $ExpectedResult
        }
    }

    Context "Encoding Parameter" {
        $testCases = @(
            @{
                Name           = "Can process ASCII encoding 'fhx -InputObject 'hello' -Encoding ASCII'"
                Encoding       = "ASCII"
                Count          = 1
                ExpectedResult = "00000000000000000000   68 65 6C 6C 6F                                   hello"
            }
            @{
                Name           = "Can process BigEndianUnicode encoding 'fhx -InputObject 'hello' -Encoding BigEndianUnicode'"
                Encoding       = "BigEndianUnicode"
                Count          = 1
                ExpectedResult = "00000000000000000000   00 68 00 65 00 6C 00 6C 00 6F                    .h.e.l.l.o"
            }
            @{
                Name           = "Can process Unicode encoding 'fhx -InputObject 'hello' -Encoding Unicode'"
                Encoding       = "Unicode"
                Count          = 1
                ExpectedResult = "00000000000000000000   68 00 65 00 6C 00 6C 00 6F 00                    h.e.l.l.o."
            }
            @{
                Name           = "Can process UTF7 encoding 'fhx -InputObject 'hello' -Encoding UTF7'"
                Encoding       = "UTF7"
                Count          = 1
                ExpectedResult = "00000000000000000000   68 65 6C 6C 6F                                   hello"
            }
            @{
                Name           = "Can process UTF8 encoding 'fhx -InputObject 'hello' -Encoding UTF8'"
                Encoding       = "UTF8"
                Count          = 1
                ExpectedResult = "00000000000000000000   68 65 6C 6C 6F                                   hello"
            }
            @{
                Name           = "Can process UTF32 encoding 'fhx -InputObject 'hello' -Encoding UTF32'"
                Encoding       = "UTF32"
                Count          = 1
                ExpectedResult = "00000000000000000000   68 00 00 00 65 00 00 00 6C 00 00 00 6C 00 00 00  h...e...l...l...$($newline)00000000000000000010   6F 00 00 00                                      o..."
            }
        )

        It "<Name>" -TestCase $testCases {

            param ($Name, $Encoding, $Count, $ExpectedResult)

            $result = Format-Hex -InputObject 'hello' -Encoding $Encoding

            $result.count | Should -Be $Count
            $result | Should -BeOfType 'Microsoft.PowerShell.Commands.ByteCollection'
            $result[0].ToString() | Should -MatchExactly $ExpectedResult
        }
    }

    Context "Validate Error Scenarios" {

        $testDirectory = $inputFile1.DirectoryName

        $testCases = @(
            @{
                Name                          = "Does not support non-FileSystem Provider paths 'fhx -Path 'Cert:\CurrentUser\My\`$thumbprint' -ErrorAction Stop'"
                PathParameterErrorCase        = $true
                Path                          = "Cert:\CurrentUser\My\$thumbprint"
                ExpectedFullyQualifiedErrorId = "FormatHexOnlySupportsFileSystemPaths,Microsoft.PowerShell.Commands.FormatHex"
            }
            @{
                Name                          = "Type Not Supported 'fhx -InputObject @{'hash' = 'table'} -ErrorAction Stop'"
                InputObjectErrorCase          = $true
                Path                          = $inputFile1
                InputObject                   = @{ "hash" = "table" }
                ExpectedFullyQualifiedErrorId = "FormatHexTypeNotSupported,Microsoft.PowerShell.Commands.FormatHex"
            }
        )

        It "<Name>" -Skip:$skipTest -TestCase $testCases {

            param ($Name, $PathParameterErrorCase, $Path, $InputObject, $InputObjectErrorCase, $ExpectedFullyQualifiedErrorId)

            {
                if ($PathParameterErrorCase) {
                    $result = Format-Hex -Path $Path -ErrorAction Stop
                }
                if ($InputObjectErrorCase) {
                    $result = Format-Hex -InputObject $InputObject -ErrorAction Stop
                }
            } | Should -Throw -ErrorId $ExpectedFullyQualifiedErrorId
        }
    }

    Context "Continues to Process Valid Paths" {

        $testCases = @(
            @{
                Name                          = "If given invalid path in array, continues to process valid paths 'fhx -Path `$invalidPath, `$inputFile1  -ErrorVariable e -ErrorAction SilentlyContinue'"
                PathCase                      = $true
                InvalidPath                   = "$($inputFile1.DirectoryName)\fakefile8888845345345348709.txt"
                ExpectedFullyQualifiedErrorId = "FileNotFound,Microsoft.PowerShell.Commands.FormatHex"
            }
            @{
                Name                          = "If given a non FileSystem path in array, continues to process valid paths 'fhx -Path `$invalidPath, `$inputFile1  -ErrorVariable e -ErrorAction SilentlyContinue'"
                PathCase                      = $true
                InvalidPath                   = "Cert:\CurrentUser\My\$thumbprint"
                ExpectedFullyQualifiedErrorId = "FormatHexOnlySupportsFileSystemPaths,Microsoft.PowerShell.Commands.FormatHex"
            }
            @{
                Name                          = "If given a non FileSystem path in array (with LiteralPath), continues to process valid paths 'fhx -Path `$invalidPath, `$inputFile1  -ErrorVariable e -ErrorAction SilentlyContinue'"
                InvalidPath                   = "Cert:\CurrentUser\My\$thumbprint"
                ExpectedFullyQualifiedErrorId = "FormatHexOnlySupportsFileSystemPaths,Microsoft.PowerShell.Commands.FormatHex"
            }
        )

        It "<Name>" -Skip:$skipTest -TestCase $testCases {

            param ($Name, $PathCase, $InvalidPath, $ExpectedFullyQualifiedErrorId)

            $output = $null
            $errorThrown = $null

            if ($PathCase) {
                $output = Format-Hex -Path $InvalidPath, $inputFile1 -ErrorVariable errorThrown -ErrorAction SilentlyContinue
            } else {
                # LiteralPath
                $output = Format-Hex -LiteralPath $InvalidPath, $inputFile1 -ErrorVariable errorThrown -ErrorAction SilentlyContinue
            }

            $errorThrown.FullyQualifiedErrorId | Should -MatchExactly $ExpectedFullyQualifiedErrorId

            $output.Length | Should -Be 1
            $output[0].ToString() | Should -MatchExactly $inputText1
        }
    }

    Context "Cmdlet Functionality" {

        It "Path is default Parameter Set 'fhx `$inputFile1'" {

            $result = Format-Hex $inputFile1

            $result | Should -Not -BeNullOrEmpty
            , $result | Should -BeOfType 'Microsoft.PowerShell.Commands.ByteCollection'
            $actualResult = $result.ToString()
            $actualResult | Should -MatchExactly $inputText1
        }

        It "Validate file input from Pipeline 'Get-ChildItem `$inputFile1 | Format-Hex'" {

            $result = Get-ChildItem $inputFile1 | Format-Hex

            $result | Should -Not -BeNullOrEmpty
            , $result | Should -BeOfType 'Microsoft.PowerShell.Commands.ByteCollection'
            $actualResult = $result.ToString()
            $actualResult | Should -MatchExactly $inputText1
        }

        It "Validate that streamed text does not have buffer underrun problems ''a' * 30 | Format-Hex'" {

            $result = "a" * 30 | Format-Hex

            $result | Should -Not -BeNullOrEmpty
            , $result | Should -BeOfType 'Microsoft.PowerShell.Commands.ByteCollection'
            $result.ToString() | Should -MatchExactly "00000000000000000000   61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61  aaaaaaaaaaaaaaaa$($newline)00000000000000000010   61 61 61 61 61 61 61 61 61 61 61 61 61 61        aaaaaaaaaaaaaa  "
        }

        It "Validate that files do not have buffer underrun problems 'Format-Hex -Path `$InputFile4'" {

            $result = Format-Hex -Path $InputFile4

            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 3
            $result[0].ToString() | Should -MatchExactly "00000000000000000000   4E 6F 77 20 69 73 20 74 68 65 20 77 69 6E 74 65  Now is the winte"
            $result[1].ToString() | Should -MatchExactly "00000000000000000010   72 20 6F 66 20 6F 75 72 20 64 69 73 63 6F 6E 74  r of our discont"
            $result[2].ToString() | Should -MatchExactly "00000000000000000020   65 6E 74                                         ent             "
        }
    }

    Context "Count and Offset parameters" {
        It "Count = length" {

            $result = Format-Hex -Path $InputFile4 -Count $inputText4.Length

            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 3
            $result[0].ToString() | Should -MatchExactly "00000000000000000000   4E 6F 77 20 69 73 20 74 68 65 20 77 69 6E 74 65  Now is the winte"
            $result[1].ToString() | Should -MatchExactly "00000000000000000010   72 20 6F 66 20 6F 75 72 20 64 69 73 63 6F 6E 74  r of our discont"
            $result[2].ToString() | Should -MatchExactly "00000000000000000020   65 6E 74                                         ent             "
        }

        It "Count = 1" {
            $result = Format-Hex -Path $inputFile4 -Count 1
            $result.ToString() | Should -MatchExactly    "00000000000000000000   4E                                               N               "
        }

        It "Offset = length" {

            $result = Format-Hex -Path $InputFile4 -Offset $inputText4.Length
            $result | Should -BeNullOrEmpty

            $result = Format-Hex -InputObject $inputText4 -Offset $inputText4.Length
            $result.Bytes | Should -HaveCount 0
        }

        It "Offset = 1" {

            $result = Format-Hex -Path $InputFile4 -Offset 1

            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 3
            $result[0].ToString() | Should -MatchExactly "00000000000000000001   6F 77 20 69 73 20 74 68 65 20 77 69 6E 74 65 72  ow is the winter"
            $result[1].ToString() | Should -MatchExactly "00000000000000000011   20 6F 66 20 6F 75 72 20 64 69 73 63 6F 6E 74 65   of our disconte"
            $result[2].ToString() | Should -MatchExactly "00000000000000000021   6E 74                                            nt              "
        }

        It "Count = 1 and Offset = 1" {
            $result = Format-Hex -Path $inputFile4 -Count 1 -Offset 1
            $result.ToString() | Should -MatchExactly    "00000000000000000001   6F                                               o               "
        }

        It "Count should be > 0" {
            { Format-Hex -Path $inputFile4 -Count 0 } | Should -Throw -ErrorId "ParameterArgumentValidationError,Microsoft.PowerShell.Commands.FormatHex"
        }

        It "Offset should be >= 0" {
            { Format-Hex -Path $inputFile4 -Offset -1 } | Should -Throw -ErrorId "ParameterArgumentValidationError,Microsoft.PowerShell.Commands.FormatHex"
        }

        It "Offset = 0" {

            $result = Format-Hex -Path $InputFile4 -Offset 0

            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 3
            $result[0].ToString() | Should -MatchExactly "00000000000000000000   4E 6F 77 20 69 73 20 74 68 65 20 77 69 6E 74 65  Now is the winte"
            $result[1].ToString() | Should -MatchExactly "00000000000000000010   72 20 6F 66 20 6F 75 72 20 64 69 73 63 6F 6E 74  r of our discont"
            $result[2].ToString() | Should -MatchExactly "00000000000000000020   65 6E 74                                         ent             "
        }
    }
}
