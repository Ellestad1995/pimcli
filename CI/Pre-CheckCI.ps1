<#
.SYNOPSIS
    Continous Integration tests
#>
[cmdletbinding(DefaultParameterSetName='Scope')]
param(
    [Parameter(Mandatory = $true, ParameterSetName = 'ModulePath')]
    [ValidateNotNullOrEmpty()]
    [String]$ModulePath,

    # Path to install the module to, PSModulePath "CurrentUser" or "AllUsers", if not provided "CurrentUser" used.
    [Parameter(ParameterSetName = 'Scope')]
    [ValidateSet('CurrentUser', 'AllUsers')]
    [string]
    $Scope = 'CurrentUser',
    [Parameter(ParameterSetName = 'ModulePath')]
    [Parameter(ParameterSetName = 'Scope')]
    [switch]
    $SkipPreChecks
)


<#
    Get the Module
#>
if ($PSScriptRoot) {
    $WorkingDir = Split-Path -Parent $PSScriptRoot
    Push-Location $WorkingDir
}

$psdPath = Get-Item "*.psd1"


if (-not $psdPath -or $psdPath.count -gt 1) {
    if ($PSScriptRoot) { Pop-Location }
    throw "Did not find a unique PSD file "
}
else {

    <#
        Throw the real error when the Powershell guys fixes this
       https://github.com/PowerShell/PowerShell/issues/7495
    #>
    try{
        Test-ModuleManifest -Path $psdPath -ErrorAction stop | Out-Null
    }catch{
        "[WARNING] $(Out-String -InputObject $_)"
    }
    $ModuleName         = $psdPath.Name -replace '\.psd1$' , ''
    $Settings           = $(& ([scriptblock]::Create(($psdPath | Get-Content -Raw))))
    $approvedVerbs      = Get-Verb | Select-Object -ExpandProperty verb
    #$script:warningfile = Join-Path -Path $pwd -ChildPath "warnings.txt"
}

<#######################
    Pre build test
#######################
    Manifest exists
    File defined in manifest exists
#>
if(-not $SkipPreChecks){
    <#
        Check that files in manifest is present
    #>
    foreach($file in $Settings.FileList){
        if(-not (Test-Path -Path $file)){
            Write-Output "File $file defined in manifest is not present"
        }
    }
}
######### pre build test end ##############

<####################
    Build Module
####################

#>

try{
    "[Info] Installing module started"
    <#
    # Creating directory for the module
    #>

    if (-not $ModulePath) {
        if($IsLinux -or $IsMacOS){
            $ModulePathSeparator = ':' 
        }else{
            $ModulePathSeparator = ';' 
        }

        # Install for CurrentUser nothing else is specified.
        if($Scope -eq 'CurrentUser'){
            $dir = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::UserProfile) 
        }else{
            $dir = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::ProgramFiles) 
        }
        
        # Build the ModulePath
        $ModulePath = ($env:PSModulePath -split $ModulePathSeparator).where({$_ -like "$dir*"},"First",1)
        $ModulePath = Join-Path -Path $ModulePath -ChildPath $ModuleName
        $ModulePath = Join-Path -Path $ModulePath -ChildPath $Settings.ModuleVersion # Add the version to the path
    }

    # Create Directory
    if (-not  (Test-Path -Path $ModulePath)) {
        New-Item -Path $ModulePath -ItemType Directory -ErrorAction Stop | Out-Null
        "[Info] Created module folder: $($ModulePath)"
    }

    "[Info] Copying files to $($ModulePath)"
    $outputFile = $psdPath | Copy-Item -Destination $ModulePath -PassThru

    Foreach ($file in $Settings.FileList) {

        # Create Directories if necessary
        if  ($file -like '.\*') {
            $dest = ($file -replace '\.\\',"$ModulePath\") # Create destination filepath
             
            if (-not (Test-Path -PathType Container (Split-Path -Parent $dest))) 
            {
               New-item -Type Directory -Path (Split-Path -Parent $dest) | Out-Null
            }
        }else{
            $dest = $ModulePath
        }
        Copy-Item $file -Destination $dest -Force -Recurse
    }

    $env:PSNewBuildModule = $ModulePath
    if ($Passthru) {$outputFile}

}catch{
    throw ("Failed installing module $($ModuleName). Error: $($_) in Line $($_.InvocationInfo.ScriptLineNumber)")
}finally{
    if ($PSScriptRoot) { Pop-Location }
    Write-Verbose 'Module is installed'
}

# Install required Modules

foreach($RequiredModule in $Settings.RequiredModules){
    "[INFO] Installing required module $($RequiredModule.'ModuleName')"
    $Module = Find-Module $($RequiredModule.'ModuleName')
    if((-not $Module) -or $Module.count -gt 1){
        # Can't determine which module to install
        "[WARNING] Can't determine which module to install for $(Out-String -InputObject $RequiredModule)"
    }else{
        # First check if it already is installed
        $isModuleInstalled = Get-Module -Name $Module.Name
        if(-not $isModuleInstalled){
            try{
                Install-Module $Module.Name -Scope CurrentUser -Repository $Module.Repository -Force -SkipPublisherCheck
            }catch{
                throw
            }
        }else{
            "[INFO] Module $($Module.Name) is alrady installed"
        }
        
    }
}


######## End install module ##############

<########################
    Analyze the module
#########################

    Run PSScriptAnalyzer

#>

try{
    $outputFile | Import-Module -Force -ErrorAction stop 
}catch{
    if ($PSScriptRoot){ 
        Pop-Location 
    }
    throw "New module failed to load"
}

# Run PSScriptAnalyzer

if (!(Get-Module -Name PSScriptAnalyzer -ListAvailable)) {
    '[Progress] Installing PSScriptAnalyzer.'
    Install-Module -Name PSScriptAnalyzer -Force
}

# TODO: get moduleinfo
$ModuleInfo = $null
$PSSAInfo = Import-module -Name PSScriptAnalyzer -PassThru -force
"[Info] Running $PSSAInfo.name V$($PSSAInfo.Version) against $Modulepath V$ModuleInfo"

"[Progress] Running Script Analyzer."

$AnalyzerResults = Invoke-ScriptAnalyzer -Path $ModulePath -Recurse -ErrorAction SilentlyContinue

if($AnalyzerResults){
    # Write the result to file and upload
    $PSScriptAnalyzerResultFile = Join-path $pwd -ChildPath 'PSScriptAnalyzerResult.txt'
    Out-File -InputObject $AnalyzerResults -FilePath $PSScriptAnalyzerResultFile
    if(Test-Path -Path $PSScriptAnalyzerResultFile){
        "Uploading PSScriptAnalyzer results $($PSScriptAnalyzerResultFile)"
        "##vso[task.uploadfile]$($PSScriptAnalyzerResultFile)"
    }
}
