
BeforeAll {
    $Path = Resolve-Path (Join-Path -Path $PSScriptRoot '..')
    . $Path\Private\logdate.ps1
    . $PSScriptRoot\Connect-PIM.ps1
    . $PSScriptRoot\Role.ps1
    . $PSScriptRoot\Get-PrivilegedRoleAssignments.ps1
    . $PSScriptRoot\Enable-PrivilegedRoleAssignment.ps1
    import-module $Path\Private\ps-menu\ps-menu.psm1
}
Describe 'Enable-PrivilegedRoleAssignment' {
    Context 'Enable eligible privileged role assignments' {

        BeforeEach {
            Connect-PIM -Silent -PassThru
        }

        It 'Enable: reader on subscription' {
            Enable-PrivilegedRoleAssignment
            
            #$MockRoleAssignmentRequest = Get-Content -Path $Path\Get-PrivilegedRoleAssignments.Tests.json | ConvertFrom-Json
            #Get-PrivilegedRoleAssignments -Eligible -PassThru | ConvertTo-Json | should -Be ($MockRoleAssignmentRequest | ConvertTo-Json)
        }

    }
}