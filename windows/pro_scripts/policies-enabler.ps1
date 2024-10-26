Get-ChildItem @(
     "C:\Windows\servicing\Packages\Microsoft-Windows-GroupPolicy-ClientTools-Package*.mum",
     "C:\Windows\servicing\Packages\Microsoft-Windows-GroupPolicy-ClientExtensions-Package*.mum",
     "C:\Windows\servicing\Packages\*Hyper-V*.mum"
) | ForEach-Object { 
    DISM.exe /online /norestart /add-package:"$_" 
}

DISM.exe /online /add-capability /CapabilityName:Rsat.GroupPolicy.Management.Tools~~~~0.0.1.0
DISM.exe /online /enable-feature /featurename:Microsoft-Hyper-V -All /LimitAccess /ALL

Get-WindowsCapability -Name RSAT* -Online | where State -EQ NotPresent | Add-WindowsCapability –Online

pause
