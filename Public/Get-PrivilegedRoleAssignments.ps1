
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