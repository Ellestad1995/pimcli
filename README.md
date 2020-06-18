# pimcli

## TODO

- [ ] Use Replace all fuctions to use Graph API
- [ ] Add Toast notification for expiring role assignment.
- [ ] Use existing az connection if available
- [ ] 

## Description

pimcli is a command line tool to activate Azure Active Directory Privileged Identity Management roles. 

### usage

```Powershell
#Get-Help pimcli

# Connect to the PIM service
Connect-PIM # Later updates will use existing sessions if availble

# Allows you to see available roles. Is not needed to activate roles
Get-PrivilegedRoleAssignments

# Activate role. Gives a manu to choose roles to activate
Enable-PrivilegedRoleAssignment

```

## Demo

![Enable-PrivilegedRoleAssignment demo](.\fig\demo01.gif)