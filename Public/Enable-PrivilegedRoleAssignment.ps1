
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
    # Get eligible role assignments
    #>
    $EligibleRoles = Get-PrivilegedRoleAssignments -Eligible -Detailed


    <#
        Create the menu items with eligbile roles if the SelectedRoleAssignments is empty.
    #>
    if($null -eq $SelectedRoleAssignments){
        $RoleAssignmentMenuItems = $null
        $RoleAssignmentMenuItems = @()
        $RoleAssignmentMenuItems += $EligibleRoles | Select-Object 'DisplayName' | %{$_.'DisplayName'}
        Write-Debug "Role assignments: $(Out-String -InputObject $RoleAssignmentMenuItems)"
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
        Write-Debug "Avaialbe eligible roles: $(Out-String -InputObject $EligibleRoles )"
        $SelectedRoleAssignmentDefinition = $EligibleRoles | Where-Object {$_.DisplayName -match $SelectedRoleAssignment}
        Write-Debug $SelectedRoleAssignmentDefinition
        Write-Verbose "[Reason] $Reason"
        Write-verbose "[Duration] $Duration"
        Write-verbose "[RoleDefinitionId] $($SelectedRoleAssignmentDefinition."RoleDefinitionId")"
        
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
            if($null -eq $EligibleRoles){
                Write-Debug "Eligible Roles is empty"
            }else{
                Write-Debug  -Message $(Out-String -InputObject $EligibleRoles) 
            }
            if($null -eq $SelectedRoleAssignments){
                Write-Debug "Selected Role Assignments is empty"
            }else{
                Write-Debug -Message $SelectedRoleAssignments.ToString()
            }
            if($null -eq $SelectedRoleAssignmentDefinition){
                Write-Debug "Selected Role Assignment Definition is empty"
            }else{
                Write-Debug -Message $(Out-String -InputObject $SelectedRoleAssignmentDefinition )
            }
             throw "$_." 
        }
    }
}