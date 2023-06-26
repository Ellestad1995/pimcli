
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
        $SelectedRoleAssignments,
        [parameter(Mandatory=$false, ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $UserObjectId = $Global:CurrentLoggedInUser.ObjectId
    )
    Write-Verbose "Enable-PrivilegedRoleAssignment"

    <#
    # Get eligible role assignments
    #>
    try {
        $null = [Role]
    }
    catch {
        Write-Verbose "Cant't find class Role"
        return
    }

    $EligibleRoles = Get-PrivilegedRoleAssignments -Eligible -Detailed

    <#
        Create the menu items with eligbile roles if the SelectedRoleAssignments is empty.
    #>
    if($null -eq $SelectedRoleAssignments){
        $RoleAssignmentMenuItems = $null
        $RoleAssignmentMenuItems = @()
        $RoleAssignmentMenuItems += $EligibleRoles | %{"$($_.DisplayName) (Max grant period: $($_.GetMaximumGrantPeriodInMinutes()) minutes)"}

        Write-Debug "Role assignments: $(Out-String -InputObject $RoleAssignmentMenuItems)"
        $SelectedRoleAssignments = Menu -menuItems $RoleAssignmentMenuItems -Multiselect 
        Write-Debug "SelectedRoleAssignments: $($SelectedRoleAssignments | %{$_ + " "})"
    }


    if($null -eq $SelectedRoleAssignments){
        Write-Output "No roles selected"
        return
    }

    <#
    # Prompt the user for input to schedule and reason for the privileged role request 
    # Reason: Input a string. The string will be used for all selected role request for the current selected roles
    # Schedule: Input a number/int in hours. The number will be used to all selected role requests for the current selected roles.
    #>
    Write-Output "Selected Role Assignments: $($SelectedRoleAssignments | %{$_ + ", "})"
    $Reason = Read-Host -Prompt "Write a reason for activating one or more roles (This will apply to all selected roles)"
    $InputDuration = Read-Host -Prompt "Write a valid duration in hours for your selected roles (This will apply to all selected roles)"
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
    $schedule.Duration = "PT$($Duration)H" #https://en.wikipedia.org/wiki/ISO_8601#Durations
    $schedule.StartDateTime = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ") 
    #$schedule.endDateTime = $schedule.StartDateTime.AddHours($Duration)

    foreach($SelectedRoleAssignment in $SelectedRoleAssignments){
        Write-Verbose "Privileged role assignment request for $($SelectedRoleAssignment)"
        $SelectedRoleAssignmentDisplayName = ($SelectedRoleAssignment.Split('(').trim())[0]
        $SelectedEligibleRole = $EligibleRoles | Where-Object {$_.DisplayName -match $SelectedRoleAssignmentDisplayName}
        
        Write-Debug "Selected eligible role $($SelectedEligibleRole.DisplayName)"        
        Write-Debug "[Reason] $Reason"
        Write-Debug "[Duration] $Duration"
        
        $SelectedEligibleRole.OpenPrivilegedRoleAssignmentRequest($UserObjectId, $schedule, $Reason)
    }
}