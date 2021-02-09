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
    [CmdletBinding(DefaultParameterSetName = 'PublicClient-Interactive')]
    [OutputType([PSCustomObject])]
    param(
        # Interactive request to acquire token for the specified scope
        [Parameter(Mandatory = $true, ParameterSetName = 'PublicClient-Interactive')]
        [switch] $Interactive,

        # Attempts to acquire an access token from the user token cache.
        [Parameter(Mandatory = $true, ParameterSetName = 'PublicClient-Silent')]
        [switch] $Silent,

        # Identifier of the user. Generally a UPN.
        #[Parameter(Mandatory = $true, ParameterSetName = 'PublicClient-Silent', ValueFromPipelineByPropertyName = $true)]
        #[string] $LoginHint,

        # Force authentication using MFA - sometimes PIM requires mfa authorization
        #[Parameter(Mandatory = $true, ParameterSetName = 'RequireMFA')]
        [Parameter(Mandatory = $false, ParameterSetName = 'PublicClient-Silent')]
        [Parameter(Mandatory = $false, ParameterSetName = 'PublicClient-Interactive')]
        [switch] $RequireMFA,

        # PassThru
        [Parameter(Mandatory = $false, ParameterSetName = 'PublicClient-Interactive')]
        [Parameter(Mandatory = $false, ParameterSetName = 'PublicClient-Silent')]
        [switch] $PassThru
    )

    begin{
        # begin
        Write-Verbose "$(logdate) Running Connect-PIM"
    }

    process{
        $MsalToken  = $null
        switch -wildcard ($PSCmdlet.ParameterSetName) {
            "PublicClient*" { 
               if ($PSBoundParameters.ContainsKey("Interactive") -and $Interactive) {
                   if($PSBoundParameters.ContainsKey("RequireMFA") -and $RequireMFA){
                    Write-Verbose "$(logdate) Connect-PIM -Interactive -RequireMFA"
                        $MsalToken = Get-MSALToken -Scopes @("https://graph.microsoft.com/.default") `
                        -ClientId "1b730954-1685-4b74-9bfd-dac224a7b894" -RedirectUri "urn:ietf:wg:oauth:2.0:oob" `
                        -Authority "https://login.microsoftonline.com/common" `
                        -Interactive `
                        -ExtraQueryParameters @{claims='{"access_token" : {"amr": { "values": ["mfa"] }}}'}
                   }
                   Write-Verbose "$(logdate) Connect-PIM -Interactive"

                    $MsalToken =  Get-MSALToken -Scopes @("https://graph.microsoft.com/.default") `
                    -ClientId "1b730954-1685-4b74-9bfd-dac224a7b894" -RedirectUri "urn:ietf:wg:oauth:2.0:oob" `
                    -Authority "https://login.microsoftonline.com/common" `
                    -Interactive   
                }
                elseif($PSBoundParameters.ContainsKey("Silent") -and $Silent){

                   if($PSBoundParameters.ContainsKey("RequireMFA") -and $RequireMFA){
                    Write-Verbose "$(logdate) Connect-PIM -Silent -RequireMFA"

                        $MsalToken = Get-MSALToken -Scopes @("https://graph.microsoft.com/.default") `
                        -ClientId "1b730954-1685-4b74-9bfd-dac224a7b894" -RedirectUri "urn:ietf:wg:oauth:2.0:oob" `
                        -Authority "https://login.microsoftonline.com/common" `
                        -Silent `
                        -ExtraQueryParameters @{claims='{"access_token" : {"amr": { "values": ["mfa"] }}}'}
                   }
                   Write-Verbose "$(logdate) Connect-PIM -Silent"

                    $MsalToken =  Get-MSALToken -Scopes @("https://graph.microsoft.com/.default") `
                    -ClientId "1b730954-1685-4b74-9bfd-dac224a7b894" -RedirectUri "urn:ietf:wg:oauth:2.0:oob" `
                    -Authority "https://login.microsoftonline.com/common" `
                    -Silent
                }
                
             }
            Default {}
        }

       <#
        
       #>
        $AadResponse = $null
        try {
            $AadResponse = Get-MSALToken -Scopes @("https://graph.windows.net/.default") `
            -ClientId "1b730954-1685-4b74-9bfd-dac224a7b894" `
            -RedirectUri "urn:ietf:wg:oauth:2.0:oob" `
            -Authority "https://login.microsoftonline.com/common"
            Write-Debug "$(logdate) $($AadResponse | fl -force)"
        }
        catch {
            # Catch stuff
        }
        
        if($null -ne $AadResponse){
            $AzureAdConnection = $null
            try {
                $AzureAdConnection = Connect-AzureAD -AadAccessToken $AadResponse.AccessToken `
                -MsAccessToken $MsalToken.AccessToken `
                -AccountId $AadResponse.Account.Username `
                -tenantId $AadResponse."TenantId" 
                Write-Debug "$(logdate) $($AzureAdConnection | fl -force)"
            }
            catch {
                #catch stuff
            }
        }

        if($PSBoundParameters.ContainsKey("PassThru") -and $PassThru){
               
            $CurrentLoggedInUser = Get-AzureAdUser -ObjectId "$($AzureAdConnection.Account)" # ObjectId, DisplayName, userPrincipalName, UserType
            if($null -eq $CurrentLoggedInUser){
                throw "Could not get Azure Ad User"
            }

            $Connection = New-Object PSCustomObject -Property @{
                userPrincipalName = $AadResponse.Account.Username
                UserObjectId = $CurrentLoggedInUser.ObjectId
                DisplayName = $CurrentLoggedInUser.DisplayName
                UserType = $CurrentLoggedInUser.UserType
                TenantID = $AadResponse."TenantId"
            }
            return $Connection
        }
    }
}
