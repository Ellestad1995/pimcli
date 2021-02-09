
BeforeAll {
    $Path = Resolve-Path (Join-Path -Path $PSScriptRoot '..')
    . $Path\Private\logdate.ps1
    . $PSScriptRoot\Connect-PIM.ps1
  
    
}
Describe 'Connect-pim' {
    Context 'PublicClient-*' {
        BeforeEach {
            $MockConnection = New-Object PSCustomObject -Property @{
                userPrincipalName = 'pim.testesen@nivlheim.cloud'
                UserObjectId = '70327b75-6e39-45b4-87d7-371c8679c02a'
                DisplayName = 'Pim Testesen'
                UserType = 'Member'
                TenantID = '14f35847-d583-4ad4-8d76-f1297bd68c82'
            }
        }

        It 'Login using interactive mode' {
            Connect-PIM -Interactive -PassThru | ConvertTo-Json | Should -Be ($MockConnection | ConvertTo-Json)
        }

        It 'Login using interactive mode with MFA' {
            Connect-PIM -Interactive -RequireMFA -PassThru | ConvertTo-Json | Should -Be ($MockConnection | ConvertTo-Json)
        }
        
        It 'Login using silent mode' {
            Connect-PIM -Silent -PassThru | ConvertTo-Json | Should -Be ($MockConnection | ConvertTo-Json)
        }

        It 'Login using silent mode, but force MFA'{
            Connect-PIM -Silent -RequireMFA -PassThru | ConvertTo-Json | Should -Be ($MockConnection | ConvertTo-Json)
        }
    }
}