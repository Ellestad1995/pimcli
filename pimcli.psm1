<#
.SYNOPSIS
pimcli is a Powershell commandline tool for activating pim-roles in Azure.
.DESCRIPTION

.NOTES
    Author: Joakim Ellestad
#>

# For debuging purposes
$DebugPreference = "continue"
$VerbosePreference = "Continue"

if($PSScriptRoot){
    Write-Debug $PSScriptRoot
}

<#
Import the module PS-Menu in order to display privileged roles in a nice checkbox-style list.
#>
Import-Module "$($PSScriptRoot)\Private\ps-menu\ps-menu.psm1"



Write-Verbose "Checking powershell version and importing modules"
if($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Verbose "Importing necessary modules"
    try{
        Import-Module AzureAdPreview -Function Connect-AzureAD, Get-AzureAdUser, Get-AzureADMSPrivilegedRoleDefinition, Get-AzureADMSPrivilegedRoleAssignment, Open-AzureADMSPrivilegedRoleAssignmentRequest
    } catch {
        throw "Missing module AzureAdPreview. Run Install-Module AzureAdPreview in a Poweshell 5.1 Administrator terminal"
    }
}else{

    if($IsLinux -or $IsMacOS){
        Write-Warning "Module is not tested on your platform. Please report any issues."
    }
    try{
        Import-Module AzureAdPreview -UseWindowsPowershell -Function Connect-AzureAD, Get-AzureAdUser, Get-AzureADMSPrivilegedRoleDefinition, Get-AzureADMSPrivilegedRoleAssignment, Open-AzureADMSPrivilegedRoleAssignmentRequest
    } catch {
        throw "Missing module AzureAdPreview. Run Install-Module AzureAdPreview in a Poweshell 5.1 Administrator terminal"
    }
}

<#
Check if msal.ps is installed
If msal.ps is installed the user can be triggered for mfa token if needed.
#>
try {
    
}
catch {
    
}
if(-not (Get-Package 'msal.ps' -ErrorAction SilentlyContinue)){
    Write-Information "Note that a Powershell module msal.ps is not installed on your system. It is not necessarily needed for pimcli to work." -InformationAction Continue
    Write-Information "Install msal.ps if you need to be prompted for mfa authentication when enabling privileged roles. E.g. have a valid authentication token with mfa." -InformationAction Continue
}else{
    Import-Module MSAL.PS
}


# Import functions
try{
    . "$PSScriptRoot\Public\Connect-pim.ps1"
    . "$PSScriptRoot\Public\Get-PrivilegedRoleAssignments.ps1"
    . "$PSScriptRoot\Public\Enable-PrivilegedRoleAssignment.ps1"
    . "$PSScriptRoot\Public\Role.ps1"
}catch{
    throw "Could not import one or more functions. $_"
}

<#
     Privileged Identity Management
     Connect to service
     Save Connection details
     Save Account details for authenticated user
#>
$global:AzureAdConnection = $null
$global:AzureConnDirectoryId = $null # Directory id / Tenant id
$global:CurrentLoggedInUser = $null # The authenticated user

## Add the DisplayName to the assignments
#$global:RoleAssignmentMenuItems = @() #@("Global Cloud King", "Powershell jedi", "Knight of the Holy shell", "Lord of the Sith")
#$global:RoleAssignmentMenuItems += "$($RoleDefinition."DisplayName")"
$global:RoleAssignmentMenuItems = $null