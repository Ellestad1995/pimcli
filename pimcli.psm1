<#
.SYNOPSIS
.DESCRIPTION
.NOTES
    Author: Joakim Ellestad
#>
Import-Module "$($PSScriptRoot)\ps-menu\ps-menu.psm1"
if($IsLiniux -or $IsMacOS){
    Write-Warning "Module is not tested on your platform. Please report any issues."
}

Write-Verbose "Checking powershell version"
if($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Verbose "Will you consider using Powershell 7? Come on"
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
     Privileged Identity Management
     Connect to service 
     Save Connection details
     Save Account details for authenticated user
#>
$global:AzureAdConnection = $null
$global:AzureConnDirectoryId = $null # Directory id / Tenant id
$global:CurrentLoggedInUser = $null # The authenticated user

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
function Connect-PIM{
    [cmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [switch]
        $WaitIf
    )
    Write-Verbose "Connect-PIM"
    if($null -eq $global:AzureAdConnection){
        # Connect prompting for credentials
        Write-Verbose "Connecting to Azure Ad"
        $global:AzureAdConnection = Connect-AzureAD #Az Account, Environment, TenantId, TenantDomain, AccountType
        if ($null -eq $global:AzureAdConnection){
            throw "Could not connect to Azure. Exit"
            return
        }
    }
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "Success")]
    $global:AzureConnDirectoryId = $global:AzureAdConnection."TenantId"
    Write-Verbose "Getting Azure Ad user for the logged in user"
    $global:CurrentLoggedInUser = Get-AzureAdUser -ObjectId "$($global:AzureAdConnection.Account)" # ObjectId, DisplayName, userPrincipalName, UserType
    if($null -eq $global:CurrentLoggedInUser){
        throw "Could not get Azure Ad User"
        return
    }
}



<#
.SYNOPSIS
Gets the Privileged Role assignment for the currently logged in user
Adds the DisplayName to the role assignment so the role assignment is humanly readable.
Bulds the menu with the role assignment
.DESCRIPTION
When a Role is active there will be two occurences of a assignment from Azure.
One with AssignmentState = Eligible and another with AssignmentState = Active.
There is no current usecase for keeping the assignment where AssignmentState equal Eligible. Therefor these are filtered out.

.EXAMPLE
An example

.NOTES
General notes
#>#
function Get-PrivilegedRoleAssignments{
    [cmdletBinding(DefaultParameterSetName='Default')]
    param(
        # By default Get-privilegedRoleAssignments displays the human friendly version. The default switch outputs all data about the role assignment
        [Parameter(Mandatory=$false)]
        [switch]
        $Detailed,
        # Get the details for the specified role
        [Parameter(Mandatory=$false, ParameterSetName='DisplayName')]
        [ValidateNotNullOrEmpty()]
        [string]
        $DisplayName,
        # The Active switch displays the roles which has the AssignmentState equal to Active.
        [Parameter(Mandatory=$false, ParameterSetName='ActiveRoles')]
        [switch]
        $Active,
        # The Eligible switch displays the roles which has the AssignmentState equal to Eligible and is not already Active. Cannot be used with DisplayName parameter
        [Parameter(Mandatory=$false, ParameterSetName='EligibleRoles')]
        [switch]
        $Eligible
    )
    
    if($null -eq $global:AzureConnDirectoryId){
        throw("There are no connection to Azure. Please authenticate first.")
        return
    }
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

    if($DisplayName){
        $ErrorActionPreference = "Stop"
        try{
            Write-Verbose "Getting Role Definition for $DisplayName"
            $RoleDefinitions = Get-AzureADMSPrivilegedRoleDefinition -ProviderId aadRoles -ResourceId $global:AzureConnDirectoryId -Filter "DisplayName eq '$($Displayname)'"
        }catch{
            throw
        }finally{
            $ErrorActionPreference = "Continue"
        }

    }else{
            $ErrorActionPreference = "Stop"
        try{
            Write-Verbose "Getting Role Definitions"
            $RoleDefinitions = Get-AzureADMSPrivilegedRoleDefinition -ProviderId aadRoles -ResourceId $global:AzureConnDirectoryId
        }catch{
            throw
        }finally{
            $ErrorActionPreference = "Continue"
        }
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
    

    if($DisplayName){
        <#
            Role defined by it's DisplayName
        #>
        $AzureADRoleAssignments = Get-AzureADMSPrivilegedRoleAssignment `
                                    -ProviderId "aadRoles" `
                                    -ResourceId $global:AzureConnDirectoryId `
                                    -Filter "subjectId eq '$($global:CurrentLoggedInUser.ObjectId)' And DisplayName eq $($DisplayName)"
    }elseif($Active){
        <#
            Roles that are alreadu active
        #>
        $AzureADRoleAssignments = Get-AzureADMSPrivilegedRoleAssignment `
        -ProviderId "aadRoles" `
        -ResourceId $global:AzureConnDirectoryId `
        -Filter "subjectId eq '$($global:CurrentLoggedInUser.ObjectId)' And AssignmentState eq 'Active'"
    }
    elseif($Eligible){
        <#
            Roles that are aligible for activation.
        #>
        $AzureADRoleAssignments = Get-AzureADMSPrivilegedRoleAssignment `
        -ProviderId "aadRoles" `
        -ResourceId $global:AzureConnDirectoryId `
        -Filter "subjectId eq '$($global:CurrentLoggedInUser.ObjectId)' And AssignmentState eq 'Eligible'"
    }
    else{
        $AzureADRoleAssignments = Get-AzureADMSPrivilegedRoleAssignment `
                                    -ProviderId "aadRoles" `
                                    -ResourceId $global:AzureConnDirectoryId `
                                    -Filter "subjectId eq '$($global:CurrentLoggedInUser.ObjectId)'"
    }
    

    ###################################################################################################

    <#
    ###########################################################################################################
    ###########################################################################################################
    ###########################################################################################################
    
    legge til DisplayName sm ble mottatt fra Get-AzureADMSPrivilegedRoleDefinition, 
    og legge de til i global:AzureADRoleAssignments som ble mottatt fra Get-AzureADMSPrivilegedRoleAssignment
    
    Bygge opp menyen som skal vise hvilke roller som kan aktiveres.
    
    ###########################################################################################################
    ###########################################################################################################
    ###########################################################################################################
    #>
    <#
        All role assignments. Active and Eligible
        | get the assignments which are Active.
        | For each Active assignment, remove the assignment with the same id that is Eligible.
    #>
    #$ActiveAssignmentRoles = $AzureADRoleAssignments | Where-Object {$_AssignmentState -match "Active"}
    
    # Debug
    Write-Debug "AzureADRoleAssignments"
    Write-Debug $(Out-String -InputObject $AzureADRoleAssignments)
    #Write-Debug "ActiveAssignmentRoles"
    #Write-Debug $ActiveAssignmentRoles
    # End debug
<#
    foreach($ActiveAssignment in $ActiveAssignmentRoles){
        $AzureADRoleAssignments.Remove
            (
                ($AzureADRoleAssignments | `
                Where-Object{
                $_."AssignmentState" -match "Eligible" -and `
                $_."ExternalId" -match $ActiveAssignment."LinkedEligibleRoleAssignmentId"})
            )
    }
    Write-Debug "AzureADRoleAssignments after filter"
    Write-Debug $AzureADRoleAssignments
#>
    foreach($RoleAssignment in $AzureADRoleAssignments){
        # Add the displayname to the role assignment
        $RoleDefinitionId = $RoleAssignment."RoleDefinitionId"
        $RoleDefinition = $RoleDefinitions | Where-Object{$_."Id" -eq $RoleDefinitionId}
        $ErrorActionPreference = "Stop"
        try{
            Add-Member -MemberType NoteProperty -InputObject $RoleAssignment -Name "DisplayName" -Value $RoleDefinition."DisplayName"   
        }catch{
            throw("Cannot add RoleDefinition on RoleAssignment")
        }finally{
            $ErrorActionPreference = "Continue"
        }
    }
    #######################################################################

    if($Detailed){
        # Display all
        $AzureADRoleAssignments
    }else{
        # make it human readable
        $AzureADRoleAssignments | Select-Object 'DisplayName','AssignmentState','MemberType','EndDateTime'
    }
}



## Add the DisplayName to the assignments
#$global:RoleAssignmentMenuItems = @() #@("Global Cloud King", "Powershell jedi", "Knight of the Holy shell", "Lord of the Sith")
#$global:RoleAssignmentMenuItems += "$($RoleDefinition."DisplayName")"
$global:RoleAssignmentMenuItems = $null



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
        [ValidateNotNullOrEmpty()]
        [string[]]
        $SelectedRoleAssignments
    )
    Write-Verbose "Enable-PrivilegedRoleAssignment"
   


    <#
        Get the available role assignments
    #>
    if($null -eq $SelectedRoleAssignments){
        $EligibleRoles = Get-PrivilegedRoleAssignments -Eligible
        $RoleAssignmentMenuItems = $null
        $RoleAssignmentMenuItems = @()
        $RoleAssignmentMenuItems += $EligibleRoles | Select-Object 'DisplayName' | %{$_.'DisplayName'}
        Write-Debug "$(Out-String $RoleAssignmentMenuItems)"
        $SelectedRoleAssignments = Menu -menuItems $RoleAssignmentMenuItems -Multiselect 
        Write-Verbose "SelectedRoleAssignments: $($SelectedRoleAssignments | %{$_ + " "})"
    }
    
    <#
    # Ask the user for 
    # Schedule
    # reason
    #>
    Write-Output "Selected Role Assignments: $($SelectedRoleAssignments | %{$_ + ", "})"
    $Reason = Read-Host -Prompt "Write a reason for activating one or more roles: "
    $InputDuration = Read-Host -Prompt "Write a duration between 1 and whats allowed in your tenant(e.g. 10)"
    try{
        $Duration = [int]$InputDuration
    }catch{
        Throw("Duration specified is not a valid number.")
    }

    if((-not($Duration -is [int])) -or (-not ($Duration -gt 0))){
        # Ikke et tall og ikke duration over 0
        throw("Cannot use the duration specified.")
        return
    }

    $schedule = New-Object Microsoft.Open.MSGraph.Model.AzureADMSPrivilegedSchedule
    $schedule.Type = "Once"
    $schedule.Duration = "PT$($Duration)H"
    $schedule.StartDateTime = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    #$schedule.endDateTime = $schedule.StartDateTime.AddHours($Duration)

    foreach($SelectedRoleAssignment in $SelectedRoleAssignments){
        Write-Verbose "Privileged role assignment request for $($SelectedRoleAssignment)"
        $SelectedRoleAssignmentDefinition = $EligibleRoles | Where-Object {$_.DisplayName -match $SelectedRoleAssignment}
        Write-Verbose $SelectedRoleAssignmentDefinition
        Write-Verbose "[Reason] $Reason"
        Write-verbose "[Duration] $Duration"
        Write-verbose "[RoleAssignment] $($SelectedRoleAssignmentDefinition."RoleDefinitionId")"
        
        try{
            Open-AzureADMSPrivilegedRoleAssignmentRequest `
            -ProviderId 'aadRoles' `
            -ResourceId $global:AzureConnDirectoryId `
            -RoleDefinitionId $SelectedRoleAssignmentDefinition."RoleDefinitionId" `
            -SubjectId $global:CurrentLoggedInUser.ObjectId `
            -Type 'UserAdd' `
            -AssignmentState 'Active' `
            -schedule $schedule `
            -reason $Reason
            
        }catch{
             throw
        }
    }
}