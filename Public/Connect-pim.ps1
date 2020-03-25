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
