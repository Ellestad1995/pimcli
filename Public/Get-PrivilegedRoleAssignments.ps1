
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
    [cmdletBinding(DefaultParameterSetName='EligibleRoles')]
    param(
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
        $Eligible,
        [Parameter(Mandatory=$false, ParameterSetName='EligibleRoles')]
        [Parameter(Mandatory=$false, ParameterSetName='ActiveRoles')]
        [Parameter(Mandatory=$false, ParameterSetName='DisplayName')]
        [switch]
        $PassThru
    )

    <#
        Get the authenticated user
    #>
    $AuthenticationResult = $null
    try {
        $AuthenticationResult =  Connect-PIM -Silent -PassThru
    }
    catch {
        #Handle exception
        Write-Output "$_"
    }

    if($null -eq $AuthenticationResult){
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
                                    -ResourceId $AuthenticationResult.TenantID `
                                    -Filter "subjectId eq '$($AuthenticationResult.UserObjectId)' And DisplayName eq $($DisplayName)"
    }elseif($Active){
        <#
            Roles that are already active
        #>
        $AzureADRoleAssignments = Get-AzureADMSPrivilegedRoleAssignment `
        -ProviderId "aadRoles" `
        -ResourceId $AuthenticationResult.TenantID `
        -Filter "subjectId eq '$($AuthenticationResult.UserObjectId)' And AssignmentState eq 'Active'"
    }
    elseif($Eligible){
        <#
            Roles that are aligible for activation.
        #>
        $AzureADRoleAssignments = Get-AzureADMSPrivilegedRoleAssignment `
        -ProviderId "aadRoles" `
        -ResourceId $AuthenticationResult.TenantID `
        -Filter "subjectId eq '$($AuthenticationResult.UserObjectId)' And AssignmentState eq 'Eligible'"
    }
    else{
        $AzureADRoleAssignments = Get-AzureADMSPrivilegedRoleAssignment `
                                    -ProviderId "aadRoles" `
                                    -ResourceId $AuthenticationResult.TenantID `
                                    -Filter "subjectId eq '$($AuthenticationResult.UserObjectId)'"
    }
    

    <#
    AzureResources
    #>
    try{
        $AzureResourcesPrivilegedRoleAssignmentRequests = Get-AzureADMSPrivilegedRoleAssignmentRequest -ProviderId 'AzureResources' `
        -Filter "subjectId eq '$($AuthenticationResult.UserObjectId)' And AssignmentState eq 'Eligible'"
        Write-Verbose "$(logdate) AzureResourcesPrivilegedRoleAssignmentRequests: $($AzureResourcesPrivilegedRoleAssignmentRequests.Count)"
    }catch{
        throw $_
    }

    if($null -eq $AzureResourcesPrivilegedRoleAssignmentRequests){
        # There are no role assignments for azure resources for the user
        Write-Verbose "$(logdate) No available role assignments for the signed in user"
    }




    
    [System.Collections.ArrayList]$Roles = @()
    foreach($AzureResourcesPrivilegedRoleAssignmentRequest in $AzureResourcesPrivilegedRoleAssignmentRequests){
        $Roles += [Role]::New($AzureResourcesPrivilegedRoleAssignmentRequest."ResourceId", $AzureResourcesPrivilegedRoleAssignmentRequest."RoleDefinitionId", 'AzureResources')
    }

    foreach($AzureADRoleAssignment in $AzureADRoleAssignments){
        $Roles += [Role]::New($AzureADRoleAssignment."ResourceId", $AzureADRoleAssignment."RoleDefinitionId", 'Aadroles')
    }

    Write-Verbose "Total roles count: $($Roles.Count)"
    
    if($PSBoundParameters.ContainsKey("PassThru") -and $PassThru){
        return $Roles
    }
}
