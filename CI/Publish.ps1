<#
    .SYNOPSIS
    Deploy module to PowerShellGallery.
#>

[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "Success")]
[CmdletBinding(DefaultParameterSetName = 'ModuleName')]
Param
(
    # The name of the installed module to be deployed, if not provided the name of the .psm1 file in the parent folder is used.
    [Parameter(ParameterSetName = 'ModuleName')]
    [ValidateNotNullOrEmpty()]
    [String]$ModuleName,

    # Publish module from path (module folder), if not provided -ModuleName is used.
    [Parameter(Mandatory, ParameterSetName = 'Path')]
    [ValidateNotNullOrEmpty()]
    [String]$Path,

    # Key for PowerShellGallery deployment, if not provided $env:NugetApiKey is used.
    [ValidateNotNullOrEmpty()]
    [String]$NugetApiKey,

    # Skip Version verification for PowerShellGallery deployment, can be used for first release.
    [Switch]$Force
)
$ErrorActionPreference = 'Stop'

<#
# if path is provided we can get the Module manifest easily
#>
if ($Path) {
    $Path = Resolve-Path -Path $Path
    if ($Path.Count -ne 1) {
        throw ('Invalid Path, $Path.Count: {0}.' -f $Path.Count)
    }
    $Psd1Path = (Get-ChildItem -File -Filter *.psd1 -Path $Path -Recurse)[0].FullName
    $ModuleName = [System.IO.Path]::GetFileNameWithoutExtension($Psd1Path)
    $VersionLocal = (. ([Scriptblock]::Create((Get-Content -Path $Psd1Path | Out-String)))).ModuleVersion
}
else {
    <# 
    # Find the module manifest
    # Get Script Root. Publish.ps1 can only be in one nested folder from root
    # Need to find the name of the Module
    #>

    if ($PSScriptRoot) {
        $ScriptRoot = $PSScriptRoot
    }
    elseif ($psISE.CurrentFile.IsUntitled -eq $false) {
        $ScriptRoot = Split-Path -Path $psISE.CurrentFile.FullPath
    }
    elseif ($null -ne $psEditor.GetEditorContext().CurrentFile.Path -and $psEditor.GetEditorContext().CurrentFile.Path -notlike 'untitled:*') {
        $ScriptRoot = Split-Path -Path $psEditor.GetEditorContext().CurrentFile.Path
    }
    else {
        $ScriptRoot = '.'
    }

    # Get Module Info
    # Can only handle one nested folder.
    if (-not $ModuleName) {
        $ModuleName = [System.IO.Path]::GetFileNameWithoutExtension((Get-ChildItem -File -Filter *.psm1 -Name -Path (Split-Path $ScriptRoot)))
    }
    $VersionLocal = ((Get-Module -Name $ModuleName -ListAvailable).Version | Measure-Object -Maximum).Maximum
}

"[Progress] Starting publish Module: $ModuleName, Version: $VersionLocal."
<#
# Get Module version from Gallery
#>
try {
    $VersionGallery = (Find-Module -Name $ModuleName -ErrorAction Stop).Version
}
catch {
    if ($_.Exception.Message -notlike 'No match was found for the specified search criteria*' -or !$Force) {
        throw $_
    }
}
"[Info] PowerShellGallery. $ModuleName, VersionGallery: $VersionGallery, VersionLocal: $VersionLocal."

<#
# Publish if we have a new version or forced
#>
if ($VersionGallery -lt $VersionLocal -or $Force) {
    if (!$NugetApiKey) {
        $NugetApiKey = $env:NUGETAPIKEY
    }
    "[Info] PowerShellGallery. Deploying $ModuleName version $VersionLocal."
    if ($Path) {
        Publish-Module -NuGetApiKey $NugetApiKey -Path $Path
    }
    else {
        Publish-Module -NuGetApiKey $NugetApiKey -Name $ModuleName  -RequiredVersion $VersionLocal
    }
}
else {
    '[Info] PowerShellGallery Deploy Skipped (Version Check).'
}
'[Progress] Deploy Ended.'