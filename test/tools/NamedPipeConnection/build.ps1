# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

# Do NOT edit this file.  Edit dobuild.ps1
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "")]
param (
    [Parameter(ParameterSetName="build")]
    [switch]
    $Clean,

    [Parameter(ParameterSetName="build")]
    [switch]
    $Build,

    [Parameter(ParameterSetName="publish")]
    [switch]
    $Publish,

    [Parameter(ParameterSetName="publish")]
    [switch]
    $Signed,

    [Parameter(ParameterSetName="build")]
    [switch]
    $Test,

    [Parameter(ParameterSetName="build")]
    [string[]]
    [ValidateSet("Functional","StaticAnalysis")]
    $TestType = @("Functional"),

    [Parameter(ParameterSetName="help")]
    [switch]
    $UpdateHelp,

    [ValidateSet("Debug", "Release")]
    [string] $BuildConfiguration = "Debug",

    [ValidateSet("net7.0")]
    [string] $BuildFramework = "net7.0"
)

<<<<<<< HEAD
<<<<<<< HEAD
$script:ModuleName = 'Microsoft.PowerShell.NamedPipeConnection'
$script:SrcPath = Join-Path -Path $PSScriptRoot -ChildPath 'src'
$script:OutDirectory = Join-Path -Path $PSScriptRoot -ChildPath 'out'
=======
if ( ! (Get-Module -ErrorAction SilentlyContinue PSPackageProject -ListAvailable)) {
    Install-Module -Name PSPackageProject -MinimumVersion 0.1.17 -Force
}

$config = Get-PSPackageProjectConfiguration -ConfigPath $PSScriptRoot

$script:ModuleName = $config.ModuleName
$script:SrcPath = $config.SourcePath
$script:OutDirectory = $config.BuildOutputPath
$script:SignedDirectory = $config.SignedOutputPath
$script:TestPath = $config.TestPath

$script:ModuleRoot = $PSScriptRoot
$script:Culture = $config.Culture
$script:HelpPath = $config.HelpPath
>>>>>>> Add NamedPipeConnection module to testing tools and add test.
=======
$script:ModuleName = 'Microsoft.PowerShell.NamedPipeConnection'
$script:SrcPath = Join-Path -Path $PSScriptRoot -ChildPath 'src'
$script:OutDirectory = Join-Path -Path $PSScriptRoot -ChildPath 'out'
>>>>>>> Remove PSPackageProject dependency, make tool and test Windows only

$script:BuildConfiguration = $BuildConfiguration
$script:BuildFramework = $BuildFramework

<<<<<<< HEAD
<<<<<<< HEAD
. $PSScriptRoot/doBuild.ps1

if ($Clean)
{
    if (Test-Path "${PSScriptRoot}/out")
    {
        Remove-Item -Path "${PSScriptRoot}/out" -Force -Recurse -ErrorAction Stop -Verbose
    }
=======
if ($env:TF_BUILD) {
    $vstsCommandString = "vso[task.setvariable variable=BUILD_OUTPUT_PATH]$OutDirectory"
    Write-Host ("sending " + $vstsCommandString)
    Write-Host "##$vstsCommandString"

    $vstsCommandString = "vso[task.setvariable variable=SIGNED_OUTPUT_PATH]$SignedDirectory"
    Write-Host ("sending " + $vstsCommandString)
    Write-Host "##$vstsCommandString"
}

=======
>>>>>>> Remove PSPackageProject dependency, make tool and test Windows only
. $PSScriptRoot/doBuild.ps1

if ($Clean)
{
<<<<<<< HEAD
    Remove-Item -Path $OutDirectory -Force -Recurse -ErrorAction Stop -Verbose
>>>>>>> Add NamedPipeConnection module to testing tools and add test.
=======
    if (Test-Path "${PSScriptRoot}/out")
    {
        Remove-Item -Path "${PSScriptRoot}/out" -Force -Recurse -ErrorAction Stop -Verbose
    }
>>>>>>> Remove PSPackageProject dependency, make tool and test Windows only

    if (Test-Path "${SrcPath}/code/bin")
    {
        Remove-Item -Path "${SrcPath}/code/bin" -Recurse -Force -ErrorAction Stop -Verbose
    }

    if (Test-Path "${SrcPath}/code/obj")
    {
        Remove-Item -Path "${SrcPath}/code/obj" -Recurse -Force -ErrorAction Stop -Verbose
    }
}

if (-not (Test-Path $OutDirectory))
{
    $script:OutModule = New-Item -ItemType Directory -Path (Join-Path $OutDirectory $ModuleName)
}
else
{
    $script:OutModule = Join-Path $OutDirectory $ModuleName
}

if ($Build.IsPresent)
{
<<<<<<< HEAD
<<<<<<< HEAD
    Write-Verbose -Verbose -Message "Invoking DoBuild script"
    DoBuild
    Write-Verbose -Verbose -Message "Finished invoking DoBuild script"
=======
    $sb = (Get-Item Function:DoBuild).ScriptBlock
    Invoke-PSPackageProjectBuild -BuildScript $sb -SkipPublish
}

if ($Publish.IsPresent)
{
    Invoke-PSPackageProjectPublish -Signed:$Signed.IsPresent -AllowPreReleaseDependencies
}

if ( $Test.IsPresent ) {
    Invoke-PSPackageProjectTest -Type $TestType
}

if ($UpdateHelp.IsPresent) {
    Add-PSPackageProjectCmdletHelp -ProjectRoot $ModuleRoot -ModuleName $ModuleName -Culture $Culture
>>>>>>> Add NamedPipeConnection module to testing tools and add test.
=======
    Write-Verbose -Verbose -Message "Invoking DoBuild script"
    DoBuild
    Write-Verbose -Verbose -Message "Finished invoking DoBuild script"
>>>>>>> Remove PSPackageProject dependency, make tool and test Windows only
}
