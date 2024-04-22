[CmdletBinding()]
param (
    $operation = 'disable'
)

$currentScriptPath = $MyInvocation.MyCommand.Definition
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
$needsRestart = $false

if (-not $isAdmin) {
    Write-Host "Elevating script to admin..."
    if (Get-Command -Name "gsudo" -ErrorAction SilentlyContinue) {
        gsudo $currentScriptPath -operation $operation
        exit
    } else {
        Write-Host "'gsudo' not found, using native elevation..."
        $adminArgs = "-NoProfile -ExecutionPolicy Bypass -File `"$currentScriptPath`" -operation $operation"
        $output = Start-Process -FilePath "powershell" -ArgumentList $adminArgs -Verb RunAs -Wait | Out-String
        Write-Host $output
        exit
    }
}

Write-Host "Vanguard Control"
Write-Host "----------------"

try {
    Write-Host "Operation: $operation"
    switch ($operation) {
        'enable' {
            Write-Host "Attempting to enable VGC & VGK..."
            $vgcService = Get-Service -Name "vgc"
            $vgkService = Get-Service -Name "vgk"

            if (($vgcService.StartType -eq "Manual") -and ( $vgkService.StartType -eq "System")) {
                $alreadyEnabled = "VGC & VGK already enabled"
            } else {
                $vgcService | Set-Service -StartupType "Manual"

                $command = { sc.exe config vgk start= system }
                . $command | Out-Null
                $needsRestart = $true

                $enabled = "VGC & VGK enabled"
            }
        }
        'disable' {
            Write-Host "Attempting to disable VGC & VGK..."
            $vgcService = Get-Service -Name "vgc"
            $vgkService = Get-Service -Name "vgk"

            if (($vgcService.StartType -eq "Disabled") -and ($vgkService.StartType -eq "Disabled")) {
                $alreadyDisabled = "VGC & VGK already disabled"
            } else {

                if (($vgcService.StartType -eq "Manual") -and ($vgkService.StartType -eq "System")) {
                    $vgcService | Set-Service -StartupType "Disabled"
                    Stop-Service $vgcService -ErrorAction SilentlyContinue

                    $vgkService | Set-Service -StartupType "Disabled"
                    Stop-Service $vgkService -ErrorAction SilentlyContinue

                    $disabled = "VGC & VGK disabled"
                }
            }
        }
        'vgk_status' {
            Get-Service -Name "vgk" | Select-Object -Property *
        }
        default {
            $errored = "Error: Invalid operation '$operation'. Valid options are 'enable', 'disable' and 'vgk_status'."
        }
    }

    $output = @($enabled, $alreadyEnabled, $disabled, $alreadyDisabled, $errored) | Where-Object { $_ }
    $output | Out-String
}
catch {
    Write-Error "Error: $_"
}

Get-Process -Name "vgtray" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

if ($needsRestart) {
    Write-Host "To load driver (initiate rootkit), restart is required."
    Restart-Computer -Confirm
}
