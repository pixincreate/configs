# Define backup location
$backupPath = "$HOME\Desktop\GroupPolicy"

# Create backup directory if it doesn't exist
if (-not (Test-Path -Path $backupPath)) {
    New-Item -ItemType Directory -Path $backupPath
}

# Function to export modified Local Group Policy settings
function Export-ModifiedLocalGPO {
    # Paths for registry where local group policies are stored
    $policyPath = "HKLM:\SOFTWARE\Policies"
    
    # Get all keys under the policies path
    $policies = Get-ChildItem -Path $policyPath -Recurse

    # Check if there are any policies to backup
    if ($policies.Count -eq 0) {
        Write-Host "No modified Local Group Policies found."
        return
    }

    # Loop through policies and export them to a file
    foreach ($policy in $policies) {
        $policyExportPath = Join-Path -Path $backupPath -ChildPath "$($policy.PSChildName)_Policy.reg"
        Export-RegistryKey -Path $policy.PSPath -Destination $policyExportPath
        Write-Host "Exported: $policyExportPath"
    }
}

# Function to export a registry key to a .reg file
function Export-RegistryKey {
    param (
        [string]$Path,
        [string]$Destination
    )
    $regContent = "Windows Registry Editor Version 5.00`n`n"
    $regContent += Get-ItemProperty -Path $Path | Out-String
    Set-Content -Path $Destination -Value $regContent
}

# Call the export function
Export-ModifiedLocalGPO

Write-Host "Backup completed."
