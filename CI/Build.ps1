[CmdletBinding(DefaultParameterSetName = 'Default')]
param(
    # Path to install the module to, if not provided -Scope used.
    [Parameter(Mandatory, ParameterSetName = 'ModulePath')]
    #[ValidateNotNullOrEmpty()]
    [String]
    $ModulePath,

    # PSModulePath "CurrentUser" or "AllUsers", if not provided "CurrentUser" used.
    [Parameter(Mandatory, ParameterSetName = 'Scope')]
    [ValidateSet('CurrentUser', 'AllUsers')]
    [string]
    $Scope = 'CurrentUser',
    [switch]$Passthru
)

if ($PSScriptRoot) { Push-Location "$PSScriptRoot\.." }

# Get pimcli module manifest
$psdPath = Get-Item -Path "*.psd1"

if (-not $psdPath -or $psdPath.count -gt 1) {
    throw "Did not find a unique PSD file "
}
else {
    # Remove the extension and keep the name
    $ModuleName = $psdPath.Name -replace '\.psd1$' , ''
    # Read in the settings in the manifest
    $Settings   = $(& ([scriptblock]::Create(($psdpath | Get-Content -Raw))))
}



try{
    Write-Verbose "Installing module started"

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
        Write-Verbose "Created module folder: $($ModulePath)"
    }

    Write-Verbose "Copying files to $($ModulePath)"
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