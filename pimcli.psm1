<#
.SYNOPSIS
.DESCRIPTION
.NOTES
    Author: Joakim Ellestad
#>

# For debuging purposes
#$DebugPreference = "continue"
#$VerbosePreference = "Continue"

if($PSScriptRoot){
    Write-Debug $PSScriptRoot
}


Import-Module "$($PSScriptRoot)\Private\ps-menu\ps-menu.psm1"
if($IsLiniux -or $IsMacOS){
    Write-Warning "Module is not tested on your platform. Please report any issues."
}

Write-Verbose "Checking powershell version"
if($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Verbose "Will you consider using Powershell 7? Come on"
    try{
        Import-Module AzureAdPreview -Function Connect-AzureAD, Get-AzureAdUser, Get-AzureADMSPrivilegedRoleDefinition, Get-AzureADMSPrivilegedRoleAssignment, Open-AzureADMSPrivilegedRoleAssignmentRequest
    } catch {
        throw "Missing module AzureAdPreview. Run Install-Module AzureAdPreview in a Poweshell 5.1 Administrator terminal"
    }
}else{
    try{
        Import-Module AzureAdPreview -UseWindowsPowershell -Function Connect-AzureAD, Get-AzureAdUser, Get-AzureADMSPrivilegedRoleDefinition, Get-AzureADMSPrivilegedRoleAssignment, Open-AzureADMSPrivilegedRoleAssignmentRequest 
    } catch {
        throw "Missing module AzureAdPreview. Run Install-Module AzureAdPreview in a Poweshell 5.1 Administrator terminal"
    }
}


# Import functions
try{
    . "$PSScriptRoot\Public\Connect-pim.ps1"
    . "$PSScriptRoot\Public\Get-PrivilegedRoleAssignments.ps1"
    . "$PSScriptRoot\Public\Enable-PrivilegedRoleAssignment.ps1"

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