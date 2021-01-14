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
        # Force MFA prompt if it's not prompted by default when logging in to your tenant.
        [Parameter(Mandatory=$false)]
        [bool]
        $ForceMFA,

        [Parameter(Mandatory=$false)]
        [switch]
        $WaitIf
    )
    Write-Verbose "Connect-PIM"    
    #Force a re-authentication to AzureAD using information from the existing connection. But now force MFA prompt
    if($ForceMFA){
        Write-Verbose "Connect AzureAD with enforced MFA prompt"
        # Get token for MS Graph by prompting for MFA
        # Note the ClientID is for Azure AD Powershell
        $MsResponse = Get-MSALToken -Scopes @("https://graph.microsoft.com/.default") `
        -ClientId "1b730954-1685-4b74-9bfd-dac224a7b894" -RedirectUri "urn:ietf:wg:oauth:2.0:oob" `
        -Authority "https://login.microsoftonline.com/common" `
        -Interactive `
        -ExtraQueryParameters @{claims='{"access_token" : {"amr": { "values": ["mfa"] }}}'}
        
        # Get token for AzureAD Graph
        $AadResponse = Get-MSALToken -Scopes @("https://graph.windows.net/.default") `
        -ClientId "1b730954-1685-4b74-9bfd-dac224a7b894" `
        -RedirectUri "urn:ietf:wg:oauth:2.0:oob" `
        -Authority "https://login.microsoftonline.com/common"

        $global:AzureAdConnection = Connect-AzureAD -AadAccessToken $AadResponse.AccessToken `
        -MsAccessToken $MsResponse.AccessToken `
        -AccountId $global:AzureAdConnection.UserPrincipalName `
        -tenantId $global:AzureAdConnection."TenantId"
    }

    # If no connection has been made to AzureAD. Also if forced MFA failed.
    if(($null -eq $global:AzureAdConnection)){        
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
