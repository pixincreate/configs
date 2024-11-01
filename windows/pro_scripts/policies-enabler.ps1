# Retrieve the relevant .mum files and install them using DISM
Get-ChildItem @(
    "C:\Windows\servicing\Packages\Microsoft-Windows-GroupPolicy-ClientTools-Package*.mum",
    "C:\Windows\servicing\Packages\Microsoft-Windows-GroupPolicy-ClientExtensions-Package*.mum",
    "C:\Windows\servicing\Packages\*Hyper-V*.mum"
) | ForEach-Object {
    DISM.exe /online /norestart /add-package:"$($_.FullName)"
}

# Enable Hyper-V Feature
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All

# Add RSAT capabilities
Add-WindowsCapability -Online -Name Rsat.GroupPolicy.Management.Tools~~~~0.0.1.0

# Pause for output
Pause
