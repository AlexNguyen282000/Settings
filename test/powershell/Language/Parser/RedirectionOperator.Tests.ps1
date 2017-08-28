Describe "Redirection operator now supports encoding changes" -Tags "CI" {
    BeforeAll {
        $asciiString = "abc"

        if ( $IsWindows ) {
             $asciiCR = "`r`n"
        }
        else {
            $asciiCR = [string][char]10
        }


        # If out-file -encoding happens to have a default, be sure to
        # save it away
        $SavedValue = $null
        $oldDefaultParameterValues = $psDefaultParameterValues
        $psDefaultParameterValues = @{}
    }
    AfterAll {
        # be sure to tidy up afterwards
        $psDefaultParameterValues = $oldDefaultParameterValues
    }
    BeforeEach {
        # start each test with a clean plate!
        $psdefaultParameterValues.Remove("out-file:encoding")
    }
    AfterEach {
        # end each test with a clean plate!
        $psdefaultParameterValues.Remove("out-file:encoding")
    }

    It "If encoding is unset, redirection should be platform appropriate" {
        $asciiString > TESTDRIVE:\file.txt
        $encoder = [Microsoft.PowerShell.EncodingUtils]::GetEncoding("utf8nobom")
        $bytes = get-content -encoding byte TESTDRIVE:\file.txt
        # create the expected
        $BOM = $encoder.GetPreamble()
        $TXT = $encoder.GetBytes($asciiString)
        $CR  = $encoder.GetBytes($asciiCR)
        $expectedBytes = .{ $BOM; $TXT; $CR }
        $bytes.Count | should be $expectedBytes.count
        $bytes -join "-" | should be ($expectedBytes -join "-")
    }

    # WindowsLegacy encoding tests will be done elsewhere
    $availableEncodings = [enum]::GetNames([Microsoft.PowerShell.FileEncoding])|?{@("default","WindowsLegacy") -notcontains $_ }

    foreach($encoding in $availableEncodings) {
        $skipTest = $false
        if ($encoding -eq "default") {
            # [System.Text.Encoding]::Default is exposed by 'System.Private.CoreLib.dll' at
            # runtime via reflection. However,it isn't exposed in the reference contract of
            # 'System.Text.Encoding', and therefore we cannot use 'Encoding.Default' in our
            # code. So we need to skip this encoding in the test.
            $skipTest = $true
        }

        # some of the encodings accepted by out-file aren't real,
        # and out-file has its own translation, so we'll
        # not do that logic here, but simply ignore those encodings
        # as they eventually are translated to "real" encoding
        $enc = [Microsoft.PowerShell.EncodingUtils]::GetEncoding($encoding)
        if ( $enc )
        {
            $msg = "Overriding encoding for out-file is respected for $encoding"
            $BOM = $enc.GetPreamble()
            $TXT = $enc.GetBytes($asciiString)
            $CR  = $enc.GetBytes($asciiCR)
            $expectedBytes = .{ $BOM; $TXT; $CR }
            $psdefaultparameterValues["out-file:encoding"] = "$encoding"
            $asciiString > TESTDRIVE:/file.txt
            $observedBytes = Get-Content -encoding Byte TESTDRIVE:/file.txt
            # THE TEST
            It $msg -Skip:$skipTest {
                $observedBytes.Count | Should be $expectedBytes.Count
                for($i = 0;$i -lt $observedBytes.Count; $i++) {
                    $observedBytes[$i] | Should be $expectedBytes[$i]
                }
            }

        }
    }
}

Describe "File redirection mixed with Out-Null" -Tags CI {
    It "File redirection before Out-Null should work" {
        "some text" > $TestDrive\out.txt | Out-Null
        Get-Content $TestDrive\out.txt | Should Be "some text"

        echo "some more text" > $TestDrive\out.txt | Out-Null
        Get-Content $TestDrive\out.txt | Should Be "some more text"
    }
}
