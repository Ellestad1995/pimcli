
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
    Get privileged role assinment for the current logged in user.
    Examples below show samples that are received.

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
            Roles that are already active
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
    
    
    [System.Collections.ArrayList]$Roles = $null
    foreach($AzureADRoleAssignment in $AzureADRoleAssignments){
        $Roles += [Role]::New($AzureADRoleAssignment."ResourceId", $AzureADRoleAssignment."RoleDefinitionId")
    }
    return $Roles
}