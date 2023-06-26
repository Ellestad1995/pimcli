$module = 'pimcli'


if ($PSScriptRoot) { Push-Location "$PSScriptRoot\..\" }

pwd

dotnet build $PWD\src -o $PWD\output\$module\bin
Copy-Item "$PWD\$module\*" "$PWD\output\$module" -Recurse -Force

Import-Module "$PWD\Output\$module\$module.psd1" -Force
#Invoke-Pester "$PSScriptRoot\Tests"

#dotnet.exe build



#Remove-Module -name pimcli -ErrorAction SilentlyContinue
#import-module .\bin\Debug\netstandard2.0\pimcli.dll 

Get-Command -Module pimcli
