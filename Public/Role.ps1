Class Role {
    [String]$ResourceId
    [String]$ResourceIdDisplayName
    [String]$DisplayName
    [String]$RoleDefinitionId
    [Microsoft.Open.MSGraph.Model.AzureADMSPrivilegedRuleSetting[]]$UserMemberSettings
    [String]$ProviderId

    #Required for if  TicketingRule {"ticketingRequired":true}
    # These variables are shared across each instance of the class
    # since each Role in most cases will use the ticketing system and number
    # user will anyway need to approve use of the system and ticket before each request attempt
    static [string] $TicketingSystem = ""
    static [string] $TicketingNumber

    
    
    Role(){}

    Role(
        [String]$ResourceId,
        [String]$RoleDefinitionId,
        [String]$ProviderId
    ){
        $this.ResourceId = $ResourceId
        $this.RoleDefinitionId = $RoleDefinitionId
        $this.ProviderId = $ProviderId
        $this.DisplayName = ""
        $this.GetPrivilegedRoleDefinition()
        $this.GetPrivilegedRolePrivilegedRoleSetting()
        if($this.ProviderId -eq 'AzureResources'){
            $this.GetPrivilegedResource()
        }
        Write-Verbose "$(logdate) [ResourceId] $($this.ResourceId)"
        Write-Verbose "$(logdate)[ProviderId] $($this.ProviderId)"
        Write-Verbose "$(logdate)[DisplayName] $($this.DisplayName)"
        Write-Verbose "$(logdate)[RoleDefinitionId] $($this.RoleDefinitionId)"
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
            $RoleDefinition = Get-AzureADMSPrivilegedRoleDefinition -ProviderId $this.ProviderId `
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
            $RoleSetting = Get-AzureADMSPrivilegedRoleSetting -ProviderId $this.ProviderId `
            -Filter "ResourceId eq '$($this.ResourceId)' and RoleDefinitionId eq '$($this.RoleDefinitionId)'"
            $this.UserMemberSettings = $RoleSetting.UserMemberSettings
        }
        catch {
            throw
        }
    }

    [void]OpenPrivilegedRoleAssignmentRequest($ObjectId, $Schedule, $Reason, $TicketingSystem, $TicketingNumber){
        Write-Verbose "$(logdate) Open Privileged Role Assignment Request for $($this.DisplayName)"
        Write-Debug "$ObjectId"
        Write-Debug "$Schedule"
        Write-Debug "$Reason"

        

        # Check if ticketing is required
        $TicketingRule = (($this.UserMemberSettings | Where-Object {$_.RuleIdentifier -eq 'TicketingRule'} | Select-Object -First 1).Setting | ConvertFrom-Json).'ticketingRequired'
        if($true -eq $TicketingRule){
            Write-Verbose "$(logdate) Ticketing is required for role $($this.DisplayName)"
            #$this.PromptForTicketingInformation()
            #Prompt for ticketing information
            Write-Host "Ticketing information is required for $($this.DisplayName)"
            Write-Host "It is currently not supported by AzureADPreview."
            Write-Host "Role activation canceled for $($this.DisplayName)"
            return
        }

        # Check if MFA is required
        $MfaRule = (($this.UserMemberSettings | Where-Object {$_.RuleIdentifier -eq 'MfaRule'} | Select-Object -First 1).Setting | ConvertFrom-Json).'mfaRequired'
        if($true -eq $MfaRule){
            Write-Verbose "$(logdate) Mfa is required for role $($this.DisplayName)"
            Write-Host "Mfa is required to activate this role."
            Write-Host "Waiting for Mfa..."
            Connect-PIM -Interactive -RequireMFA
        }

        try{
            $OpenPrivilegedAssignmentRequest = Open-AzureADMSPrivilegedRoleAssignmentRequest `
             -ProviderId $this.ProviderId `
             -ResourceId $this.ResourceId `
             -RoleDefinitionId $this.RoleDefinitionId `
             -SubjectId $ObjectId `
             -Type 'UserAdd' `
             -AssignmentState 'Active' `
             -schedule $Schedule `
             -reason $Reason
             Write-Debug $OpenPrivilegedAssignmentRequest
             Write-Host "Aktiverte $($this.DisplayName)"
         }catch{
              throw "$_" 
         }
    }


    <#

    Id                  : 11c886e0-fd79-4162-83d9-0f2dd63e018b
    ExternalId          : /subscriptions/fbe5505b-e7b7-4cdd-aa50-efccaf5df9a3
    Type                : subscription
    DisplayName         : Visual Studio Enterprise Subscription – MPN
    Status              : Active
    RegisteredDateTime  : 09.02.2021 16:40:22
    RegisteredRoot      :
    RoleAssignmentCount :
    RoleDefinitionCount :
    Permissions         :
    #>
    [void] GetPrivilegedResource(){
        Write-Verbose "$(logdate)Get Privileged Resource"
        Write-Verbose "$(logdate)ResourceId: $($this.ResourceId)"
        $Resource = Get-AzureADMSPrivilegedResource -Provider $this.ProviderId -Id $this.ResourceId
        Write-Verbose "$(logdate)$($Resource.'DisplayName')"
        $this.ResourceIdDisplayName = $Resource.'DisplayName'
        $this.DisplayName = $this.DisplayName + " on " +  $Resource.'DisplayName'
    }


    [string]GetMaximumGrantPeriodInMinutes(){
        return (($this.UserMemberSettings | Where-Object{$_.'RuleIdentifier' -eq 'ExpirationRule'}).Setting | ConvertFrom-Json).maximumGrantPeriodInMinutes
    }

    [void]PromptForTicketingInformation(){
        $this.TicketingSystem = Read-Host -Prompt "Ticket system"
        $this.TicketingNumber = Read-Host -Prompt "Ticket number *" 
    }
}

<#
Get-AzureADMSPrivilegedResource -ProviderId AzureResources | 
Select-Object -Property type, DisplayName, Id | 
%{Get-AzureADMSPrivilegedRoleAssignment -ProviderId AzureResources -ResourceId $_.Id -Filter "(AssignmentState eq 'Eligible') And (MemberType ne 'Inherited') And (SubjectId eq '70327b75-6e39-45b4-87d7-371c8679c02a')"} | 
%{Get-AzureADMSPrivilegedRoleDefinition -ProviderId AzureResources -ResourceId $_.ResourceId -Id $_.RoleDefinitionId} | 
%{Get-AzureADMSPrivilegedRoleSetting -ProviderId AzureResources -Id $_.Id}

#>


<#
Get-AzureADMSPrivilegedRoleAssignmentRequest -ProviderId AzureResources | 
%{Get-AzureADMSPrivilegedRoleDefinition -ProviderId AzureResources -ResourceId $_.ResourceId -Id $_.RoleDefinitionId }


Id                      : acdd72a7-3385-48ef-bd42-f606fba81ae7
ResourceId              : 11c886e0-fd79-4162-83d9-0f2dd63e018b
ExternalId              : /subscriptions/fbe5505b-e7b7-4cdd-aa50-efccaf5df9a3/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7
DisplayName             : Reader
SubjectCount            :
EligibleAssignmentCount :
ActiveAssignmentCount   :

Id                      : b24988ac-6180-42a0-ab88-20f7382dd24c
ResourceId              : 3e38ceeb-8ab8-4ebe-8032-711e6c7806be
ExternalId              : /subscriptions/fbe5505b-e7b7-4cdd-aa50-efccaf5df9a3/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c
DisplayName             : Contributor
SubjectCount            :
EligibleAssignmentCount :
ActiveAssignmentCount   :
#>