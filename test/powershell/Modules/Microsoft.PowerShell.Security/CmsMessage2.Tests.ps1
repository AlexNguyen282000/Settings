﻿# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

using namespace System.Security.Cryptography.X509Certificates
using namespace System.Security.Cryptography

function New-CmsRecipient {
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([System.Security.Cryptography.X509Certificates.X509Certificate2])]
    param([String]$Name, [Switch]$Invalid, [String]$OutPfxFile)
    $hash = [HashAlgorithmName]::SHA256
    $pad = [RSASignaturePadding]::Pkcs1
    $oids = [OidCollection]::new()
    $oids.Add("1.3.6.1.4.1.311.80.1") | Out-Null
    $ext1 = [X509KeyUsageExtension]::new([X509KeyUsageFlags]::DataEncipherment, $false)
    $ext2 = [X509EnhancedKeyUsageExtension]::new($oids, $false)
    $req = ([CertificateRequest]::new("CN=$Name", ([RSA]::Create(2048)), $hash, $pad))
    if (!$Invalid) { ($ext1, $ext2).ForEach( { $req.CertificateExtensions.Add($_) }) }
    $certTmp = $req.CreateSelfSigned([datetime]::Now.AddDays(-1), [datetime]::Now.AddDays(365))
    $certBytes = $certTmp.Export([X509ContentType]::Pfx, "tmp")
    [X509KeyStorageFlags[]]$flags = "PersistKeySet", "Exportable"
    $cert = [X509Certificate2]::new($certBytes, "tmp", $flags)
    if ($OutPfxFile) {
        [System.IO.File]::WriteAllBytes($OutPfxFile, $cert.Export([X509ContentType]::Pfx))
    }
    return $cert
}

Describe "CmsMessage cmdlets using X509 cert" -Tags "CI" {

    BeforeAll {
        Write-Verbose    "Generating certs"
        $vc1 = New-CmsRecipient "ValidCms1"
        $vc2 = New-CmsRecipient "ValidCms2"
        $ic = New-CmsRecipient "InvalidCms" -Invalid
        $tmpfile = New-TemporaryFile
        $certContent = "
            -----BEGIN CERTIFICATE-----
            MIIDXTCCAkWgAwIBAgIQRTsRwsx0LZBHrx9z5Dag2zANBgkqhkiG9w0BAQUFADAh
            MR8wHQYDVQQDDBZNeURhdGFFbmNpcGhlcm1lbnRDZXJ0MCAXDTE0MDcyNTIyMjkz
            OVoYDzMwMTQwNzI1MjIzOTM5WjAhMR8wHQYDVQQDDBZNeURhdGFFbmNpcGhlcm1l
            bnRDZXJ0MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAx3SuShUvnRqn
            tYOIouJdP3wPZ5rtDi2KYPurpngGNZjM0EGDTrnhmEAI8DL4Kp6n/zz1mYVoX73+
            6uCpZX/13VDXg1neebJ261XpBX6FzxtclIQr8ywdUtrEgCnUAhgqgvO1Wwm4ogNR
            tWGCGkmlnqyaoV1j/V4KSn4WvKqSUIOZm0umGCTtNAJ6VtdpYO+uxxnRAapPUCY+
            qQ7DFzTUECIo1lMlBcuMiXj6NSFr4/D7ltkZ27jCdsZmzI7ZvRnDlfSYTPQnAO/E
            0uYn9uyKY/xfngWkUX/pe+j+10Lm1ypbASrj2Ezgf0KeZRXBwqKUOLhKheEmBJ18
            rLV27qwHeQIDAQABo4GOMIGLMA4GA1UdDwEB/wQEAwIEMDAUBgNVHSUEDTALBgkr
            BgEEAYI3UAEwRAYJKoZIhvcNAQkPBDcwNTAOBggqhkiG9w0DAgICAIAwDgYIKoZI
            hvcNAwQCAgCAMAcGBSsOAwIHMAoGCCqGSIb3DQMHMB0GA1UdDgQWBBRIyIzwInLJ
            3B+FajVUFMACf1hrxjANBgkqhkiG9w0BAQUFAAOCAQEAfFt4rmUmWfCbbwi2mCrZ
            Osq0lfVNUiZ+iLlEKga4VAI3sJZRtErnVM70eXUt7XpRaOdIfxjuXFpsgc37KyLi
            ByCORLuRC0itZVs3aba48opfMDXivxBy0ngqCPPLQsyaN9K7WnpvYV1QxiudYwwU
            8U5rFmzlwNLvc3XiyoGWaVZluk2DIJawQ5QYAU9/NMBBCbPHjTG7k0l4cpcEC+Ex
            od3RlO6/MOYuK2WB4VTxKsV80EdA3ljlu7Td8P4movnrbB4rG4wpCpk05eREkg/5
            Y54Ilo9m5OSAWtdx4yfS779eebLgUs3P+dk6EKwovXMokVveZA8cenIp3QkqSpeT
            cQ==
            -----END CERTIFICATE-----
            "
    }

    It " Encrypting with X509Cert" {
        "test" | Protect-CmsMessage -To $vc1 | Should -BeLike '-----BEGIN CMS*'
    }

    It " Encrypting with base64 string" {
        "test" | Protect-CmsMessage -To $certContent | Should -BeLike '-----BEGIN CMS*'
    }

    It " Encrypting with multiple X509Cert" {
        $msg = "test" | Protect-CmsMessage -To $vc1, $vc2 | Should -BeLike '-----BEGIN CMS*'
    }

    It " Decrypt with X509Cert" {
        "test" | Protect-CmsMessage -To $vc1 | Unprotect-CmsMessage -To $vc1 | Should -BeExactly "test"
    }

    It " Decrypt with multiple X509Cert" {
        "test" | Protect-CmsMessage -To $vc1, $vc2 | Unprotect-CmsMessage -To $vc1, $vc2 | Should -BeExactly "test"
    }

    It " Encrypt with invalid cert" {
        { "test" | Protect-CmsMessage -To $ic -ErrorAction Stop } | Should -Throw -ErrorId 'CertificateCannotBeUsedForEncryption'
    }

    It "Encrypt with valid and invalid" {
        { "test" | Protect-CmsMessage -To $vc1, $vc2, $ic -ErrorAction Stop } | Should -Throw -ErrorId 'CertificateCannotBeUsedForEncryption'
    }

    It "Encrypt/Decrypt from file" {
        "test" | Protect-CmsMessage -To $vc1 -OutFile $tmpfile
        $msg = Unprotect-CmsMessage -To $vc1 -Path $tmpfile
        $msg | Should -BeExactly "test"
    }

    It "Get-CmsMessage from content" {
        ("test" | Protect-CmsMessage -To $vc1 | Get-CmsMessage).Content | Should -BeLike '-----BEGIN CMS*'
    }

    It "Get-CmsMessage from file" {
        (Get-CmsMessage -Path $tmpfile).Content | Should -BeLike '-----BEGIN CMS*'
    }
}

Describe "CmsMessage cmdlets using files" -Tags "CI" {

    BeforeAll {
        Write-Verbose    "generating temp cert files"
        $vc1File = New-TemporaryFile
        $vc2File = New-TemporaryFile
        $tempDir = New-Item -ItemType Directory -Path (Join-Path $vc1File.Directory.FullName "psCertTempDir") -Force
        $vc3File = New-Item -Name "vc1.cert" -Path $tempDir
        [System.IO.File]::WriteAllBytes("$vc1File", $vc1.Export("pfx"))
        [System.IO.File]::WriteAllBytes("$vc2File", $vc2.Export("pfx"))
        [System.IO.File]::WriteAllBytes("$vc3File", $vc1.Export("pfx"))
    }

    It "Encrypt With Single File" {
        "test" | Protect-CmsMessage -To "$vc1File" | Unprotect-CmsMessage -To $vc1 | Should -BeExactly "test"
    }

    It "Encrypt With Multiple File" {
        $msg = "test" | Protect-CmsMessage -To "$vc1File", "$vc2File"
        ($msg | Unprotect-CmsMessage -To    $vc1) | Should -BeExactly "test"
        ($msg | Unprotect-CmsMessage -To    $vc2) | Should -BeExactly "test"
    }

    It "Encrypt/Decrypt with Directory" {
        "test" | Protect-CmsMessage -To "$tempDir" | Unprotect-CmsMessage -To "$tempDir" | Should -BeExactly "test"
    }

    It "Decrypt with multiple files" {
        "test" | Protect-CmsMessage -To $vc1 | Unprotect-CmsMessage -To "$vc1File", "$vc2File" | Should -BeExactly "test"
    }
}

Describe "CmsMessage cmdlets using cert Store" -Tags "CI" {

    BeforeAll -Scriptblock {
        Write-Verbose    "adding temp certs to CurrentUser\My Store (on Mac those were added while generating vc1/vc2)"
        $store = [X509Store]::new("My", [StoreLocation]::CurrentUser)
        $store.Open("ReadWrite")
        if (!$IsMacOS) {
            $cert1 = [X509Certificate2]::new("$vc1File")
            $cert2 = [X509Certificate2]::new("$vc2File")
            $store.Add($cert1)
            $store.Add($cert2)
        } else {
            $cert1 = $store.Certificates.Find([X509FindType]::FindByThumbprint, $vc1.Thumbprint, $false)[0]
            $cert2 = $store.Certificates.Find([X509FindType]::FindByThumbprint, $vc2.Thumbprint, $false)[0]
        }
    }

    It "Encrypt/Decrypt using subject" {
        "test" | Protect-CmsMessage -To $cert1.Subject | Unprotect-CmsMessage | Should -BeExactly "test"
        "test" | Protect-CmsMessage -To $cert1.Subject, $cert2.Subject | Unprotect-CmsMessage | Should -BeExactly "test"
    }

    It "Encrypt/Decrypt using Thumbprint" {
        "test" | Protect-CmsMessage -To $cert1.Thumbprint | Unprotect-CmsMessage | Should -BeExactly "test"
        "test" | Protect-CmsMessage -To $cert1.Thumbprint, $cert2.Thumbprint | Unprotect-CmsMessage | Should -BeExactly "test"
    }

    It "Encrypt/Decrypt mix" {
        "test" | Protect-CmsMessage -To $cert1.Thumbprint, $cert2.Subject | Unprotect-CmsMessage | Should -BeExactly "test"
    }

    AfterAll {
        Write-Verbose    "Removing temp files and certs"
        $store.Remove($cert1)
        $store.Remove($cert2)
        if ($IsMacOS) {
            $store.Remove($ic)
        }
        $store.Dispose()
        Remove-Item $vc1File, $vc2File, $tmpfile
        Remove-Item -Recurse $tempDir -Force
    }
}
