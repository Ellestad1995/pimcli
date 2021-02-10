
BeforeAll {
    $Path = Resolve-Path (Join-Path -Path $PSScriptRoot '..')
    . $Path\Private\logdate.ps1
    . $PSScriptRoot\Connect-PIM.ps1
    . $PSScriptRoot\Role.ps1
    . $PSScriptRoot\Get-PrivilegedRoleAssignments.ps1  
}
Describe 'Get-PrivilegedRoleAssignments' {
    Context 'Eligible role assignments' {

        BeforeEach {
            Connect-PIM -Silent -PassThru
        }

        It 'Get Eligible roles' {
            $MockRoleAssignmentRequest = Get-Content -Path $Path\Get-PrivilegedRoleAssignments.Tests.json | ConvertFrom-Json
            Get-PrivilegedRoleAssignments -Eligible -PassThru | ConvertTo-Json | should -Be ($MockRoleAssignmentRequest | ConvertTo-Json)
        }

    }
}