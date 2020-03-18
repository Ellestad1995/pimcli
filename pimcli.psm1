Import-Module "$($PSScriptRoot)\ps-menu\ps-menu.psm1"

if($IsLiniux -or $IsMacOS){
    Write-Warning "Module is not tested on your platform. Please report any issues."
}

Write-Verbose "Checking powershell version"
if($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Warning "Will you consider using Powershell 7. Come on"
    try{
        Import-Module AzureAdPreview -Function Connect-AzureAD, Get-AzureAdUser, Get-AzureADMSPrivilegedRoleDefinition, Get-AzureADMSPrivilegedRoleAssignment 
    } catch {
        throw "Missing module AzureAdPreview. Run Install-Module AzureAdPreview in a Poweshell 5.1 Administrator terminal"
    }
}else{
    try{
        Import-Module AzureAdPreview -UseWindowsPowershell -Function Connect-AzureAD, Get-AzureAdUser, Get-AzureADMSPrivilegedRoleDefinition, Get-AzureADMSPrivilegedRoleAssignment 
    } catch {
        throw "Missing module AzureAdPreview. Run Install-Module AzureAdPreview in a Poweshell 5.1 Administrator terminal"
    }
}


<#
# Privileged Identity Management
# Connect to service 
# Save Connection details
# Save Account details for authenticated user
#>
$AzureAdConnection = $null
$global:DirectoryId = $null # Directory id / Tenant id

function Connect-PIM{
    Write-Verbose "Connect-PIM"
    if($null -eq $AzureAdConnection){
        # Connect prompting for credentials
        Write-Verbose "Connecting to Azure Ad"
        $AzureAdConnection = Connect-AzureAD #Az Account, Environment, TenantId, TenantDomain, AccountType
        if ($null -eq $AzureAdConnection){
            throw "Could not connect to Azure. Exit"
            return
        }
    }

    $global:DirectoryId = $AzureAdConnection."TenantId"
    Write-Verbose "Getting Azure Ad user for the logged in user"
    $CurrentLoggedInUser = Get-AzureAdUser -ObjectId "$($AzureAdConnection.Account)" # ObjectId, DisplayName, userPrincipalName, UserType
    if($null -eq $CurrentLoggedInUser){
        throw "Could not get Azure Ad User"
        return
    }
}



$global:AzureADRoleAssignments = $null 
$global:RoleAssignmentMenuItems = $null
<#
.SYNOPSIS
Gets the Privileged Role assignment for the currently logged in user
Adds the DisplayName to the role assignment so the role assignment is humanly readable
Bulds the menu with the role assignment
.DESCRIPTION
Long description

.EXAMPLE
An example

.NOTES
General notes
#>#
function Get-PrivilegedRoleAssignmentsFromAzure{

    
    <#
    ###########################################################################################################
    ###########################################################################################################
    ###########################################################################################################
    
    Get the role definitions. This gived the DislayName on the cmdlet   Get-AzureADMSPrivilegedRoleAssignmen

    RunspaceId              : xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
    Id                      : xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
    ResourceId              : xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
    ExternalId              : xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
    DisplayName             : Global Readers
    SubjectCount            :
    EligibleAssignmentCount :
    ActiveAssignmentCount   :
    ###########################################################################################################
    ###########################################################################################################
    ###########################################################################################################
    #>
    $ErrorActionPreference = "Stop"
    try{
        Write-Verbose "Getting Role Definitions"
        $RoleDefinitions = Get-AzureADMSPrivilegedRoleDefinition -ProviderId aadRoles -ResourceId $global:DirectoryId
    }catch{
        Write-Error "Could not get Role Definitions. Displayname will be unavailable."
    }finally{
        $ErrorActionPreference = "Continue"
    }
    #####################################################################################

    <#
    ###########################################################################################################
    ###########################################################################################################
    ###########################################################################################################
    
    Get privileged role assinment for the current logged in user.
    Examples below show samples that are received.
    
    ###########################################################################################################
    ###########################################################################################################
    ###########################################################################################################
    #>
    <#
    RunspaceId                     : xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
    Id                             : XXxxxxxxxXxxxxXxxxXXXXxxXXxxXxXXxxxxxXxxXXX-1
    ResourceId                     : xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
    RoleDefinitionId               : xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
    SubjectId                      : xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
    LinkedEligibleRoleAssignmentId : XXxxxxxxxXxxxxXxxxXXXXxxXXxxXxXXxxxxxXxxXXX-1-e
    ExternalId                     : XXxxxxxxxXxxxxXxxxXXXXxxXXxxXxXXxxxxxXxxXXX-1
    StartDateTime                  : 04.03.2020 20:10:10
    EndDateTime                    : 05.03.2020 06:10:10
    AssignmentState                : Active
    MemberType                     : Direct

    RunspaceId                     : xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
    Id                             : XXxxxxxxxXxxxxXxxxXXXXxxXXxxXxXXxxxxxXxxXXX-1-e
    ResourceId                     : xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
    RoleDefinitionId               : xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
    SubjectId                      : xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
    LinkedEligibleRoleAssignmentId :
    ExternalId                     : XXxxxxxxxXxxxxXxxxXXXXxxXXxxXxXXxxxxxXxxXXX-1-e
    StartDateTime                  : 16.02.2020 02:49:08
    EndDateTime                    :
    AssignmentState                : Eligible
    MemberType                     : Direct
    #>
    $global:AzureADRoleAssignments = Get-AzureADMSPrivilegedRoleAssignment -ProviderId "aadRoles" -ResourceId $global:DirectoryId -Filter "subjectId eq '$($CurrentLoggedInUser.ObjectId)'"
    ###################################################################################################

    <#
    ###########################################################################################################
    ###########################################################################################################
    ###########################################################################################################
    
    legge til DisplayName sm ble mottatt fra Get-AzureADMSPrivilegedRoleDefinition, 
    og legge de til i AzureADRoleAssignments som ble mottatt fra Get-AzureADMSPrivilegedRoleAssignment
    
    Bygge opp menyen som skal vise hvilke roller som kan aktiveres.
    
    ###########################################################################################################
    ###########################################################################################################
    ###########################################################################################################
    #>
    $global:RoleAssignmentMenuItems = @() #@("Global Cloud King", "Powershell jedi", "Knight of the Holy shell", "Lord of the Sith")

    foreach($RoleAssignment in $global:AzureADRoleAssignments){
        # Add the displayname to the role assignment
        $RoleDefinitionId = $RoleAssignment."RoleDefinitionId"
        $RoleDefinition = $RoleDefinitions | Where-Object{$_."Id" -eq $RoleDefinitionId}
        $ErrorActionPreference = "Stop"
        try{
            Add-Member -MemberType NoteProperty -InputObject $RoleAssignment -Name "DisplayName" -Value $RoleDefinition."DisplayName"   
        }catch{
            Write-Output "Cannot add RoleDefinition on RoleAssignment"
        }finally{
            $ErrorActionPreference = "Continue"
        }
        if($RoleAssignment."AssignmentState" -ne "Active"){
            $global:RoleAssignmentMenuItems += "$($RoleDefinition."DisplayName")"
        }
    }
    #######################################################################

}


<#
.SYNOPSIS
Short description

.DESCRIPTION
Long description

.EXAMPLE
An example

.NOTES
General notes
#>
function Get-PrivilegedRoleAssignments{
    [cmdletbinding()]
    param(
        [parameter(Mandatory=$false)]
        [switch]
        $Force = $false
    )
    Write-Verbose "Get-PrivilegedRoleAssignments"
    if($Force){
        # Update the cached privileges
        Write-Verbose "Get-PrivilegedRoleAssignments: Using -Force switch. Requesting privileged roles from Azure"
        Get-PrivilegedRoleAssignmentsFromAzure
    }
    $global:AzureADRoleAssignments
}
<#
#############################
########### Get-PrivilegedRoleAssignments 
#############################
#>


<#
# Display the available Role Assignments to the user
# Make it selectable easily
# 
#>

<#
.SYNOPSIS
    Displays a menu to be able to select Priviled Role Assignments

.DESCRIPTION

Default option: If no parameter is specified, displays a menu so the user can select one or more RoleAssignments

Option 1: If DisplayName is passed in, either through pipe or as parameter, the menu doesn't appear. A role assignment request is created for each displayname passed in.


.EXAMPLE
An example

.NOTES
General notes
#>
function Enable-PrivilegedRoleAssignment{
    [CmdletBinding()]
    param(
        # Array with DisplayNames of Role Assignments. E.g. @("Security Administrator","Cloud Device Administrator")
        [parameter(Mandatory=$false, ValueFromPipeline=$true)]
        [string[]]
        $SelectedRoleAssignments
    )
    Write-Verbose "Enable-PrivilegedRoleAssignment"

    if($null -eq $SelectedRoleAssignments){
        $SelectedRoleAssignments = Menu -menuItems $RoleAssignmentMenuItems -Multiselect 
        Write-Verbose "SelectedRoleAssignments: $($SelectedRoleAssignments | %{$_ + " "})"
    }
    <#
    # Ask the user for 
    # Schedule
    # reason
    #>
    $Reason = Read-Host -Prompt "Write a reason for activating one or more roles: "
    $InputDuration = Read-Host -Prompt "Write a duration between 1 and whats allowed in your tenant(e.g. 10)"
    try{
        $Duration = [int]$InputDuration
    }catch{
        Write-Warning "Duration specified is not a valid number."
    }

    if((-not($Duration -is [int])) -or (-not ($Duration -gt 0))){
        # Ikke et tall og ikke duration over 0
        Write-Warning "Cannot use the duration specified."
        return
    }

    $schedule = New-Object Microsoft.Open.MSGraph.Model.AzureADMSPrivilegedSchedule
    $schedule.Type = "Once"
    $schedule.Duration = "PT$($Duration)H"
    $schedule.StartDateTime = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    #$schedule.endDateTime = $schedule.StartDateTime.AddHours($Duration)

    foreach($SelectedRoleAssignment in $SelectedRoleAssignments){
        Write-Verbose "Privileged role assignment request for $($SelectedRoleAssignment)"
        $SelectedRoleAssignmentDefinition = $RoleAssignments | Where-Object {$_.DisplayName -match $SelectedRoleAssignment}
        
        $Reason
        $Duration
        $schedule
        $SelectedRoleAssignmentDefinition
        
        try{
            Open-AzureADMSPrivilegedRoleAssignmentRequest `
            -ProviderId 'aadRoles' `
            -ResourceId $global:DirectoryId `
            -RoleDefinitionId $SelectedRoleAssignmentDefinition."RoleDefinitionId" `
            -SubjectId $CurrentLoggedInUser.ObjectId `
            -Type 'UserAdd' `
            -AssignmentState 'Active' `
            -schedule $schedule `
            -reason $Reason
            
        }catch{
            Write-Error $Error[0]
        }

    }


}
