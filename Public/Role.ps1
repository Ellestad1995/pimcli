Class Role {
    [String]$ResourceId
    [String]$DisplayName
    [String]$RoleDefinitionId
    [System.Object]$UserMemberSettings
    
    Role(){}

    Role(
        [String]$ResourceId,
        [String]$RoleDefinitionId
    ){
        $this.ResourceId = $ResourceId
        $this.RoleDefinitionId = $RoleDefinitionId
        $this.DisplayName = ""
        $this.GetPrivilegedRoleDefinition()
        $this.GetPrivilegedRolePrivilegedRoleSetting()
        Write-Debug "[ResourceId] $($this.ResourceId)"
        Write-Debug "[DisplayName] $($this.DisplayName)"
        Write-Debug "[RoleDefinitionId] $($this.RoleDefinitionId)"
        #Write-Debug "[UserMemberSettings] $($this.UserMemberSettings)"
    }


    <#
    RunspaceId              : xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
    Id                      : xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
    ResourceId              : xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
    ExternalId              : xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
    DisplayName             : Global Readers
    SubjectCount            :
    EligibleAssignmentCount :
    ActiveAssignmentCount   :
    #>
    [void] GetPrivilegedRoleDefinition(){
        try {
            $RoleDefinition = Get-AzureADMSPrivilegedRoleDefinition -ProviderId aadRoles `
            -ResourceId $this.ResourceId `
            -Filter "Id eq '$($this.RoleDefinitionId)'"
    
            $this.DisplayName = $RoleDefinition."DisplayName"
        }
        catch {
            throw 
        }
    }

    <#
    
    RuleIdentifier    Setting
    --------------    -------
    ExpirationRule    {"permanentAssignment":true,"maximumGrantPeriodInMinutes":120}
    MfaRule           {"mfaRequired":true}
    JustificationRule {"required":true}
    ApprovalRule      {"Approvers":[]}
    TicketingRule     {"ticketingRequired":false}
    AcrsRule          {"acrsRequired":false,"acrs":""}
    #>
    [void] GetPrivilegedRolePrivilegedRoleSetting(){
        try {
            $RoleSetting = Get-AzureADMSPrivilegedRoleSetting -ProviderId aadRoles `
            -Filter "ResourceId eq '$($this.ResourceId)' and RoleDefinitionId eq '$($this.RoleDefinitionId)'"
            $this.UserMemberSettings = $RoleSetting.UserMemberSettings
        }
        catch {
            throw
        }
    }

    [void]OpenPrivilegedRoleAssignmentRequest($ObjectId, $Schedule, $Reason){
        Write-Verbose "Open Privileged Role Assignment Request for"
        Write-Debug "$ObjectId"
        Write-Debug "$Schedule"
        Write-Debug "$Reason"
        try{
            $OpenPrivilegedAssignmentRequest = Open-AzureADMSPrivilegedRoleAssignmentRequest `
             -ProviderId 'aadRoles' `
             -ResourceId $this.ResourceId `
             -RoleDefinitionId $this.RoleDefinitionId `
             -SubjectId $ObjectId `
             -Type 'UserAdd' `
             -AssignmentState 'Active' `
             -schedule $Schedule `
             -reason $Reason
             Write-Debug $OpenPrivilegedAssignmentRequest
             Write-Output "Aktiverte $($this.DisplayName)"
         }catch{
              throw "$_" 
         }
         
    }
    [string]GetMaximumGrantPeriodInMinutes(){
        return (($this.UserMemberSettings | Where-Object{$_.'RuleIdentifier' -eq 'ExpirationRule'}).Setting | ConvertFrom-Json).maximumGrantPeriodInMinutes
    }
}
